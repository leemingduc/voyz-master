import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/models/destination_suggestion.dart';
import 'package:voyz/utils/destination_rating_calculator.dart';

void main() {
  group('DestinationRatingCalculator', () {
    test('returns base 100 votes and 5.0 rating when no user reviews', () {
      expect(DestinationRatingCalculator.calculateReviewCount(0), 100);
      expect(DestinationRatingCalculator.calculateAverageRating([]), 5.0);
    });

    test('correctly calculates new rating and count when user reviews added', () {
      // 1 user review of 4 stars -> (500 + 4) / 101 = 4.990099...
      expect(DestinationRatingCalculator.calculateReviewCount(1), 101);
      final avg1 = DestinationRatingCalculator.calculateAverageRating([4]);
      expect(avg1, closeTo(4.99, 0.01));

      // 5 user reviews of 1 star -> (500 + 5) / 105 = 4.8095...
      expect(DestinationRatingCalculator.calculateReviewCount(5), 105);
      final avg5 = DestinationRatingCalculator.calculateAverageRating([1, 1, 1, 1, 1]);
      expect(avg5, closeTo(4.81, 0.01));
    });

    test('calculates real votes and formats vote breakdown strings', () {
      expect(DestinationRatingCalculator.calculateRealVotes(100), 0);
      expect(DestinationRatingCalculator.calculateRealVotes(103), 3);
      expect(DestinationRatingCalculator.calculateRealVotes(50), 0);

      expect(
        DestinationRatingCalculator.formatVotesSummary(100),
        '100 • 100 ảo + 0 thật',
      );
      expect(
        DestinationRatingCalculator.formatVotesSummary(105),
        '105 • 100 ảo + 5 thật',
      );
      expect(
        DestinationRatingCalculator.formatVotesShort(102),
        '100 ảo + 2 thật',
      );
    });
  });

  group('DestinationSuggestion defaults', () {
    test('defaults to 100 reviews and 5.0 rating when 0 or not provided', () {
      final suggestion = DestinationSuggestion.fromSupabase({
        'name': 'Da Nang',
        'image_url': '',
        'match_percent': 90,
        'rating': 0,
        'review_count': 0,
      });
      expect(suggestion.reviewCount, 100);
      expect(suggestion.rating, 5.0);
      expect(suggestion.baseVotes, 100);
      expect(suggestion.realVotes, 0);
    });

    test('computes rating and votes from embedded community_reviews if present', () {
      final suggestion = DestinationSuggestion.fromSupabase({
        'name': 'Da Nang',
        'image_url': '',
        'match_percent': 90,
        'rating': 0,
        'review_count': 0,
        'community_reviews': [
          {'rating': 4},
          {'rating': 4},
        ],
      });
      // 100 base + 2 real = 102
      expect(suggestion.reviewCount, 102);
      expect(suggestion.realVotes, 2);
      // (500 + 8) / 102 = 4.98039...
      expect(suggestion.rating, closeTo(4.98, 0.01));
    });
  });
}
