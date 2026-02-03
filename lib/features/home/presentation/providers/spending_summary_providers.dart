import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../budget/domain/entities/budget_entity.dart';
import '../../../expenses/presentation/providers/expenses_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../user_preferences/presentation/providers/user_preferences_providers.dart';

/// Utility function to get start and end dates for a budget period
/// [weekStartDay] is 0 for Sunday, 1 for Monday
/// Defaults to Sunday (0) to match WeekPreferencesService.defaultWeekStartDay
({DateTime startDate, DateTime endDate}) getPeriodDates(
  BudgetType type, {
  int weekStartDay = 0,
}) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  late DateTime startDate;
  late DateTime endDate;

  switch (type) {
    case BudgetType.daily:
      startDate = startOfDay;
      // End date should be end of today (23:59:59.999)
      endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      break;

    case BudgetType.weekly:
      // Week starts on Sunday (0) or Monday (1) based on user preference
      final dayOfWeek = now.weekday; // Monday = 1, Sunday = 7
      int daysToSubtract;
      if (weekStartDay == 0) {
        // Week starts on Sunday
        daysToSubtract = dayOfWeek == 7 ? 0 : dayOfWeek;
      } else {
        // Week starts on Monday (default)
        daysToSubtract = dayOfWeek == 7 ? 6 : dayOfWeek - 1;
      }
      startDate = startOfDay.subtract(Duration(days: daysToSubtract));
      // End date should be end of the last day of the week (23:59:59.999)
      final weekEndDay = startDate.add(const Duration(days: 6));
      endDate = DateTime(
        weekEndDay.year,
        weekEndDay.month,
        weekEndDay.day,
        23,
        59,
        59,
        999,
      );
      break;

    case BudgetType.monthly:
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
      break;

    case BudgetType.quarterly:
      // Quarters: Q1 (Jan-Mar), Q2 (Apr-Jun), Q3 (Jul-Sep), Q4 (Oct-Dec)
      final currentQuarter = (now.month - 1) ~/ 3;
      final quarterStartMonth = currentQuarter * 3;
      startDate = DateTime(now.year, quarterStartMonth + 1, 1);
      endDate = DateTime(now.year, quarterStartMonth + 4, 0, 23, 59, 59, 999);
      break;

    case BudgetType.semiAnnual:
      // First half: Jan-Jun, Second half: Jul-Dec
      final isFirstHalf = now.month < 7;
      final semiAnnualStartMonth = isFirstHalf ? 1 : 7;
      startDate = DateTime(now.year, semiAnnualStartMonth, 1);
      endDate = DateTime(
        now.year,
        semiAnnualStartMonth + 6,
        0,
        23,
        59,
        59,
        999,
      );
      break;

    case BudgetType.annual:
      startDate = DateTime(now.year, 1, 1);
      endDate = DateTime(now.year, 12, 31, 23, 59, 59, 999);
      break;
  }

  return (startDate: startDate, endDate: endDate);
}

/// Provider for calculating total spending for a given period
/// CRITICAL: Depends on auth state and expenses to ensure data is refreshed when expenses change
final periodSpendingProvider = FutureProvider.family<double, BudgetType>((
  ref,
  periodType,
) async {
  // Watch user ID - only refetch when user actually changes
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return 0.0;
  }

  // Await expenses directly instead of using .when() to prevent flickering
  // This ensures we wait for the actual data instead of showing loading states
  final allExpenses = await ref.watch(expensesProvider.future);

  // Get user's week start day preference for weekly periods from backend
  // Default to Sunday (0) if preference can't be loaded
  int weekStartDay = 0; // Default to Sunday
  if (periodType == BudgetType.weekly) {
    try {
      final preferences = await ref.read(userPreferencesProvider.future);
      weekStartDay = preferences.weekStartDay.toNumber();
    } catch (e) {
      // Use default (Sunday = 0) if preference can't be loaded
      weekStartDay = 0;
    }
  }

  final periodDates = getPeriodDates(periodType, weekStartDay: weekStartDay);

  // Filter expenses by date range and sum amounts
  double totalSpent = 0.0;

  // Normalize dates for comparison
  final startDateOnly = DateTime(
    periodDates.startDate.year,
    periodDates.startDate.month,
    periodDates.startDate.day,
  );
  final endDateOnly = DateTime(
    periodDates.endDate.year,
    periodDates.endDate.month,
    periodDates.endDate.day,
  );
  final startMs = startDateOnly.millisecondsSinceEpoch;
  final endMs = endDateOnly.millisecondsSinceEpoch;

  for (final expense in allExpenses) {
    final expenseDate = expense.date;
    // Normalize expense date to start of day for comparison
    final expenseDateOnly = DateTime(
      expenseDate.year,
      expenseDate.month,
      expenseDate.day,
    );

    // Check if expense date is within range (inclusive)
    // Compare using milliseconds since epoch for accurate comparison
    final expenseMs = expenseDateOnly.millisecondsSinceEpoch;

    if (expenseMs >= startMs && expenseMs <= endMs) {
      totalSpent += expense.amount;
    }
  }

  // Always return current-period spending only (no fallback to past periods).
  // This keeps the summary aligned with the period label and budget comparison.
  return totalSpent;
});
