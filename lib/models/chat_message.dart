/// Model for a single chat message in the AI Chatbot.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  factory ChatMessage.user(String text) =>
      ChatMessage(text: text, isUser: true, timestamp: DateTime.now());

  factory ChatMessage.ai(String text) =>
      ChatMessage(text: text, isUser: false, timestamp: DateTime.now());

  factory ChatMessage.fromMap(Map<dynamic, dynamic> map) {
    return ChatMessage(
      text: map['text']?.toString() ?? '',
      isUser: map['isUser'] == true,
      timestamp:
          DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };
}
