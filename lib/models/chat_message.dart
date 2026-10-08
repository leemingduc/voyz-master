import 'package:uuid/uuid.dart';
import 'package:voyz/models/ai_action.dart';

/// Model for a single chat message in the AI Chatbot.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final AiAction? action;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.action,
  });

  factory ChatMessage.user(String text) =>
      ChatMessage(text: text, isUser: true, timestamp: DateTime.now());

  factory ChatMessage.ai(String text, {AiAction? action}) =>
      ChatMessage(text: text, isUser: false, timestamp: DateTime.now(), action: action);

  factory ChatMessage.fromMap(Map<dynamic, dynamic> map) {
    final rawAction = map['action'];
    return ChatMessage(
      text: map['text']?.toString() ?? '',
      isUser: map['isUser'] == true,
      timestamp:
          DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      action: rawAction is Map ? AiAction.fromJson(Map<String, dynamic>.from(rawAction)) : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    if (action != null) 'action': action!.toJson(),
  };
}

/// A saved AI Chatbot conversation, shown in the AI Tools history menu.
class ChatConversation {
  ChatConversation({
    String? id,
    required this.messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get title {
    var text = '';
    for (final message in messages) {
      if (message.isUser) {
        text = message.text.trim();
        break;
      }
    }
    if (text.isEmpty && messages.isNotEmpty) text = messages.first.text.trim();
    return text.length <= 48 ? text : '${text.substring(0, 48)}…';
  }

  ChatConversation copyWith({
    List<ChatMessage>? messages,
    DateTime? updatedAt,
  }) => ChatConversation(
    id: id,
    messages: messages ?? this.messages,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory ChatConversation.fromMap(Map<dynamic, dynamic> map) {
    final rawMessages = map['messages'];
    return ChatConversation(
      id: map['id']?.toString(),
      messages: rawMessages is List
          ? rawMessages
                .whereType<Map>()
                .map(ChatMessage.fromMap)
                .where((message) => message.text.isNotEmpty)
                .toList()
          : const [],
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'messages': messages.map((message) => message.toMap()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class ChatConversationHistory {
  const ChatConversationHistory({
    required this.conversations,
    this.activeConversationId,
  });

  final List<ChatConversation> conversations;
  final String? activeConversationId;
}
