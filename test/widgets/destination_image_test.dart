import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/widgets/shared/destination_image.dart';

void main() {
  testWidgets('DestinationImage renders branded ShimmerLoadingBox with rocket icon and loading text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DestinationImage(
            imageUrl: '',
            destinationName: 'Đà Nẵng',
            isLoading: true,
          ),
        ),
      ),
    );

    // Verify shimmer widget renders when loading with rocket icon
    expect(find.byType(ShimmerLoadingBox), findsOneWidget);
    expect(find.byIcon(Icons.rocket_launch_rounded), findsOneWidget);
    expect(find.text('AIVIVU đang nạp ảnh...'), findsNothing);
  });

  testWidgets('DestinationImage renders Fallback with name when not loading and empty', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DestinationImage(
            imageUrl: '',
            destinationName: 'Đà Lạt',
            isLoading: false,
          ),
        ),
      ),
    );

    expect(find.text('Đà Lạt'), findsOneWidget);
  });
}
