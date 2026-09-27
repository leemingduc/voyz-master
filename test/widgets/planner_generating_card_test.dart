import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/widgets/planner/planner_generating_card.dart';

void main() {
  testWidgets('PlannerGeneratingCard renders and cycles messages', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlannerGeneratingCard(),
        ),
      ),
    );

    // Initial render checks
    expect(find.byType(PlannerGeneratingCard), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    expect(find.text('Đang phân tích sở thích và mong muốn của bạn...'), findsOneWidget);

    // Advance 2.3s to test timer message cycle
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump(const Duration(milliseconds: 400)); // Finish AnimatedSwitcher transition

    expect(find.text('Khám phá và chọn lọc các điểm đến phù hợp nhất...'), findsOneWidget);
  });
}
