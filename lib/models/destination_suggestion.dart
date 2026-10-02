import 'package:voyz/utils/destination_rating_calculator.dart';

/// Model for AI-suggested travel destinations displayed on the Suggestions screen.
class DestinationSuggestion {
  final String name;
  final String imageUrl;
  final int matchPercent;
  final double rating;
  final int reviewCount;
  final String price;
  final String aiInsight;
  final bool isTopMatch;

  const DestinationSuggestion({
    required this.name,
    required this.imageUrl,
    required this.matchPercent,
    required this.rating,
    required this.reviewCount,
    required this.price,
    required this.aiInsight,
    this.isTopMatch = false,
  });

  int get realVotes => DestinationRatingCalculator.calculateRealVotes(reviewCount);
  int get baseVotes => DestinationRatingCalculator.baseVotes;

  factory DestinationSuggestion.fromJson(
    Map<String, dynamic> json,
    String imageUrl,
  ) {
    final rawRating = (json['rating'] as num?)?.toDouble() ?? 0.0;
    final rawReviewCount = (json['reviewCount'] as num?)?.toInt() ?? 0;
    return DestinationSuggestion(
      name: json['name'] as String? ?? '',
      imageUrl: imageUrl,
      matchPercent: (json['matchPercent'] as num?)?.toInt() ?? 0,
      rating: rawRating > 0 ? rawRating : 5.0,
      reviewCount: rawReviewCount >= 100 ? rawReviewCount : 100,
      price: json['price'] as String? ?? '',
      aiInsight: json['aiInsight'] as String? ?? '',
      isTopMatch: json['isTopMatch'] as bool? ?? false,
    );
  }

  factory DestinationSuggestion.fromSupabase(
    Map<String, dynamic> row, {
    bool isTopMatch = false,
  }) {
    final reviews = (row['community_reviews'] as List?)?.whereType<Map>().toList();
    double effectiveRating;
    int effectiveReviewCount;

    if (reviews != null && reviews.isNotEmpty) {
      final ratings = reviews.map((r) => (r['rating'] as num?)?.toInt() ?? 5);
      effectiveReviewCount = DestinationRatingCalculator.calculateReviewCount(reviews.length);
      effectiveRating = DestinationRatingCalculator.calculateAverageRating(ratings);
    } else {
      final rawRating = (row['rating'] as num?)?.toDouble() ?? 0.0;
      final rawReviewCount = (row['review_count'] as num?)?.toInt() ?? 0;
      effectiveRating = rawRating > 0 ? rawRating : 5.0;
      effectiveReviewCount = rawReviewCount >= 100 ? rawReviewCount : 100;
    }

    return DestinationSuggestion(
      name: row['name']?.toString() ?? '',
      imageUrl: _resolvedImageUrl(
        row['image_url']?.toString(),
        row['name']?.toString() ?? '',
        category: row['category']?.toString(),
      ),
      matchPercent: (row['match_percent'] as num?)?.toInt() ?? 0,
      rating: effectiveRating,
      reviewCount: effectiveReviewCount,
      price: row['price']?.toString() ?? '',
      aiInsight: row['ai_insight']?.toString() ?? '',
      isTopMatch: isTopMatch,
    );
  }

  /// Convert to Map for compatibility with existing UI widgets.
  Map<String, dynamic> toMap() => {
    'name': name,
    'imageUrl': imageUrl,
    'matchPercent': matchPercent,
    'rating': rating,
    'reviewCount': reviewCount,
    'price': price,
    'aiInsight': aiInsight,
    'isTopMatch': isTopMatch,
  };
  factory DestinationSuggestion.fromMap(Map<dynamic, dynamic> map) {
    final rawRating = (map['rating'] as num?)?.toDouble() ?? 0.0;
    final rawReviewCount = (map['reviewCount'] as num?)?.toInt() ?? 0;
    return DestinationSuggestion(
      name: map['name']?.toString() ?? '',
      imageUrl: _resolvedImageUrl(
        map['imageUrl']?.toString(),
        map['name']?.toString() ?? '',
      ),
      matchPercent: (map['matchPercent'] as num?)?.toInt() ?? 0,
      rating: rawRating > 0 ? rawRating : 5.0,
      reviewCount: rawReviewCount >= 100 ? rawReviewCount : 100,
      price: map['price']?.toString() ?? '',
      aiInsight: map['aiInsight']?.toString() ?? '',
      isTopMatch: map['isTopMatch'] == true,
    );
  }
}

/// Ảnh rỗng là trạng thái hợp lệ: UI có errorWidget placeholder ở mọi
/// call site, không dùng fallback URL cứng trong code.
String _resolvedImageUrl(
  String? rawUrl,
  String destinationName, {
  String? category,
}) {
  return rawUrl?.trim() ?? '';
}
