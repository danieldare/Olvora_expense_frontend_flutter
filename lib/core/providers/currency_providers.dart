import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/currency_service.dart';
import '../models/currency.dart';

/// Provider for currency service
final currencyServiceProvider = Provider<CurrencyService>((ref) {
  return CurrencyService();
});

/// Provider for the currently selected currency
/// Using keepAlive to cache results and prevent unnecessary refetches
final selectedCurrencyProvider = FutureProvider<Currency>((ref) async {
  ref.keepAlive(); // Keep provider alive to cache results
  final currencyService = ref.watch(currencyServiceProvider);
  return currencyService.getSelectedCurrency();
});

/// Notifier for managing currency selection
final currencyNotifierProvider =
    StateNotifierProvider<CurrencyNotifier, AsyncValue<Currency>>((ref) {
      final currencyService = ref.watch(currencyServiceProvider);
      return CurrencyNotifier(currencyService, ref);
    });

class CurrencyNotifier extends StateNotifier<AsyncValue<Currency>> {
  final CurrencyService _currencyService;
  final Ref _ref;

  CurrencyNotifier(this._currencyService, this._ref)
    : super(const AsyncValue.loading()) {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    try {
      final currency = await _currencyService.getSelectedCurrency();
      state = AsyncValue.data(currency);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> setCurrency(Currency currency) async {
    try {
      await _currencyService.setSelectedCurrency(currency);
      state = AsyncValue.data(currency);
      // Invalidate the provider to update all listeners
      _ref.invalidate(selectedCurrencyProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
