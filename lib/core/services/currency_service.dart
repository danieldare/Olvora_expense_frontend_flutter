import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/currency.dart';

/// Service for managing currency preferences
class CurrencyService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _currencyKey = 'selected_currency';

  /// Get the currently selected currency
  Future<Currency> getSelectedCurrency() async {
    try {
      final currencyCode = await _storage.read(key: _currencyKey);
      if (currencyCode != null) {
        final currency = Currency.findByCode(currencyCode);
        if (currency != null) {
          return currency;
        }
      }
    } catch (e) {
      // If there's an error, return default currency
    }
    return Currency.defaultCurrency;
  }

  /// Set the selected currency
  Future<void> setSelectedCurrency(Currency currency) async {
    await _storage.write(key: _currencyKey, value: currency.code);
  }

  /// Clear the selected currency (reset to default)
  Future<void> clearCurrency() async {
    await _storage.delete(key: _currencyKey);
  }
}
