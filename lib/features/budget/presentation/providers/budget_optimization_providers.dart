import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../data/datasources/budget_optimization_remote_data_source.dart';
import '../../data/repositories/budget_repository.dart';
import '../../domain/entities/budget_suggestion_entity.dart';
import '../../domain/entities/spending_forecast_entity.dart';
import '../../domain/entities/budget_alert_entity.dart';
import '../../domain/entities/reallocation_suggestion_entity.dart';
import '../../domain/entities/budget_health_entity.dart';
import '../../domain/entities/budget_entity.dart';

// ==================== Data Source Provider ====================

final budgetOptimizationDataSourceProvider = Provider<BudgetOptimizationRemoteDataSource>((ref) {
  final apiService = ref.watch(apiServiceV2Provider);
  return BudgetOptimizationRemoteDataSource(apiService);
});

// ==================== Repository Provider ====================

final budgetOptimizationRepositoryProvider = Provider<BudgetOptimizationRepository>((ref) {
  final dataSource = ref.watch(budgetOptimizationDataSourceProvider);
  return BudgetOptimizationRepositoryImpl(dataSource);
});

// ==================== Suggestions Providers ====================

final budgetSuggestionsProvider = FutureProvider<List<BudgetSuggestionEntity>>((ref) async {
  final repository = ref.watch(budgetOptimizationRepositoryProvider);
  try {
    return await repository.getPendingSuggestions();
  } catch (e, st) {
    // Avoid surfacing raw errors; show empty state so user can retry or generate
    debugPrint('Budget suggestions failed: $e\n$st');
    return [];
  }
});

final generateSuggestionsProvider = FutureProvider.family<List<BudgetSuggestionEntity>, void>((ref, _) async {
  final repository = ref.watch(budgetOptimizationRepositoryProvider);
  return repository.generateSuggestions();
});

// ==================== Forecasts Providers ====================

final budgetForecastProvider = FutureProvider.family<SpendingForecastEntity?, String>((ref, budgetId) async {
  final repository = ref.watch(budgetOptimizationRepositoryProvider);
  try {
    return await repository.getForecast(budgetId);
  } catch (e) {
    return null;
  }
});

final allForecastsProvider = FutureProvider<List<SpendingForecastEntity>>((ref) async {
  final repository = ref.watch(budgetOptimizationRepositoryProvider);
  return repository.getAllForecasts();
});

// ==================== Alerts Providers ====================

final budgetAlertsProvider = FutureProvider<List<BudgetAlertEntity>>((ref) async {
  final repository = ref.watch(budgetOptimizationRepositoryProvider);
  return repository.getActiveAlerts();
});

final generateAlertsProvider = FutureProvider.family<List<BudgetAlertEntity>, void>((ref, _) async {
  final repository = ref.watch(budgetOptimizationRepositoryProvider);
  return repository.generateAlerts();
});

// ==================== Reallocations Providers ====================

final reallocationSuggestionsProvider = FutureProvider<List<ReallocationSuggestionEntity>>((ref) async {
  final repository = ref.watch(budgetOptimizationRepositoryProvider);
  return repository.getPendingReallocations();
});

final generateReallocationsProvider = FutureProvider.family<List<ReallocationSuggestionEntity>, void>((ref, _) async {
  final repository = ref.watch(budgetOptimizationRepositoryProvider);
  return repository.generateReallocations();
});

// ==================== Health Score Providers ====================

final budgetHealthProvider = FutureProvider.family<BudgetHealthScoreEntity?, String>((ref, budgetId) async {
  final repository = ref.watch(budgetOptimizationRepositoryProvider);
  try {
    return await repository.getBudgetHealth(budgetId);
  } catch (e) {
    return null;
  }
});

final allBudgetHealthProvider = FutureProvider<List<BudgetHealthScoreEntity>>((ref) async {
  final repository = ref.watch(budgetOptimizationRepositoryProvider);
  return repository.getAllBudgetHealth();
});

final overallHealthProvider = FutureProvider<OverallHealthScoreEntity>((ref) async {
  final repository = ref.watch(budgetOptimizationRepositoryProvider);
  return repository.getOverallHealth();
});

// ==================== Action Providers ====================

final applySuggestionProvider = FutureProvider.family<BudgetEntity, Map<String, dynamic>>((ref, params) async {
  final repository = ref.watch(budgetOptimizationRepositoryProvider);
  final id = params['id'] as String;
  final budgetTypeParam = params['budgetType'];
  final budgetType = budgetTypeParam != null 
      ? _parseBudgetType(budgetTypeParam) 
      : null;
  return repository.applySuggestion(id, budgetType: budgetType);
});

BudgetType? _parseBudgetType(dynamic type) {
  if (type is BudgetType) return type;
  if (type is String) {
    switch (type.toLowerCase()) {
      case 'daily':
        return BudgetType.daily;
      case 'weekly':
        return BudgetType.weekly;
      case 'monthly':
        return BudgetType.monthly;
      case 'quarterly':
        return BudgetType.quarterly;
      case 'semi_annual':
        return BudgetType.semiAnnual;
      case 'annual':
        return BudgetType.annual;
      default:
        return null;
    }
  }
  return null;
}

final dismissSuggestionProvider = FutureProvider.family<void, String>((ref, id) async {
  final repository = ref.watch(budgetOptimizationRepositoryProvider);
  await repository.dismissSuggestion(id);
});

final dismissAlertProvider = FutureProvider.family<void, String>((ref, id) async {
  final repository = ref.watch(budgetOptimizationRepositoryProvider);
  await repository.dismissAlert(id);
});

final applyReallocationProvider = FutureProvider.family<Map<String, BudgetEntity>, String>((ref, id) async {
  final repository = ref.watch(budgetOptimizationRepositoryProvider);
  return repository.applyReallocation(id);
});

final dismissReallocationProvider = FutureProvider.family<void, String>((ref, id) async {
  final repository = ref.watch(budgetOptimizationRepositoryProvider);
  await repository.dismissReallocation(id);
});
