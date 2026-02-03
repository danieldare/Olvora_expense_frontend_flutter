import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../domain/entities/expense_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../../core/utils/auth_error_handler.dart';

/// Provider for fetching all expenses
/// CRITICAL: Depends on auth state to ensure data is cleared when user changes
final expensesProvider = FutureProvider<List<ExpenseEntity>>((ref) async {
  // Keep data alive to prevent disposal on widget unmount
  ref.keepAlive();

  // Watch user ID - only refetch when user actually changes, not on every auth state update
  // This prevents flickering caused by token refreshes or minor auth state changes
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return [];
  }

  final apiService = ref.watch(apiServiceV2Provider);

  try {
    final response = await apiService.dio.get(
      '/expenses',
      queryParameters: {
        'order': 'DESC', // Newest first
      },
    );

    debugPrint('ExpensesProvider: Raw response status: ${response.statusCode}');
    debugPrint(
      'ExpensesProvider: Raw response data type: ${response.data.runtimeType}',
    );
    debugPrint('ExpensesProvider: Raw response data: ${response.data}');

    // Handle TransformInterceptor response wrapper
    dynamic actualData = response.data;
    if (response.data is Map<String, dynamic>) {
      final responseMap = response.data as Map<String, dynamic>;
      debugPrint(
        'ExpensesProvider: Response is Map, keys: ${responseMap.keys.toList()}',
      );
      if (responseMap.containsKey('data') && responseMap['data'] != null) {
        actualData = responseMap['data'];
        debugPrint(
          'ExpensesProvider: Extracted data from wrapper, type: ${actualData.runtimeType}',
        );
      } else {
        debugPrint('ExpensesProvider: No data key found in response map');
      }
    }

    List<dynamic> expensesList;
    if (actualData is List) {
      expensesList = actualData;
      debugPrint(
        'ExpensesProvider: Expenses list length: ${expensesList.length}',
      );
    } else {
      debugPrint(
        'ExpensesProvider: actualData is not a List, type: ${actualData.runtimeType}',
      );
      expensesList = [];
    }

    // Parse expenses
    final expenses = <ExpenseEntity>[];
    for (final json in expensesList) {
      try {
        expenses.add(ExpenseEntity.fromJson(json as Map<String, dynamic>));
      } catch (e) {
        debugPrint('ExpensesProvider: Error parsing expense: $e');
        debugPrint('ExpensesProvider: Expense JSON: $json');
        // Skip invalid expenses
      }
    }

    debugPrint(
      'ExpensesProvider: Successfully loaded ${expenses.length} expenses',
    );
    return expenses;
  } catch (e, stackTrace) {
    debugPrint('ExpensesProvider: Error fetching expenses: $e');
    debugPrint('ExpensesProvider: Stack trace: $stackTrace');

    // Handle authentication errors centrally
    if (AuthErrorHandler.isAuthError(e)) {
      // CRITICAL FIX: Do NOT invalidate authNotifierProvider - it resets state to Initial
      // causing navigation loops. Instead, call logout() which properly transitions to Unauthenticated.
      // Only logout if we're currently authenticated (don't logout if already unauthenticated)
      final currentAuthState = ref.read(authNotifierProvider);
      if (currentAuthState is AuthStateAuthenticated) {
        Future.microtask(() {
          ref.read(authNotifierProvider.notifier).logout();
        });
      }

      return AuthErrorHandler.handleAuthError<List<ExpenseEntity>>(
        e,
        stackTrace,
        tag: 'ExpensesProvider',
      );
    }

    // For other errors, re-throw to show error state in UI
    throw Exception(
      'Failed to load expenses: ${AuthErrorHandler.extractErrorMessage(e)}',
    );
  }
});

/// Provider for fetching only the last 5 recent transactions
/// CRITICAL: Depends on auth state to ensure data is cleared when user changes
final recentTransactionsProvider = FutureProvider<List<ExpenseEntity>>((
  ref,
) async {
  // Keep data alive to prevent disposal on widget unmount
  ref.keepAlive();

  // Watch user ID - only refetch when user actually changes
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return [];
  }

  final apiService = ref.watch(apiServiceV2Provider);

  try {
    final response = await apiService.dio.get(
      '/expenses',
      queryParameters: {
        'limit': 5, // Only fetch 5 transactions
        'order': 'DESC', // Newest first
      },
    );

    debugPrint(
      'RecentTransactionsProvider: Raw response status: ${response.statusCode}',
    );
    debugPrint(
      'RecentTransactionsProvider: Raw response data type: ${response.data.runtimeType}',
    );

    // Handle TransformInterceptor response wrapper
    dynamic actualData = response.data;
    if (response.data is Map<String, dynamic>) {
      final responseMap = response.data as Map<String, dynamic>;
      debugPrint(
        'RecentTransactionsProvider: Response is Map, keys: ${responseMap.keys.toList()}',
      );
      if (responseMap.containsKey('data') && responseMap['data'] != null) {
        actualData = responseMap['data'];
        debugPrint(
          'RecentTransactionsProvider: Extracted data from wrapper, type: ${actualData.runtimeType}',
        );
      }
    }

    List<dynamic> expensesList;
    if (actualData is List) {
      expensesList = actualData;
      debugPrint(
        'RecentTransactionsProvider: Expenses list length: ${expensesList.length}',
      );
    } else {
      expensesList = [];
    }

    // Parse expenses
    final expenses = <ExpenseEntity>[];
    for (final json in expensesList) {
      try {
        expenses.add(ExpenseEntity.fromJson(json as Map<String, dynamic>));
      } catch (e) {
        debugPrint('RecentTransactionsProvider: Error parsing expense: $e');
        // Skip invalid expenses
      }
    }

    debugPrint(
      'RecentTransactionsProvider: Successfully loaded ${expenses.length} expenses',
    );
    return expenses;
  } catch (e) {
    return [];
  }
});
