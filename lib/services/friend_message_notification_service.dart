import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:voyz/data/friend_message_notification_settings.dart';
import 'package:voyz/services/friends_service.dart';

/// An incoming message that can be presented by the app shell.
class FriendMessageAlert {
  const FriendMessageAlert({required this.friendship, required this.message});

  final Friendship friendship;
  final FriendMessage message;
}

/// Tracks unread friend messages and in-app alerts.
///
/// Existing unread messages are restored from the server, but alerts are sent
/// only for messages received after the realtime listener has started.
class FriendMessageNotificationService {
  FriendMessageNotificationService._();

  static final FriendMessageNotificationService instance =
      FriendMessageNotificationService._();

  final ValueNotifier<Map<String, int>> unreadByFriendship =
      ValueNotifier<Map<String, int>>(const <String, int>{});
  final StreamController<FriendMessageAlert> _alerts =
      StreamController<FriendMessageAlert>.broadcast();
  final Map<String, StreamSubscription<List<FriendMessage>>> _subscriptions =
      <String, StreamSubscription<List<FriendMessage>>>{};
  final Map<String, Set<String>> _knownMessageIds = <String, Set<String>>{};

  String? _currentUserId;
  String? _activeFriendshipId;
  bool _isStarted = false;

  Stream<FriendMessageAlert> get alerts => _alerts.stream;

  /// Starts listeners for the signed-in user's accepted friendships.
  Future<void> start() async {
    String currentUserId;
    try {
      currentUserId = FriendsService.instance.currentUserId;
    } catch (_) {
      await stop();
      return;
    }

    if (_isStarted && _currentUserId == currentUserId) return;

    await stop();
    _isStarted = true;
    _currentUserId = currentUserId;

    try {
      final friendships = await FriendsService.instance.getFriendships();
      if (!_isStarted || _currentUserId != currentUserId) return;

      for (final friendship in friendships.where((item) => item.isAccepted)) {
        await _listenToFriendship(friendship, currentUserId);
      }
    } catch (error) {
      debugPrint('Friend message notification setup error: $error');
    }
  }

  /// Rebuilds listeners after the friendship list changes.
  Future<void> refresh() async {
    await stop();
    await start();
  }

  /// Marks a conversation as read and suppresses alerts while it is open.
  void openConversation(String friendshipId) {
    _activeFriendshipId = friendshipId;
    markRead(friendshipId);
  }

  void closeConversation(String friendshipId) {
    if (_activeFriendshipId == friendshipId) {
      _activeFriendshipId = null;
    }
  }

  void markRead(String friendshipId) {
    final current = unreadByFriendship.value;
    if (current.containsKey(friendshipId)) {
      final updated = Map<String, int>.from(current)..remove(friendshipId);
      unreadByFriendship.value = Map<String, int>.unmodifiable(updated);
    }
    unawaited(_markMessagesReadRemotely(friendshipId));
  }

  Future<void> _markMessagesReadRemotely(String friendshipId) async {
    try {
      await FriendsService.instance.markMessagesRead(friendshipId);
    } catch (error) {
      debugPrint('Friend message read update error: $error');
    }
  }

  Future<void> _markMessagesDeliveredRemotely(String friendshipId) async {
    try {
      await FriendsService.instance.markMessagesDelivered(friendshipId);
    } catch (error) {
      debugPrint('Friend message delivery update error: $error');
    }
  }

  Future<void> stop() async {
    final subscriptions = _subscriptions.values.toList();
    _subscriptions.clear();
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    _knownMessageIds.clear();
    _currentUserId = null;
    _activeFriendshipId = null;
    _isStarted = false;
    unreadByFriendship.value = const <String, int>{};
  }

  Future<void> _listenToFriendship(
    Friendship friendship,
    String currentUserId,
  ) async {
    try {
      final existing = await FriendsService.instance.getMessages(friendship.id);
      if (!_isStarted || _currentUserId != currentUserId) return;

      _knownMessageIds[friendship.id] = existing.map((item) => item.id).toSet();
      final unreadCount = existing
          .where(
            (message) =>
                message.senderId != currentUserId &&
                !message.isRead &&
                !message.isRecalled,
          )
          .length;
      // Fetching this conversation means the signed-in recipient has received
      // its pending messages on this device, including messages sent offline.
      unawaited(_markMessagesDeliveredRemotely(friendship.id));
      if (_activeFriendshipId == friendship.id) {
        markRead(friendship.id);
      } else {
        _updateUnreadCount(friendship.id, unreadCount);
      }
      _subscriptions[friendship.id] = FriendsService.instance
          .streamMessages(friendship.id)
          .listen(
            (messages) => _handleMessages(
              friendship: friendship,
              currentUserId: currentUserId,
              messages: messages,
            ),
            onError: (Object error) {
              debugPrint('Friend message notification stream error: $error');
            },
          );
    } catch (error) {
      debugPrint('Friend message notification listener error: $error');
    }
  }

  void _handleMessages({
    required Friendship friendship,
    required String currentUserId,
    required List<FriendMessage> messages,
  }) {
    if (!_isStarted || _currentUserId != currentUserId) return;

    final known = _knownMessageIds.putIfAbsent(friendship.id, () => <String>{});
    final incoming = <FriendMessage>[];
    var hasUndeliveredIncomingMessage = false;
    for (final message in messages) {
      if (!known.add(message.id)) continue;
      if (message.senderId != currentUserId &&
          !message.isRecalled &&
          !message.isDelivered) {
        hasUndeliveredIncomingMessage = true;
      }
      if (message.senderId != currentUserId &&
          !message.isRecalled &&
          !message.isRead) {
        incoming.add(message);
      }
    }
    if (hasUndeliveredIncomingMessage) {
      unawaited(_markMessagesDeliveredRemotely(friendship.id));
    }
    final unreadCount = messages
        .where(
          (message) =>
              message.senderId != currentUserId &&
              !message.isRead &&
              !message.isRecalled,
        )
        .length;
    _updateUnreadCount(friendship.id, unreadCount);

    if (_activeFriendshipId == friendship.id) {
      markRead(friendship.id);
      return;
    }
    if (incoming.isEmpty) return;

    if (!FriendMessageNotificationSettings.instance.isEnabled(friendship.id)) {
      return;
    }
    _alerts.add(
      FriendMessageAlert(friendship: friendship, message: incoming.last),
    );
  }

  void _updateUnreadCount(String friendshipId, int count) {
    final updated = Map<String, int>.from(unreadByFriendship.value);
    if (count > 0) {
      updated[friendshipId] = count;
    } else {
      updated.remove(friendshipId);
    }
    unreadByFriendship.value = Map<String, int>.unmodifiable(updated);
  }
}
