import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/widgets/shared/aivivu_rocket_mascot.dart';

void main() {
  testWidgets('AivivuRocketMascot renders custom paint and runs animation', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: AivivuRocketMascot(size: 80)),
        ),
      ),
    );

    expect(find.byType(AivivuRocketMascot), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    // Pump animation frames to verify it animates smoothly without errors
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  });
}
