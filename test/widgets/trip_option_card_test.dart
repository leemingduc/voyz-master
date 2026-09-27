import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/data/currency_provider.dart';
import 'package:voyz/l10n/app_localizations.dart';
import 'package:voyz/models/plan_turn.dart';
import 'package:voyz/widgets/planner/trip_option_card.dart';

void main() {
  testWidgets('shows title, duration, route and estimate label', (
    tester,
  ) async {
    var tapped = 0;
    await tester.pumpWidget(
      CurrencyProvider(
        controller: CurrencyController('VND'),
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: TripOptionCard(
                // Giá không parse được thành tiền: CurrencyAmountText hiện
                // nguyên chuỗi, test không gọi mạng quy đổi tiền.
                option: const TripOption(
                  title: 'Biển & lặn',
                  destination: 'Côn Đảo, Việt Nam',
                  numDays: 4,
                  stops: ['Bến Đầm', 'Hòn Bảy Cạnh', 'Bãi Đầm Trầu'],
                  imageStop: 'Hòn Bảy Cạnh',
                  price: 'khoảng sáu triệu',
                  aiInsight: 'Hợp nhóm bạn thích biển',
                ),
                onTap: () => tapped++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Biển & lặn'), findsOneWidget);
    expect(find.text('Côn Đảo, Việt Nam'), findsOneWidget);
    expect(find.text('4 ngày'), findsOneWidget);
    expect(find.text('Bến Đầm → Hòn Bảy Cạnh → Bãi Đầm Trầu'), findsOneWidget);
    expect(find.text('Ước tính AI'), findsOneWidget);
    expect(find.text('khoảng sáu triệu'), findsOneWidget);

    await tester.ensureVisible(find.text('Xem chi tiết'));
    await tester.pump();
    await tester.tap(find.text('Xem chi tiết'));
    expect(tapped, 1);
  });
}
