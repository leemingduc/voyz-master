import 'package:hive_flutter/hive_flutter.dart';
import 'package:voyz/data/trip_data.dart';

class SearchHistoryService {
  SearchHistoryService._();

  static final SearchHistoryService instance = SearchHistoryService._();
  static const String _boxName = 'search_history';

  Future<void> init() async {
    await Hive.openBox<Map>(_boxName);
  }

  Box<Map> get _box => Hive.box<Map>(_boxName);

  Future<void> recordTripSearch(TripData trip) async {
    final now = DateTime.now().toUtc().toIso8601String();
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
      'created_at': now,
    };

    await _box.add(payload);
  }

  String? _dateOnly(DateTime? value) {
    if (value == null) return null;
    return value.toUtc().toIso8601String().split('T').first;
  }
}
