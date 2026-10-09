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

  test('parses the quoted message attached to a reply', () {
    final message = FriendMessage.fromMap({
      'id': 'message-2',
      'friendship_id': 'friendship-1',
      'sender_id': 'user-1',
      'body': 'Mình đồng ý!',
      'reply_to_message_id': 'message-1',
      'reply_to_body': 'Đi Đà Lạt cuối tuần nhé?',
      'reply_to_sender_id': 'user-2',
      'created_at': '2026-10-09T10:00:00.000Z',
    });

    expect(message.replyToMessageId, 'message-1');
    expect(message.replyToBody, 'Đi Đà Lạt cuối tuần nhé?');
    expect(message.replyToSenderId, 'user-2');
  });

  group('SocialProfile presence and activity', () {
    test('parses last_active_at correctly from map', () {
      final profile = SocialProfile.fromMap({
        'user_id': 'user-123',
        'email': 'user@example.com',
        'display_name': 'Test User',
        'last_active_at': '2026-10-09T12:00:00.000Z',
      });

      expect(profile.userId, 'user-123');
      expect(profile.lastActiveAt, isNotNull);
      expect(profile.lastActiveAt!.toUtc(), DateTime.utc(2026, 10, 9, 12, 0, 0));
    });

    test('isCurrentlyActive returns true when within threshold', () {
      final now = DateTime.utc(2026, 10, 9, 12, 5, 0);
      final activeProfile = SocialProfile(
        userId: 'u1',
        email: 'u1@test.com',
        displayName: 'User 1',
        lastActiveAt: DateTime.utc(2026, 10, 9, 12, 3, 30), // 1.5 min ago
      );

      expect(activeProfile.isCurrentlyActive(now: now), isTrue);
      expect(activeProfile.formatLastActiveText(now: now), 'Đang hoạt động');
    });

    test('isCurrentlyActive returns false and formats minutes when inactive', () {
      final now = DateTime.utc(2026, 10, 9, 12, 30, 0);
      final inactiveProfile = SocialProfile(
        userId: 'u2',
        email: 'u2@test.com',
        displayName: 'User 2',
        lastActiveAt: DateTime.utc(2026, 10, 9, 12, 15, 0), // 15 min ago
      );

      expect(inactiveProfile.isCurrentlyActive(now: now), isFalse);
      expect(inactiveProfile.formatLastActiveText(now: now), 'Hoạt động 15 phút trước');
    });

    test('formats hours and days correctly when offline for longer', () {
      final now = DateTime.utc(2026, 10, 9, 18, 0, 0);
      final profileHoursAgo = SocialProfile(
        userId: 'u3',
        email: 'u3@test.com',
        displayName: 'User 3',
        lastActiveAt: DateTime.utc(2026, 10, 9, 15, 0, 0), // 3 hours ago
      );
      expect(profileHoursAgo.formatLastActiveText(now: now), 'Hoạt động 3 giờ trước');

      final profileDaysAgo = SocialProfile(
        userId: 'u4',
        email: 'u4@test.com',
        displayName: 'User 4',
        lastActiveAt: DateTime.utc(2026, 10, 7, 18, 0, 0), // 2 days ago
      );
      expect(profileDaysAgo.formatLastActiveText(now: now), 'Hoạt động 2 ngày trước');
    });

    test('handles null lastActiveAt gracefully', () {
      const profile = SocialProfile(
        userId: 'u5',
        email: 'u5@test.com',
        displayName: 'User 5',
      );
      expect(profile.isCurrentlyActive(), isFalse);
      expect(profile.formatLastActiveText(), 'Không hoạt động');
    });
  });
}
