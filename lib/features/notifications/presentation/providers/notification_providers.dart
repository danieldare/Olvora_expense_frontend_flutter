import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/entities/notification_entity.dart';

/// Provider for notification repository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiService = ref.watch(apiServiceV2Provider);
  return NotificationRepository(dio: apiService.dio);
});

/// Provider for fetching all notifications
final notificationsProvider =
    FutureProvider<List<NotificationEntity>>((ref) async {
  // Keep data alive to prevent disposal on widget unmount
  ref.keepAlive();

  // Watch user ID - only refetch when user actually changes
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return [];
  }

  final repository = ref.watch(notificationRepositoryProvider);

  try {
    final notifications = await repository.getNotifications();
    if (kDebugMode) {
      debugPrint('NotificationsProvider: Fetched ${notifications.length} notifications');
    }
    return notifications;
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('NotificationsProvider: Error fetching notifications: $e');
      debugPrint('NotificationsProvider: Stack trace: $stackTrace');
    }
    // Return empty list on error (graceful degradation)
    return [];
  }
});

/// Provider for unread notification count
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  // Keep data alive to prevent disposal on widget unmount
  ref.keepAlive();

  // Watch user ID - only refetch when user actually changes
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return 0;
  }

  final repository = ref.watch(notificationRepositoryProvider);

  try {
    final count = await repository.getUnreadCount();
    return count;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('UnreadCountProvider: Error fetching count: $e');
    }
    return 0;
  }
});

/// Notifier for managing notification state (mark as read, etc.)
class NotificationNotifier extends StateNotifier<AsyncValue<List<NotificationEntity>>> {
  NotificationNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    _loadNotifications();
  }

  final NotificationRepository _repository;
  final Ref _ref;

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _repository.getNotifications();
      state = AsyncValue.data(notifications);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);

      // Update local state optimistically
      state.whenData((notifications) {
        final updated = notifications.map((n) {
          if (n.id == notificationId) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();
        state = AsyncValue.data(updated);
      });

      // Invalidate unread count provider to refresh the badge
      _ref.invalidate(unreadNotificationCountProvider);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationNotifier: Error marking as read: $e');
      }
      // Reload to sync with server
      await _loadNotifications();
      // Still invalidate count even on error
      _ref.invalidate(unreadNotificationCountProvider);
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();

      // Update local state optimistically
      state.whenData((notifications) {
        final updated = notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
        state = AsyncValue.data(updated);
      });

      // Invalidate unread count provider to refresh the badge
      _ref.invalidate(unreadNotificationCountProvider);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationNotifier: Error marking all as read: $e');
      }
      // Reload to sync with server
      await _loadNotifications();
      // Still invalidate count even on error
      _ref.invalidate(unreadNotificationCountProvider);
    }
  }

  /// Refresh notifications
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadNotifications();
    // Invalidate unread count when refreshing
    _ref.invalidate(unreadNotificationCountProvider);
  }
}

/// Provider for notification notifier
final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<List<NotificationEntity>>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repository, ref);
});
