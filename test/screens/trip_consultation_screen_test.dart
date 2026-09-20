import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:voyz/data/locale_provider.dart';
import 'package:voyz/data/saved_trips_provider.dart';
import 'package:voyz/data/trip_data.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/screens/trip_consultation_screen.dart';

void main() {
  setUpAll(() {
    final tempDir = Directory.systemTemp.createTempSync('voyz_consult_test');
    Hive.init(tempDir.path);
  });

  testWidgets('TripConsultationScreen renders top bar, trip info, and chat greeting', (
    WidgetTester tester,
  ) async {
    final controller = LocaleController(const Locale('vi'));

    await tester.pumpWidget(
      LocaleProvider(
        controller: controller,
        child: const SavedTripsProvider(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TripConsultationScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Action button
    expect(find.text('Aivivu AI Travel Companion'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsWidgets);

    // Verify Collapsible Trip info banner
    expect(find.byIcon(Icons.tune), findsOneWidget);

    // Tap to expand trip info
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    // Should see budget chips
    expect(find.byType(ChoiceChip), findsWidgets);
  });
}
