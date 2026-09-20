import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:voyz/data/currency_provider.dart';
import 'package:voyz/data/locale_provider.dart';
import 'package:voyz/data/saved_trips_provider.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/screens/smart_planner_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('planner_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });
  Widget buildScreen() {
    final localeController = LocaleController(const Locale('vi'));
    final currencyController = CurrencyController('VND');

    return LocaleProvider(
      controller: localeController,
      child: CurrencyProvider(
        controller: currencyController,
        child: SavedTripsProvider(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            home: const SmartPlannerScreen(),
          ),
        ),
      ),
    );
  }

  testWidgets('renders prompt box, inspiration chips and cta button without old form fields', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    // Verify Prompt box and CTA are present
    expect(find.byType(TextField), findsOneWidget); // Only prompt TextField
    expect(find.textContaining('Gợi ý chuyến đi'), findsOneWidget);

    // Verify old form fields are removed
    expect(find.byIcon(Icons.public), findsNothing);
    expect(find.byIcon(Icons.calendar_month), findsNothing);
    expect(find.byIcon(Icons.cake), findsNothing);
  });

  testWidgets('shows snackbar when prompt is empty on submit', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    final submitBtn = find.text('Gợi ý chuyến đi');
    expect(submitBtn, findsOneWidget);
    await tester.ensureVisible(submitBtn);
    await tester.pumpAndSettle();
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('tapping an inspiration chip sets the prompt text', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    final inspirationChip = find.textContaining('Đà Lạt');
    expect(inspirationChip, findsOneWidget);
    await tester.tap(inspirationChip);
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, contains('Đà Lạt'));
  });
}
