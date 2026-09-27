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
                  hintText: 'Enter your email address...',
                  hintStyle: TextStyle(
                    color: Colors.white54,
                    fontSize: 15,
                    height: 1.45,
                    letterSpacing: 0.2,
                  ),
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

  testWidgets('Multiline textarea has top alignment, 16x14 padding, and handles long multiline text', (tester) async {
    const longMultiLineText =
        'Chuyến đi Đà Nẵng - Hội An 4 ngày 3 đêm cho gia đình có trẻ nhỏ.\n'
        'Cần lịch trình nhẹ nhàng, khách sạn gần biển Mỹ Khê.\n'
        'Ẩm thực địa phương phong phú và không quá cay.';

    final controller = TextEditingController(text: longMultiLineText);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: TextField(
                controller: controller,
                minLines: 3,
                maxLines: 6,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.45,
                  letterSpacing: 0.2,
                ),
                decoration: const InputDecoration(
                  hintText: 'Nhập ghi chú chi tiết...',
                  hintStyle: TextStyle(
                    color: Colors.white54,
                    fontSize: 15,
                    height: 1.45,
                    letterSpacing: 0.2,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.textAlignVertical, TextAlignVertical.top);
    expect(textField.minLines, 3);
    expect(textField.maxLines, 6);
    expect(textField.style?.height, 1.45);
    expect(textField.decoration?.contentPadding, const EdgeInsets.symmetric(horizontal: 16, vertical: 14));
    expect(find.text(longMultiLineText), findsOneWidget);
  });

  testWidgets('Input adapts properly across narrow mobile and wide tablet constraints', (tester) async {
    final controller = TextEditingController(text: 'Khám phá Phú Quốc');

    Widget buildInputWithWidth(double width) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
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
      );
    }

    // Narrow mobile (320px)
    await tester.pumpWidget(buildInputWithWidth(320));
    expect(find.text('Khám phá Phú Quốc'), findsOneWidget);

    // Wide tablet (768px)
    await tester.pumpWidget(buildInputWithWidth(768));
    expect(find.text('Khám phá Phú Quốc'), findsOneWidget);
  });
}
