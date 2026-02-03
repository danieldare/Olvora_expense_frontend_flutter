import 'package:dio/dio.dart';
import '../../../../core/services/api_service_v2.dart';
import '../../../../core/utils/auth_error_handler.dart';
import '../../domain/entities/weekly_summary_entity.dart';
import '../../domain/entities/detailed_weekly_summary_entity.dart';

/// Service for fetching weekly summaries from the backend
/// Backend automatically uses user's week start day preference
class WeeklySummaryService {
  final ApiServiceV2 _apiService;

  WeeklySummaryService(this._apiService);

  /// Get current week's summary (generates if doesn't exist)
  /// Backend uses user's week start day preference automatically
  Future<WeeklySummaryEntity> getCurrentWeekSummary() async {
    try {
      // Backend automatically uses user's week start day preference
      final response = await _apiService.dio.get('/weekly-summary');

      // Handle response wrapper
      dynamic data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        data = data['data'];
      }

      // Validate data is not null
      if (data == null) {
        throw Exception('Weekly summary data is null');
      }

      // Validate data is a Map
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid weekly summary response format: ${data.runtimeType}');
      }

      return WeeklySummaryEntity.fromJson(data);
    } on DioException catch (e) {
      // Provide more detailed error information
      final statusCode = e.response?.statusCode;
      final errorMessage = e.response?.data?['message'] ?? e.message ?? 'Unknown error';
      
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      } else if (statusCode == 404) {
        throw Exception('Weekly summary not found. Please try generating one.');
      } else if (statusCode != null && statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Failed to fetch weekly summary: $errorMessage');
      }
    } catch (e) {
      // Handle non-DioException errors (parsing errors, etc.)
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get summary for specific week
  /// Backend uses user's week start day preference automatically
  Future<WeeklySummaryEntity?> getWeekSummary(DateTime weekStartDate) async {
    try {
      final dateStr = weekStartDate.toIso8601String().split('T')[0];
      // Backend automatically uses user's week start day preference
      final response = await _apiService.dio.get(
        '/weekly-summary/week/$dateStr',
      );

      if (response.statusCode == 404) {
        return null;
      }

      dynamic data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        data = data['data'];
      }

      return WeeklySummaryEntity.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Failed to fetch weekly summary: ${e.message}');
    }
  }

  /// Force generate summary for current week
  /// Backend uses user's week start day preference automatically
  Future<WeeklySummaryEntity> generateSummary() async {
    try {
      // Backend automatically uses user's week start day preference
      final response = await _apiService.dio.post('/weekly-summary/generate');

      dynamic data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        data = data['data'];
      }

      return WeeklySummaryEntity.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Failed to generate weekly summary: ${e.message}');
    }
  }

  /// Get push notification message for current week
  /// Backend uses user's week start day preference automatically
  Future<String?> getPushNotificationMessage() async {
    try {
      // Backend automatically uses user's week start day preference
      final response = await _apiService.dio.get(
        '/weekly-summary/push-notification',
      );

      dynamic data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        data = data['data'];
      }

      final message = (data as Map<String, dynamic>)['message'] as String?;
      return message;
    } catch (_) {
      return null;
    }
  }

  /// Get detailed weekly summary with all analytics
  /// Backend uses user's week start day preference automatically
  Future<DetailedWeeklySummaryEntity> getDetailedWeeklySummary({
    DateTime? weekStartDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (weekStartDate != null) {
        queryParams['weekStartDate'] = weekStartDate.toIso8601String().split('T')[0];
      }

      final endpoint = weekStartDate != null
          ? '/weekly-summary/detailed/week/${weekStartDate.toIso8601String().split('T')[0]}'
          : '/weekly-summary/detailed';

      // Backend automatically uses user's week start day preference
      final response = await _apiService.dio.get(
        endpoint,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      // Handle response wrapper
      dynamic data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        data = data['data'];
      }

      // Validate data is not null
      if (data == null) {
        throw Exception('Detailed weekly summary data is null');
      }

      // Validate data is a Map
      if (data is! Map<String, dynamic>) {
        throw Exception(
            'Invalid detailed weekly summary response format: ${data.runtimeType}');
      }

      return DetailedWeeklySummaryEntity.fromJson(data);
    } on DioException catch (e) {
      // Provide more detailed error information
      final statusCode = e.response?.statusCode;
      final errorMessage =
          e.response?.data?['message'] ?? e.message ?? 'Unknown error';

      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      } else if (statusCode == 404) {
        throw Exception(
            'Detailed weekly summary not found. Please try generating one.');
      } else if (statusCode != null && statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Failed to fetch detailed weekly summary: $errorMessage');
      }
    } catch (e) {
      // Handle non-DioException errors (parsing errors, etc.)
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Unexpected error: $e');
    }
  }
}
