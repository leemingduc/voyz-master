import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// Currencies offered in the travel-planning experience.
const List<SupportedCurrency> supportedCurrencies = <SupportedCurrency>[
  SupportedCurrency(code: 'VND', name: 'Vietnamese đồng', symbol: '₫'),
  SupportedCurrency(code: 'USD', name: 'US dollar', symbol: r'$'),
  SupportedCurrency(code: 'EUR', name: 'Euro', symbol: '€'),
  SupportedCurrency(code: 'KRW', name: 'South Korean won', symbol: '₩'),
  SupportedCurrency(code: 'JPY', name: 'Japanese yen', symbol: '¥'),
  SupportedCurrency(code: 'THB', name: 'Thai baht', symbol: '฿'),
  SupportedCurrency(code: 'GBP', name: 'British pound', symbol: '£'),
  SupportedCurrency(code: 'AUD', name: 'Australian dollar', symbol: r'A$'),
  SupportedCurrency(code: 'SGD', name: 'Singapore dollar', symbol: r'S$'),
  SupportedCurrency(code: 'CAD', name: 'Canadian dollar', symbol: r'C$'),
];

class SupportedCurrency {
  const SupportedCurrency({
    required this.code,
    required this.name,
    required this.symbol,
  });

  final String code;
  final String name;
  final String symbol;
}

SupportedCurrency currencyForCode(String code) =>
    supportedCurrencies.firstWhere(
      (currency) => currency.code == code,
      orElse: () => supportedCurrencies.first,
    );

/// Persists the user's preferred display currency independently of any trip.
class CurrencySettingsStore {
  CurrencySettingsStore._();
  static final CurrencySettingsStore instance = CurrencySettingsStore._();

  static const String _boxName = 'app_settings';
  static const String _currencyCodeKey = 'display_currency_code';

  Future<String> load() async {
    final box = await Hive.openBox<String>(_boxName);
    final saved = box.get(_currencyCodeKey) ?? 'VND';
    return supportedCurrencies.any((currency) => currency.code == saved)
        ? saved
        : 'VND';
  }

  Future<void> save(String code) async {
    if (!supportedCurrencies.any((currency) => currency.code == code)) return;
    final box = await Hive.openBox<String>(_boxName);
    await box.put(_currencyCodeKey, code);
  }
}

class CurrencyController extends ValueNotifier<String> {
  CurrencyController(super.initialCode);

  Future<void> setDisplayCurrency(String code) async {
    if (!supportedCurrencies.any((currency) => currency.code == code) ||
        code == value) {
      return;
    }
    value = code;
    await CurrencySettingsStore.instance.save(code);
  }
}

class CurrencyProvider extends InheritedNotifier<CurrencyController> {
  const CurrencyProvider({
    super.key,
    required CurrencyController controller,
    required super.child,
  }) : super(notifier: controller);

  static CurrencyController of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<CurrencyProvider>();
    assert(provider != null, 'No CurrencyProvider found in widget tree.');
    return provider!.notifier!;
  }
}
