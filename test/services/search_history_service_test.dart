import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/services/search_history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SearchHistoryService & Entry Tests', () {
    test('SearchHistoryEntry serializes and deserializes correctly', () {
      final now = DateTime.now();
      final entry = SearchHistoryEntry(
        id: 'test-id-123',
        destination: 'Da Nang, Vietnam',
        departDate: DateTime(2026, 9, 1),
        returnDate: DateTime(2026, 9, 5),
        budget: '5M',
        currency: 'VND',
        participants: '2 adults',
        ageRange: '25-35',
        selectedInterests: ['beach', 'food'],
        aiPrompt: 'Relaxing trip',
        additionalNotes: 'Need hotel near beach',
        createdAt: now,
      );

      final map = entry.toMap();
      expect(map['id'], equals('test-id-123'));
      expect(map['destination'], equals('Da Nang, Vietnam'));
      expect(map['currency'], equals('VND'));

      final fromMap = SearchHistoryEntry.fromMap(map);
      expect(fromMap.id, equals('test-id-123'));
      expect(fromMap.destination, equals('Da Nang, Vietnam'));
      expect(fromMap.selectedInterests, containsAll(['beach', 'food']));

      final tripData = fromMap.toTripData();
      expect(tripData.destination, equals('Da Nang, Vietnam'));
      expect(tripData.budget, equals('5M'));
      expect(tripData.currency, equals('VND'));
    });

    test('SearchHistoryEntry handles empty / null fields gracefully', () {
      final entry = SearchHistoryEntry.fromMap({});
      expect(entry.id, isEmpty);
      expect(entry.destination, isEmpty);
      expect(entry.currency, equals('VND'));
      expect(entry.selectedInterests, isEmpty);
    });
  });
}
