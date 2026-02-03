import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kHideSpendingAmountsKey = 'hide_spending_amounts';

/// Notifier for hiding spending amounts (privacy - show asterisks instead).
class HideSpendingAmountsNotifier extends StateNotifier<bool> {
  HideSpendingAmountsNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_kHideSpendingAmountsKey) ?? false;
    } catch (_) {
      // Keep default false
    }
  }

  Future<void> setHidden(bool hidden) async {
    state = hidden;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kHideSpendingAmountsKey, hidden);
    } catch (_) {
      // State already updated
    }
  }

  void toggle() => setHidden(!state);
}

/// Provider for "hide spending amounts" (privacy toggle).
/// When true, spending summary shows asterisks instead of amounts.
final hideSpendingAmountsProvider =
    StateNotifierProvider<HideSpendingAmountsNotifier, bool>((ref) {
  return HideSpendingAmountsNotifier();
});
