import 'package:flutter/material.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/data/saved_trips_provider.dart';
import 'package:voyz/screens/splash_screen.dart';

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
