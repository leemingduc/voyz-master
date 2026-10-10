import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/utils/destination_share.dart';
import 'package:voyz/widgets/shared/share_destination_bottom_sheet.dart';

void main() {
  test('extracts a destination from a shared friend message', () {
    expect(
      destinationNameFromShareMessage(
        '\u{1f4cd} [\u{0110}\u{1ecb}a \u{0111}i\u{1ec3}m] Da Nang',
      ),
      'Da Nang',
    );
  });
  testWidgets(
    'renders ShareDestinationBottomSheet without a copy link button',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShareDestinationBottomSheet(
              destinationName: 'Đà Nẵng',
              destinationId: 'da-nang-1',
            ),
          ),
        ),
      );

      expect(find.text('Chia sẻ địa điểm'), findsOneWidget);
      expect(find.text('Đà Nẵng'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsNothing);
    },
  );
}
