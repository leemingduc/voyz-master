import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Stores which friend conversations are muted for the signed-in user.
///
/// Muting affects only the in-app banner for that one friend. Unread badges
/// remain visible, and settings from one account never affect another account.
class FriendMessageNotificationSettings {
  FriendMessageNotificationSettings._();

  static final FriendMessageNotificationSettings instance =
      FriendMessageNotificationSettings._();

  static const _boxName = 'friend_message_notification_settings';
  static const _mutedKeyPrefix = 'muted';

  final ValueNotifier<Set<String>> mutedFriendshipIds =
      ValueNotifier<Set<String>>(const <String>{});
  String? _currentUserId;

  bool isEnabled(String friendshipId) =>
      !mutedFriendshipIds.value.contains(friendshipId);

  Future<void> loadForUser(String userId) async {
    final box = await Hive.openBox<bool>(_boxName);
    _currentUserId = userId;
    final prefix = '$_mutedKeyPrefix:$userId:';
    final muted = box.keys
        .whereType<String>()
        .where((key) => key.startsWith(prefix) && box.get(key) == true)
        .map((key) => key.substring(prefix.length))
        .where((friendshipId) => friendshipId.isNotEmpty)
        .toSet();
    mutedFriendshipIds.value = Set<String>.unmodifiable(muted);
  }

  Future<void> setEnabled(String friendshipId, bool enabled) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null || friendshipId.isEmpty) return;
    final updated = Set<String>.from(mutedFriendshipIds.value);
    if (enabled) {
      updated.remove(friendshipId);
    } else {
      updated.add(friendshipId);
    }
    mutedFriendshipIds.value = Set<String>.unmodifiable(updated);

    final box = await Hive.openBox<bool>(_boxName);
    final key = '$_mutedKeyPrefix:$currentUserId:$friendshipId';
    if (enabled) {
      await box.delete(key);
    } else {
      await box.put(key, true);
    }
  }

  void clearUser() {
    _currentUserId = null;
    mutedFriendshipIds.value = const <String>{};
  }
}
