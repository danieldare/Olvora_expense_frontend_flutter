import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../user_preferences/presentation/providers/user_preferences_providers.dart';

/// Provider for spending trends data
/// Fetches expenses for a given time period and groups them by date
/// CRITICAL: Depends on auth state to ensure data is cleared when user changes
final spendingTrendsProvider = FutureProvider.family<List<Map<String, dynamic>>, TimePeriod>((
  ref,
  period,
) async {
  // Keep data alive to prevent disposal on widget unmount
  ref.keepAlive();

  // Watch user ID - only refetch when user actually changes
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return [];
  }

  final apiService = ref.watch(apiServiceV2Provider);

  // Get user's week start day preference from backend (needed for week period calculations)
  int weekStartDay = 0; // Default to Sunday
  try {
    final preferences = await ref.read(userPreferencesProvider.future);
    weekStartDay = preferences.weekStartDay.toNumber();
  } catch (e) {
    // Use default if preference can't be loaded
    weekStartDay = 0;
  }

  // Calculate date range based on period
  final now = DateTime.now();
  DateTime startDate;
  DateTime endDate = now;

  switch (period) {
    case TimePeriod.day:
      // Last 7 days
      startDate = now.subtract(const Duration(days: 6));
      break;
    case TimePeriod.week:
      // Last 4 weeks
      startDate = now.subtract(const Duration(days: 27));
      break;
    case TimePeriod.month:
      // Last 6 months
      startDate = DateTime(now.year, now.month - 6, now.day);
      break;
  }

  try {
    // Fetch expenses from API
    final response = await apiService.dio.get(
      '/expenses',
      queryParameters: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'order': 'ASC', // Oldest first for proper grouping
      },
    );

    // Handle TransformInterceptor response wrapper
    // The backend wraps ALL responses in { data: ..., statusCode: ... }
    dynamic actualData = response.data;

    if (kDebugMode) {
      print('Spending trends: Response type: ${response.data.runtimeType}');
    }

    // Check if response is wrapped by TransformInterceptor
    if (response.data is Map<String, dynamic>) {
      final responseMap = response.data as Map<String, dynamic>;
      if (kDebugMode) {
        print('Spending trends: Response map keys: ${responseMap.keys.toList()}');
      }

      if (responseMap.containsKey('data')) {
        actualData = responseMap['data'];
        if (kDebugMode) {
          print('Spending trends: Unwrapped data type: ${actualData.runtimeType}');
        }
      } else {
        // If no 'data' key, maybe the response itself is the data
        if (kDebugMode) {
          print('Spending trends: No data key found, using response.data directly');
        }
      }
    }

    List<dynamic> expensesList;
    if (actualData is List) {
      expensesList = actualData;
      if (kDebugMode) {
        print('Spending trends: Found list with ${expensesList.length} items');
      }
    } else {
      // Log for debugging
      if (kDebugMode) {
        print('Spending trends: Unexpected response format. Type: ${actualData.runtimeType}');
        print('Spending trends: Response data: $actualData');
      }
      expensesList = [];
    }

    // Generate all periods even if no expenses
    final List<DateTime> allPeriods = [];

    switch (period) {
      case TimePeriod.day:
        // Generate all 7 days (last 7 days including today)
        for (int i = 0; i < 7; i++) {
          final date = now.subtract(Duration(days: 6 - i));
          allPeriods.add(DateTime(date.year, date.month, date.day));
        }
        break;
      case TimePeriod.week:
        // Generate all 4 weeks (last 4 weeks, starting from user's week start day)
        // Calculate current week start based on user preference
        final currentWeekday = now.weekday; // Monday = 1, Sunday = 7
        int daysToSubtract;
        if (weekStartDay == 0) {
          // Week starts on Sunday
          daysToSubtract = currentWeekday == 7 ? 0 : currentWeekday;
        } else {
          // Week starts on Monday
          daysToSubtract = currentWeekday == 7 ? 6 : currentWeekday - 1;
        }
        final currentWeekStart = now.subtract(Duration(days: daysToSubtract));
        final normalizedWeekStart = DateTime(
          currentWeekStart.year,
          currentWeekStart.month,
          currentWeekStart.day,
        );

        final weekList = <DateTime>[];
        for (int i = 0; i < 4; i++) {
          final weekStart = normalizedWeekStart.subtract(Duration(days: i * 7));
          weekList.add(
            DateTime(weekStart.year, weekStart.month, weekStart.day),
          );
        }
        // Reverse to show oldest to newest
        allPeriods.addAll(weekList.reversed);
        break;
      case TimePeriod.month:
        // Generate all 6 months (last 6 months including current month)
        for (int i = 5; i >= 0; i--) {
          final monthDate = DateTime(now.year, now.month - i, 1);
          allPeriods.add(monthDate);
        }
        break;
    }

    if (expensesList.isEmpty) {
      if (kDebugMode) {
        print('Spending trends: No expenses found for period ${period.name}');
      }
      // Return all periods with zero amounts
      return allPeriods
          .map((periodDate) => {'date': periodDate, 'amount': 0.0})
          .toList();
    }

    if (kDebugMode) {
      print('Spending trends: Found ${expensesList.length} expenses');
    }

    // Parse expenses
    final expenses = <ExpenseEntity>[];
    for (final json in expensesList) {
      try {
        expenses.add(ExpenseEntity.fromJson(json as Map<String, dynamic>));
      } catch (e) {
        if (kDebugMode) {
          print('Spending trends: Error parsing expense: $e');
          print('Spending trends: Expense JSON: $json');
        }
      }
    }

    if (expenses.isEmpty) {
      if (kDebugMode) {
        print('Spending trends: No valid expenses after parsing');
      }
      // Return all periods with zero amounts
      return allPeriods
          .map((periodDate) => {'date': periodDate, 'amount': 0.0})
          .toList();
    }

    // Group expenses by date and sum amounts based on period
    final Map<DateTime, double> groupedData = {};

    // Initialize all periods with zero
    for (final periodDate in allPeriods) {
      groupedData[periodDate] = 0.0;
    }

    // Fill in actual expense data
    for (final expense in expenses) {
      DateTime dateKey;

      switch (period) {
        case TimePeriod.day:
          // Group by day
          dateKey = DateTime(
            expense.date.year,
            expense.date.month,
            expense.date.day,
          );
          break;
        case TimePeriod.week:
          // Group by week (start of week based on user preference)
          final expenseWeekday = expense.date.weekday; // Monday = 1, Sunday = 7
          int daysToSubtract;
          if (weekStartDay == 0) {
            // Week starts on Sunday
            daysToSubtract = expenseWeekday == 7 ? 0 : expenseWeekday;
          } else {
            // Week starts on Monday
            daysToSubtract = expenseWeekday == 7 ? 6 : expenseWeekday - 1;
          }
          dateKey = DateTime(
            expense.date.year,
            expense.date.month,
            expense.date.day,
          ).subtract(Duration(days: daysToSubtract));
          // Normalize to start of day
          dateKey = DateTime(dateKey.year, dateKey.month, dateKey.day);
          break;
        case TimePeriod.month:
          // Group by month
          dateKey = DateTime(expense.date.year, expense.date.month, 1);
          break;
      }

      // Add to grouped data (will be 0 if not in our range, but we still want to track it)
      if (groupedData.containsKey(dateKey)) {
        groupedData[dateKey] = (groupedData[dateKey] ?? 0) + expense.amount;
      }
    }

    // Convert to list format expected by chart, maintaining order
    final chartData = allPeriods
        .map(
          (periodDate) => {
            'date': periodDate,
            'amount': groupedData[periodDate] ?? 0.0,
          },
        )
        .toList();

    if (kDebugMode) {
      print('Spending trends: Generated ${chartData.length} chart data points');
    }
    return chartData;
  } catch (e, stackTrace) {
    // Log error for debugging
    if (kDebugMode) {
      print('Spending trends: Error fetching trends: $e');
      print('Spending trends: Stack trace: $stackTrace');
    }
    return [];
  }
});

enum TimePeriod { day, week, month }
