/// Model for a single chat message in the AI Chatbot with optional function call actions.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? actionName;
  final String? actionSummary;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.actionName,
    this.actionSummary,
  });

  factory ChatMessage.user(String text) =>
      ChatMessage(text: text, isUser: true, timestamp: DateTime.now());

  factory ChatMessage.ai(
    String text, {
    String? actionName,
    String? actionSummary,
  }) =>
      ChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
        actionName: actionName,
        actionSummary: actionSummary,
      );

  factory ChatMessage.fromMap(Map<dynamic, dynamic> map) {
    return ChatMessage(
      text: map['text']?.toString() ?? '',
      isUser: map['isUser'] == true,
      timestamp:
          DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      actionName: map['actionName']?.toString(),
      actionSummary: map['actionSummary']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    if (actionName != null) 'actionName': actionName,
    if (actionSummary != null) 'actionSummary': actionSummary,
  };
}
