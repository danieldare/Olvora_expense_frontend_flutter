import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/state/auth_state.dart';

/// Provider for fetching expenses for a specific trip
final tripExpensesProvider = FutureProvider.family<List<ExpenseEntity>, String>((ref, tripId) async {
  // Watch auth state - if user is not authenticated, return empty list immediately
  final authState = ref.watch(authNotifierProvider);

  if (authState is! AuthStateAuthenticated) {
    return [];
  }

  final apiService = ref.watch(apiServiceV2Provider);

  try {
    final response = await apiService.dio.get(
      '/expenses',
      queryParameters: {
        'tripId': tripId,
        'order': 'DESC', // Newest first
      },
    );

    // Handle TransformInterceptor response wrapper
    dynamic actualData = response.data;
    if (response.data is Map<String, dynamic>) {
      final responseMap = response.data as Map<String, dynamic>;
      if (responseMap.containsKey('data') && responseMap['data'] != null) {
        actualData = responseMap['data'];
      }
    }

    List<dynamic> expensesList;
    if (actualData is List) {
      expensesList = actualData;
    } else {
      expensesList = [];
    }

    // Parse expenses
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
});
