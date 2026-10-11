import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/models/itinerary_plan.dart';

void main() {
  test('itinerary keeps its response language when it is saved', () {
    const plan = ItineraryPlan(
      destinationName: 'Da Nang',
      dateRange: 'May 1 - May 3',
      days: [],
      proTip: 'Bring sunscreen.',
      tripId: 'trip-1',
      languageCode: 'en',
    );

    final restored = ItineraryPlan.fromJson(plan.toMap());

    expect(restored.languageCode, 'en');
    expect(restored.tripId, 'trip-1');
  });
}
