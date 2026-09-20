import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/widgets/shared/trip_chips.dart';

void main() {
  Widget buildTestWidget({
    required TripData trip,
    required ValueChanged<TripData> onTripChanged,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TripChips(
          trip: trip,
          onTripChanged: onTripChanged,
        ),
      ),
    );
  }

  testWidgets('renders all chips with provided trip data', (tester) async {
    final trip = TripData(
      destination: 'Đà Lạt',
      departDate: DateTime(2026, 10, 1),
      returnDate: DateTime(2026, 10, 4),
      budget: 'economy',
      participants: '3',
    );

    await tester.pumpWidget(buildTestWidget(trip: trip, onTripChanged: (_) {}));
    await tester.pumpAndSettle();

    expect(find.textContaining('Đà Lạt'), findsOneWidget);
    expect(find.textContaining('01/10 - 04/10'), findsOneWidget);
    expect(find.textContaining('3 người'), findsOneWidget);
  });

  testWidgets('renders dimmed placeholder when destination is empty', (tester) async {
    final trip = TripData(destination: '');

    await tester.pumpWidget(buildTestWidget(trip: trip, onTripChanged: (_) {}));
    await tester.pumpAndSettle();

    expect(find.textContaining('AI gợi ý'), findsOneWidget);
  });

  testWidgets('tapping budget chip opens sheet and invokes onTripChanged', (tester) async {
    TripData? updated;
    final trip = TripData(budget: 'moderate');

    await tester.pumpWidget(buildTestWidget(
      trip: trip,
      onTripChanged: (newTrip) => updated = newTrip,
    ));
    await tester.pumpAndSettle();

    // Tap the budget chip
    final budgetFinder = find.byKey(const ValueKey('trip_chip_budget'));
    expect(budgetFinder, findsOneWidget);
    await tester.tap(budgetFinder);
    await tester.pumpAndSettle();

    // Select luxury in bottom sheet
    final luxuryOption = find.byKey(const ValueKey('budget_option_luxury'));
    expect(luxuryOption, findsOneWidget);
    await tester.tap(luxuryOption);
    await tester.pumpAndSettle();

    expect(updated, isNotNull);
    expect(updated!.budget, 'luxury');
  });
}
