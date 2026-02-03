import 'package:dio/dio.dart';
import '../../../../core/services/api_service_v2.dart';
import '../../../../core/utils/auth_error_handler.dart';
import '../models/budget_suggestion_model.dart';
import '../models/spending_forecast_model.dart';
import '../../domain/entities/budget_alert_entity.dart';
import '../../domain/entities/reallocation_suggestion_entity.dart';
import '../../domain/entities/budget_health_entity.dart';
import '../../domain/entities/budget_entity.dart';
import '../models/budget_model.dart';

/// Remote data source for budget optimization features
class BudgetOptimizationRemoteDataSource {
  final ApiServiceV2 _apiService;

  BudgetOptimizationRemoteDataSource(this._apiService);

  // ==================== Suggestions ====================

  /// Generate budget suggestions
  Future<List<BudgetSuggestionModel>> generateSuggestions() async {
    try {
      final response = await _apiService.dio.post('/budgets/suggestions/generate');
      
      dynamic data = response.data;
      if (data is Map && data['data'] != null) {
        data = data['data'];
      }

      if (data is List) {
        return data
            .map((json) => BudgetSuggestionModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to generate suggestions: ${e.message}');
    }
  }

  /// Get pending suggestions
  Future<List<BudgetSuggestionModel>> getPendingSuggestions() async {
    try {
      final response = await _apiService.dio.get('/budgets/suggestions');
      
      dynamic data = response.data;
      if (data is Map && data['data'] != null) {
        data = data['data'];
      }

      if (data is List) {
        return data
            .map((json) => BudgetSuggestionModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to get suggestions: ${e.message}');
    }
  }

  /// Apply a suggestion
  Future<BudgetEntity> applySuggestion(String id, {BudgetType? budgetType}) async {
    try {
      final response = await _apiService.dio.post(
        '/budgets/suggestions/$id/apply',
        data: budgetType != null ? {'budgetType': _budgetTypeToString(budgetType)} : null,
      );
      
      dynamic data = response.data;
      if (data is Map && data['data'] != null) {
        data = data['data'];
      }

      final budgetModel = BudgetModel.fromJson(data as Map<String, dynamic>);
      return budgetModel.toEntity();
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to apply suggestion: ${e.message}');
    }
  }

  /// Dismiss a suggestion
  Future<void> dismissSuggestion(String id) async {
    try {
      await _apiService.dio.post('/budgets/suggestions/$id/dismiss');
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to dismiss suggestion: ${e.message}');
    }
  }

  // ==================== Forecasts ====================

  /// Get forecast for a budget
  Future<SpendingForecastModel> getForecast(String budgetId) async {
    try {
      final response = await _apiService.dio.get('/budgets/$budgetId/forecast');
      
      dynamic data = response.data;
      if (data is Map && data['data'] != null) {
        data = data['data'];
      }

      return SpendingForecastModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to get forecast: ${e.message}');
    }
  }

  /// Get forecasts for all budgets
  Future<List<SpendingForecastModel>> getAllForecasts() async {
    try {
      final response = await _apiService.dio.get('/budgets/forecasts/all');
      
      dynamic data = response.data;
      if (data is Map && data['data'] != null) {
        data = data['data'];
      }

      if (data is List) {
        return data
            .map((json) => SpendingForecastModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to get forecasts: ${e.message}');
    }
  }

  // ==================== Alerts ====================

  /// Generate alerts
  Future<List<BudgetAlertEntity>> generateAlerts() async {
    try {
      final response = await _apiService.dio.post('/budgets/alerts/generate');
      
      dynamic data = response.data;
      if (data is Map && data['data'] != null) {
        data = data['data'];
      }

      if (data is List) {
        return data.map((json) => _parseAlert(json as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to generate alerts: ${e.message}');
    }
  }

  /// Get active alerts
  Future<List<BudgetAlertEntity>> getActiveAlerts() async {
    try {
      final response = await _apiService.dio.get('/budgets/alerts');
      
      dynamic data = response.data;
      if (data is Map && data['data'] != null) {
        data = data['data'];
      }

      if (data is List) {
        return data.map((json) => _parseAlert(json as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to get alerts: ${e.message}');
    }
  }

  /// Dismiss an alert
  Future<void> dismissAlert(String id) async {
    try {
      await _apiService.dio.post('/budgets/alerts/$id/dismiss');
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to dismiss alert: ${e.message}');
    }
  }

  // ==================== Reallocations ====================

  /// Generate reallocation suggestions
  Future<List<ReallocationSuggestionEntity>> generateReallocations() async {
    try {
      final response = await _apiService.dio.post('/budgets/reallocations/generate');
      
      dynamic data = response.data;
      if (data is Map && data['data'] != null) {
        data = data['data'];
      }

      if (data is List) {
        return data
            .map((json) => _parseReallocation(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to generate reallocations: ${e.message}');
    }
  }

  /// Get pending reallocation suggestions
  Future<List<ReallocationSuggestionEntity>> getPendingReallocations() async {
    try {
      final response = await _apiService.dio.get('/budgets/reallocations/suggestions');
      
      dynamic data = response.data;
      if (data is Map && data['data'] != null) {
        data = data['data'];
      }

      if (data is List) {
        return data
            .map((json) => _parseReallocation(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to get reallocations: ${e.message}');
    }
  }

  /// Apply a reallocation
  Future<Map<String, BudgetEntity>> applyReallocation(String id) async {
    try {
      final response = await _apiService.dio.post('/budgets/reallocations/$id/apply');
      
      dynamic data = response.data;
      if (data is Map && data['data'] != null) {
        data = data['data'];
      }

      final fromBudget = BudgetModel.fromJson(data['fromBudget'] as Map<String, dynamic>);
      final toBudget = BudgetModel.fromJson(data['toBudget'] as Map<String, dynamic>);

      return {
        'from': fromBudget.toEntity(),
        'to': toBudget.toEntity(),
      };
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to apply reallocation: ${e.message}');
    }
  }

  /// Dismiss a reallocation
  Future<void> dismissReallocation(String id) async {
    try {
      await _apiService.dio.post('/budgets/reallocations/$id/dismiss');
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to dismiss reallocation: ${e.message}');
    }
  }

  // ==================== Health Scores ====================

  /// Get health score for a budget
  Future<BudgetHealthScoreEntity> getBudgetHealth(String budgetId) async {
    try {
      final response = await _apiService.dio.get('/budgets/$budgetId/health');
      
      dynamic data = response.data;
      if (data is Map && data['data'] != null) {
        data = data['data'];
      }

      return _parseBudgetHealth(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to get budget health: ${e.message}');
    }
  }

  /// Get health scores for all budgets
  Future<List<BudgetHealthScoreEntity>> getAllBudgetHealth() async {
    try {
      final response = await _apiService.dio.get('/budgets/health/all');
      
      dynamic data = response.data;
      if (data is Map && data['data'] != null) {
        data = data['data'];
      }

      if (data is List) {
        return data
            .map((json) => _parseBudgetHealth(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to get budget health: ${e.message}');
    }
  }

  /// Get overall financial health
  Future<OverallHealthScoreEntity> getOverallHealth() async {
    try {
      final response = await _apiService.dio.get('/budgets/health/overall');
      
      dynamic data = response.data;
      if (data is Map && data['data'] != null) {
        data = data['data'];
      }

      return _parseOverallHealth(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to get overall health: ${e.message}');
    }
  }

  // ==================== Helper Methods ====================

  String _budgetTypeToString(BudgetType type) {
    switch (type) {
      case BudgetType.daily:
        return 'daily';
      case BudgetType.weekly:
        return 'weekly';
      case BudgetType.monthly:
        return 'monthly';
      case BudgetType.quarterly:
        return 'quarterly';
      case BudgetType.semiAnnual:
        return 'semi_annual';
      case BudgetType.annual:
        return 'annual';
    }
  }


  BudgetAlertEntity _parseAlert(Map<String, dynamic> json) {
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is String) return DateTime.parse(dateValue);
      if (dateValue is DateTime) return dateValue;
      throw FormatException('Invalid date format: $dateValue');
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    AlertType parseAlertType(String? type) {
      switch (type?.toUpperCase()) {
        case 'CRITICAL':
          return AlertType.critical;
        case 'EXCEEDED':
          return AlertType.exceeded;
        default:
          return AlertType.warning;
      }
    }

    AlertStatus parseStatus(String? status) {
      switch (status?.toLowerCase()) {
        case 'dismissed':
          return AlertStatus.dismissed;
        case 'resolved':
          return AlertStatus.resolved;
        default:
          return AlertStatus.active;
      }
    }

    return BudgetAlertEntity(
      id: json['id'] as String,
      budgetId: json['budgetId'] as String,
      budgetName: json['budget']?['categoryName']?.toString() ?? 
                  json['budgetName']?.toString(),
      alertType: parseAlertType(json['alertType']?.toString()),
      message: json['message'] as String,
      projectedOverage: parseDouble(json['projectedOverage']),
      safeDailySpend: parseDouble(json['safeDailySpend']),
      suggestedAction: json['suggestedAction']?.toString(),
      triggeredAt: parseDate(json['triggeredAt']),
      dismissedAt: json['dismissedAt'] != null 
          ? parseDate(json['dismissedAt']) 
          : null,
      status: parseStatus(json['status']?.toString()),
    );
  }

  ReallocationSuggestionEntity _parseReallocation(Map<String, dynamic> json) {
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is String) return DateTime.parse(dateValue);
      if (dateValue is DateTime) return dateValue;
      throw FormatException('Invalid date format: $dateValue');
    }

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.parse(value);
      return 0.0;
    }

    ReallocationStatus parseStatus(String? status) {
      switch (status?.toLowerCase()) {
        case 'applied':
          return ReallocationStatus.applied;
        case 'dismissed':
          return ReallocationStatus.dismissed;
        default:
          return ReallocationStatus.pending;
      }
    }

    final fromBudgetJson = json['fromBudget'] as Map<String, dynamic>;
    final toBudgetJson = json['toBudget'] as Map<String, dynamic>;

    return ReallocationSuggestionEntity(
      id: json['id'] as String,
      fromBudget: BudgetInfo(
        id: fromBudgetJson['id'] as String,
        name: fromBudgetJson['name'] as String,
        amount: parseDouble(fromBudgetJson['amount']),
        spent: parseDouble(fromBudgetJson['spent']),
        projectedSpent: parseDouble(fromBudgetJson['projectedSpent']),
        projectedUnused: parseDouble(fromBudgetJson['projectedUnused']),
        projectedOverage: 0.0,
      ),
      toBudget: BudgetInfo(
        id: toBudgetJson['id'] as String,
        name: toBudgetJson['name'] as String,
        amount: parseDouble(toBudgetJson['amount']),
        spent: parseDouble(toBudgetJson['spent']),
        projectedSpent: parseDouble(toBudgetJson['projectedSpent']),
        projectedUnused: 0.0,
        projectedOverage: parseDouble(toBudgetJson['projectedOverage']),
      ),
      suggestedAmount: parseDouble(json['suggestedAmount']),
      reasoning: json['reasoning'] as String,
      confidence: parseDouble(json['confidence']),
      expiresAt: json['expiresAt'] != null 
          ? parseDate(json['expiresAt']) 
          : null,
      status: parseStatus(json['status']?.toString()),
      createdAt: parseDate(json['createdAt']),
      appliedAt: json['appliedAt'] != null 
          ? parseDate(json['appliedAt']) 
          : null,
      dismissedAt: json['dismissedAt'] != null 
          ? parseDate(json['dismissedAt']) 
          : null,
    );
  }

  BudgetHealthScoreEntity _parseBudgetHealth(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.parse(value);
      return 0.0;
    }

    HealthGrade parseGrade(String? grade) {
      switch (grade?.toUpperCase()) {
        case 'A':
          return HealthGrade.a;
        case 'B':
          return HealthGrade.b;
        case 'C':
          return HealthGrade.c;
        case 'D':
          return HealthGrade.d;
        default:
          return HealthGrade.f;
      }
    }

    HealthTrend parseTrend(String? trend) {
      switch (trend?.toLowerCase()) {
        case 'improving':
          return HealthTrend.improving;
        case 'worsening':
          return HealthTrend.worsening;
        default:
          return HealthTrend.stable;
      }
    }

    final factorsJson = json['factors'] as Map<String, dynamic>;

    return BudgetHealthScoreEntity(
      budgetId: json['budgetId'] as String,
      budgetName: json['budgetName'] as String,
      score: parseDouble(json['score']),
      grade: parseGrade(json['grade']?.toString()),
      utilizationRate: parseDouble(json['utilizationRate']),
      consistency: parseDouble(json['consistency']),
      trend: parseTrend(json['trend']?.toString()),
      forecastAccuracy: parseDouble(json['forecastAccuracy']),
      factors: HealthFactors(
        utilization: parseDouble(factorsJson['utilization']),
        consistency: parseDouble(factorsJson['consistency']),
        trend: parseDouble(factorsJson['trend']),
        forecastAccuracy: parseDouble(factorsJson['forecastAccuracy']),
      ),
      insights: List<String>.from(json['insights'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }

  OverallHealthScoreEntity _parseOverallHealth(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.parse(value);
      return 0.0;
    }

    HealthGrade parseGrade(String? grade) {
      switch (grade?.toUpperCase()) {
        case 'A':
          return HealthGrade.a;
        case 'B':
          return HealthGrade.b;
        case 'C':
          return HealthGrade.c;
        case 'D':
          return HealthGrade.d;
        default:
          return HealthGrade.f;
      }
    }

    final factorsJson = json['factors'] as Map<String, dynamic>;
    final budgetScoresJson = json['budgetScores'] as List<dynamic>? ?? [];

    return OverallHealthScoreEntity(
      score: parseDouble(json['score']),
      grade: parseGrade(json['grade']?.toString()),
      budgetCoverage: parseDouble(json['budgetCoverage']),
      averageBudgetScore: parseDouble(json['averageBudgetScore']),
      spendingDiscipline: parseDouble(json['spendingDiscipline']),
      forecastReliability: parseDouble(json['forecastReliability']),
      factors: OverallHealthFactors(
        budgetCoverage: parseDouble(factorsJson['budgetCoverage']),
        budgetPerformance: parseDouble(factorsJson['budgetPerformance']),
        spendingDiscipline: parseDouble(factorsJson['spendingDiscipline']),
        forecastReliability: parseDouble(factorsJson['forecastReliability']),
      ),
      insights: List<String>.from(json['insights'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      budgetScores: budgetScoresJson
          .map((json) => _parseBudgetHealth(json as Map<String, dynamic>))
          .toList(),
    );
  }
}
