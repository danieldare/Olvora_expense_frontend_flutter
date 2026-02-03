import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../expenses/presentation/providers/future_expenses_providers.dart';
import '../../../expenses/presentation/providers/recurring_expenses_providers.dart';

/// Summary of planned expenses (future + recurring)
class PlannedExpensesSummary {
  final int activeFutureExpenses;
  final int activeRecurringExpenses;

  int get total => activeFutureExpenses + activeRecurringExpenses;

  const PlannedExpensesSummary({
    required this.activeFutureExpenses,
    required this.activeRecurringExpenses,
  });
}

/// Provider that combines future and recurring expenses into a single summary.
///
/// This eliminates nested `.when()` calls in the UI by handling both
/// async providers in one place.
final plannedExpensesSummaryProvider = FutureProvider<PlannedExpensesSummary>((ref) async {
  // Watch user ID - only refetch when user actually changes
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return const PlannedExpensesSummary(
      activeFutureExpenses: 0,
      activeRecurringExpenses: 0,
    );
  }

  final futureExpenses = await ref.watch(futureExpensesProvider.future);
  final recurringExpenses = await ref.watch(recurringExpensesProvider.future);

  return PlannedExpensesSummary(
    activeFutureExpenses: futureExpenses.where((e) => !e.isConverted).length,
    activeRecurringExpenses: recurringExpenses.where((e) => e.isActive).length,
  );
});
