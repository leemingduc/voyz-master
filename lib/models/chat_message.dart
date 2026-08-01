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
}
