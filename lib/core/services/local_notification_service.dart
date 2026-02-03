import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'reminder_preferences_service.dart';
import '../navigation/navigator_service.dart';
import '../../features/expenses/presentation/screens/weekly_summary_screen.dart';

/// Service for managing local notifications for expense reminders
///
/// Features:
/// - Automatic timezone detection and handling
/// - Robust error handling and recovery
/// - Permission management with user-friendly messages
/// - Smart scheduling with validation
/// - Notification channel management (Android)
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final ReminderPreferencesService _preferencesService =
      ReminderPreferencesService();

  bool _isInitialized = false;
  bool _isInitializing = false;

  /// Callback when user taps "Receipt Shared - Tap to process" (payload: share_receipt).
  /// Set by ShareHandlerService to avoid circular dependency.
  void Function()? _shareReceiptHandler;

  static const String _channelId = 'expense_reminder_channel';
  static const String _channelName = 'Expense Reminders';
  static const String _channelDescription =
      'Daily reminders to track your expenses';

  /// Initialize the notification service
  /// Returns true if successful, false otherwise
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    if (_isInitializing) {
      // Wait for ongoing initialization
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _isInitialized;
    }

    _isInitializing = true;

    try {
      // Initialize timezone data
      tz.initializeTimeZones();

      // Get device timezone (not UTC)
      try {
        final location = tz.getLocation(tz.local.name);
        tz.setLocalLocation(location);
      } catch (e) {
        // Fallback to UTC if location not found
        if (kDebugMode) {
          debugPrint('⚠️ Using UTC timezone as fallback: $e');
        }
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      // Check notification permission (don't request yet - will request when user enables reminder)
      // This allows the service to initialize without blocking on permission
      final permissionStatus = await Permission.notification.status;
      if (!permissionStatus.isGranted) {
        if (kDebugMode) {
          debugPrint(
            'ℹ️ Notification permission not yet granted. Will request when user enables expense reminder.',
          );
        }
        // Continue initialization - permission will be requested when needed
      }

      // Create notification channel (Android)
      await _createNotificationChannel();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize the plugin
      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == false) {
        if (kDebugMode) {
          debugPrint('❌ Failed to initialize local notifications');
        }
        _isInitializing = false;
        return false;
      }

      _isInitialized = true;

      // Schedule reminders if enabled
      await _scheduleRemindersIfEnabled();

      if (kDebugMode) {
        debugPrint('✅ Local notifications initialized successfully');
      }

      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing local notifications: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      _isInitialized = false;
      return false;
    } finally {
      _isInitializing = false;
    }
  }

  /// Public method to request notification permission
  /// This should be called before scheduling reminders to ensure permission is granted
  Future<bool> requestNotificationPermission() async {
    return await _requestNotificationPermission();
  }

  /// Request notification permission with proper handling
  /// Uses flutter_local_notifications API for iOS (more reliable) and permission_handler for Android
  Future<bool> _requestNotificationPermission() async {
    try {
      // Ensure service is initialized first
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          if (kDebugMode) {
            debugPrint('❌ Cannot request permission: service not initialized');
          }
          return false;
        }
      }

      // Check current status using permission_handler
      final status = await Permission.notification.status;

      if (kDebugMode) {
        debugPrint('📱 Current notification permission status: $status');
      }

      if (status.isGranted) {
        if (kDebugMode) {
          debugPrint('✅ Notification permission already granted');
        }
        return true;
      }

      if (status.isPermanentlyDenied) {
        if (kDebugMode) {
          debugPrint(
            '⚠️ Notification permission permanently denied - user must enable in settings',
          );
        }
        return false;
      }

      if (status.isDenied) {
        if (kDebugMode) {
          debugPrint('ℹ️ Notification permission denied, requesting...');
        }

        // For iOS, use flutter_local_notifications API which is more reliable
        // For Android, use permission_handler
        // Try iOS-specific permission request first (if on iOS)
        try {
          final iosImplementation = _notifications
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();

          if (iosImplementation != null) {
            if (kDebugMode) {
              debugPrint(
                '📱 Detected iOS platform, requesting permissions via plugin',
              );
            }
            // Request iOS permissions using the plugin's API
            final iosResult = await iosImplementation.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );

            if (kDebugMode) {
              debugPrint('📱 iOS permission request result: $iosResult');
            }

            if (iosResult == true) {
              // Give it a moment for the system to update
              await Future.delayed(const Duration(milliseconds: 500));

              // Verify with permission_handler
              final verifiedStatus = await Permission.notification.status;
              if (verifiedStatus.isGranted) {
                if (kDebugMode) {
                  debugPrint('✅ iOS notification permission granted');
                }
                return true;
              } else {
                if (kDebugMode) {
                  debugPrint(
                    '⚠️ iOS plugin returned true but permission_handler shows: $verifiedStatus',
                  );
                }
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              '⚠️ iOS permission request failed, trying permission_handler: $e',
            );
          }
        }

        // Fallback to permission_handler for Android or if iOS method failed
        if (kDebugMode) {
          debugPrint('📱 Using permission_handler to request permission');
        }
        final result = await Permission.notification.request();

        if (kDebugMode) {
          debugPrint('📱 Permission request result: $result');
        }

        if (result.isGranted) {
          if (kDebugMode) {
            debugPrint('✅ Notification permission granted after request');
          }
          return true;
        } else if (result.isPermanentlyDenied) {
          if (kDebugMode) {
            debugPrint(
              '⚠️ Notification permission permanently denied after request',
            );
          }
          return false;
        } else {
          if (kDebugMode) {
            debugPrint('❌ Notification permission denied after request');
          }
          return false;
        }
      }

      // Default: permission not granted
      if (kDebugMode) {
        debugPrint('❌ Notification permission not granted (status: $status)');
      }
      return false;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error requesting notification permission: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    try {
      const androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);

      if (kDebugMode) {
        debugPrint('✅ Notification channel created');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error creating notification channel: $e');
      }
      // Continue even if channel creation fails (may already exist)
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('📱 Notification tapped: ${response.id}');
      debugPrint('Action: ${response.actionId}');
      debugPrint('Payload: ${response.payload}');
    }

    // Handle weekly summary notifications
    if (response.payload != null &&
        response.payload!.startsWith('weekly_summary')) {
      _navigateToWeeklySummary(response.payload!);
      return;
    }

    // Handle share receipt notification (tap to process queued receipt)
    if (response.payload == 'share_receipt') {
      if (_shareReceiptHandler != null) {
        scheduleMicrotask(() {
          try {
            _shareReceiptHandler!();
            if (kDebugMode) {
              debugPrint('✅ Share receipt notification handled');
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ Error handling share receipt notification: $e');
            }
          }
        });
      } else if (kDebugMode) {
        debugPrint('⚠️ Share receipt handler not registered');
      }
      return;
    }
  }

  /// Register handler for "Receipt Shared - Tap to process" notification.
  /// Called by ShareHandlerService.initialize() to avoid circular dependency.
  void registerShareReceiptHandler(void Function()? handler) {
    _shareReceiptHandler = handler;
  }

  /// Navigate to weekly summary screen
  void _navigateToWeeklySummary(String payload) {
    // Wait for Navigator to be available
    if (!NavigatorService.isAvailable) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _navigateToWeeklySummary(payload);
      });
      return;
    }

    final context = NavigatorService.context;
    if (context == null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _navigateToWeeklySummary(payload);
      });
      return;
    }

    // Navigate to weekly summary screen
    scheduleMicrotask(() {
      try {
        // Import WeeklySummaryScreen dynamically to avoid circular dependencies
        // For now, we'll use a route name or import at the top
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              // Import here to avoid circular dependency
              return const WeeklySummaryScreen();
            },
          ),
        );

        if (kDebugMode) {
          debugPrint('✅ Navigated to Weekly Summary screen');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error navigating to Weekly Summary: $e');
        }
      }
    });
  }

  /// Schedule daily expense reminders
  /// Validates input and handles errors gracefully
  Future<bool> scheduleDailyReminder({
    required String message,
    required TimeOfDay time,
  }) async {
    // Validate inputs
    if (message.trim().isEmpty) {
      if (kDebugMode) {
        debugPrint('❌ Cannot schedule reminder: message is empty');
      }
      return false;
    }

    if (message.length > 200) {
      if (kDebugMode) {
        debugPrint(
          '❌ Cannot schedule reminder: message too long (${message.length} > 200)',
        );
      }
      return false;
    }

    // Ensure initialized
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        if (kDebugMode) {
          debugPrint('❌ Cannot schedule reminder: service not initialized');
        }
        return false;
      }
    }

    // Request permission if not granted
    final permissionStatus = await Permission.notification.status;
    if (!permissionStatus.isGranted) {
      final requested = await _requestNotificationPermission();
      if (!requested) {
        if (kDebugMode) {
          debugPrint(
            '❌ Cannot schedule reminder: notification permission denied',
          );
        }
        return false;
      }
    }

    try {
      // Cancel existing reminder first to avoid duplicates
      await cancelDailyReminder();

      // Calculate next scheduled time
      final scheduledTime = _nextInstanceOfTime(time);
      final now = tz.TZDateTime.now(tz.local);

      if (kDebugMode) {
        debugPrint('📅 Scheduling reminder:');
        debugPrint('   Current time: ${now.toString()}');
        debugPrint(
          '   Target time: ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        );
        debugPrint('   Scheduled time: ${scheduledTime.toString()}');
      }

      if (scheduledTime.isBefore(now)) {
        if (kDebugMode) {
          debugPrint('❌ Scheduled time is in the past: $scheduledTime < $now');
        }
        return false;
      }

      // Schedule new reminder with daily repeat
      await _notifications.zonedSchedule(
        1, // Notification ID (consistent for daily reminder)
        'Expense Reminder',
        message.trim(),
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            showWhen: true,
            styleInformation: BigTextStyleInformation(''),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents:
            DateTimeComponents.time, // Repeat daily at this time
      );

      if (kDebugMode) {
        debugPrint('✅ Daily reminder scheduled successfully');
        debugPrint(
          '   Time: ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        );
        debugPrint('   First notification: ${scheduledTime.toString()}');
        debugPrint('   Will repeat daily at this time');
      }

      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error scheduling reminder: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Cancel daily reminder
  Future<void> cancelDailyReminder() async {
    try {
      await _notifications.cancel(1);
      if (kDebugMode) {
        debugPrint('✅ Daily reminder cancelled');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error cancelling reminder: $e');
      }
      // Continue even if cancellation fails (may not exist)
    }
  }

  /// Get next instance of the specified time in local timezone
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);

    // Create scheduled time for today
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
      0,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Schedule a one-time reminder for a future expense
  ///
  /// [id] - Unique identifier for the future expense (used as notification ID)
  /// [title] - Title of the future expense
  /// [amount] - Formatted amount string
  /// [expectedDate] - When the expense is expected to occur
  /// [reminderDate] - When to send the reminder notification
  Future<bool> scheduleFutureExpenseReminder({
    required String id,
    required String title,
    required String amount,
    required DateTime expectedDate,
    required DateTime reminderDate,
  }) async {
    try {
      // Ensure service is initialized
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          if (kDebugMode) {
            debugPrint('❌ Cannot schedule reminder: service not initialized');
          }
          return false;
        }
      }

      // Check and request permission if needed
      final permissionStatus = await Permission.notification.status;
      if (!permissionStatus.isGranted) {
        final requested = await _requestNotificationPermission();
        if (!requested) {
          if (kDebugMode) {
            debugPrint('❌ Notification permission denied');
          }
          return false;
        }
      }

      // Convert reminder date to timezone-aware datetime
      final reminderTZ = tz.TZDateTime.from(reminderDate, tz.local);
      final now = tz.TZDateTime.now(tz.local);

      // Validate reminder date is in the future
      if (reminderTZ.isBefore(now)) {
        if (kDebugMode) {
          debugPrint('❌ Reminder date is in the past: $reminderTZ');
        }
        return false;
      }

      // Format expected date for display
      final expectedDateFormatted = DateFormat('MMM d, y').format(expectedDate);

      // Create notification message
      final message =
          '$title is due on $expectedDateFormatted. Expected amount: $amount';

      // Use a unique notification ID based on future expense ID hash
      final notificationId =
          id.hashCode.abs() % 2147483647; // Max int for notification ID

      // Schedule the notification
      await _notifications.zonedSchedule(
        notificationId,
        'Future Expense Reminder',
        message,
        reminderTZ,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            showWhen: true,
            styleInformation: BigTextStyleInformation(message),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null, // One-time notification
      );

      if (kDebugMode) {
        debugPrint('✅ Future expense reminder scheduled:');
        debugPrint('   ID: $notificationId');
        debugPrint('   Title: $title');
        debugPrint(
          '   Reminder date: ${DateFormat('MMM d, y h:mm a').format(reminderDate)}',
        );
        debugPrint('   Expected date: $expectedDateFormatted');
      }

      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error scheduling future expense reminder: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Cancel a future expense reminder by notification ID
  Future<void> cancelFutureExpenseReminder(String futureExpenseId) async {
    try {
      final notificationId = futureExpenseId.hashCode.abs() % 2147483647;
      await _notifications.cancel(notificationId);
      if (kDebugMode) {
        debugPrint('✅ Future expense reminder cancelled: $notificationId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error cancelling future expense reminder: $e');
      }
    }
  }

  /// Schedule reminders if enabled in preferences
  Future<void> _scheduleRemindersIfEnabled() async {
    try {
      final isEnabled = await _preferencesService.isEnabled();
      if (!isEnabled) {
        if (kDebugMode) {
          debugPrint('ℹ️ Reminders disabled, skipping schedule');
        }
        return;
      }

      final timeString = await _preferencesService.getReminderTime();
      final message = await _preferencesService.getReminderMessage();

      // Validate and parse time string (format: "HH:mm")
      final timeParts = timeString.split(':');
      if (timeParts.length != 2) {
        if (kDebugMode) {
          debugPrint('❌ Invalid time format: $timeString');
        }
        return;
      }

      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);

      if (hour == null || minute == null) {
        if (kDebugMode) {
          debugPrint('❌ Invalid time values: hour=$hour, minute=$minute');
        }
        return;
      }

      // Validate time range
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        if (kDebugMode) {
          debugPrint('❌ Time out of range: $hour:$minute');
        }
        return;
      }

      final success = await scheduleDailyReminder(
        message: message,
        time: TimeOfDay(hour: hour, minute: minute),
      );

      if (!success && kDebugMode) {
        debugPrint('⚠️ Failed to schedule reminder from preferences');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error in _scheduleRemindersIfEnabled: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  /// Update reminder schedule based on preferences
  /// This method ensures the reminder is properly rescheduled with current settings
  Future<bool> updateReminderSchedule() async {
    try {
      // Ensure service is initialized
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          if (kDebugMode) {
            debugPrint('❌ Cannot update schedule: service not initialized');
          }
          return false;
        }
      }

      // Check if reminders are enabled
      final isEnabled = await _preferencesService.isEnabled();
      if (!isEnabled) {
        // Cancel any existing reminders if disabled
        await cancelDailyReminder();
        if (kDebugMode) {
          debugPrint('ℹ️ Reminders disabled, cancelled existing reminders');
        }
        return true;
      }

      // Get current preferences
      final timeString = await _preferencesService.getReminderTime();
      final message = await _preferencesService.getReminderMessage();

      // Validate and parse time string (format: "HH:mm")
      final timeParts = timeString.split(':');
      if (timeParts.length != 2) {
        if (kDebugMode) {
          debugPrint('❌ Invalid time format: $timeString');
        }
        return false;
      }

      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);

      if (hour == null || minute == null) {
        if (kDebugMode) {
          debugPrint('❌ Invalid time values: hour=$hour, minute=$minute');
        }
        return false;
      }

      // Validate time range
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        if (kDebugMode) {
          debugPrint('❌ Time out of range: $hour:$minute');
        }
        return false;
      }

      // Check and request permission if needed
      final permissionStatus = await Permission.notification.status;
      if (!permissionStatus.isGranted) {
        if (kDebugMode) {
          debugPrint('ℹ️ Notification permission not granted, requesting...');
        }
        final requested = await _requestNotificationPermission();
        if (!requested) {
          if (kDebugMode) {
            debugPrint(
              '❌ Cannot update schedule: notification permission denied or not granted',
            );
            debugPrint('   Permission status: $permissionStatus');
          }
          return false;
        }
        if (kDebugMode) {
          debugPrint('✅ Notification permission granted');
        }
      }

      // Cancel existing reminder first to ensure clean reschedule
      await cancelDailyReminder();

      // Schedule with new settings
      final success = await scheduleDailyReminder(
        message: message,
        time: TimeOfDay(hour: hour, minute: minute),
      );

      if (success) {
        if (kDebugMode) {
          debugPrint('✅ Reminder schedule updated successfully');
          debugPrint('   Time: $hour:$minute');
          debugPrint(
            '   Message: ${message.length > 50 ? "${message.substring(0, 50)}..." : message}',
          );
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to schedule reminder with new settings');
        }
      }

      return success;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error updating reminder schedule: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Show a notification with custom title, body, and payload
  Future<bool> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? channelId,
  }) async {
    if (title.trim().isEmpty || body.trim().isEmpty) {
      if (kDebugMode) {
        debugPrint('❌ Cannot show notification: title or body is empty');
      }
      return false;
    }

    // Ensure initialized
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        if (kDebugMode) {
          debugPrint('❌ Cannot show notification: service not initialized');
        }
        return false;
      }
    }

    try {
      final effectiveChannelId = channelId ?? _channelId;
      
      await _notifications.show(
        id,
        title.trim(),
        body.trim(),
        NotificationDetails(
          android: AndroidNotificationDetails(
            effectiveChannelId,
            channelId != null ? 'Custom Notifications' : _channelName,
            channelDescription: channelId != null 
                ? 'Custom notification channel'
                : _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            styleInformation: BigTextStyleInformation(''),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
        payload: payload,
      );

      if (kDebugMode) {
        debugPrint('✅ Notification shown: $title');
      }

      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error showing notification: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Show a test notification
  Future<bool> showTestNotification(String message) async {
    if (message.trim().isEmpty) {
      if (kDebugMode) {
        debugPrint('❌ Cannot show test notification: message is empty');
      }
      return false;
    }

    // Ensure initialized
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        if (kDebugMode) {
          debugPrint(
            '❌ Cannot show test notification: service not initialized',
          );
        }
        return false;
      }
    }

    try {
      await _notifications.show(
        999, // Test notification ID (different from daily reminder)
        'Expense Reminder',
        message.trim(),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            styleInformation: BigTextStyleInformation(''),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
      );

      if (kDebugMode) {
        debugPrint('✅ Test notification shown');
      }

      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error showing test notification: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get notification permission status
  Future<PermissionStatus> getPermissionStatus() async {
    try {
      return await Permission.notification.status;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking permission status: $e');
      }
      return PermissionStatus.denied;
    }
  }

  /// Open app settings for notification permission
  Future<void> openNotificationSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error opening settings: $e');
      }
    }
  }
}
