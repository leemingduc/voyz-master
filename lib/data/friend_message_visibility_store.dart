import 'package:hive/hive.dart';

/// Persists messages that the current user chose to remove only from their
/// own conversation view. The message itself remains available to the friend.
class FriendMessageVisibilityStore {
  FriendMessageVisibilityStore._();

  static const _messageBoxName = 'friend_message_visibility';
  static const _conversationBoxName = 'friend_conversation_visibility';

  static Future<void> hideForUser({
    required String userId,
    required String messageId,
  }) async {
    final box = await Hive.openBox<bool>(_messageBoxName);
    await box.put(_key(userId, messageId), true);
  }

  static Future<Set<String>> hiddenMessageIdsForUser(String userId) async {
    final box = await Hive.openBox<bool>(_messageBoxName);
    final prefix = '$userId:';
    return box.keys
        .whereType<String>()
        .where((key) => key.startsWith(prefix) && box.get(key) == true)
        .map((key) => key.substring(prefix.length))
        .toSet();
  }

  /// Removes all existing messages in this conversation from only this user's
  /// view. Messages received after [clearedAt] remain visible.
  static Future<void> clearConversationForUser({
    required String userId,
    required String friendshipId,
    required DateTime clearedAt,
  }) async {
    final box = await Hive.openBox<int>(_conversationBoxName);
    await box.put(
      _conversationKey(userId, friendshipId),
      clearedAt.toUtc().millisecondsSinceEpoch,
    );
  }

  static Future<DateTime?> clearedAtForUser({
    required String userId,
    required String friendshipId,
  }) async {
    final box = await Hive.openBox<int>(_conversationBoxName);
    final value = box.get(_conversationKey(userId, friendshipId));
    if (value == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true).toLocal();
  }

  static String _key(String userId, String messageId) => '$userId:$messageId';

  static String _conversationKey(String userId, String friendshipId) =>
      '$userId:$friendshipId';
}
