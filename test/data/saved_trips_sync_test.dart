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
    test('SavedItem tu sinh id UUID va giu nguyen qua toMap/fromMap', () {
      final item = SavedItem(
        name: 'Hue',
        imageUrl: '',
        price: '',
        matchPercent: 0,
        rating: 0,
        reviewCount: 0,
        aiInsight: '',
      );
      expect(item.id, hasLength(36));
      final restored = SavedItem.fromMap(item.toMap());
      expect(restored.id, equals(item.id));
      expect(SavedItem.fromMap(restored.toMap()).id, equals(item.id));
    });

    test('SavedItem.fromMap thieu id thi sinh id moi', () {
      final restored = SavedItem.fromMap({'name': 'Hue'});
      expect(restored.id, hasLength(36));
    });

    test('hai SavedItem cung name khac id la hai item', () {
      SavedItem make() => SavedItem(
        name: 'Da Nang',
        imageUrl: '',
        price: '',
        matchPercent: 0,
        rating: 0,
        reviewCount: 0,
        aiInsight: '',
        tripData: TripData(destination: 'Da Nang'),
      );
      final a = make();
      final b = make();
      expect(a.id, isNot(equals(b.id)));
      expect(a.copyWith(workspaceNotes: 'x').id, equals(a.id));
    });

    test('ItineraryPlan giu tripId qua toMap/fromJson va copyWith', () {
      const plan = ItineraryPlan(
        destinationName: 'Hue',
        dateRange: '3 days',
        days: [],
        proTip: '',
        tripId: 'trip-123',
      );
      expect(ItineraryPlan.fromJson(plan.toMap()).tripId, equals('trip-123'));
      expect(plan.copyWith(tripId: 'trip-456').tripId, equals('trip-456'));
      expect(plan.copyWith(tripId: 'trip-456').destinationName, equals('Hue'));
    });

    test('TripData.dayCount tinh ca ngay di va ngay ve, kep 1..7', () {
      expect(
        TripData(
          departDate: DateTime(2026, 6, 1),
          returnDate: DateTime(2026, 6, 3),
        ).dayCount(),
        equals(3),
      );
      expect(TripData().dayCount(), equals(3));
      expect(TripData().dayCount(fallback: 5), equals(5));
      expect(
        TripData(
          departDate: DateTime(2026, 6, 1),
          returnDate: DateTime(2026, 6, 20),
        ).dayCount(),
        equals(7),
      );
      expect(
        TripData(
          departDate: DateTime(2026, 6, 1),
          returnDate: DateTime(2026, 6, 1),
        ).dayCount(),
        equals(1),
      );
    });

    test('TripData.dayCount dung numDays khi khong co ngay', () {
      expect(TripData(numDays: 7).dayCount(), equals(7));
      expect(TripData(numDays: 4).dayCount(), equals(4));
      expect(TripData(numDays: 10).dayCount(), equals(7));
      expect(TripData(numDays: 0).dayCount(), equals(3));
    });

    test('TripData.dayCount uu tien ngay di/ve hon numDays', () {
      expect(
        TripData(
          departDate: DateTime(2026, 10, 10),
          returnDate: DateTime(2026, 10, 13),
          numDays: 7,
        ).dayCount(),
        equals(4),
      );
    });

    test('TripData numDays di qua toMap/fromMap/copyWith', () {
      final trip = TripData(destination: 'Con Dao', numDays: 5);
      final restored = TripData.fromMap(trip.toMap());
      expect(restored.numDays, equals(5));
      expect(TripData.fromMap({'numDays': '6'}).numDays, equals(6));
      expect(TripData.fromMap({}).numDays, isNull);
      expect(trip.copyWith(destination: 'Hue').numDays, equals(5));
      expect(trip.copyWith(numDays: 2).numDays, equals(2));
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
