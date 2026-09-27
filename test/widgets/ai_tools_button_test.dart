import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/widgets/shared/ai_tools_button.dart';

void main() {
  testWidgets('AIToolsButton renders icon without text', (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        home: Scaffold(
          body: AIToolsButton(navigatorKey: navKey),
        ),
      ),
    );

    // AI Tools should be an icon button without extended text
    expect(find.text('AI Tools'), findsNothing);
  });
}
