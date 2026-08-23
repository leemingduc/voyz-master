import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyz/services/supabase_service.dart';

class FriendsSetupException implements Exception {
  const FriendsSetupException();

  @override
  String toString() {
    return 'Friends is not ready yet. Please apply the latest Supabase migration first.';
  }
}

class SocialProfile {
  const SocialProfile({
    required this.userId,
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });

  final String userId;
  final String email;
  final String displayName;
  final String? avatarUrl;

  factory SocialProfile.fromMap(Map<String, dynamic> map) {
    final avatar = map['avatar_url']?.toString() ?? '';
    return SocialProfile(
      userId: map['user_id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      displayName: map['display_name']?.toString() ?? '',
      avatarUrl: avatar.isEmpty ? null : avatar,
    );
  }
}

class Friendship {
  const Friendship({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.createdAt,
    required this.friend,
  });

  final String id;
  final String requesterId;
  final String addresseeId;
  final String status;
  final DateTime createdAt;
  final SocialProfile friend;

  bool get isAccepted => status == 'accepted';
}

class FriendMessage {
  const FriendMessage({
    required this.id,
    required this.friendshipId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String friendshipId;
  final String senderId;
  final String body;
  final DateTime createdAt;

  factory FriendMessage.fromMap(Map<String, dynamic> map) {
    return FriendMessage(
      id: map['id']?.toString() ?? '',
      friendshipId: map['friendship_id']?.toString() ?? '',
      senderId: map['sender_id']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class FriendsService {
  FriendsService._();

  static final FriendsService instance = FriendsService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  GoTrueClient get _auth => SupabaseService.instance.auth;

  String get currentUserId => _requireUser().id;

  Future<void> syncCurrentProfile() async {
    final user = _requireUser();
    final metadata = user.userMetadata ?? {};
    final displayName = (metadata['display_name'] ?? metadata['username'] ?? '')
        .toString();
    final avatarUrl = metadata['avatar_url']?.toString();

    await _guardSchema(() async {
      await _client.from('social_profiles').upsert({
        'user_id': user.id,
        'email': user.email ?? '',
        'display_name': displayName.isEmpty
            ? (user.email ?? 'Traveler')
            : displayName,
        'avatar_url': avatarUrl == null || avatarUrl.isEmpty ? null : avatarUrl,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
    });
  }

  Future<List<SocialProfile>> searchProfiles(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];
    await syncCurrentProfile();
    final currentId = currentUserId;
    final escaped = _escapeSearch(trimmed);

    return _guardSchema(() async {
      final byEmail = await _client
          .from('social_profiles')
          .select()
          .ilike('email', '%$escaped%')
          .neq('user_id', currentId)
          .limit(10);
      final byName = await _client
          .from('social_profiles')
          .select()
          .ilike('display_name', '%$escaped%')
          .neq('user_id', currentId)
          .limit(10);

      final byId = <String, SocialProfile>{};
      for (final row in [...byEmail, ...byName]) {
        final profile = SocialProfile.fromMap(Map<String, dynamic>.from(row));
        if (profile.userId.isNotEmpty) byId[profile.userId] = profile;
      }
      return byId.values.toList();
    });
  }

  Future<void> sendFriendRequest(String addresseeId) async {
    final requesterId = currentUserId;
    if (requesterId == addresseeId) return;
    final pair = _orderedPair(requesterId, addresseeId);

    await _guardSchema(() async {
      final existing = await _client
          .from('friendships')
          .select()
          .eq('user_low', pair.$1)
          .eq('user_high', pair.$2)
          .maybeSingle();

      if (existing != null) {
        final map = Map<String, dynamic>.from(existing);
        final id = map['id']?.toString() ?? '';
        final status = map['status']?.toString() ?? 'pending';
        final incoming = map['addressee_id']?.toString() == requesterId;
        if (status == 'pending' && incoming && id.isNotEmpty) {
          await acceptFriendRequest(id);
        }
        return;
      }

      await _client.from('friendships').insert({
        'requester_id': requesterId,
        'addressee_id': addresseeId,
        'user_low': pair.$1,
        'user_high': pair.$2,
        'status': 'pending',
      });
    });
  }

  Future<void> acceptFriendRequest(String friendshipId) async {
    await _guardSchema(() async {
      await _client.from('friendships').update({
        'status': 'accepted',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', friendshipId);
    });
  }

  Future<List<Friendship>> getFriendships() async {
    await syncCurrentProfile();
    final currentId = currentUserId;

    return _guardSchema(() async {
      final outgoing = await _client
          .from('friendships')
          .select()
          .eq('requester_id', currentId)
          .order('updated_at', ascending: false);
      final incoming = await _client
          .from('friendships')
          .select()
          .eq('addressee_id', currentId)
          .order('updated_at', ascending: false);

      final byId = <String, Map<String, dynamic>>{};
      for (final row in [...outgoing, ...incoming]) {
        final map = Map<String, dynamic>.from(row);
        final id = map['id']?.toString() ?? '';
        if (id.isNotEmpty) byId[id] = map;
      }

      final rows = byId.values.toList()
        ..sort(
          (a, b) => (b['updated_at']?.toString() ?? '')
              .compareTo(a['updated_at']?.toString() ?? ''),
        );

      final friendIds = rows
          .map<String>((map) {
            final requester = map['requester_id']?.toString() ?? '';
            final addressee = map['addressee_id']?.toString() ?? '';
            return requester == currentId ? addressee : requester;
          })
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final profiles = await _profilesById(friendIds);
      return rows.map<Friendship>((map) {
        final requester = map['requester_id']?.toString() ?? '';
        final addressee = map['addressee_id']?.toString() ?? '';
        final friendId = requester == currentId ? addressee : requester;
        return Friendship(
          id: map['id']?.toString() ?? '',
          requesterId: requester,
          addresseeId: addressee,
          status: map['status']?.toString() ?? 'pending',
          createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
              DateTime.now(),
          friend: profiles[friendId] ??
              SocialProfile(
                userId: friendId,
                email: 'Unknown traveler',
                displayName: 'Traveler',
              ),
        );
      }).toList();
    });
  }

  Future<List<FriendMessage>> getMessages(String friendshipId) async {
    return _guardSchema(() async {
      final rows = await _client
          .from('friend_messages')
          .select()
          .eq('friendship_id', friendshipId)
          .order('created_at', ascending: true)
          .limit(100);
      return rows
          .map<FriendMessage>(
            (row) => FriendMessage.fromMap(Map<String, dynamic>.from(row)),
          )
          .toList();
    });
  }

  /// Realtime stream for messages in a friendship conversation.
  Stream<List<FriendMessage>> streamMessages(String friendshipId) {
    return _client
        .from('friend_messages')
        .stream(primaryKey: ['id'])
        .eq('friendship_id', friendshipId)
        .order('created_at', ascending: true)
        .map(
          (rows) => rows
              .map<FriendMessage>(
                (row) => FriendMessage.fromMap(Map<String, dynamic>.from(row)),
              )
              .toList(),
        );
  }

  Future<void> sendMessage(String friendshipId, String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    await _guardSchema(() async {
      await _client.from('friend_messages').insert({
        'friendship_id': friendshipId,
        'sender_id': currentUserId,
        'body': trimmed,
      });
    });
  }

  Future<Map<String, SocialProfile>> _profilesById(List<String> ids) async {
    if (ids.isEmpty) return const {};
    final rows = await _client
        .from('social_profiles')
        .select()
        .inFilter('user_id', ids);
    final result = <String, SocialProfile>{};
    for (final row in rows) {
      final profile = SocialProfile.fromMap(Map<String, dynamic>.from(row));
      result[profile.userId] = profile;
    }
    return result;
  }

  (String, String) _orderedPair(String a, String b) {
    return a.compareTo(b) <= 0 ? (a, b) : (b, a);
  }

  String _escapeSearch(String value) {
    return value.replaceAll('%', '').replaceAll('_', '').replaceAll(',', '');
  }

  Future<T> _guardSchema<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      if (error.code == '42P01' || error.message.contains('schema cache')) {
        throw const FriendsSetupException();
      }
      rethrow;
    }
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException('loginRequired');
    return user;
  }
}