import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/services/friends_service.dart';

void main() {
  test('parses a chat-theme event as a system message', () {
    final message = FriendMessage.fromMap({
      'id': 'event-1',
      'friendship_id': 'friendship-1',
      'sender_id': 'user-1',
      'body': 'An đã đổi giao diện thành Twilight',
      'message_type': 'system',
      'created_at': '2026-10-09T10:00:00.000Z',
    });

    expect(message.type, FriendMessageType.system);
    expect(message.isSystem, isTrue);
  });

  test('treats messages created before the migration as normal text', () {
    final message = FriendMessage.fromMap({
      'id': 'message-1',
      'friendship_id': 'friendship-1',
      'sender_id': 'user-1',
      'body': 'Hello',
      'created_at': '2026-10-09T10:00:00.000Z',
    });

    expect(message.type, FriendMessageType.text);
    expect(message.isSystem, isFalse);
  });
}
