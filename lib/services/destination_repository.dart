import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyz/models/destination_detail.dart';
import 'package:voyz/models/destination_suggestion.dart';
import 'package:voyz/services/supabase_service.dart';

class DestinationRepository {
  DestinationRepository._();

  static final DestinationRepository instance = DestinationRepository._();
  static const _cacheBoxName = 'curated_destinations_cache';
  static const _cacheTtl = Duration(hours: 6);

  SupabaseClient get _client => SupabaseService.instance.client;

  Future<List<DestinationSuggestion>> getFeaturedDestinations({
    required String categoryKey,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'featured_$categoryKey';
    final box = await Hive.openBox<Map>(_cacheBoxName);

    if (!forceRefresh) {
      final cached = box.get(cacheKey);
      final cachedAt = DateTime.tryParse(cached?['cachedAt']?.toString() ?? '');
      final rawItems = cached?['items'];
      if (cachedAt != null &&
          DateTime.now().difference(cachedAt) < _cacheTtl &&
          rawItems is List) {
        final items = rawItems
            .whereType<Map>()
            .map(DestinationSuggestion.fromMap)
            .where((item) => item.name.isNotEmpty)
            .toList();
        if (items.isNotEmpty) return items.take(limit).toList();
      }
    }

    try {
      final rows = await _client
          .from('featured_destinations')
          .select('rank, destinations(*)')
          .eq('category_key', categoryKey)
          .eq('is_active', true)
          .order('rank', ascending: true)
          .limit(limit);

      final items = <DestinationSuggestion>[];
      for (var index = 0; index < rows.length; index++) {
        final row = Map<String, dynamic>.from(rows[index]);
        final destination = row['destinations'];
        if (destination is Map) {
          items.add(
            DestinationSuggestion.fromSupabase(
              Map<String, dynamic>.from(destination),
              isTopMatch: index == 0,
            ),
          );
        }
      }

      final effectiveItems = items.isNotEmpty
          ? items
          : await getDestinationsByCategory(
              categoryKey: categoryKey,
              limit: limit,
              forceRefresh: true,
            );

      if (effectiveItems.isNotEmpty) {
        await box.put(cacheKey, {
          'cachedAt': DateTime.now().toIso8601String(),
          'items': effectiveItems.map((item) => item.toMap()).toList(),
        });
      }
      return effectiveItems;
    } catch (_) {
      final cached = box.get(cacheKey);
      final rawItems = cached?['items'];
      if (rawItems is List) {
        return rawItems
            .whereType<Map>()
            .map(DestinationSuggestion.fromMap)
            .where((item) => item.name.isNotEmpty)
            .take(limit)
            .toList();
      }
      rethrow;
    }
  }

  Future<List<DestinationSuggestion>> getDestinationsByCategory({
    required String categoryKey,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final query = _client
        .from('destinations')
        .select()
        .eq('is_active', true)
        .order('match_percent', ascending: false)
        .limit(limit);

    final rows = categoryKey == 'random'
        ? await query
        : await _client
            .from('destinations')
            .select()
            .eq('is_active', true)
            .eq('category', categoryKey)
            .order('match_percent', ascending: false)
            .limit(limit);

    return List.generate(rows.length, (index) {
      return DestinationSuggestion.fromSupabase(
        Map<String, dynamic>.from(rows[index]),
        isTopMatch: index == 0,
      );
    });
  }

  Future<DestinationDetail?> getDestinationDetail(String name) async {
    try {
      final row = await _client
          .from('destinations')
          .select()
          .ilike('name', name)
          .eq('is_active', true)
          .maybeSingle();
      if (row == null) return null;
      return destinationDetailFromRow(Map<String, dynamic>.from(row));
    } catch (_) {
      return null;
    }
  }

  Future<String?> getDestinationIdByName(String name) async {
    final row = await _client
        .from('destinations')
        .select('id')
        .ilike('name', name)
        .eq('is_active', true)
        .maybeSingle();
    return row?['id']?.toString();
  }

  Future<String> uploadDestinationMedia({
    required String destinationSlug,
    required String fileName,
    required List<int> bytes,
    String contentType = 'image/jpeg',
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = '$destinationSlug/$safeName';
    await _client.storage.from('destination-media').uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(
            contentType: contentType,
            cacheControl: '86400',
            upsert: true,
          ),
        );
    return _client.storage.from('destination-media').getPublicUrl(path);
  }
}

DestinationDetail destinationDetailFromRow(Map<String, dynamic> row) {
  final detailData = row['detail_data'] is Map
      ? Map<String, dynamic>.from(row['detail_data'] as Map)
      : <String, dynamic>{};
  final galleryData = row['gallery'] is List ? row['gallery'] as List : const [];

  return DestinationDetail.fromJson(
    {
      'name': row['name']?.toString() ?? '',
      'location': row['location']?.toString() ?? row['country']?.toString() ?? '',
      'tags': row['tags'] is List ? row['tags'] : const [],
      'weather': detailData['weather']?.toString() ?? '',
      'dateRange': detailData['dateRange']?.toString() ?? '',
      'totalBudget': detailData['totalBudget']?.toString() ?? row['price']?.toString() ?? '',
      'budgetBreakdown': detailData['budgetBreakdown'] is List
          ? detailData['budgetBreakdown']
          : const [],
    },
    row['image_url']?.toString() ?? '',
    gallery: galleryData
        .whereType<Map>()
        .map((item) => DestinationLandmarkPhoto.fromJson(Map<String, dynamic>.from(item)))
        .where((photo) => photo.imageUrl.isNotEmpty)
        .toList(),
  );
}
