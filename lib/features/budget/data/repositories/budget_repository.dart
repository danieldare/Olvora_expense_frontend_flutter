import 'package:dio/dio.dart';
import '../../../../core/services/api_service_v2.dart';
import '../../../../core/utils/auth_error_handler.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/entities/budget_suggestion_entity.dart';
import '../../domain/entities/spending_forecast_entity.dart';
import '../../domain/entities/budget_alert_entity.dart';
import '../../domain/entities/reallocation_suggestion_entity.dart';
import '../../domain/entities/budget_health_entity.dart';
import '../models/budget_model.dart';
import '../dto/create_budget_dto.dart';
import '../dto/update_budget_dto.dart';
import '../datasources/budget_optimization_remote_data_source.dart';

/// Repository interface for budget operations
abstract class BudgetRepository {
  /// Get all general budgets (daily, weekly, monthly)
  Future<List<BudgetEntity>> getGeneralBudgets();

  /// Get all category-specific budgets
  Future<List<BudgetEntity>> getCategoryBudgets();

  /// Create a new budget (general or category)
  Future<BudgetEntity> createBudget(CreateBudgetDto dto);

  /// Update an existing budget
  Future<BudgetEntity> updateBudget(String id, UpdateBudgetDto dto);

  /// Delete a budget
  /// [deleteAssociatedCategories] - If true, deletes all associated category budgets. If false, keeps them as independent.
  Future<void> deleteBudget(String id, {bool deleteAssociatedCategories = false});

  /// Get spending statistics for a period
  Future<Map<String, double>> getSpendingStatistics({
    DateTime? startDate,
    DateTime? endDate,
  });
}

/// Implementation of BudgetRepository
/// Uses ApiServiceV2 for automatic token management and refresh
class BudgetRepositoryImpl implements BudgetRepository {
  final ApiServiceV2 _apiService;

  BudgetRepositoryImpl(this._apiService);

  @override
  Future<List<BudgetEntity>> getGeneralBudgets() async {
    try {
      // ApiServiceV2 handles token management automatically
      // Try to fetch from dedicated budgets endpoint first
      try {
        final response = await _apiService.dio.get(
          '/budgets',
          queryParameters: {'category': 'general'},
        );

        // Backend uses TransformInterceptor which wraps response in { data: ..., statusCode: ... }
        dynamic actualData = response.data;
        if (response.data is Map && response.data['data'] != null) {
          actualData = response.data['data'];
        }

        if (actualData != null) {
          if (actualData is List) {
            final budgetsList = actualData;

            if (budgetsList.isEmpty) {
              return await _calculateGeneralBudgetsFromExpenses();
            }

            final budgets = budgetsList.map((json) {
              try {
                return BudgetModel.fromJson(
                  json as Map<String, dynamic>,
                ).toEntity();
              } catch (e) {
                rethrow;
              }
            }).toList();

            return budgets;
          } else {
            throw Exception(
              'Invalid response format: expected List, got ${actualData.runtimeType}',
            );
          }
        } else {
          return await _calculateGeneralBudgetsFromExpenses();
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          return await _calculateGeneralBudgetsFromExpenses();
        }

        // Handle 401 Unauthorized - use centralized auth error handler
        if (AuthErrorHandler.isAuthError(e)) {
          throw Exception(AuthErrorHandler.getAuthErrorMessage());
        }

        // For other errors, rethrow with better message
        final errorMessage =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            e.message ??
            'Unknown error';
        throw Exception('Failed to fetch general budgets: $errorMessage');
      }
    } catch (e) {
      if (e is! DioException) {
        // If it's not a DioException, it might be a parsing error
        throw Exception('Failed to fetch general budgets: ${e.toString()}');
      }
      rethrow;
    }
  }

  @override
  Future<List<BudgetEntity>> getCategoryBudgets() async {
    try {
      // ApiServiceV2 handles token management automatically
      // Try to fetch from dedicated budgets endpoint first
      try {
        final response = await _apiService.dio.get(
          '/budgets',
          queryParameters: {'category': 'category'},
        );

        // Backend uses TransformInterceptor which wraps response in { data: ..., statusCode: ... }
        dynamic actualData = response.data;
        if (response.data is Map && response.data['data'] != null) {
          actualData = response.data['data'];
        }

        if (actualData != null) {
          if (actualData is List) {
            final budgetsList = actualData;

            final budgets = budgetsList.map((json) {
              try {
                return BudgetModel.fromJson(
                  json as Map<String, dynamic>,
                ).toEntity();
              } catch (e) {
                rethrow;
              }
            }).toList();

            return budgets;
          } else {
            throw Exception(
              'Invalid response format: expected List, got ${actualData.runtimeType}',
            );
          }
        } else {
          return await _getCategoryBudgetsFromCategories();
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          return await _getCategoryBudgetsFromCategories();
        }

        // Handle 401 Unauthorized - use centralized auth error handler
        if (AuthErrorHandler.isAuthError(e)) {
          throw Exception(AuthErrorHandler.getAuthErrorMessage());
        }

        // For other errors, rethrow with better message
        final errorMessage =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            e.message ??
            'Unknown error';
        throw Exception('Failed to fetch category budgets: $errorMessage');
      }
    } catch (e) {
      if (e is! DioException) {
        // If it's not a DioException, it might be a parsing error
        throw Exception('Failed to fetch category budgets: ${e.toString()}');
      }
      rethrow;
    }
  }

  @override
  Future<BudgetEntity> createBudget(CreateBudgetDto dto) async {
    try {
      // Try dedicated budgets endpoint first
      try {
        final response = await _apiService.dio.post(
          '/budgets',
          data: dto.toJson(),
        );

        // Backend uses TransformInterceptor which wraps response in { data: ..., statusCode: ... }
        dynamic actualData = response.data;
        if (response.data is Map && response.data['data'] != null) {
          actualData = response.data['data'];
        }

        final budget = BudgetModel.fromJson(
          actualData as Map<String, dynamic>,
        ).toEntity();
        // Backend already calculates spent, so we can return directly
        return budget;
      } on DioException catch (e) {
        // If budgets endpoint doesn't exist, use fallback
        if (e.response?.statusCode == 404) {
          return await _createBudgetFallback(dto);
        }
        rethrow;
      }
    } catch (e) {
      if (e is DioException) {
        final message =
            e.response?.data?['message'] ?? e.message ?? 'Unknown error';
        throw Exception('Failed to create budget: $message');
      }
      rethrow;
    }
  }

  @override
  Future<BudgetEntity> updateBudget(String id, UpdateBudgetDto dto) async {
    try {
      // Try dedicated budgets endpoint first
      try {
        final response = await _apiService.dio.patch(
          '/budgets/$id',
          data: dto.toJson(),
        );

        // Backend uses TransformInterceptor which wraps response in { data: ..., statusCode: ... }
        dynamic actualData = response.data;
        if (response.data is Map && response.data['data'] != null) {
          actualData = response.data['data'];
        }

        final budget = BudgetModel.fromJson(
          actualData as Map<String, dynamic>,
        ).toEntity();
        // Backend already calculates spent, so we can return directly
        return budget;
      } on DioException catch (e) {
        // If budgets endpoint doesn't exist, use fallback
        if (e.response?.statusCode == 404) {
          return await _updateBudgetFallback(id, dto);
        }
        rethrow;
      }
    } catch (e) {
      if (e is DioException) {
        final message =
            e.response?.data?['message'] ?? e.message ?? 'Unknown error';
        throw Exception('Failed to update budget: $message');
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteBudget(String id, {bool deleteAssociatedCategories = false}) async {
    try {
      // Try dedicated budgets endpoint first
      try {
        await _apiService.dio.delete(
          '/budgets/$id',
          queryParameters: {
            if (deleteAssociatedCategories) 'deleteAssociatedCategories': true,
          },
        );
        return;
      } on DioException catch (e) {
        // If budgets endpoint doesn't exist, use fallback
        if (e.response?.statusCode == 404) {
          await _deleteBudgetFallback(id);
          return;
        }
        rethrow;
      }
    } catch (e) {
      if (e is DioException) {
        final message =
            e.response?.data?['message'] ?? e.message ?? 'Unknown error';
        throw Exception('Failed to delete budget: $message');
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, double>> getSpendingStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await _apiService.dio.get(
        '/expenses/statistics',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.data == null) return {};

      final stats = response.data as Map<String, dynamic>;
      return stats.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    } catch (e) {
      return {};
    }
  }

  // Private helper methods

  Future<List<BudgetEntity>> _calculateGeneralBudgetsFromExpenses() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      final dailySpent = await _getSpentForPeriod(startOfDay, now);
      final weeklySpent = await _getSpentForPeriod(startOfWeek, now);
      final monthlySpent = await _getSpentForPeriod(startOfMonth, now);

      return [
        BudgetEntity(
          id: 'general-daily',
          type: BudgetType.daily,
          category: BudgetCategory.general,
          amount: 0.0,
          spent: dailySpent,
          enabled: true,
          createdAt: now,
          updatedAt: now,
        ),
        BudgetEntity(
          id: 'general-weekly',
          type: BudgetType.weekly,
          category: BudgetCategory.general,
          amount: 0.0,
          spent: weeklySpent,
          enabled: true,
          createdAt: now,
          updatedAt: now,
        ),
        BudgetEntity(
          id: 'general-monthly',
          type: BudgetType.monthly,
          category: BudgetCategory.general,
          amount: 0.0,
          spent: monthlySpent,
          enabled: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  // Legacy method - no longer used since we have dedicated /budgets endpoint
  // Categories no longer have monthlyBudget field - budgets are in the budgets table
  Future<List<BudgetEntity>> _getCategoryBudgetsFromCategories() async {
    // This method is deprecated - budgets should come from /budgets endpoint
    return [];
  }

  Future<BudgetEntity> _createBudgetFallback(CreateBudgetDto dto) async {
    // Fallback method - budgets endpoint should always be available
    throw UnimplementedError(
      'Budget creation requires the /budgets endpoint. Please ensure the backend is properly configured.',
    );
  }

  Future<BudgetEntity> _updateBudgetFallback(
    String id,
    UpdateBudgetDto dto,
  ) async {
    // Fallback method - budgets endpoint should always be available
    throw UnimplementedError(
      'Budget update requires the /budgets endpoint. Please ensure the backend is properly configured.',
    );
  }

  Future<void> _deleteBudgetFallback(String id) async {
    // Fallback method - budgets endpoint should always be available
    throw UnimplementedError(
      'Budget deletion requires the /budgets endpoint. Please ensure the backend is properly configured.',
    );
  }

  Future<double> _getSpentForPeriod(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final expenses = await _getExpensesForPeriod(startDate, endDate);
      return expenses.fold<double>(
        0.0,
        (sum, expense) => sum + (expense['amount'] as num).toDouble(),
      );
    } catch (e) {
      return 0.0;
    }
  }

  Future<List<Map<String, dynamic>>> _getExpensesForPeriod(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _apiService.dio.get(
        '/expenses',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Note: Enrichment methods removed since backend now calculates spent amounts

  // Note: _getPeriodStartDate removed - no longer needed since backend calculates spent
}

/// Extended repository for budget optimization features
abstract class BudgetOptimizationRepository {
  // Suggestions
  Future<List<BudgetSuggestionEntity>> generateSuggestions();
  Future<List<BudgetSuggestionEntity>> getPendingSuggestions();
  Future<BudgetEntity> applySuggestion(String id, {BudgetType? budgetType});
  Future<void> dismissSuggestion(String id);

  // Forecasts
  Future<SpendingForecastEntity> getForecast(String budgetId);
  Future<List<SpendingForecastEntity>> getAllForecasts();

  // Alerts
  Future<List<BudgetAlertEntity>> generateAlerts();
  Future<List<BudgetAlertEntity>> getActiveAlerts();
  Future<void> dismissAlert(String id);

  // Reallocations
  Future<List<ReallocationSuggestionEntity>> generateReallocations();
  Future<List<ReallocationSuggestionEntity>> getPendingReallocations();
  Future<Map<String, BudgetEntity>> applyReallocation(String id);
  Future<void> dismissReallocation(String id);

  // Health Scores
  Future<BudgetHealthScoreEntity> getBudgetHealth(String budgetId);
  Future<List<BudgetHealthScoreEntity>> getAllBudgetHealth();
  Future<OverallHealthScoreEntity> getOverallHealth();
}

/// Implementation of BudgetOptimizationRepository
class BudgetOptimizationRepositoryImpl implements BudgetOptimizationRepository {
  final BudgetOptimizationRemoteDataSource _dataSource;

  BudgetOptimizationRepositoryImpl(this._dataSource);

  // Suggestions
  @override
  Future<List<BudgetSuggestionEntity>> generateSuggestions() async {
    final models = await _dataSource.generateSuggestions();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<BudgetSuggestionEntity>> getPendingSuggestions() async {
    final models = await _dataSource.getPendingSuggestions();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<BudgetEntity> applySuggestion(String id, {BudgetType? budgetType}) async {
    return await _dataSource.applySuggestion(id, budgetType: budgetType);
  }

  @override
  Future<void> dismissSuggestion(String id) async {
    await _dataSource.dismissSuggestion(id);
  }

  // Forecasts
  @override
  Future<SpendingForecastEntity> getForecast(String budgetId) async {
    final model = await _dataSource.getForecast(budgetId);
    return model.toEntity();
  }

  @override
  Future<List<SpendingForecastEntity>> getAllForecasts() async {
    final models = await _dataSource.getAllForecasts();
    return models.map((m) => m.toEntity()).toList();
  }

  // Alerts
  @override
  Future<List<BudgetAlertEntity>> generateAlerts() async {
    return await _dataSource.generateAlerts();
  }

  @override
  Future<List<BudgetAlertEntity>> getActiveAlerts() async {
    return await _dataSource.getActiveAlerts();
  }

  @override
  Future<void> dismissAlert(String id) async {
    await _dataSource.dismissAlert(id);
  }

  // Reallocations
  @override
  Future<List<ReallocationSuggestionEntity>> generateReallocations() async {
    return await _dataSource.generateReallocations();
  }

  @override
  Future<List<ReallocationSuggestionEntity>> getPendingReallocations() async {
    return await _dataSource.getPendingReallocations();
  }

  @override
  Future<Map<String, BudgetEntity>> applyReallocation(String id) async {
    return await _dataSource.applyReallocation(id);
  }

  @override
  Future<void> dismissReallocation(String id) async {
    await _dataSource.dismissReallocation(id);
  }

  // Health Scores
  @override
  Future<BudgetHealthScoreEntity> getBudgetHealth(String budgetId) async {
    return await _dataSource.getBudgetHealth(budgetId);
  }

  @override
  Future<List<BudgetHealthScoreEntity>> getAllBudgetHealth() async {
    return await _dataSource.getAllBudgetHealth();
  }

  @override
  Future<OverallHealthScoreEntity> getOverallHealth() async {
    return await _dataSource.getOverallHealth();
  }
}
