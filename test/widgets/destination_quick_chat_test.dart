import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/widgets/shared/destination_quick_chat.dart';

void main() {
  Widget buildSubject() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DestinationQuickChat(
          destinationName: 'Đà Lạt',
          onDestinationSelected: (_) {},
        ),
      ),
    );
  }

  testWidgets('shows the current destination and can be minimized', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('Đà Lạt'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.tap(find.byIcon(Icons.minimize));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });
}
