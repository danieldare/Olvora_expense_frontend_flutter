import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/state/auth_state.dart';

/// Provider to check if user has expenses for today
/// CRITICAL: Depends on auth state to ensure data is cleared when user changes
final hasExpensesTodayProvider = FutureProvider<bool>((ref) async {
  // Watch auth state - if user is not authenticated, return false immediately
  final authState = ref.watch(authNotifierProvider);
  
  if (authState is! AuthStateAuthenticated) {
    return false;
  }

  final apiService = ref.watch(apiServiceV2Provider);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  try {
    final response = await apiService.dio.get(
      '/expenses',
      queryParameters: {
        'startDate': todayStart.toIso8601String(),
        'endDate': todayEnd.toIso8601String(),
        'order': 'DESC',
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

    // Check if there are any expenses for today
    return expensesList.isNotEmpty;
  } catch (e) {
    // If error, assume no expenses (safer for reminder logic)
    return false;
  }
});

