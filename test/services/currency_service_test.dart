import 'package:flutter_test/flutter_test.dart';
import 'package:voyz/services/currency_service.dart';

void main() {
  group('MoneyParser', () {
    test('parses estimated Vietnamese prices with an M suffix', () {
      final money = MoneyParser.tryParse('~4.2M VNĐ');

      expect(money, isNotNull);
      expect(money!.amount, 4200000);
      expect(money.currencyCode, 'VND');
      expect(money.isEstimate, isTrue);
    });

    test('parses ISO currency codes and keeps exact prices exact', () {
      final money = MoneyParser.tryParse('125.50 USD');

      expect(money, isNotNull);
      expect(money!.amount, 125.5);
      expect(money.currencyCode, 'USD');
      expect(money.isEstimate, isFalse);
    });

    test('does not treat non-monetary labels as prices', () {
      expect(MoneyParser.tryParse('Budget TBD'), isNull);
    });
  });

  group('CurrencyFormatter', () {
    test('uses zero decimal places for Vietnamese đồng', () {
      expect(CurrencyFormatter.format(4200000.8, 'VND'), contains('4,200,001'));
    });

    test('marks estimates with an approximation prefix', () {
      expect(
        CurrencyFormatter.format(165.3, 'USD', estimate: true),
        startsWith('≈'),
      );
    });
  });
}
