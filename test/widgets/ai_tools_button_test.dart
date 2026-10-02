import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/screens/ai_tools_screen.dart';
import 'package:voyz/widgets/shared/ai_tools_button.dart';

Widget _buildTestApp({required GlobalKey<NavigatorState> navKey}) {
  return MaterialApp(
    navigatorKey: navKey,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Stack(
        children: [
          AIToolsButton(navigatorKey: navKey),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('AIToolsButton renders icon without text', (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(_buildTestApp(navKey: navKey));

    // AI Tools should be an icon button without extended text
    expect(find.text('AI Tools'), findsNothing);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });

  testWidgets('AIToolsButton moves when dragged', (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    AIToolsButton.savedPosition = null;

    await tester.pumpWidget(_buildTestApp(navKey: navKey));

    final initialCenter = tester.getCenter(find.byType(AIToolsButton));
    
    // Drag button up and left
    await tester.drag(find.byType(AIToolsButton), const Offset(-100, -100));
    await tester.pumpAndSettle();

    final newCenter = tester.getCenter(find.byType(AIToolsButton));
    expect(newCenter.dx, lessThan(initialCenter.dx));
    expect(newCenter.dy, lessThan(initialCenter.dy));
  });

  testWidgets('AIToolsButton tap opens AIToolsScreen', (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    AIToolsButton.savedPosition = null;

    await tester.pumpWidget(_buildTestApp(navKey: navKey));

    await tester.tap(find.byType(AIToolsButton));
    await tester.pumpAndSettle();

    // Verify AIToolsScreen opened
    expect(find.byType(AIToolsScreen), findsOneWidget);
  });
}
