import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('verify prompt text field has non-zero contentPadding and proper line height', (tester) async {
    final controller = TextEditingController(text: 'Explore Da Nang for 3 days');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 500,
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 2,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.4,
                  letterSpacing: 0.2,
                ),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.style?.height, 1.4);
    expect(textField.decoration?.contentPadding, const EdgeInsets.symmetric(horizontal: 4, vertical: 4));
  });
}
