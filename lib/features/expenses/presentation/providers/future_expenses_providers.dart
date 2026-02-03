import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../domain/entities/future_expense_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Provider for fetching all future expenses
/// CRITICAL: Depends on auth state to ensure data is cleared when user changes
final futureExpensesProvider =
    FutureProvider<List<FutureExpenseEntity>>((ref) async {
  // Keep data alive to prevent disposal on widget unmount
  ref.keepAlive();

  // Watch user ID - only refetch when user actually changes
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return [];
  }

  final apiService = ref.watch(apiServiceV2Provider);

  try {
    final response = await apiService.dio.get('/future-expenses');

    // Handle TransformInterceptor response wrapper
    dynamic actualData = response.data;
    if (response.data is Map<String, dynamic>) {
      final responseMap = response.data as Map<String, dynamic>;
      if (responseMap.containsKey('data') && responseMap['data'] != null) {
        actualData = responseMap['data'];
      }
    }

    List<dynamic> futureList;
    if (actualData is List) {
      futureList = actualData;
    } else {
      futureList = [];
    }

    return futureList
        .map((json) =>
            FutureExpenseEntity.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});

