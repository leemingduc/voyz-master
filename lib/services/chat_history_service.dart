import 'package:hive_flutter/hive_flutter.dart';
import 'package:voyz/models/chat_message.dart';
import 'package:voyz/services/supabase_service.dart';

/// Persists AI chat history separately for each signed-in account.
class ChatHistoryService {
  ChatHistoryService._();

  static final ChatHistoryService instance = ChatHistoryService._();

  static const _boxPrefix = 'ai_chat_history_';

  Future<List<ChatMessage>> load() async {
    final box = await _openBox();
    return box.values
        .map(ChatMessage.fromMap)
        .where((message) => message.text.isNotEmpty)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> save(List<ChatMessage> messages) async {
    final box = await _openBox();
    await box.clear();
    for (var index = 0; index < messages.length; index++) {
      await box.put(index, messages[index].toMap());
    }
  }

  Future<void> clear() async {
    final box = await _openBox();
    await box.clear();
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
