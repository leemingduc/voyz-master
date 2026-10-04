/// Helper tính số lượt đánh giá và điểm sao trung bình cho địa điểm.
///
/// Chỉ dùng đánh giá thật của người dùng. Không cộng thêm lượt ảo, vì
/// người dùng đọc "100 lượt" sẽ hiểu là có 100 người đã đánh giá.
class DestinationRatingCalculator {
  DestinationRatingCalculator._();

  /// Số lượt đánh giá thật.
  static int calculateReviewCount(int userReviewCount) {
    return userReviewCount < 0 ? 0 : userReviewCount;
  }

  /// Điểm sao trung bình của các lượt đánh giá thật.
  ///
  /// Trả về `null` khi chưa có đánh giá, để UI hiện "Chưa có đánh giá"
  /// thay vì một con số không có căn cứ.
  static double? calculateAverageRating(Iterable<int> ratings) {
    if (ratings.isEmpty) return null;
    final total = ratings.fold<int>(0, (sum, r) => sum + r);
    return total / ratings.length;
  }

  /// Định dạng số lượt: "Chưa có đánh giá", "1 lượt", "12 lượt".
  static String formatVotes(int totalVotes) {
    if (totalVotes <= 0) return 'Chưa có đánh giá';
    return '$totalVotes lượt';
  }
}
