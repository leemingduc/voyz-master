import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyz/services/supabase_service.dart';

/// Returns a public reviewer name, or null when the profile still uses email.
String? reviewerDisplayName({
  required String displayName,
  required String email,
}) {
  final name = displayName.trim();
  final normalizedEmail = email.trim();
  if (name.isEmpty || name.toLowerCase() == normalizedEmail.toLowerCase()) {
    return null;
  }
  return name;
}

class CommunityReview {
  const CommunityReview({
    required this.id,
    required this.destinationId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String destinationId;
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CommunityReview.fromMap(
    Map<String, dynamic> map, {
    String userName = '',
  }) {
    return CommunityReview(
      id: map['id']?.toString() ?? '',
      destinationId: map['destination_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      userName: userName,
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: map['comment']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class CommunityReviewService {
  CommunityReviewService._();

  static final CommunityReviewService instance = CommunityReviewService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  GoTrueClient get _auth => SupabaseService.instance.auth;

  Future<List<CommunityReview>> listForDestination(
    String destinationId,
  ) async {
    // Bước 1: Fetch reviews
    final rows = await _client
        .from('community_reviews')
        .select()
        .eq('destination_id', destinationId)
        .order('created_at', ascending: false)
        .limit(20);

    if (rows.isEmpty) return [];

    final reviews = rows
        .map((row) => CommunityReview.fromMap(Map<String, dynamic>.from(row)))
        .toList();

    // Bước 2: Lấy danh sách user_id unique rồi fetch profiles riêng
    final userIds = reviews.map((r) => r.userId).toSet().toList();
    final nameMap = await _fetchDisplayNames(userIds);

    // Bước 3: Gán tên vào từng review
    return reviews.map((r) {
      final name = nameMap[r.userId] ?? '';
      if (name.isEmpty) return r;
      return CommunityReview(
        id: r.id,
        destinationId: r.destinationId,
        userId: r.userId,
        userName: name,
        rating: r.rating,
        comment: r.comment,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );
    }).toList();
  }

  /// Fetch tên công khai từ social_profiles cho danh sách user_id.
  /// Nếu tên vẫn là email, trả về rỗng để UI hiển thị Anonymous.
  Future<Map<String, String>> _fetchDisplayNames(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};
    try {
      final rows = await _client
          .from('social_profiles')
          .select('user_id, email, display_name')
          .inFilter('user_id', userIds);
      final map = <String, String>{};
      for (final row in rows) {
        final uid = row['user_id']?.toString() ?? '';
        final name = reviewerDisplayName(
          displayName: row['display_name']?.toString() ?? '',
          email: row['email']?.toString() ?? '',
        );
        if (uid.isNotEmpty && name != null) {
          map[uid] = name;
        }
      }
      return map;
    } catch (e) {
      debugPrint('Could not fetch profile names: $e');
      return {};
    }
  }

  Future<void> upsertReview({
    required String destinationId,
    required int rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('loginRequired');
    }

    await _client.from('community_reviews').upsert(
      {
        'destination_id': destinationId,
        'user_id': user.id,
        'rating': rating,
        'comment': comment.trim(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'destination_id,user_id',
    );

    // Trigger community_reviews_refresh_stats_trigger trong DB tự cập nhật
    // destinations.rating và review_count, client không cần gọi thêm.
  }
}
