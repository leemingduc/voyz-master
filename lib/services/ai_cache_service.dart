import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voyz/services/supabase_service.dart';

/// Cache một tầng cho phản hồi AI. Chỉ là cache: mất là được phép.
///
/// Mỗi entry trong box là JSON string `{"payload": "...", "expiresAt": "ISO-8601"}`.
/// Muốn xem cache đang có gì: mở box Hive [boxName].
class AiCacheService {
  AiCacheService._();
  static final AiCacheService instance = AiCacheService._();

  /// Tăng số version mỗi khi sửa prompt: box mới, cache cũ tự bị bỏ qua.
  static const boxName = 'ai_cache_v3';

  /// Một TTL cho mọi feature. Explore muốn mới thì đã có nút refresh.
  static const ttl = Duration(days: 7);

  static const _oldBoxNames = ['gemini_cache', 'gemini_multi_tier_cache_v2'];

  Box<String>? _box;

  Future<void> init() async {
    if (_box != null) return;
    for (final name in _oldBoxNames) {
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (_) {}
    }
    try {
      _box = await Hive.openBox<String>(boxName);
    } catch (e) {
      debugPrint('AiCacheService init error: $e');
    }
  }

  /// Key md5 từ prefix + mọi input ảnh hưởng đến kết quả + userId hiện tại.
  String buildKey(String prefix, Map<String, dynamic> parts) {
    final sorted = parts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final buffer = StringBuffer(prefix);
    for (final entry in sorted) {
      buffer.write('|${entry.key}=');
      if (entry.value is List) {
        final list = List<String>.from(entry.value as List)..sort();
        buffer.write(list.join(','));
      } else {
        buffer.write(entry.value.toString().trim().toLowerCase());
      }
    }
    buffer.write('|user=$_userId');
    return md5.convert(utf8.encode(buffer.toString())).toString();
  }

  /// Trả payload nếu còn hạn; hết hạn hoặc hỏng thì xoá và trả null.
  String? get(String key) {
    final raw = _box?.get(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final expiresAt = DateTime.tryParse(map['expiresAt']?.toString() ?? '');
      if (expiresAt == null || expiresAt.isBefore(DateTime.now())) {
        _box?.delete(key);
        return null;
      }
      return map['payload']?.toString();
    } catch (_) {
      _box?.delete(key);
      return null;
    }
  }

  Future<void> put(String key, String payload) async {
    final entry = jsonEncode({
      'payload': payload,
      'expiresAt': DateTime.now().add(ttl).toIso8601String(),
    });
    await _box?.put(key, entry);
  }

  Future<void> clear() async => _box?.clear();

  String get _userId {
    try {
      return SupabaseService.instance.auth.currentUser?.id ?? 'anonymous';
    } catch (_) {
      // Test hoặc khởi động offline: chưa có Supabase.
      return 'anonymous';
    }
  }
}
