import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../user_preferences/presentation/providers/user_preferences_providers.dart';

/// Report time period enum
enum ReportPeriod { week, month, quarter, year, allTime }

/// Parameters for report date range calculation
class ReportDateRangeParams {
  final ReportPeriod period;
  final int periodOffset;

  const ReportDateRangeParams({
    required this.period,
    this.periodOffset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportDateRangeParams &&
          runtimeType == other.runtimeType &&
          period == other.period &&
          periodOffset == other.periodOffset;

  @override
  int get hashCode => period.hashCode ^ periodOffset.hashCode;
}

/// Provider that calculates date range for a report period
/// Handles week start day preference and period offset navigation
final reportDateRangeProvider =
    Provider.family<Map<String, DateTime>?, ReportDateRangeParams>(
  (ref, params) {
    final period = params.period;
    final periodOffset = params.periodOffset;
    final now = DateTime.now();

    // Get week start day preference (defaults to Sunday if not available)
    int weekStartDay = 0;
    try {
      final preferencesAsync = ref.read(userPreferencesProvider);
      weekStartDay = preferencesAsync.maybeWhen(
        data: (preferences) => preferences.weekStartDay.toNumber(),
        orElse: () => 0,
      );
    } catch (e) {
      weekStartDay = 0; // Default to Sunday
    }
    final weekStartsSunday = weekStartDay == 0;

    DateTime startDate;
    DateTime endDate;

    switch (period) {
      case ReportPeriod.week:
        final weekStartDayNum = weekStartsSunday ? 0 : 1;
        final dayOfWeek = now.weekday;

        if (weekStartDayNum == 0) {
          final daysFromSunday = dayOfWeek == 7 ? 0 : dayOfWeek;
          startDate = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: daysFromSunday));
        } else {
          final daysFromMonday = dayOfWeek == 7 ? 6 : (dayOfWeek - 1);
          startDate = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: daysFromMonday));
        }

        startDate = startDate.add(Duration(days: 7 * periodOffset));
        endDate = startDate.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );

        if (periodOffset == 0) {
          final today = DateTime(now.year, now.month, now.day, 23, 59, 59);
          if (today.isBefore(endDate)) endDate = today;
        }
        break;

      case ReportPeriod.month:
        var targetMonth = now.month + periodOffset;
        var targetYear = now.year;

        while (targetMonth < 1) {
          targetMonth += 12;
          targetYear--;
        }
        while (targetMonth > 12) {
          targetMonth -= 12;
          targetYear++;
        }

        startDate = DateTime(targetYear, targetMonth, 1);

        if (periodOffset == 0) {
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        } else {
          final nextMonth = targetMonth == 12 ? 1 : targetMonth + 1;
          final nextYear = targetMonth == 12 ? targetYear + 1 : targetYear;
          endDate = DateTime(nextYear, nextMonth, 1)
              .subtract(const Duration(seconds: 1));
        }
        break;

      case ReportPeriod.quarter:
        final currentQuarter = (now.month - 1) ~/ 3;
        var targetQuarter = currentQuarter + periodOffset;
        var targetYear = now.year;

        while (targetQuarter < 0) {
          targetQuarter += 4;
          targetYear--;
        }
        while (targetQuarter > 3) {
          targetQuarter -= 4;
          targetYear++;
        }

        final quarterStartMonth = targetQuarter * 3 + 1;
        startDate = DateTime(targetYear, quarterStartMonth, 1);

        if (periodOffset == 0) {
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        } else {
          final quarterEndMonth = quarterStartMonth + 2;
          final nextMonth = quarterEndMonth == 12 ? 1 : quarterEndMonth + 1;
          final nextYear = quarterEndMonth == 12 ? targetYear + 1 : targetYear;
          endDate = DateTime(nextYear, nextMonth, 1)
              .subtract(const Duration(seconds: 1));
        }
        break;

      case ReportPeriod.year:
        final targetYear = now.year + periodOffset;
        startDate = DateTime(targetYear, 1, 1);

        if (periodOffset == 0) {
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        } else {
          endDate = DateTime(targetYear, 12, 31, 23, 59, 59);
        }
        break;

      case ReportPeriod.allTime:
        return null;
    }

    return {'start': startDate, 'end': endDate};
  },
);

/// Provider for category breakdown data
/// CRITICAL: Depends on auth state to ensure data is cleared when user changes
final categoryBreakdownProvider =
    FutureProvider.family<Map<ExpenseCategory, double>, ReportDateRangeParams>(
  (ref, params) async {
    // Keep data alive to prevent disposal on navigation
    ref.keepAlive();

    // Watch user ID - only refetch when user actually changes
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) {
      return <ExpenseCategory, double>{};
    }

    // Get date range from the date range provider
    final dateRange = ref.read(reportDateRangeProvider(params));

    DateTime startDate;
    DateTime endDate;

    if (dateRange == null) {
      // All time - use a far back date
      startDate = DateTime(2000, 1, 1);
      endDate = DateTime.now();
    } else {
      startDate = dateRange['start']!;
      endDate = dateRange['end']!;
    }

    try {
      final apiService = ref.read(apiServiceV2Provider);
      final response = await apiService.dio.get(
        '/expenses',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );

        dynamic actualData = response.data;
        if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;
          if (responseMap.containsKey('data')) {
            actualData = responseMap['data'];
          }
        }

        List<dynamic> expensesList;
        if (actualData is List) {
          expensesList = actualData;
        } else {
          expensesList = [];
        }

        final categoryTotals = <ExpenseCategory, double>{};
        for (final category in ExpenseCategory.values) {
          categoryTotals[category] = 0.0;
        }

        for (final json in expensesList) {
          try {
            final expense = ExpenseEntity.fromJson(
              json as Map<String, dynamic>,
            );
            categoryTotals[expense.category] =
                (categoryTotals[expense.category] ?? 0.0) + expense.amount;
          } catch (e) {
            // Skip invalid expenses
          }
        }

        return categoryTotals;
      } catch (e) {
        return <ExpenseCategory, double>{};
      }
    });

/// Provider for spending overview statistics
/// CRITICAL: Depends on auth state to ensure data is cleared when user changes
final spendingOverviewProvider =
    FutureProvider.family<Map<String, dynamic>, ReportDateRangeParams>(
  (ref, params) async {
    // Keep data alive to prevent disposal on navigation
    ref.keepAlive();

    // Watch user ID - only refetch when user actually changes
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) {
      return {
        'total': 0.0,
        'average': 0.0,
        'count': 0,
        'highest': 0.0,
        'lowest': 0.0,
        'transactions': <ExpenseEntity>[],
      };
    }

    // Get date range from the date range provider
    final dateRange = ref.read(reportDateRangeProvider(params));

    DateTime startDate;
    DateTime endDate;

    if (dateRange == null) {
      // All time - use a far back date
      startDate = DateTime(2000, 1, 1);
      endDate = DateTime.now();
    } else {
      startDate = dateRange['start']!;
      endDate = dateRange['end']!;
    }

    try {
      final apiService = ref.read(apiServiceV2Provider);
      final response = await apiService.dio.get(
        '/expenses',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );

        dynamic actualData = response.data;
        if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;
          if (responseMap.containsKey('data')) {
            actualData = responseMap['data'];
          }
        }

        List<dynamic> expensesList;
        if (actualData is List) {
          expensesList = actualData;
        } else {
          expensesList = [];
        }

        final expenses = <ExpenseEntity>[];
        for (final json in expensesList) {
          try {
            expenses.add(ExpenseEntity.fromJson(json as Map<String, dynamic>));
          } catch (e) {
            // Skip invalid expenses
          }
        }

        if (expenses.isEmpty) {
          return {
            'total': 0.0,
            'average': 0.0,
            'count': 0,
            'highest': 0.0,
            'lowest': 0.0,
            'transactions': <ExpenseEntity>[],
          };
        }

        final total = expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
        final average = total / expenses.length;
        final amounts = expenses.map((e) => e.amount).toList()..sort();
        final highest = amounts.last;
        final lowest = amounts.first;

        // Get top 5 expenses
        final sortedExpenses = List<ExpenseEntity>.from(expenses)
          ..sort((a, b) => b.amount.compareTo(a.amount));
        final topExpenses = sortedExpenses.take(5).toList();

        return {
          'total': total,
          'average': average,
          'count': expenses.length,
          'highest': highest,
          'lowest': lowest,
          'transactions': topExpenses,
        };
      } catch (e) {
        return {
          'total': 0.0,
          'average': 0.0,
          'count': 0,
          'highest': 0.0,
          'lowest': 0.0,
          'transactions': <ExpenseEntity>[],
        };
      }
    });

/// Provider for monthly spending comparison
/// CRITICAL: Depends on auth state to ensure data is cleared when user changes
final monthlyComparisonProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  // Keep data alive to prevent disposal on navigation
  ref.keepAlive();

  // Watch user ID - only refetch when user actually changes
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return [];
  }

  final apiService = ref.watch(apiServiceV2Provider);
  final now = DateTime.now();

  try {
    // Get last 6 months - use parallel requests for better performance
    final monthFutures = <Future<Map<String, dynamic>>>[];

    for (int i = 5; i >= 0; i--) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = i == 0
          ? now
          : DateTime(now.year, now.month - i + 1, 0, 23, 59, 59);

      final future = apiService.dio
          .get(
            '/expenses',
            queryParameters: {
              'startDate': monthStart.toIso8601String(),
              'endDate': (i == 0 ? now : monthEnd).toIso8601String(),
            },
          )
          .then((response) {
            dynamic actualData = response.data;
            if (response.data is Map<String, dynamic>) {
              final responseMap = response.data as Map<String, dynamic>;
              if (responseMap.containsKey('data')) {
                actualData = responseMap['data'];
              }
            }

            List<dynamic> expensesList;
            if (actualData is List) {
              expensesList = actualData;
            } else {
              expensesList = [];
            }

            double total = 0.0;
            for (final json in expensesList) {
              try {
                final expense = ExpenseEntity.fromJson(
                  json as Map<String, dynamic>,
                );
                total += expense.amount;
              } catch (e) {
                // Skip invalid expenses
              }
            }

            return {
              'month': monthStart,
              'total': total,
              'label': '${_getMonthName(monthStart.month)} ${monthStart.year}',
            };
          })
          .catchError((e) {
            // Return zero total for failed requests
            return {
              'month': monthStart,
              'total': 0.0,
              'label': '${_getMonthName(monthStart.month)} ${monthStart.year}',
            };
          });

      monthFutures.add(future);
    }

    // Wait for all requests in parallel
    final months = await Future.wait(monthFutures);
    return months;
  } catch (e) {
    return [];
  }
});

String _getMonthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}
