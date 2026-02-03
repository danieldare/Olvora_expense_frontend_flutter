import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../domain/entities/recurring_expense_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Provider for fetching all recurring expenses
/// CRITICAL: Depends on auth state to ensure data is cleared when user changes
final recurringExpensesProvider =
    FutureProvider<List<RecurringExpenseEntity>>((ref) async {
  // Keep data alive to prevent disposal on widget unmount
  ref.keepAlive();

  // Watch user ID - only refetch when user actually changes
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return [];
  }

  final apiService = ref.watch(apiServiceV2Provider);

  try {
    final response = await apiService.dio.get('/recurring-expenses');

    // Handle TransformInterceptor response wrapper
    dynamic actualData = response.data;
    if (response.data is Map<String, dynamic>) {
      final responseMap = response.data as Map<String, dynamic>;
      if (responseMap.containsKey('data') && responseMap['data'] != null) {
        actualData = responseMap['data'];
      }
    }

    List<dynamic> recurringList;
    if (actualData is List) {
      recurringList = actualData;
    } else {
      recurringList = [];
    }

    return recurringList
        .map((json) =>
            RecurringExpenseEntity.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});

/// Provider for fetching next occurrences of a recurring expense
final nextOccurrencesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, id) async {
  final apiService = ref.watch(apiServiceV2Provider);

  try {
    final response = await apiService.dio.get(
      '/recurring-expenses/$id/next-occurrences',
      queryParameters: {'count': 6},
    );

    dynamic actualData = response.data;
    if (response.data is Map<String, dynamic>) {
      final responseMap = response.data as Map<String, dynamic>;
      if (responseMap.containsKey('data') && responseMap['data'] != null) {
        actualData = responseMap['data'];
      }
    }

    if (actualData is List) {
      return actualData
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }

    return [];
  } catch (e) {
    return [];
  }
});

