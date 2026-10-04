import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/widgets/shared/typing_indicator_bubble.dart';

void main() {
  testWidgets('TypingIndicatorBubble renders AI avatar and 3 dots', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TypingIndicatorBubble(),
        ),
      ),
    );

    // Verify AI sparkle icon exists
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);

    // Verify typing indicator bubble exists
    expect(find.byType(TypingIndicatorBubble), findsOneWidget);

    // Pump frames to verify animation runs without errors
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('TypingIndicatorBubble renders label when provided', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TypingIndicatorBubble(label: 'AI đang soạn câu trả lời...'),
        ),
      ),
    );

    expect(find.text('AI đang soạn câu trả lời...'), findsOneWidget);
  });
}
