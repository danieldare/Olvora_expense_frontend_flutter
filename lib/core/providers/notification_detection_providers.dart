import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/platform_notification_service.dart';
import '../services/notification_preferences_service.dart';

/// Provider for platform notification service
final platformNotificationServiceProvider =
    Provider<PlatformNotificationService>((ref) {
  final service = PlatformNotificationService();
  // Initialize on first access
  service.initialize();
  return service;
});

/// Provider for notification preferences
final notificationPreferencesServiceProvider =
    Provider<NotificationPreferencesService>((ref) {
  return NotificationPreferencesService();
});

/// State notifier for notification detection enabled state
/// This ensures the UI updates reactively when the state changes
class NotificationDetectionStateNotifier extends StateNotifier<bool> {
  final PlatformNotificationService _service;
  final NotificationPreferencesService _prefsService;

  NotificationDetectionStateNotifier(
    this._service,
    this._prefsService,
  ) : super(false) {
    // Load initial state asynchronously
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    try {
      final isEnabled = await _prefsService.isEnabled();
      // Only update if state changed to avoid unnecessary rebuilds
      if (state != isEnabled) {
        state = isEnabled;
      }
    } catch (e) {
      // If error, keep state as false
      state = false;
    }
  }

  Future<bool> enable() async {
    final success = await _service.enable();
    // Update state to match service state
    if (success && state != true) {
      state = true;
    } else if (!success && state != false) {
      // If enable failed, ensure state is false
      state = false;
    }
    return success;
  }

  Future<void> disable() async {
    await _service.disable();
    // Update state to match service state
    if (state != false) {
      state = false;
    }
  }

  /// Refresh state from preferences (useful after external changes)
  Future<void> refresh() async {
    try {
      final isEnabled = await _prefsService.isEnabled();
      // Only update if state changed
      if (state != isEnabled) {
        state = isEnabled;
      }
    } catch (e) {
      // If error, set to false
      if (state != false) {
        state = false;
      }
    }
  }
}

/// Provider for notification detection state notifier
/// This provider ensures reactive state updates across the app
final notificationDetectionStateProvider =
    StateNotifierProvider<NotificationDetectionStateNotifier, bool>((ref) {
  final service = ref.watch(platformNotificationServiceProvider);
  final prefsService = ref.watch(notificationPreferencesServiceProvider);
  return NotificationDetectionStateNotifier(service, prefsService);
});

