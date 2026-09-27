import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Standardized single-line input has 18x15 contentPadding and 1.45 line-height', (tester) async {
    final controller = TextEditingController(text: 'test@example.com');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: TextField(
                controller: controller,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.45,
                  letterSpacing: 0.2,
                ),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.textAlignVertical, TextAlignVertical.center);
    expect(textField.style?.height, 1.45);
    expect(textField.style?.fontSize, 15);
    expect(textField.decoration?.contentPadding, const EdgeInsets.symmetric(horizontal: 18, vertical: 15));
  });
}
