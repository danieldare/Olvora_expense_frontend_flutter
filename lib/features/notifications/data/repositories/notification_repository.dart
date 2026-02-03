import 'package:dio/dio.dart';
import '../../domain/entities/notification_entity.dart';

/// Repository for managing notifications
class NotificationRepository {
  final Dio _dio;

  NotificationRepository({required Dio dio}) : _dio = dio;

  /// Fetch all notifications for the current user
  Future<List<NotificationEntity>> getNotifications({
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      };

      final response = await _dio.get(
        '/notifications',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      // Handle TransformInterceptor response wrapper
      dynamic actualData = response.data;
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        if (responseMap.containsKey('data') && responseMap['data'] != null) {
          actualData = responseMap['data'];
        }
      }

      List<dynamic> notificationsList;
      if (actualData is List) {
        notificationsList = actualData;
      } else {
        notificationsList = [];
      }

      return notificationsList
          .map((json) {
            try {
              return NotificationEntity.fromJson(
                json as Map<String, dynamic>,
              );
            } catch (e) {
              rethrow;
            }
          })
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Endpoint doesn't exist yet, return empty list
        return [];
      }
      rethrow;
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _dio.patch(
        '/notifications/$notificationId/read',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Endpoint doesn't exist yet, silently succeed
        return;
      }
      rethrow;
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _dio.patch('/notifications/read-all');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Endpoint doesn't exist yet, silently succeed
        return;
      }
      rethrow;
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('/notifications/unread-count');

      // Handle TransformInterceptor response wrapper
      dynamic actualData = response.data;
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        if (responseMap.containsKey('data') && responseMap['data'] != null) {
          actualData = responseMap['data'];
        }
      }

      if (actualData is Map && actualData.containsKey('count')) {
        return (actualData['count'] as num).toInt();
      }

      return 0;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Endpoint doesn't exist yet, return 0
        return 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
