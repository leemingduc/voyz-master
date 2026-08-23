import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/models/itinerary_plan.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SavedItem & ItineraryPlan Serialization for Cloud Sync Tests', () {
    test('SavedItem full workspace serialization roundtrip', () {
      final trip = TripData(
        destination: 'Phu Quoc',
        budget: '10M',
        currency: 'VND',
        selectedInterests: ['beach', 'wellness'],
      );

      final item = SavedItem(
        name: 'Phu Quoc, Vietnam',
        imageUrl: 'https://example.com/pq.jpg',
        price: '~5M VND',
        matchPercent: 95,
        rating: 4.8,
        reviewCount: 220,
        aiInsight: 'Great for wellness and beach lovers',
        tripData: trip,
        checklist: [
          const WorkspaceChecklistItem(text: 'Book resort', isDone: true),
          const WorkspaceChecklistItem(text: 'Check flight', isDone: false),
        ],
        workspaceNotes: 'Stay at Sunset Beach',
        bookingRefs: ['VJ123', 'HTL999'],
        sharedWith: ['friend@example.com'],
      );

      final map = item.toMap();
      expect(map['name'], equals('Phu Quoc, Vietnam'));
      expect(map['bookingRefs'], contains('VJ123'));
      expect(map['sharedWith'], contains('friend@example.com'));

      final restored = SavedItem.fromMap(map);
      expect(restored.name, equals(item.name));
      expect(restored.tripData, isNotNull);
      expect(restored.tripData!.destination, equals('Phu Quoc'));
      expect(restored.checklist.length, equals(2));
      expect(restored.checklist[0].isDone, isTrue);
      expect(restored.checklist[1].isDone, isFalse);
      expect(restored.bookingRefs, contains('HTL999'));
    });

    test('SavedItem wishlist card without tripData roundtrip', () {
      final item = SavedItem(
        name: 'Con Dao, Vietnam',
        imageUrl: 'https://example.com/cd.jpg',
        price: '~4M VND',
        matchPercent: 90,
        rating: 4.5,
        reviewCount: 150,
        aiInsight: 'Serene getaway',
        tripData: null,
      );

      final map = item.toMap();
      expect(map['tripData'], isNull);

      final restored = SavedItem.fromMap(map);
      expect(restored.name, equals('Con Dao, Vietnam'));
      expect(restored.tripData, isNull);
    });

    test('ItineraryPlan serialization roundtrip', () {
      const plan = ItineraryPlan(
        destinationName: 'Da Nang',
        dateRange: '3 days',
        days: [
          ItineraryDay(
            dayNumber: 1,
            title: 'Arrival & Beach',
            subtitle: 'Explore the coastline',
            items: [
              ItineraryItem(
                time: '09:00 AM',
                title: 'Arrival',
                description: 'Landing at DAD airport',
                icon: 'flight_land',
              ),
            ],
          ),
        ],
        proTip: 'Eat local seafood at My Khe',
      );

      final map = plan.toMap();
      expect(map['destinationName'], equals('Da Nang'));

      final restored = ItineraryPlan.fromJson(map);
      expect(restored.destinationName, equals('Da Nang'));
      expect(restored.days.length, equals(1));
      expect(restored.days[0].items.length, equals(1));
      expect(restored.proTip, contains('My Khe'));
    });
  });
}
