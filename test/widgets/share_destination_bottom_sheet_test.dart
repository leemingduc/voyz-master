import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/widgets/shared/share_destination_bottom_sheet.dart';

void main() {
  testWidgets(
    'renders ShareDestinationBottomSheet header and copy link fallback button',
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
      expect(find.text('Sao chép liên kết'), findsOneWidget);
    },
  );
}
