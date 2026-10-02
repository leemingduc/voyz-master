/// Helper tính toán số lượt đánh giá và điểm sao trung bình cho địa điểm
/// dựa trên số liệu gốc ban đầu (100 vote gốc 5.0 sao).
class DestinationRatingCalculator {
  DestinationRatingCalculator._();

  static const int baseVotes = 100;
  static const double baseRating = 5.0;
  static const double baseScore = baseVotes * baseRating; // 500.0

  /// Tính tổng số lượt vote sau khi cộng dồn [userReviewCount] đánh giá từ người dùng.
  static int calculateReviewCount(int userReviewCount) {
    return baseVotes + userReviewCount;
  }

  /// Tính số vote thật từ tổng số vote (đã có 100 vote ảo).
  static int calculateRealVotes(int totalVotes) {
    return totalVotes >= baseVotes ? (totalVotes - baseVotes) : 0;
  }

  /// Tính điểm sao trung bình sau khi cộng dồn các lượt đánh giá [ratings] từ người dùng.
  static double calculateAverageRating(Iterable<int> ratings) {
    if (ratings.isEmpty) return baseRating;
    final totalScore = baseScore + ratings.fold<int>(0, (sum, r) => sum + r);
    final totalCount = baseVotes + ratings.length;
    return totalScore / totalCount;
  }

  /// Định dạng tóm tắt: "100 (100 ảo + 0 thật)" hoặc "102 (100 ảo + 2 thật)"
  static String formatVotesSummary(int totalVotes) {
    final real = calculateRealVotes(totalVotes);
    return '$totalVotes • $baseVotes ảo + $real thật';
  }

  /// Định dạng ngắn gọn: "100 ảo + 0 thật" hoặc "100 ảo + 2 thật"
  static String formatVotesShort(int totalVotes) {
    final real = calculateRealVotes(totalVotes);
    return '$baseVotes ảo + $real thật';
  }
}

