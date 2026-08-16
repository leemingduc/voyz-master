import 'package:flutter/material.dart';
import 'package:voyz/data/currency_provider.dart';
import 'package:voyz/l10n/app_localizations.dart';

Future<String?> showCurrencySelector(BuildContext context) {
  final controller = CurrencyProvider.of(context);
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF161B2E),
    showDragHandle: true,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext)!;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.currencySelectorTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.currencySelectorDescription,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: supportedCurrencies.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: Color(0xFF27324A)),
                  itemBuilder: (context, index) {
                    final currency = supportedCurrencies[index];
                    final selected = currency.code == controller.value;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF27324A),
                        child: Text(
                          currency.symbol,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        _localizedCurrencyName(currency.code, l10n),
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        currency.code,
                        style: const TextStyle(color: Color(0xFF94A3B8)),
                      ),
                      trailing: selected
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFFFF6B9D),
                            )
                          : null,
                      onTap: () =>
                          Navigator.of(sheetContext).pop(currency.code),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _localizedCurrencyName(String code, AppLocalizations l10n) =>
    switch (code) {
      'VND' => l10n.currencyVietnameseDong,
      'USD' => l10n.currencyUsDollar,
      'EUR' => l10n.currencyEuro,
      'KRW' => l10n.currencyKoreanWon,
      'JPY' => l10n.currencyJapaneseYen,
      'THB' => l10n.currencyThaiBaht,
      'GBP' => l10n.currencyBritishPound,
      'AUD' => l10n.currencyAustralianDollar,
      'SGD' => l10n.currencySingaporeDollar,
      'CAD' => l10n.currencyCanadianDollar,
      _ => code,
    };
