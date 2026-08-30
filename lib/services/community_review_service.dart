import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyz/services/supabase_service.dart';

class CommunityReview {
  const CommunityReview({
    required this.id,
    required this.destinationId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String destinationId;
  final String userId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CommunityReview.fromMap(Map<String, dynamic> map) {
    return CommunityReview(
      id: map['id']?.toString() ?? '',
      destinationId: map['destination_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: map['comment']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class CommunityReviewService {
  CommunityReviewService._();

  static final CommunityReviewService instance = CommunityReviewService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  GoTrueClient get _auth => SupabaseService.instance.auth;

  Future<List<CommunityReview>> listForDestination(String destinationId) async {
    final rows = await _client
        .from('community_reviews')
        .select()
        .eq('destination_id', destinationId)
        .order('created_at', ascending: false)
        .limit(20);
    return rows
        .map((row) => CommunityReview.fromMap(Map<String, dynamic>.from(row)))
        .toList();
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
  }
}
