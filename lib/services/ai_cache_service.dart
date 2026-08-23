import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:voyz/services/supabase_service.dart';

/// Represents a cached AI response including optional pre-cached image URLs.
class CachedAiResponse {
  final String payload;
  final Map<String, String> imageUrls;

  const CachedAiResponse({
    required this.payload,
    this.imageUrls = const {},
  });

  Map<String, dynamic> toMap() => {
        'payload': payload,
        'imageUrls': imageUrls,
      };

  factory CachedAiResponse.fromMap(Map<dynamic, dynamic> map) {
    final rawImages = map['imageUrls'];
    final Map<String, String> images = {};
    if (rawImages is Map) {
      rawImages.forEach((k, v) {
        if (k != null && v != null) {
          images[k.toString()] = v.toString();
        }
      });
    }
    return CachedAiResponse(
      payload: map['payload']?.toString() ?? '',
      imageUrls: images,
    );
  }
}

/// Multi-tier cache service for AI responses.
///
/// Hierarchy:
/// Tier 1: In-Memory Map (0ms)
/// Tier 2: Hive Local Box (<5ms)
/// Tier 3: Supabase Cloud Database `ai_generated_cache` (~50-100ms)
class AiCacheService {
  AiCacheService._();
  static final AiCacheService instance = AiCacheService._();

  static const String _boxName = 'gemini_multi_tier_cache';
  static const String _legacyBoxName = 'gemini_cache';

  final Map<String, CachedAiResponse> _memoryCache = {};
  bool _initialized = false;

  /// Initializes the local Hive cache box.
  Future<void> init() async {
    if (_initialized) return;
    try {
      await Hive.openBox<String>(_boxName);
      // Also open legacy box if exists for backward compatibility
      if (Hive.isBoxOpen(_legacyBoxName) || await Hive.boxExists(_legacyBoxName)) {
        await Hive.openBox<String>(_legacyBoxName);
      }
    } catch (e) {
      debugPrint('AiCacheService Hive init error: $e');
    }
    _initialized = true;
  }

  Box<String>? get _box {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        return Hive.box<String>(_boxName);
      }
    } catch (_) {}
    return null;
  }

  Box<String>? get _legacyBox {
    try {
      if (Hive.isBoxOpen(_legacyBoxName)) {
        return Hive.box<String>(_legacyBoxName);
      }
    } catch (_) {}
    return null;
  }

  /// Build a deterministic cache key from input parts.
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

    final bytes = utf8.encode(buffer.toString());
    return md5.convert(bytes).toString();
  }

  /// Retrieves cached AI response from Tier 1 (Memory) -> Tier 2 (Hive) -> Tier 3 (Supabase).
  Future<CachedAiResponse?> getResponse(String key) async {
    // 1. Tier 1: In-Memory cache (0ms)
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }

    // 2. Tier 2: Hive Local Cache (~5ms)
    final hiveData = _box?.get(key);
    if (hiveData != null && hiveData.isNotEmpty) {
      try {
        final decoded = jsonDecode(hiveData);
        if (decoded is Map) {
          final res = CachedAiResponse.fromMap(decoded);
          _memoryCache[key] = res;
          return res;
        }
      } catch (_) {
        // Raw string format backward compatibility
        final res = CachedAiResponse(payload: hiveData);
        _memoryCache[key] = res;
        return res;
      }
    }

    // Check legacy box
    final legacyData = _legacyBox?.get(key);
    if (legacyData != null && legacyData.isNotEmpty) {
      final res = CachedAiResponse(payload: legacyData);
      _memoryCache[key] = res;
      return res;
    }

    // 3. Tier 3: Supabase Cloud DB (~50-100ms)
    try {
      final supabase = SupabaseService.instance.client;
      final response = await supabase
          .from('ai_generated_cache')
          .select('payload, image_urls')
          .eq('cache_key', key)
          .maybeSingle();

      if (response != null && response['payload'] != null) {
        final rawPayload = response['payload'];
        final payloadStr = rawPayload is String ? rawPayload : jsonEncode(rawPayload);

        final rawImages = response['image_urls'];
        final Map<String, String> imageUrls = {};
        if (rawImages is Map) {
          rawImages.forEach((k, v) {
            if (k != null && v != null) {
              imageUrls[k.toString()] = v.toString();
            }
          });
        }

        final res = CachedAiResponse(
          payload: payloadStr,
          imageUrls: imageUrls,
        );

        // Populate Memory & Hive
        _memoryCache[key] = res;
        await _box?.put(key, jsonEncode(res.toMap()));

        // Background touch hit_count without waiting
        _incrementHitCount(key);

        return res;
      }
    } catch (e) {
      // Offline or Supabase not reachable; gracefully fall through
      debugPrint('AiCacheService Supabase get error: $e');
    }

    return null;
  }

  /// Convenience method to retrieve just the raw payload string.
  Future<String?> get(String key) async {
    final res = await getResponse(key);
    return res?.payload;
  }

  /// Save response across all 3 tiers.
  Future<void> putResponse(
    String key,
    String payload, {
    required String featureType,
    String? destination,
    String languageCode = 'vi',
    Map<String, String>? imageUrls,
  }) async {
    final responseObj = CachedAiResponse(
      payload: payload,
      imageUrls: imageUrls ?? const {},
    );

    // 1. Tier 1: RAM
    _memoryCache[key] = responseObj;

    // 2. Tier 2: Hive Box
    try {
      await _box?.put(key, jsonEncode(responseObj.toMap()));
    } catch (e) {
      debugPrint('AiCacheService Hive put error: $e');
    }

    // 3. Tier 3: Supabase DB (Upsert)
    _saveToSupabase(
      key: key,
      payload: payload,
      featureType: featureType,
      destination: destination,
      languageCode: languageCode,
      imageUrls: imageUrls,
    );
  }

  /// Save raw string to cache (compatible with legacy CacheService signature).
  Future<void> put(
    String key,
    String payload, {
    String featureType = 'general',
    String? destination,
    String languageCode = 'vi',
    Map<String, String>? imageUrls,
  }) async {
    await putResponse(
      key,
      payload,
      featureType: featureType,
      destination: destination,
      languageCode: languageCode,
      imageUrls: imageUrls,
    );
  }

  /// Async background save to Supabase.
  Future<void> _saveToSupabase({
    required String key,
    required String payload,
    required String featureType,
    String? destination,
    required String languageCode,
    Map<String, String>? imageUrls,
  }) async {
    try {
      dynamic parsedPayload;
      try {
        parsedPayload = jsonDecode(payload);
      } catch (_) {
        parsedPayload = payload;
      }

      final supabase = SupabaseService.instance.client;
      await supabase.from('ai_generated_cache').upsert({
        'cache_key': key,
        'feature_type': featureType,
        'destination': destination,
        'language_code': languageCode,
        'payload': parsedPayload,
        'image_urls': imageUrls ?? {},
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'cache_key');
    } catch (e) {
      debugPrint('AiCacheService Supabase upsert error (non-fatal): $e');
    }
  }

  /// Background hit count increment.
  Future<void> _incrementHitCount(String key) async {
    try {
      final supabase = SupabaseService.instance.client;
      await supabase.rpc('increment_ai_cache_hit', params: {'target_key': key});
    } catch (_) {
      // Stored procedure is optional; ignore if not created
    }
  }

  /// Clear in-memory and Hive caches.
  Future<void> clearLocal() async {
    _memoryCache.clear();
    await _box?.clear();
    await _legacyBox?.clear();
  }
}
