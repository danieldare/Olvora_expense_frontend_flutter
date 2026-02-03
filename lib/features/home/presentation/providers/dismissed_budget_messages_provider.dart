import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../budget/domain/entities/budget_entity.dart';

const _kDismissedMessagesKey = 'dismissed_budget_messages';

/// State for dismissed budget messages
class DismissedBudgetMessagesState {
  final Set<String> dismissedPeriods;
  final bool isLoaded;

  const DismissedBudgetMessagesState({
    this.dismissedPeriods = const {},
    this.isLoaded = false,
  });

  DismissedBudgetMessagesState copyWith({
    Set<String>? dismissedPeriods,
    bool? isLoaded,
  }) {
    return DismissedBudgetMessagesState(
      dismissedPeriods: dismissedPeriods ?? this.dismissedPeriods,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  bool isPeriodDismissed(BudgetType period) {
    return dismissedPeriods.contains(period.name);
  }
}

/// Notifier for managing dismissed budget messages
///
/// This replaces the local state in SpendingSummaryCard that was causing
/// setState-triggered rebuilds after loading from SharedPreferences.
class DismissedBudgetMessagesNotifier extends StateNotifier<DismissedBudgetMessagesState> {
  DismissedBudgetMessagesNotifier() : super(const DismissedBudgetMessagesState()) {
    _loadDismissedMessages();
  }

  Future<void> _loadDismissedMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getStringList(_kDismissedMessagesKey) ?? [];
      state = state.copyWith(
        dismissedPeriods: dismissed.toSet(),
        isLoaded: true,
      );
    } catch (e) {
      // On error, mark as loaded with empty set
      state = state.copyWith(isLoaded: true);
    }
  }

  /// Dismiss the budget message for a specific period
  Future<void> dismissPeriod(BudgetType period) async {
    final periodKey = period.name;
    final newDismissed = {...state.dismissedPeriods, periodKey};

    // Update state immediately for responsive UI
    state = state.copyWith(dismissedPeriods: newDismissed);

    // Persist to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kDismissedMessagesKey, newDismissed.toList());
    } catch (e) {
      // Ignore persistence errors - state is already updated
    }
  }

  /// Reset all dismissed messages (useful for testing or user request)
  Future<void> resetAll() async {
    state = state.copyWith(dismissedPeriods: {});

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kDismissedMessagesKey);
    } catch (e) {
      // Ignore persistence errors
    }
  }
}

/// Provider for dismissed budget messages
///
/// Use this instead of local SharedPreferences loading in widgets to prevent
/// setState-triggered rebuilds that cause flickering.
final dismissedBudgetMessagesProvider =
    StateNotifierProvider<DismissedBudgetMessagesNotifier, DismissedBudgetMessagesState>((ref) {
  return DismissedBudgetMessagesNotifier();
});
