import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/models/destination_suggestion.dart';
import 'package:voyz/utils/destination_rating_calculator.dart';

void main() {
  group('DestinationRatingCalculator', () {
    test('has no average and zero votes when there are no reviews', () {
      expect(DestinationRatingCalculator.calculateReviewCount(0), 0);
      expect(DestinationRatingCalculator.calculateAverageRating([]), isNull);
    });

    test('uses only real reviews for count and average', () {
      expect(DestinationRatingCalculator.calculateReviewCount(1), 1);
      expect(DestinationRatingCalculator.calculateAverageRating([4]), 4.0);

      // 5 reviews of 1 star must give 1.0, not a value close to 5.0.
      expect(DestinationRatingCalculator.calculateReviewCount(5), 5);
      expect(
        DestinationRatingCalculator.calculateAverageRating([1, 1, 1, 1, 1]),
        1.0,
      );
      expect(
        DestinationRatingCalculator.calculateAverageRating([5, 4, 3]),
        4.0,
      );
    });

    test('formatVotes returns readable string', () {
      expect(DestinationRatingCalculator.formatVotes(0), 'Chưa có đánh giá');
      expect(DestinationRatingCalculator.formatVotes(1), '1 lượt');
      expect(DestinationRatingCalculator.formatVotes(105), '105 lượt');
    });
  });

  group('DestinationSuggestion rating', () {
    test('keeps zero reviews and zero rating when nothing is provided', () {
      final suggestion = DestinationSuggestion.fromSupabase({
        'name': 'Da Nang',
        'image_url': '',
        'match_percent': 90,
        'rating': 0,
        'review_count': 0,
      });
      expect(suggestion.reviewCount, 0);
      expect(suggestion.rating, 0.0);
    });

    test('uses DB columns when community_reviews is not embedded', () {
      final suggestion = DestinationSuggestion.fromSupabase({
        'name': 'Da Nang',
        'image_url': '',
        'match_percent': 90,
        'rating': 4.5,
        'review_count': 2,
      });
      expect(suggestion.reviewCount, 2);
      expect(suggestion.rating, 4.5);
    });

    test('computes rating and count from embedded community_reviews', () {
      final suggestion = DestinationSuggestion.fromSupabase({
        'name': 'Da Nang',
        'image_url': '',
        'match_percent': 90,
        'rating': 0,
        'review_count': 0,
        'community_reviews': [
          {'rating': 4},
          {'rating': 3},
        ],
      });
      expect(suggestion.reviewCount, 2);
      expect(suggestion.rating, 3.5);
    });
  });
}
