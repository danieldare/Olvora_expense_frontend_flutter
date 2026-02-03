import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/reminder_preferences_service.dart';
import '../../../../core/services/local_notification_service.dart';

/// Provider for reminder preferences service
final reminderPreferencesServiceProvider =
    Provider<ReminderPreferencesService>((ref) {
  return ReminderPreferencesService();
});

/// Provider for local notification service
final localNotificationServiceProvider =
    Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});

/// Provider for reminder enabled state
/// Uses keepAlive to cache the state
final reminderEnabledProvider = FutureProvider<bool>((ref) async {
  ref.keepAlive();
  final service = ref.watch(reminderPreferencesServiceProvider);
  return await service.isEnabled();
});

/// Provider for reminder time
final reminderTimeProvider = FutureProvider<String>((ref) async {
  ref.keepAlive();
  final service = ref.watch(reminderPreferencesServiceProvider);
  return await service.getReminderTime();
});

/// Provider for reminder message
final reminderMessageProvider = FutureProvider<String>((ref) async {
  ref.keepAlive();
  final service = ref.watch(reminderPreferencesServiceProvider);
  return await service.getReminderMessage();
});

/// StateNotifier for managing reminder state
class ReminderNotifier extends StateNotifier<AsyncValue<bool>> {
  final ReminderPreferencesService _prefsService;
  final LocalNotificationService _notificationService;
  final Ref _ref;

  ReminderNotifier(
    this._prefsService,
    this._notificationService,
    this._ref,
  ) : super(const AsyncValue.loading()) {
    _loadEnabledState();
  }

  Future<void> _loadEnabledState() async {
    try {
      final isEnabled = await _prefsService.isEnabled();
      state = AsyncValue.data(isEnabled);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> toggleReminder(bool enabled) async {
    state = const AsyncValue.loading();
    
    try {
      final success = await _prefsService.setEnabled(enabled);
      if (!success) {
        throw Exception('Failed to save reminder preference');
      }

      if (enabled) {
        // Initialize notification service first
        final initialized = await _notificationService.initialize();
        if (!initialized) {
          throw Exception('Failed to initialize notification service');
        }
        
        // Explicitly request permission BEFORE scheduling
        // This ensures the system permission dialog appears
        final permissionGranted = await _notificationService.requestNotificationPermission();
        if (!permissionGranted) {
          throw Exception('Notification permission not granted');
        }
        
        // Now schedule the reminder
        final scheduled = await _notificationService.updateReminderSchedule();
        if (!scheduled) {
          throw Exception('Failed to schedule reminder');
        }
      } else {
        // Cancel reminder
        await _notificationService.cancelDailyReminder();
      }

      state = AsyncValue.data(enabled);
      
      // Invalidate related providers
      _ref.invalidate(reminderEnabledProvider);
      _ref.invalidate(reminderTimeProvider);
      _ref.invalidate(reminderMessageProvider);
      
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<void> refresh() async {
    await _loadEnabledState();
  }
}

/// Provider for reminder notifier
final reminderNotifierProvider =
    StateNotifierProvider<ReminderNotifier, AsyncValue<bool>>((ref) {
  final prefsService = ref.watch(reminderPreferencesServiceProvider);
  final notificationService = ref.watch(localNotificationServiceProvider);
  return ReminderNotifier(prefsService, notificationService, ref);
});

