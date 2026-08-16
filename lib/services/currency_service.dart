import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:voyz/data/currency_provider.dart';

class ParsedMoney {
  const ParsedMoney({
    required this.amount,
    required this.currencyCode,
    required this.isEstimate,
  });

  final double amount;
  final String currencyCode;
  final bool isEstimate;
}

/// Parses the legacy, human-readable money strings already stored by Voyz.
/// New monetary API payloads should carry amount and currency separately.
class MoneyParser {
  static final RegExp _pattern = RegExp(
    r'(^|\s)([~\u2248])?\s*([0-9][0-9,.]*)\s*([mMkK])?\s*(VND|VN\u0110|USD|EUR|KRW|JPY|THB|GBP|AUD|SGD|CAD)(?:\b|$)',
    caseSensitive: false,
  );

  static ParsedMoney? tryParse(String value) {
    final match = _pattern.firstMatch(value.trim());
    if (match == null) return null;

    final rawNumber = match.group(3)!.replaceAll(',', '');
    final amount = double.tryParse(rawNumber);
    if (amount == null) return null;

    final multiplier = switch (match.group(4)?.toUpperCase()) {
      'M' => 1000000,
      'K' => 1000,
      _ => 1,
    };
    final rawCode = match.group(5)!.toUpperCase();
    return ParsedMoney(
      amount: amount * multiplier,
      currencyCode: rawCode.startsWith('VN') ? 'VND' : rawCode,
      isEstimate: match.group(2) != null,
    );
  }
}

class ExchangeRate {
  const ExchangeRate({
    required this.base,
    required this.quote,
    required this.rate,
    required this.retrievedAt,
  });

  final String base;
  final String quote;
  final double rate;
  final DateTime retrievedAt;

  Map<String, dynamic> toJson() => {
    'base': base,
    'quote': quote,
    'rate': rate,
    'retrievedAt': retrievedAt.toIso8601String(),
  };

  factory ExchangeRate.fromJson(Map<String, dynamic> json) => ExchangeRate(
    base: json['base'] as String,
    quote: json['quote'] as String,
    rate: (json['rate'] as num).toDouble(),
    retrievedAt: DateTime.parse(json['retrievedAt'] as String),
  );
}

class ConvertedMoney {
  const ConvertedMoney({
    required this.amount,
    required this.currencyCode,
    required this.original,
    required this.rateRetrievedAt,
    required this.usesCachedRate,
  });

  final double amount;
  final String currencyCode;
  final ParsedMoney original;
  final DateTime? rateRetrievedAt;
  final bool usesCachedRate;
}

/// Retrieves daily reference rates from Frankfurter and keeps the latest
/// successful response for offline use. Reference rates are not payment rates.
class ExchangeRateService {
  ExchangeRateService._({http.Client? client})
    : _client = client ?? http.Client();
  static final ExchangeRateService instance = ExchangeRateService._();

  static const _boxName = 'exchange_rates';
  static const _cacheTtl = Duration(hours: 6);
  static const _apiBaseUrl = 'https://api.frankfurter.dev/v2/rate';

  final http.Client _client;
  final Map<String, ExchangeRate> _memoryCache = {};
  Box<String>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  String _key(String base, String quote) => '$base-$quote';

  ExchangeRate? _cachedRate(String base, String quote) {
    final key = _key(base, quote);
    final inMemory = _memoryCache[key];
    if (inMemory != null) return inMemory;
    final raw = _box?.get(key);
    if (raw == null) return null;
    try {
      final rate = ExchangeRate.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      _memoryCache[key] = rate;
      return rate;
    } catch (_) {
      return null;
    }
  }

  Future<ExchangeRate> rateFor(String base, String quote) async {
    if (base == quote) {
      return ExchangeRate(
        base: base,
        quote: quote,
        rate: 1,
        retrievedAt: DateTime.now(),
      );
    }
    final cached = _cachedRate(base, quote);
    if (cached != null &&
        DateTime.now().difference(cached.retrievedAt) < _cacheTtl) {
      return cached;
    }

    try {
      final response = await _client
          .get(Uri.parse('$_apiBaseUrl/$base/$quote'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw const FormatException('Rate unavailable');
      }
      final payload = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );
      final rate = ExchangeRate(
        base: payload['base'] as String,
        quote: payload['quote'] as String,
        rate: (payload['rate'] as num).toDouble(),
        retrievedAt: DateTime.now(),
      );
      _memoryCache[_key(base, quote)] = rate;
      await _box?.put(_key(base, quote), jsonEncode(rate.toJson()));
      return rate;
    } catch (_) {
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<ConvertedMoney?> convert(
    ParsedMoney original,
    String targetCode,
  ) async {
    if (original.currencyCode == targetCode) {
      return ConvertedMoney(
        amount: original.amount,
        currencyCode: targetCode,
        original: original,
        rateRetrievedAt: null,
        usesCachedRate: false,
      );
    }
    final before = _cachedRate(original.currencyCode, targetCode);
    final rate = await rateFor(original.currencyCode, targetCode);
    return ConvertedMoney(
      amount: original.amount * rate.rate,
      currencyCode: targetCode,
      original: original,
      rateRetrievedAt: rate.retrievedAt,
      usesCachedRate: before != null && identical(before, rate),
    );
  }
}

class CurrencyFormatter {
  static String format(
    double amount,
    String currencyCode, {
    bool estimate = false,
  }) {
    final decimalDigits = {'VND', 'KRW', 'JPY'}.contains(currencyCode) ? 0 : 2;
    final currency = currencyForCode(currencyCode);
    final formatted = NumberFormat.currency(
      name: currencyCode,
      symbol: currency.symbol,
      decimalDigits: decimalDigits,
    ).format(amount);
    return estimate ? '≈ $formatted' : formatted;
  }
}
