import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/widgets/shared/trip_chips.dart';

Widget _wrap(TripData trip, ValueChanged<TripData> onChanged) {
  return MaterialApp(
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: TripChips(trip: trip, onChanged: onChanged),
    ),
  );
}

void main() {
  testWidgets('empty values show as "not set" placeholders', (tester) async {
    await tester.pumpWidget(_wrap(TripData(), (_) {}));

    expect(find.text('Điểm đến: AI sẽ gợi ý'), findsOneWidget);
    expect(find.text('Ngày: linh hoạt'), findsOneWidget);
  });

  testWidgets('extracted values show on the chips', (tester) async {
    final trip = TripData(
      destination: 'Đà Lạt',
      departDate: DateTime(2026, 10, 1),
      returnDate: DateTime(2026, 10, 3),
      participants: '4',
      budget: 'economy',
    );
    await tester.pumpWidget(_wrap(trip, (_) {}));

    expect(find.text('Điểm đến: Đà Lạt'), findsOneWidget);
    expect(find.text('Ngày: 01/10 - 03/10'), findsOneWidget);
    expect(find.text('Số người: 4'), findsOneWidget);
    expect(find.textContaining('Phân khúc ngân sách: '), findsOneWidget);
  });

  testWidgets('picking a tier edits only the budget', (tester) async {
    TripData? changed;
    await tester.pumpWidget(
      _wrap(
        TripData(destination: 'Đà Lạt', budget: 'economy'),
        (trip) => changed = trip,
      ),
    );

    await tester.tap(find.textContaining('Phân khúc ngân sách'));
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('vi'));
    await tester.tap(find.text(l10n.budgetTierPremium));
    await tester.pumpAndSettle();

    expect(changed?.budget, 'premium');
    expect(changed?.destination, 'Đà Lạt');
  });
}
