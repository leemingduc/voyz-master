import 'package:flutter/material.dart';
import 'package:voyz/data/currency_provider.dart';
import 'package:voyz/services/currency_service.dart';

/// Displays a legacy price string in the selected display currency while
/// retaining its source amount as a secondary label.
class CurrencyAmountText extends StatelessWidget {
  const CurrencyAmountText(
    this.value, {
    super.key,
    required this.style,
    this.originalStyle,
    this.textAlign,
    this.showOriginal = true,
  });

  final String value;
  final TextStyle style;
  final TextStyle? originalStyle;
  final TextAlign? textAlign;
  final bool showOriginal;

  @override
  Widget build(BuildContext context) {
    final targetCode = CurrencyProvider.of(context).value;
    final money = MoneyParser.tryParse(value);
    if (money == null) {
      return Text(value, style: style, textAlign: textAlign);
    }
    return FutureBuilder<ConvertedMoney?>(
      future: ExchangeRateService.instance.convert(money, targetCode),
      builder: (context, snapshot) {
        final converted = snapshot.data;
        final display = converted == null
            ? CurrencyFormatter.format(
                money.amount,
                money.currencyCode,
                estimate: money.isEstimate,
              )
            : CurrencyFormatter.format(
                converted.amount,
                converted.currencyCode,
                estimate: money.isEstimate,
              );
        final shouldShowOriginal =
            showOriginal && money.currencyCode != targetCode;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: textAlign == TextAlign.right
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(display, style: style, textAlign: textAlign),
            if (shouldShowOriginal)
              Text(
                CurrencyFormatter.format(
                  money.amount,
                  money.currencyCode,
                  estimate: money.isEstimate,
                ),
                style:
                    originalStyle ??
                    style.copyWith(fontSize: 10, fontWeight: FontWeight.w400),
                textAlign: textAlign,
              ),
          ],
        );
      },
    );
  }
}
