import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/widgets/shared/aivivu_loading_indicator.dart';
import 'package:voyz/widgets/shared/aivivu_rocket_mascot.dart';

void main() {
  testWidgets('AivivuLoadingIndicator renders mascot and message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AivivuLoadingIndicator(message: 'AIVIVU đang chuẩn bị hành trình...'),
        ),
      ),
    );

    expect(find.byType(AivivuLoadingIndicator), findsOneWidget);
    expect(find.byType(AivivuRocketMascot), findsOneWidget);
    expect(find.text('AIVIVU đang chuẩn bị hành trình...'), findsOneWidget);
  });
}
