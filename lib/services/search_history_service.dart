import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/services/supabase_service.dart';

/// Represents a single recorded trip search entry.
class SearchHistoryEntry {
  final String id;
  final String destination;
  final DateTime? departDate;
  final DateTime? returnDate;
  final String budget;
  final String currency;
  final String participants;
  final String ageRange;
  final List<String> selectedInterests;
  final String aiPrompt;
  final String additionalNotes;
  final DateTime createdAt;

  const SearchHistoryEntry({
    required this.id,
    required this.destination,
    this.departDate,
    this.returnDate,
    required this.budget,
    required this.currency,
    required this.participants,
    required this.ageRange,
    required this.selectedInterests,
    required this.aiPrompt,
    required this.additionalNotes,
    required this.createdAt,
  });

  TripData toTripData() {
    return TripData(
      destination: destination,
      departDate: departDate,
      returnDate: returnDate,
      budget: budget,
      currency: currency,
      participants: participants,
      ageRange: ageRange,
      additionalNotes: additionalNotes,
      aiPrompt: aiPrompt,
      selectedInterests: selectedInterests,
    );
  }

  factory SearchHistoryEntry.fromMap(Map<dynamic, dynamic> map, {String? id}) {
    return SearchHistoryEntry(
      id: (id ?? map['id'])?.toString() ?? '',
      destination: map['destination']?.toString() ?? '',
      departDate: _parseDate(map['depart_date'] ?? map['departDate']),
      returnDate: _parseDate(map['return_date'] ?? map['returnDate']),
      budget: map['budget']?.toString() ?? '',
      currency: map['currency']?.toString() ?? 'VND',
      participants: map['participants']?.toString() ?? '',
      ageRange: map['age_range'] ?? map['ageRange']?.toString() ?? '',
      selectedInterests: TripData.stringList(
        map['selected_interests'] ?? map['selectedInterests'],
      ),
      aiPrompt: map['ai_prompt'] ?? map['aiPrompt']?.toString() ?? '',
      additionalNotes:
          map['additional_notes'] ?? map['additionalNotes']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'destination': destination,
    'depart_date': departDate?.toIso8601String().split('T').first,
    'return_date': returnDate?.toIso8601String().split('T').first,
    'budget': budget,
    'currency': currency,
    'participants': participants,
    'age_range': ageRange,
    'selected_interests': selectedInterests,
    'ai_prompt': aiPrompt,
    'additional_notes': additionalNotes,
    'created_at': createdAt.toIso8601String(),
  };

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class SearchHistoryService {
  SearchHistoryService._();

  static final SearchHistoryService instance = SearchHistoryService._();
  static const String _boxName = 'search_history';

  SupabaseClient get _client => SupabaseService.instance.client;
  GoTrueClient get _auth => SupabaseService.instance.auth;

  Future<void> init() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        await Hive.openBox<Map>(_boxName);
      }
    } catch (e) {
      debugPrint('SearchHistoryService Hive init error: $e');
    }
  }

  Box<Map>? get _box {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        return Hive.box<Map>(_boxName);
      }
    } catch (_) {}
    return null;
  }

  /// Records a trip search locally and pushes to Supabase if authenticated.
  Future<void> recordTripSearch(TripData trip) async {
    final now = DateTime.now().toUtc();
    final payload = <String, dynamic>{
      'destination': trip.destination.trim(),
      'depart_date': _dateOnly(trip.departDate),
      'return_date': _dateOnly(trip.returnDate),
      'budget': trip.budget.trim(),
      'currency': trip.currency,
      'participants': trip.participants.trim(),
      'age_range': trip.ageRange.trim(),
      'selected_interests': trip.selectedInterests,
      'ai_prompt': trip.aiPrompt.trim(),
      'additional_notes': trip.additionalNotes.trim(),
      'created_at': now.toIso8601String(),
    };

    // 1. Save to local Hive cache
    try {
      await _box?.add(payload);
    } catch (e) {
      debugPrint('SearchHistoryService Hive save error: $e');
    }

    // 2. Sync to Supabase Database
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _client.from('search_history').insert({
          'user_id': user.id,
          ...payload,
        });
      } catch (e) {
        debugPrint('SearchHistoryService Supabase sync error: $e');
      }
    }
  }

  /// Fetches recent searches, prioritizing Supabase DB with local fallback.
  Future<List<SearchHistoryEntry>> getRecentSearches({int limit = 10}) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final rows = await _client
            .from('search_history')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false)
            .limit(limit);

        return rows
            .map<SearchHistoryEntry>(
              (row) => SearchHistoryEntry.fromMap(
                Map<String, dynamic>.from(row),
                id: row['id']?.toString(),
              ),
            )
            .toList();
      } catch (e) {
        debugPrint('SearchHistoryService get from Supabase error: $e');
      }
    }

    // Fallback to local Hive box
    final localBox = _box;
    if (localBox != null && localBox.isNotEmpty) {
      final list = localBox.values
          .map((item) => SearchHistoryEntry.fromMap(Map<dynamic, dynamic>.from(item)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list.take(limit).toList();
    }

    return const [];
  }

  /// Delete a single search history entry.
  Future<void> deleteSearch(String id) async {
    final user = _auth.currentUser;
    if (user != null && id.isNotEmpty) {
      try {
        await _client
            .from('search_history')
            .delete()
            .eq('id', id)
            .eq('user_id', user.id);
      } catch (e) {
        debugPrint('SearchHistoryService delete error: $e');
      }
    }
  }

  /// Clears local and cloud search history.
  Future<void> clearSearchHistory() async {
    try {
      await _box?.clear();
    } catch (e) {
      debugPrint('SearchHistoryService clear Hive error: $e');
    }

    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _client
            .from('search_history')
            .delete()
            .eq('user_id', user.id);
      } catch (e) {
        debugPrint('SearchHistoryService clear Supabase error: $e');
      }
    }
  }

  String? _dateOnly(DateTime? value) {
    if (value == null) return null;
    return value.toUtc().toIso8601String().split('T').first;
  }
}
