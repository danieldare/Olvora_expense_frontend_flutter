import 'package:dio/dio.dart';
import '../../../../core/services/api_service_v2.dart';
import '../../../../core/utils/auth_error_handler.dart';
import '../../domain/entities/trip_entity.dart';

/// Service for managing trips via backend API
class TripService {
  final ApiServiceV2 _apiService;

  TripService(this._apiService);

  /// Create a new trip
  Future<TripEntity> createTrip({
    required String name,
    String? currency,
    TripVisibility? visibility,
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        if (currency != null) 'currency': currency,
        if (visibility != null) 'visibility': visibility.name.toUpperCase(),
      };

      final response = await _apiService.dio.post('/trips', data: data);
      final responseData = response.data['data'] as Map<String, dynamic>;
      return TripEntity.fromJson(responseData);
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to create trip: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Get all trips for the current user
  Future<List<TripEntity>> getTrips({
    int offset = 0,
    int limit = 20,
    TripStatus? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'offset': offset,
        'limit': limit,
        if (status != null) 'status': status.name.toUpperCase(),
      };

      final response = await _apiService.dio.get(
        '/trips',
        queryParameters: queryParams,
      );
      final responseData = response.data['data'] as Map<String, dynamic>;
      final trips = (responseData['trips'] as List)
          .map((json) => TripEntity.fromJson(json as Map<String, dynamic>))
          .toList();
      return trips;
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to fetch trips: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Get active trips for the current user (deprecated - use getActiveTrip instead)
  @Deprecated('Use getActiveTrip() instead. Only one active trip is allowed.')
  Future<List<TripEntity>> getActiveTrips() async {
    return getTrips(status: TripStatus.active);
  }

  /// Get the single active trip for the current user (or null if none exists)
  /// Only one active trip per user is allowed
  Future<TripEntity?> getActiveTrip() async {
    try {
      final response = await _apiService.dio.get('/trips/active');
      final responseData = response.data['data'] as Map<String, dynamic>?;
      if (responseData == null) return null;
      return TripEntity.fromJson(responseData);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // No active trip exists
      }
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to fetch active trip: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Get trip details by ID
  Future<TripEntity> getTrip(String tripId) async {
    try {
      final response = await _apiService.dio.get('/trips/$tripId');
      final responseData = response.data['data'] as Map<String, dynamic>;
      return TripEntity.fromJson(responseData);
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to fetch trip: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Update a trip
  Future<TripEntity> updateTrip({
    required String tripId,
    String? name,
    TripVisibility? visibility,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (visibility != null) data['visibility'] = visibility.name.toUpperCase();

      final response = await _apiService.dio.patch('/trips/$tripId', data: data);
      final responseData = response.data['data'] as Map<String, dynamic>;
      return TripEntity.fromJson(responseData);
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to update trip: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Close a trip
  Future<TripSummaryEntity> closeTrip(String tripId) async {
    try {
      final response = await _apiService.dio.post('/trips/$tripId/close');
      final responseData = response.data['data'] as Map<String, dynamic>;
      return TripSummaryEntity.fromJson(responseData);
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to close trip: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Delete a trip (only owner can delete)
  Future<void> deleteTrip(String tripId) async {
    try {
      await _apiService.dio.delete('/trips/$tripId');
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to delete trip: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Add a message to a trip
  Future<TripMessageEntity> addMessage({
    required String tripId,
    required String message,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/trips/$tripId/messages',
        data: {'message': message},
      );
      final responseData = response.data['data'] as Map<String, dynamic>;
      return TripMessageEntity.fromJson(responseData);
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to add message: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Invite a participant to a trip
  Future<TripParticipantEntity> inviteParticipant({
    required String tripId,
    required String userId,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/trips/$tripId/participants',
        data: {'userId': userId},
      );
      final responseData = response.data['data'] as Map<String, dynamic>;
      return TripParticipantEntity.fromJson(responseData);
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to invite participant: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Link an expense to a trip
  Future<void> linkExpense({
    required String tripId,
    required String expenseId,
  }) async {
    try {
      await _apiService.dio.post('/trips/$tripId/expenses/$expenseId/link');
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to link expense: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Unlink an expense from a trip
  Future<void> unlinkExpense({
    required String tripId,
    required String expenseId,
  }) async {
    try {
      await _apiService.dio.delete('/trips/$tripId/expenses/$expenseId/link');
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to unlink expense: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Get trip summary (for closed trips)
  Future<TripSummaryEntity> getTripSummary(String tripId) async {
    try {
      final response = await _apiService.dio.get('/trips/$tripId/summary');
      final responseData = response.data['data'] as Map<String, dynamic>;
      return TripSummaryEntity.fromJson(responseData);
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to fetch trip summary: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Create or update expense split
  Future<ExpenseSplitEntity> createExpenseSplit({
    required String tripId,
    required String expenseId,
    required SplitType splitType,
    List<ExpenseSplitItemDto>? items,
  }) async {
    try {
      final data = <String, dynamic>{
        'splitType': splitType.value,
        if (items != null && items.isNotEmpty)
          'items': items.map((item) => item.toJson()).toList(),
      };

      final response = await _apiService.dio.post(
        '/trips/$tripId/expenses/$expenseId/split',
        data: data,
      );
      final responseData = response.data['data'] as Map<String, dynamic>;
      return ExpenseSplitEntity.fromJson(responseData);
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to create expense split: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Get expense split
  Future<ExpenseSplitEntity?> getExpenseSplit({
    required String tripId,
    required String expenseId,
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/trips/$tripId/expenses/$expenseId/split',
      );
      final responseData = response.data['data'] as Map<String, dynamic>?;
      if (responseData == null) return null;
      return ExpenseSplitEntity.fromJson(responseData);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // No split exists
      }
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to fetch expense split: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Delete expense split
  Future<void> deleteExpenseSplit({
    required String tripId,
    required String expenseId,
  }) async {
    try {
      await _apiService.dio.delete(
        '/trips/$tripId/expenses/$expenseId/split',
      );
    } on DioException catch (e) {
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      }
      throw Exception('Failed to delete expense split: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}

/// DTO for creating expense split items
class ExpenseSplitItemDto {
  final String userId;
  final double? amount;
  final double? percentage;

  ExpenseSplitItemDto({
    required this.userId,
    this.amount,
    this.percentage,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      if (amount != null) 'amount': amount,
      if (percentage != null) 'percentage': percentage,
    };
  }
}
