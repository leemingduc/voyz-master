import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/data/saved_trips_provider.dart';
import 'package:voyz/screens/ai_tools_screen.dart';
import 'package:voyz/screens/splash_screen.dart';
import 'package:voyz/widgets/shared/aivivu_header.dart';
import 'package:voyz/widgets/shared/aivivu_page_background.dart';
import 'package:voyz/widgets/shared/bottom_nav_bar.dart';
import 'package:voyz/widgets/shared/aivivu_wordmark.dart';

/// A minimal widget that renders a single localized string so we can assert
/// the generated AppLocalizations supplies the correct translation.
class _LocalizedProbe extends StatelessWidget {
  const _LocalizedProbe();

  @override
  Widget build(BuildContext context) {
    return Text(AppLocalizations.of(context)!.signIn);
  }
}

void main() {
  setUpAll(() {
    final tempDir = Directory.systemTemp.createTempSync('voyz_widget_test');
    Hive.init(tempDir.path);
  });

  testWidgets('App launches with splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      SavedTripsProvider(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SplashScreen(nextScreen: const Scaffold(body: Text('next'))),
        ),
      ),
    );

    // Verify splash screen shows the app name
    expect(find.text('AIVIVU'), findsOneWidget);

    // Cleanly let all timers and animations finish
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('AIVIVU wordmark keeps the uppercase brand treatment', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AivivuWordmark())),
    );

    expect(find.text('AIVIVU'), findsOneWidget);
  });

  testWidgets('cosmic page background paints the reference star field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AivivuPageBackground(child: SizedBox.expand())),
    );

    expect(find.byKey(const ValueKey('cosmic_star_field')), findsOneWidget);
  });

  testWidgets('splash renders the shared AIVIVU wordmark', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SplashScreen(nextScreen: const SizedBox()),
      ),
    );

    expect(find.byType(AivivuWordmark), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
    'bottom navigation has three equal destinations and an active indicator',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            bottomNavigationBar: BottomNavBar(currentIndex: 1),
          ),
        ),
      );

      expect(find.byType(Expanded), findsNWidgets(3));
      expect(
        find.byKey(const ValueKey('bottom_nav_active_indicator')),
        findsOneWidget,
      );
    },
  );

  testWidgets('bottom sheet navigation stays a compact floating dock', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(bottomSheet: BottomNavBar(currentIndex: 0)),
      ),
    );

    expect(tester.getSize(find.byType(BottomNavBar)).height, lessThan(100));
  });

  testWidgets('AI tools uses the shared AIVIVU header', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AIToolsScreen(),
      ),
    );

    expect(find.byType(AivivuHeader), findsOneWidget);
  });

  testWidgets('generated localization supplies Vietnamese copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: _LocalizedProbe()),
      ),
    );
    await tester.pump();
    expect(find.text('Đăng nhập'), findsOneWidget);
  });

  testWidgets('generated localization supplies Korean copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: _LocalizedProbe()),
      ),
    );
    await tester.pump();
    expect(find.text('로그인'), findsOneWidget);
  });
}
