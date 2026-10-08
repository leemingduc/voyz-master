import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voyz/models/chat_message.dart';
import 'package:voyz/services/supabase_service.dart';

/// Persists AI chat history per account with cloud sync for signed-in users.
class ChatHistoryService {
  ChatHistoryService._();

  static final ChatHistoryService instance = ChatHistoryService._();

  static const _boxPrefix = 'ai_chat_history_';
  static const _conversationsBoxPrefix = 'ai_chat_conversations_';

  /// Local multi-conversation history for the AI Tools chatbot. This keeps
  /// the existing cloud-backed single thread intact while offering the same
  /// ChatGPT-style history menu when users are offline or anonymous.
  Future<ChatConversationHistory> loadConversations({
    String? destinationName,
  }) async {
    final box = await _openConversationsBox();
    final key = _conversationKey(destinationName);
    final stored = box.get(key);
    if (stored is Map) return _historyFromMap(stored);

    final legacy = await _loadLocal();
    if (legacy.isEmpty) {
      return const ChatConversationHistory(conversations: []);
    }
    final conversation = ChatConversation(messages: legacy);
    final history = ChatConversationHistory(
      conversations: [conversation],
      activeConversationId: conversation.id,
    );
    await _saveConversationHistory(box, key, history);
    return history;
  }

  Future<ChatConversationHistory> saveConversation(
    List<ChatMessage> messages, {
    String? conversationId,
    String? destinationName,
  }) async {
    if (messages.isEmpty) {
      return loadConversations(destinationName: destinationName);
    }
    final box = await _openConversationsBox();
    final key = _conversationKey(destinationName);
    final current = await loadConversations(destinationName: destinationName);
    final existing = current.conversations.where(
      (conversation) => conversation.id == conversationId,
    );
    final conversation = existing.isEmpty
        ? ChatConversation(messages: List.of(messages))
        : existing.first.copyWith(
            messages: List.of(messages),
            updatedAt: DateTime.now(),
          );
    final updated = ChatConversationHistory(
      conversations: [
        conversation,
        ...current.conversations.where((item) => item.id != conversation.id),
      ],
      activeConversationId: conversation.id,
    );
    await _saveConversationHistory(box, key, updated);
    return updated;
  }

  Future<ChatConversationHistory> openConversation(
    String id, {
    String? destinationName,
  }) async {
    final box = await _openConversationsBox();
    final key = _conversationKey(destinationName);
    final current = await loadConversations(destinationName: destinationName);
    if (!current.conversations.any((conversation) => conversation.id == id)) {
      return current;
    }
    final updated = ChatConversationHistory(
      conversations: current.conversations,
      activeConversationId: id,
    );
    await _saveConversationHistory(box, key, updated);
    return updated;
  }

  Future<ChatConversationHistory> deleteConversation(
    String id, {
    String? destinationName,
  }) async {
    final box = await _openConversationsBox();
    final key = _conversationKey(destinationName);
    final current = await loadConversations(destinationName: destinationName);
    final conversations = current.conversations
        .where((conversation) => conversation.id != id)
        .toList();
    final updated = ChatConversationHistory(
      conversations: conversations,
      activeConversationId: current.activeConversationId == id
          ? null
          : current.activeConversationId,
    );
    await _saveConversationHistory(box, key, updated);
    return updated;
  }

  Future<List<ChatMessage>> load({String? destinationName}) async {
    final local = await _loadLocal();
    if (_userId == 'anonymous') return local;

    try {
      final threadId = await _ensureThread(destinationName: destinationName);
      final rows = await SupabaseService.instance.client
          .from('chat_messages')
          .select()
          .eq('thread_id', threadId)
          .order('message_index', ascending: true)
          .order('created_at', ascending: true);

      final messages = rows
          .map((row) => _messageFromRow(Map<String, dynamic>.from(row)))
          .where((message) => message.text.isNotEmpty)
          .toList();
      if (messages.isNotEmpty) {
        await _saveLocal(messages);
        return messages;
      }
    } catch (error) {
      debugPrint('Chat cloud load skipped: $error');
    }

    return local;
  }

  Future<void> save(
    List<ChatMessage> messages, {
    String? destinationName,
  }) async {
    await _saveLocal(messages);
    if (_userId == 'anonymous') return;

    try {
      final threadId = await _ensureThread(destinationName: destinationName);
      final client = SupabaseService.instance.client;
      await client.from('chat_messages').delete().eq('thread_id', threadId);
      if (messages.isNotEmpty) {
        await client
            .from('chat_messages')
            .insert(
              List.generate(messages.length, (index) {
                final message = messages[index];
                return {
                  'thread_id': threadId,
                  'user_id': _userId,
                  'role': message.isUser ? 'user' : 'assistant',
                  'content': message.text,
                  'message_index': index,
                  'created_at': message.timestamp.toUtc().toIso8601String(),
                };
              }),
            );
      }
      await client
          .from('chat_threads')
          .update({'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', threadId);
    } catch (error) {
      debugPrint('Chat cloud save skipped: $error');
    }
  }

  Future<void> clear({String? destinationName}) async {
    final box = await _openBox();
    await box.clear();
    if (_userId == 'anonymous') return;

    try {
      final threadId = await _ensureThread(destinationName: destinationName);
      await SupabaseService.instance.client
          .from('chat_messages')
          .delete()
          .eq('thread_id', threadId);
    } catch (error) {
      debugPrint('Chat cloud clear skipped: $error');
    }
  }

  Future<List<ChatMessage>> _loadLocal() async {
    final box = await _openBox();
    return box.values
        .map(ChatMessage.fromMap)
        .where((message) => message.text.isNotEmpty)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> _saveLocal(List<ChatMessage> messages) async {
    final box = await _openBox();
    await box.clear();
    for (var index = 0; index < messages.length; index++) {
      await box.put(index, messages[index].toMap());
    }
  }

  Future<String> _ensureThread({String? destinationName}) async {
    final destination = destinationName?.trim() ?? '';
    final client = SupabaseService.instance.client;
    final existing = await client
        .from('chat_threads')
        .select('id')
        .eq('user_id', _userId)
        .eq('destination_name', destination)
        .maybeSingle();
    if (existing != null) return existing['id'].toString();

    final row = await client
        .from('chat_threads')
        .insert({
          'user_id': _userId,
          'destination_name': destination,
          'title': destination.isEmpty ? 'Travel chat' : destination,
        })
        .select('id')
        .single();
    return row['id'].toString();
  }

  ChatMessage _messageFromRow(Map<String, dynamic> row) {
    return ChatMessage(
      text: row['content']?.toString() ?? '',
      isUser: row['role'] == 'user',
      timestamp:
          DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Future<Box<Map>> _openBox() {
    return Hive.openBox<Map>('$_boxPrefix$_userId');
  }

  Future<Box<Map>> _openConversationsBox() {
    return Hive.openBox<Map>('$_conversationsBoxPrefix$_userId');
  }

  String _conversationKey(String? destinationName) =>
      destinationName?.trim() ?? '';

  ChatConversationHistory _historyFromMap(Map<dynamic, dynamic> map) {
    final rawConversations = map['conversations'];
    final conversations = rawConversations is List
        ? rawConversations
              .whereType<Map>()
              .map(ChatConversation.fromMap)
              .where((conversation) => conversation.messages.isNotEmpty)
              .toList()
        : <ChatConversation>[];
    conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final activeId = map['activeId']?.toString();
    return ChatConversationHistory(
      conversations: conversations,
      activeConversationId:
          conversations.any((conversation) => conversation.id == activeId)
          ? activeId
          : null,
    );
  }

  Future<void> _saveConversationHistory(
    Box<Map> box,
    String key,
    ChatConversationHistory history,
  ) => box.put(key, {
    'activeId': history.activeConversationId,
    'conversations': history.conversations
        .map((conversation) => conversation.toMap())
        .toList(),
  });

  String get _userId {
    try {
      return SupabaseService.instance.auth.currentUser?.id ?? 'anonymous';
    } on AssertionError {
      return 'anonymous';
    }
  }
}
