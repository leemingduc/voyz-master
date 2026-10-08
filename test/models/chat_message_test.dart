import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/models/chat_message.dart';

void main() {
  test('saved chatbot conversation keeps its messages and title', () {
    final conversation = ChatConversation(
      id: 'chat-1',
      messages: [
        ChatMessage.user('Plan a trip to Busan'),
        ChatMessage.ai('How many days would you like to stay?'),
      ],
      createdAt: DateTime(2026, 10, 7),
      updatedAt: DateTime(2026, 10, 8),
    );

    final restored = ChatConversation.fromMap(conversation.toMap());

    expect(restored.id, 'chat-1');
    expect(restored.title, 'Plan a trip to Busan');
    expect(restored.messages, hasLength(2));
    expect(restored.updatedAt, DateTime(2026, 10, 8));
  });
}
