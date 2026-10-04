import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/screens/ai_tools_screen.dart';
import 'package:voyz/widgets/shared/ai_tools_button.dart';
import 'package:voyz/widgets/shared/aivivu_page_background.dart';

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

  testWidgets('AIToolsButton sits bottom-right inside the app shell', (
    tester,
  ) async {
    // Same structure as the MaterialApp.builder in lib/main.dart.
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final navKey = GlobalKey<NavigatorState>();
    AIToolsButton.savedPosition = null;

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(backgroundColor: Colors.transparent),
        builder: (context, child) => AivivuPageBackground(
          padding: false,
          constrainContent: false,
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              ValueListenableBuilder<bool>(
                valueListenable: AIToolsButtonVisibility.isHidden,
                builder: (context, isHidden, _) => isHidden
                    ? const SizedBox.shrink()
                    : AIToolsButton(navigatorKey: navKey),
              ),
            ],
          ),
        ),
      ),
    );

    final rect = tester.getRect(find.byType(AIToolsButton));
    expect(rect.size, const Size(58, 58));
    expect(rect.right, 430 - 16);
    expect(rect.bottom, 900 - 144);

    await tester.drag(find.byType(AIToolsButton), const Offset(-200, -300));
    await tester.pumpAndSettle();
    final moved = tester.getRect(find.byType(AIToolsButton));
    expect(moved.left, lessThan(rect.left));
    expect(moved.top, lessThan(rect.top));
  });
}
