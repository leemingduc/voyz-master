import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyz/services/supabase_service.dart';

class FriendsSetupException implements Exception {
  const FriendsSetupException();

  @override
  String toString() {
    return 'Friends is not ready yet. Please apply the latest Supabase migration first.';
  }
}

class SocialProfile {
  const SocialProfile({
    required this.userId,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.lastActiveAt,
  });

  final String userId;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final DateTime? lastActiveAt;

  /// Returns true if the user has been active within [threshold] (default 3 minutes).
  bool isCurrentlyActive({DateTime? now, Duration threshold = const Duration(minutes: 3)}) {
    if (lastActiveAt == null) return false;
    final current = now ?? DateTime.now();
    final difference = current.difference(lastActiveAt!);
    return !difference.isNegative && difference <= threshold;
  }

  /// Formats the last active timestamp into a human-readable string.
  /// When active: "Đang hoạt động"
  /// When < 1 min: "Vừa mới truy cập"
  /// When < 60 min: "Hoạt động X phút trước"
  /// When < 24 hrs: "Hoạt động X giờ trước"
  /// When < 7 days: "Hoạt động X ngày trước"
  /// Otherwise: "Hoạt động dd/MM"
  String formatLastActiveText({DateTime? now, String activeText = 'Đang hoạt động'}) {
    if (lastActiveAt == null) return 'Không hoạt động';
    final current = now ?? DateTime.now();
    final difference = current.difference(lastActiveAt!);
    if (difference.isNegative || difference.inMinutes < 3) {
      return activeText;
    }
    final minutes = difference.inMinutes;
    if (minutes < 60) {
      return 'Hoạt động $minutes phút trước';
    }
    final hours = difference.inHours;
    if (hours < 24) {
      return 'Hoạt động $hours giờ trước';
    }
    final days = difference.inDays;
    if (days == 1) {
      return 'Hoạt động hôm qua';
    }
    if (days < 7) {
      return 'Hoạt động $days ngày trước';
    }
    final day = lastActiveAt!.day.toString().padLeft(2, '0');
    final month = lastActiveAt!.month.toString().padLeft(2, '0');
    return 'Hoạt động $day/$month';
  }

  factory SocialProfile.fromMap(Map<String, dynamic> map) {
    final avatar = map['avatar_url']?.toString() ?? '';
    final lastActiveRaw = map['last_active_at'] ?? map['updated_at'];
    return SocialProfile(
      userId: map['user_id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      displayName: map['display_name']?.toString() ?? '',
      avatarUrl: avatar.isEmpty ? null : avatar,
      lastActiveAt: DateTime.tryParse(lastActiveRaw?.toString() ?? '')?.toLocal(),
    );
  }
}

class Friendship {
  const Friendship({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.createdAt,
    required this.friend,
  });

  final String id;
  final String requesterId;
  final String addresseeId;
  final String status;
  final DateTime createdAt;
  final SocialProfile friend;

  bool get isAccepted => status == 'accepted';
}

class FriendMessage {
  static const recalledBody = 'Tin nhắn đã được thu hồi';

  const FriendMessage({
    required this.id,
    required this.friendshipId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.type = FriendMessageType.text,
    this.deliveredAt,
    this.readAt,
    this.replyToMessageId,
    this.replyToBody,
    this.replyToSenderId,
    this.recalledAt,
  });

  final String id;
  final String friendshipId;
  final String senderId;
  final String body;
  final DateTime createdAt;
  final FriendMessageType type;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? replyToMessageId;
  final String? replyToBody;
  final String? replyToSenderId;
  final DateTime? recalledAt;

  /// A read message has necessarily reached the recipient too.
  bool get isDelivered => deliveredAt != null || readAt != null;
  bool get isRead => readAt != null;
  bool get isSystem => type == FriendMessageType.system;
  bool get isRecalled => recalledAt != null || body == recalledBody;

  factory FriendMessage.fromMap(Map<String, dynamic> map) {
    return FriendMessage(
      id: map['id']?.toString() ?? '',
      friendshipId: map['friendship_id']?.toString() ?? '',
      senderId: map['sender_id']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      type: FriendMessageType.fromDatabaseValue(
        map['message_type']?.toString(),
      ),
      deliveredAt: DateTime.tryParse(
        map['delivered_at']?.toString() ?? '',
      )?.toLocal(),
      readAt: DateTime.tryParse(map['read_at']?.toString() ?? '')?.toLocal(),
      replyToMessageId: _nullableString(map['reply_to_message_id']),
      replyToBody: _nullableString(map['reply_to_body']),
      replyToSenderId: _nullableString(map['reply_to_sender_id']),
      recalledAt: DateTime.tryParse(
        map['recalled_at']?.toString() ?? '',
      )?.toLocal(),
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

enum FriendMessageType {
  text,
  system;

  static FriendMessageType fromDatabaseValue(String? value) {
    return value == 'system'
        ? FriendMessageType.system
        : FriendMessageType.text;
  }
}

class FriendChatTheme {
  const FriendChatTheme({
    required this.themeId,
    this.changedByUserId,
    this.changedAt,
  });

  final String themeId;
  final String? changedByUserId;
  final DateTime? changedAt;

  factory FriendChatTheme.fromMap(Map<String, dynamic> map) {
    return FriendChatTheme(
      themeId: map['chat_theme_id']?.toString() ?? 'aivivu',
      changedByUserId: map['chat_theme_changed_by']?.toString(),
      changedAt: DateTime.tryParse(
        map['chat_theme_changed_at']?.toString() ?? '',
      )?.toLocal(),
    );
  }
}

class FriendsService {
  FriendsService._();

  static final FriendsService instance = FriendsService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  GoTrueClient get _auth => SupabaseService.instance.auth;

  String get currentUserId => _requireUser().id;

  String get currentUserDisplayName {
    final user = _requireUser();
    final metadata = user.userMetadata ?? {};
    final displayName = (metadata['display_name'] ?? metadata['username'] ?? '')
        .toString()
        .trim();
    return displayName.isEmpty ? (user.email ?? 'Bạn') : displayName;
  }

  Future<void> syncCurrentProfile() async {
    final user = _requireUser();
    final metadata = user.userMetadata ?? {};
    final displayName = (metadata['display_name'] ?? metadata['username'] ?? '')
        .toString();
    final avatarUrl = metadata['avatar_url']?.toString();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    await _guardSchema(() async {
      try {
        await _client.from('social_profiles').upsert({
          'user_id': user.id,
          'email': user.email ?? '',
          'display_name': displayName.isEmpty
              ? (user.email ?? 'Traveler')
              : displayName,
          'avatar_url': avatarUrl == null || avatarUrl.isEmpty ? null : avatarUrl,
          'updated_at': nowIso,
          'last_active_at': nowIso,
        }, onConflict: 'user_id');
      } on PostgrestException catch (error) {
        // If last_active_at column has not been added to remote Supabase yet,
        // fall back to updating updated_at.
        if (error.code == '42703' ||
            error.code == 'PGRST204' ||
            error.message.contains('last_active_at')) {
          await _client.from('social_profiles').upsert({
            'user_id': user.id,
            'email': user.email ?? '',
            'display_name': displayName.isEmpty
                ? (user.email ?? 'Traveler')
                : displayName,
            'avatar_url':
                avatarUrl == null || avatarUrl.isEmpty ? null : avatarUrl,
            'updated_at': nowIso,
          }, onConflict: 'user_id');
        } else {
          rethrow;
        }
      }
    });
  }

  /// Updates the current user's last_active_at timestamp in social_profiles.
  Future<void> updateLastActive() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await _guardSchema(() async {
      try {
        await _client.from('social_profiles').update({
          'last_active_at': nowIso,
          'updated_at': nowIso,
        }).eq('user_id', user.id);
      } on PostgrestException catch (error) {
        if (error.code == '42703' ||
            error.code == 'PGRST204' ||
            error.message.contains('last_active_at')) {
          await _client.from('social_profiles').update({
            'updated_at': nowIso,
          }).eq('user_id', user.id);
        } else {
          rethrow;
        }
      }
    });
  }

  /// Fetches the profile of a single user.
  Future<SocialProfile?> getProfile(String userId) async {
    return _guardSchema(() async {
      final row = await _client
          .from('social_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return null;
      return SocialProfile.fromMap(Map<String, dynamic>.from(row));
    });
  }

  /// Realtime stream of a user's social profile.
  Stream<SocialProfile?> streamProfile(String userId) {
    return _client
        .from('social_profiles')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((rows) {
          if (rows.isEmpty) return null;
          return SocialProfile.fromMap(Map<String, dynamic>.from(rows.first));
        });
  }

  Future<List<SocialProfile>> searchProfiles(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];
    await syncCurrentProfile();
    final currentId = currentUserId;
    final escaped = _escapeSearch(trimmed);

    return _guardSchema(() async {
      final byEmail = await _client
          .from('social_profiles')
          .select()
          .ilike('email', '%$escaped%')
          .neq('user_id', currentId)
          .limit(10);
      final byName = await _client
          .from('social_profiles')
          .select()
          .ilike('display_name', '%$escaped%')
          .neq('user_id', currentId)
          .limit(10);

      final byId = <String, SocialProfile>{};
      for (final row in [...byEmail, ...byName]) {
        final profile = SocialProfile.fromMap(Map<String, dynamic>.from(row));
        if (profile.userId.isNotEmpty) byId[profile.userId] = profile;
      }
      return byId.values.toList();
    });
  }

  Future<void> sendFriendRequest(String addresseeId) async {
    final requesterId = currentUserId;
    if (requesterId == addresseeId) return;
    final pair = _orderedPair(requesterId, addresseeId);

    await _guardSchema(() async {
      final existing = await _client
          .from('friendships')
          .select()
          .eq('user_low', pair.$1)
          .eq('user_high', pair.$2)
          .maybeSingle();

      if (existing != null) {
        final map = Map<String, dynamic>.from(existing);
        final id = map['id']?.toString() ?? '';
        final status = map['status']?.toString() ?? 'pending';
        final incoming = map['addressee_id']?.toString() == requesterId;
        if (status == 'pending' && incoming && id.isNotEmpty) {
          await acceptFriendRequest(id);
        }
        return;
      }

      await _client.from('friendships').insert({
        'requester_id': requesterId,
        'addressee_id': addresseeId,
        'user_low': pair.$1,
        'user_high': pair.$2,
        'status': 'pending',
      });
    });
  }

  Future<void> acceptFriendRequest(String friendshipId) async {
    await _guardSchema(() async {
      await _client
          .from('friendships')
          .update({
            'status': 'accepted',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', friendshipId);
    });
  }

  /// Removes the relationship for both people. The database cascades this to
  /// the associated friend messages.
  Future<void> removeFriend(String friendshipId) async {
    await _guardSchema(() async {
      final deleted = await _client
          .from('friendships')
          .delete()
          .eq('id', friendshipId)
          .select('id');
      if (deleted.isEmpty) {
        throw StateError('Friendship is no longer available.');
      }
    });
  }

  /// Records that the current user cleared this conversation. Messages remain
  /// available to the other participant and messages sent afterwards still
  /// appear for the current user.
  Future<void> clearConversationForCurrentUser({
    required String friendshipId,
    required DateTime clearedAt,
  }) async {
    final userId = currentUserId;
    await _guardSchema(() async {
      await _client.from('friend_conversation_clears').upsert({
        'friendship_id': friendshipId,
        'user_id': userId,
        'cleared_at': clearedAt.toUtc().toIso8601String(),
      }, onConflict: 'friendship_id,user_id');
    });
  }

  /// Reads the server-backed clear timestamp so clearing a conversation is
  /// retained after the user signs out or uses another device.
  Future<DateTime?> conversationClearedAtForCurrentUser(
    String friendshipId,
  ) async {
    final userId = currentUserId;
    return _guardSchema(() async {
      final row = await _client
          .from('friend_conversation_clears')
          .select('cleared_at')
          .eq('friendship_id', friendshipId)
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return null;
      return DateTime.tryParse(row['cleared_at']?.toString() ?? '')?.toLocal();
    });
  }

  Future<List<Friendship>> getFriendships() async {
    await syncCurrentProfile();
    final currentId = currentUserId;

    return _guardSchema(() async {
      final outgoing = await _client
          .from('friendships')
          .select()
          .eq('requester_id', currentId)
          .order('updated_at', ascending: false);
      final incoming = await _client
          .from('friendships')
          .select()
          .eq('addressee_id', currentId)
          .order('updated_at', ascending: false);

      final byId = <String, Map<String, dynamic>>{};
      for (final row in [...outgoing, ...incoming]) {
        final map = Map<String, dynamic>.from(row);
        final id = map['id']?.toString() ?? '';
        if (id.isNotEmpty) byId[id] = map;
      }

      final rows = byId.values.toList()
        ..sort(
          (a, b) => (b['updated_at']?.toString() ?? '').compareTo(
            a['updated_at']?.toString() ?? '',
          ),
        );

      final friendIds = rows
          .map<String>((map) {
            final requester = map['requester_id']?.toString() ?? '';
            final addressee = map['addressee_id']?.toString() ?? '';
            return requester == currentId ? addressee : requester;
          })
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final profiles = await _profilesById(friendIds);
      return rows.map<Friendship>((map) {
        final requester = map['requester_id']?.toString() ?? '';
        final addressee = map['addressee_id']?.toString() ?? '';
        final friendId = requester == currentId ? addressee : requester;
        return Friendship(
          id: map['id']?.toString() ?? '',
          requesterId: requester,
          addresseeId: addressee,
          status: map['status']?.toString() ?? 'pending',
          createdAt:
              DateTime.tryParse(
                map['created_at']?.toString() ?? '',
              )?.toLocal() ??
              DateTime.now(),
          friend:
              profiles[friendId] ??
              SocialProfile(
                userId: friendId,
                email: 'Unknown traveler',
                displayName: 'Traveler',
              ),
        );
      }).toList();
    });
  }

  Future<List<FriendMessage>> getMessages(String friendshipId) async {
    return _guardSchema(() async {
      final rows = await _client
          .from('friend_messages')
          .select()
          .eq('friendship_id', friendshipId)
          .order('created_at', ascending: true)
          .limit(100);
      return rows
          .map<FriendMessage>(
            (row) => FriendMessage.fromMap(Map<String, dynamic>.from(row)),
          )
          .toList();
    });
  }

  /// Realtime stream for messages in a friendship conversation.
  Stream<List<FriendMessage>> streamMessages(String friendshipId) {
    return _client
        .from('friend_messages')
        .stream(primaryKey: ['id'])
        .eq('friendship_id', friendshipId)
        .order('created_at', ascending: true)
        .map(
          (rows) => rows
              .map<FriendMessage>(
                (row) => FriendMessage.fromMap(Map<String, dynamic>.from(row)),
              )
              .toList(),
        );
  }

  Future<FriendChatTheme?> getChatTheme(String friendshipId) async {
    return _guardSchema(() async {
      final row = await _client
          .from('friendships')
          .select('chat_theme_id, chat_theme_changed_by, chat_theme_changed_at')
          .eq('id', friendshipId)
          .maybeSingle();
      if (row == null) return null;
      return FriendChatTheme.fromMap(Map<String, dynamic>.from(row));
    });
  }

  Stream<FriendChatTheme?> streamChatTheme(String friendshipId) {
    return _client
        .from('friendships')
        .stream(primaryKey: ['id'])
        .eq('id', friendshipId)
        .map((rows) {
          if (rows.isEmpty) return null;
          return FriendChatTheme.fromMap(Map<String, dynamic>.from(rows.first));
        });
  }

  /// Opens a lightweight broadcast channel so an already-open chat changes
  /// theme immediately. The database stream remains the durable fallback for
  /// devices that were offline or opened the chat later.
  RealtimeChannel subscribeToChatThemeBroadcast({
    required String friendshipId,
    required void Function(Map<String, dynamic> payload) onThemeChanged,
  }) {
    final channel = _client
        .channel(
          'friend-chat-theme-$friendshipId',
          opts: const RealtimeChannelConfig(ack: true),
        )
        .onBroadcast(event: 'theme_changed', callback: onThemeChanged);
    channel.subscribe();
    return channel;
  }

  Future<void> broadcastChatThemeChange({
    required RealtimeChannel channel,
    required String themeId,
    required String changedByUserId,
  }) {
    return channel.sendBroadcastMessage(
      event: 'theme_changed',
      payload: {'theme_id': themeId, 'changed_by_user_id': changedByUserId},
    );
  }

  /// Opens an ephemeral channel used to show the other participant's typing
  /// state. This is intentionally not stored in the database.
  RealtimeChannel subscribeToTypingBroadcast({
    required String friendshipId,
    required void Function(Map<String, dynamic> payload) onTypingChanged,
  }) {
    final channel = _client
        .channel(
          'friend-chat-typing-$friendshipId',
          opts: const RealtimeChannelConfig(ack: true),
        )
        .onBroadcast(event: 'typing_changed', callback: onTypingChanged);
    channel.subscribe();
    return channel;
  }

  Future<void> broadcastTypingStatus({
    required RealtimeChannel channel,
    required String senderId,
    required bool isTyping,
  }) {
    return channel.sendBroadcastMessage(
      event: 'typing_changed',
      payload: {'sender_id': senderId, 'is_typing': isTyping},
    );
  }

  Future<void> closeRealtimeChannel(RealtimeChannel channel) {
    return _client.removeChannel(channel);
  }

  /// Applies the shared theme and writes the matching system event together.
  /// The database function keeps these operations atomic so the two devices
  /// never receive only one half of the change.
  Future<void> changeChatTheme({
    required String friendshipId,
    required String themeId,
    required String themeName,
  }) async {
    await _guardSchema(() async {
      await _client.rpc(
        'change_friend_chat_theme',
        params: {
          'p_friendship_id': friendshipId,
          'p_theme_id': themeId,
          'p_system_message':
              '$currentUserDisplayName đã đổi giao diện thành $themeName',
        },
      );
    });
  }

  Future<void> sendMessage(
    String friendshipId,
    String body, {
    FriendMessage? replyTo,
  }) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    if (replyTo != null && replyTo.friendshipId != friendshipId) {
      throw ArgumentError('Reply message must belong to this conversation.');
    }
    await _guardSchema(() async {
      await _client.from('friend_messages').insert({
        'friendship_id': friendshipId,
        'sender_id': currentUserId,
        'body': trimmed,
        if (replyTo != null) ...{
          'reply_to_message_id': replyTo.id,
          'reply_to_body': replyTo.body,
          'reply_to_sender_id': replyTo.senderId,
        },
      });
    });
  }

  /// Marks all messages sent by the other participant as read.
  Future<void> markMessagesRead(String friendshipId) async {
    await _guardSchema(() async {
      await _client.rpc(
        'mark_friend_messages_read',
        params: {'p_friendship_id': friendshipId},
      );
    });
  }

  /// Marks messages from the other participant as delivered to this device.
  Future<void> markMessagesDelivered(String friendshipId) async {
    await _guardSchema(() async {
      await _client.rpc(
        'mark_friend_messages_delivered',
        params: {'p_friendship_id': friendshipId},
      );
    });
  }

  /// Replaces a sent message with the shared recall event for both people.
  Future<void> recallMessage(String messageId) async {
    await _guardSchema(() async {
      await _client.rpc(
        'recall_friend_message',
        params: {'p_message_id': messageId},
      );
    });
  }

  Future<Map<String, SocialProfile>> _profilesById(List<String> ids) async {
    if (ids.isEmpty) return const {};
    final rows = await _client
        .from('social_profiles')
        .select()
        .inFilter('user_id', ids);
    final result = <String, SocialProfile>{};
    for (final row in rows) {
      final profile = SocialProfile.fromMap(Map<String, dynamic>.from(row));
      result[profile.userId] = profile;
    }
    return result;
  }

  (String, String) _orderedPair(String a, String b) {
    return a.compareTo(b) <= 0 ? (a, b) : (b, a);
  }

  String _escapeSearch(String value) {
    return value.replaceAll('%', '').replaceAll('_', '').replaceAll(',', '');
  }

  Future<T> _guardSchema<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      if (error.code == '42P01' || error.message.contains('schema cache')) {
        throw const FriendsSetupException();
      }
      rethrow;
    }
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException('loginRequired');
    return user;
  }
}
