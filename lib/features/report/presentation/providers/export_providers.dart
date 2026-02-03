import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/state/auth_state.dart';

/// Provider for fetching expenses for export with date range
final exportExpensesProvider =
    FutureProvider.family<List<ExpenseEntity>, Map<String, DateTime>>(
  (ref, dateRange) async {
    final authState = ref.watch(authNotifierProvider);

    if (authState is! AuthStateAuthenticated) {
      return [];
    }

    final startDate = dateRange['start']!;
    final endDate = dateRange['end']!;

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

      return expenses;
    } catch (e) {
      return [];
    }
  },
);

/// Provider for fetching report summary data for export
final exportReportSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, DateTime>>(
  (ref, dateRange) async {
    final authState = ref.watch(authNotifierProvider);

    if (authState is! AuthStateAuthenticated) {
      return {
        'total': 0.0,
        'average': 0.0,
        'count': 0,
        'highest': 0.0,
        'lowest': 0.0,
      };
    }

    final startDate = dateRange['start']!;
    final endDate = dateRange['end']!;

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
        };
      }

      final amounts = expenses.map((e) => e.amount).toList();
      final total = amounts.fold(0.0, (sum, amount) => sum + amount);
      final average = total / expenses.length;
      final highest = amounts.reduce((a, b) => a > b ? a : b);
      final lowest = amounts.reduce((a, b) => a < b ? a : b);

      return {
        'total': total,
        'average': average,
        'count': expenses.length,
        'highest': highest,
        'lowest': lowest,
      };
    } catch (e) {
      return {
        'total': 0.0,
        'average': 0.0,
        'count': 0,
        'highest': 0.0,
        'lowest': 0.0,
      };
    }
  },
);

/// Provider for fetching category breakdown for export
final exportCategoryBreakdownProvider =
    FutureProvider.family<Map<ExpenseCategory, double>, Map<String, DateTime>>(
  (ref, dateRange) async {
    final authState = ref.watch(authNotifierProvider);

    if (authState is! AuthStateAuthenticated) {
      return <ExpenseCategory, double>{};
    }

    final startDate = dateRange['start']!;
    final endDate = dateRange['end']!;

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
  },
);
