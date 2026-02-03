import 'package:intl/intl.dart';
import '../models/currency.dart';


class CurrencyFormatter {
  static String format(double amount, Currency currency) {
    // For currencies without decimal places (like JPY), use 0 decimal places
    final decimalDigits = _getDecimalDigits(currency.code);

    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: decimalDigits,
    );

    return formatter.format(amount);
  }

  /// Format an amount with currency symbol only (no decimals for some currencies)
  static String formatCompact(double amount, Currency currency) {
    final decimalDigits = _getDecimalDigits(currency.code);

    if (amount >= 1000000) {
      return '${currency.symbol}${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${currency.symbol}${(amount / 1000).toStringAsFixed(1)}K';
    }

    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }

  /// Get decimal digits for a currency code
  static int _getDecimalDigits(String code) {
    // Currencies that typically don't use decimal places
    const noDecimalCurrencies = ['JPY', 'KRW', 'VND'];
    return noDecimalCurrencies.contains(code) ? 0 : 2;
  }
}
