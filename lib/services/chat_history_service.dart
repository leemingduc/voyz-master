import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyz/models/chat_message.dart';
import 'package:voyz/services/supabase_service.dart';

/// Persists AI chat history per account with cloud sync for signed-in users.
class ChatHistoryService {
  ChatHistoryService._();

  static final ChatHistoryService instance = ChatHistoryService._();

  static const _boxPrefix = 'ai_chat_history_';

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
        await client.from('chat_messages').insert(
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
      timestamp: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Future<Box<Map>> _openBox() {
    return Hive.openBox<Map>('$_boxPrefix$_userId');
  }

  String get _userId {
    try {
      return SupabaseService.instance.auth.currentUser?.id ?? 'anonymous';
    } on AssertionError {
      return 'anonymous';
    }
  }
}
