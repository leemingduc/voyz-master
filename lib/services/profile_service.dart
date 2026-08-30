import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyz/data/currency_provider.dart';
import 'package:voyz/services/supabase_service.dart';

class UserProfile {
  const UserProfile({
    required this.email,
    required this.displayName,
    required this.avatarUrl,
    required this.phoneNumber,
    required this.travelStyles,
    required this.preferredCurrency,
  });

  final String email;
  final String displayName;
  final String? avatarUrl;
  final String phoneNumber;
  final List<String> travelStyles;
  final String preferredCurrency;

  UserProfile copyWith({
    String? email,
    String? displayName,
    String? avatarUrl,
    String? phoneNumber,
    List<String>? travelStyles,
    String? preferredCurrency,
  }) {
    return UserProfile(
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      travelStyles: travelStyles ?? this.travelStyles,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
    );
  }
}

class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  GoTrueClient get _auth => SupabaseService.instance.auth;

  UserProfile currentProfile() => _profileFromAuth();

  Future<UserProfile> loadCurrentProfile() async {
    final fallback = _profileFromAuth();
    final user = _requireUser();
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (row == null) {
        await _upsertProfile(fallback);
        return fallback;
      }
      return _profileFromRow(Map<String, dynamic>.from(row), fallback);
    } catch (_) {
      return fallback;
    }
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
    await _client.from('profiles').upsert({
      'user_id': user.id,
      'email': user.email ?? '',
      'display_name': _displayNameFromMetadata(user),
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    return avatarUrl;
  }

  Future<String> updateContactInfo({required String phoneNumber}) async {
    final user = _requireUser();
    final normalizedPhone = phoneNumber.trim();

    await _auth.updateUser(
      UserAttributes(
        data: {...?user.userMetadata, 'phone_number': normalizedPhone},
      ),
    );
    await _client.from('profiles').upsert({
      'user_id': user.id,
      'email': user.email ?? '',
      'display_name': _displayNameFromMetadata(user),
      'phone_number': normalizedPhone,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    return normalizedPhone;
  }

  Future<UserProfile> updateTravelPreferences({
    required List<String> travelStyles,
    required String preferredCurrency,
  }) async {
    final user = _requireUser();
    final currency = supportedCurrencies.any((item) => item.code == preferredCurrency)
        ? preferredCurrency
        : 'VND';
    final cleanStyles = travelStyles
        .map((style) => style.trim())
        .where((style) => style.isNotEmpty)
        .toSet()
        .toList();

    final existing = await loadCurrentProfile();
    await _client.from('profiles').upsert({
      'user_id': user.id,
      'email': user.email ?? existing.email,
      'display_name': existing.displayName,
      'avatar_url': existing.avatarUrl,
      'phone_number': existing.phoneNumber,
      'travel_styles': cleanStyles,
      'preferred_currency': currency,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    await _auth.updateUser(
      UserAttributes(
        data: {
          ...?user.userMetadata,
          'travel_styles': cleanStyles,
          'preferred_currency': currency,
        },
      ),
    );

    return existing.copyWith(
      travelStyles: cleanStyles,
      preferredCurrency: currency,
    );
  }

  Future<void> updatePassword(String password) {
    return _auth.updateUser(UserAttributes(password: password));
  }

  Future<void> _upsertProfile(UserProfile profile) async {
    final user = _requireUser();
    await _client.from('profiles').upsert({
      'user_id': user.id,
      'email': profile.email,
      'display_name': profile.displayName,
      'avatar_url': profile.avatarUrl,
      'phone_number': profile.phoneNumber,
      'travel_styles': profile.travelStyles,
      'preferred_currency': profile.preferredCurrency,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  UserProfile _profileFromAuth() {
    final user = _requireUser();
    final metadata = user.userMetadata ?? {};
    final displayName = _displayNameFromMetadata(user);
    final avatarUrl = metadata['avatar_url']?.toString();
    final phoneNumber = metadata['phone_number']?.toString().trim() ?? '';
    final preferredCurrency = metadata['preferred_currency']?.toString() ?? 'VND';

    return UserProfile(
      email: user.email ?? '',
      displayName: displayName,
      avatarUrl: avatarUrl == null || avatarUrl.isEmpty ? null : avatarUrl,
      phoneNumber: phoneNumber,
      travelStyles: _stringList(metadata['travel_styles']),
      preferredCurrency: supportedCurrencies.any((item) => item.code == preferredCurrency)
          ? preferredCurrency
          : 'VND',
    );
  }

  UserProfile _profileFromRow(
    Map<String, dynamic> row,
    UserProfile fallback,
  ) {
    final currency = row['preferred_currency']?.toString() ?? fallback.preferredCurrency;
    final avatarUrl = row['avatar_url']?.toString();
    return UserProfile(
      email: row['email']?.toString() ?? fallback.email,
      displayName: row['display_name']?.toString() ?? fallback.displayName,
      avatarUrl: avatarUrl == null || avatarUrl.isEmpty ? fallback.avatarUrl : avatarUrl,
      phoneNumber: row['phone_number']?.toString() ?? fallback.phoneNumber,
      travelStyles: _stringList(row['travel_styles']),
      preferredCurrency: supportedCurrencies.any((item) => item.code == currency)
          ? currency
          : fallback.preferredCurrency,
    );
  }

  String _displayNameFromMetadata(User user) {
    final metadata = user.userMetadata ?? {};
    return (metadata['display_name'] ?? metadata['username'] ?? '').toString();
  }

  List<String> _stringList(dynamic value) {
    if (value is List) return value.map((item) => item.toString()).toList();
    return const [];
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('loginRequired');
    }
    return user;
  }
}
