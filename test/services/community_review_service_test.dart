import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/services/community_review_service.dart';

void main() {
  group('reviewerDisplayName', () {
    test('returns null when the profile name is its email', () {
      expect(
        reviewerDisplayName(
          displayName: '  Traveler@Example.com ',
          email: 'traveler@example.com',
        ),
        isNull,
      );
    });

    test('returns a trimmed custom profile name', () {
      expect(
        reviewerDisplayName(
          displayName: '  Minh Anh  ',
          email: 'minh.anh@example.com',
        ),
        'Minh Anh',
      );
    });
  });
}
