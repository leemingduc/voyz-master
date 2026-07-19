import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyz/services/supabase_service.dart';

class UserProfile {
  const UserProfile({
    required this.email,
    required this.displayName,
    required this.avatarUrl,
  });

  final String email;
  final String displayName;
  final String? avatarUrl;
}

class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  GoTrueClient get _auth => SupabaseService.instance.auth;

  UserProfile currentProfile() {
    final user = _requireUser();
    final metadata = user.userMetadata ?? {};
    final displayName =
        (metadata['display_name'] ?? metadata['username'] ?? '').toString();
    final avatarUrl = metadata['avatar_url']?.toString();

    return UserProfile(
      email: user.email ?? '',
      displayName: displayName,
      avatarUrl: avatarUrl == null || avatarUrl.isEmpty ? null : avatarUrl,
    );
  }

  Future<String> saveAvatar(Uint8List pngBytes) async {
    final user = _requireUser();
    final path = '${user.id}/avatar.png';

    await _client.storage
        .from('avatars')
        .uploadBinary(
          path,
          pngBytes,
          fileOptions: const FileOptions(
            contentType: 'image/png',
            cacheControl: '3600',
            upsert: true,
          ),
        );

    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
    final avatarUrl = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
    await _auth.updateUser(
      UserAttributes(data: {...?user.userMetadata, 'avatar_url': avatarUrl}),
    );

    return avatarUrl;
  }

  Future<void> updatePassword(String password) {
    return _auth.updateUser(UserAttributes(password: password));
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('You need to be logged in.');
    }
    return user;
  }
}
