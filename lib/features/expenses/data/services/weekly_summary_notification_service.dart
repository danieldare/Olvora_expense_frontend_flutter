import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../../core/services/local_notification_service.dart';

/// Service for managing weekly summary push notifications
///
/// Features:
/// - Schedules weekly summary notifications for Sunday evenings
/// - Handles notification taps to navigate to summary screen
/// - Respects quiet hours (10pm-8am)
class WeeklySummaryNotificationService {
  static final WeeklySummaryNotificationService _instance =
      WeeklySummaryNotificationService._internal();
  factory WeeklySummaryNotificationService() => _instance;
  WeeklySummaryNotificationService._internal();

  final LocalNotificationService _localNotificationService =
      LocalNotificationService();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const String _channelId = 'weekly_summary_channel';
  static const String _channelName = 'Weekly Summary';
  static const String _channelDescription =
      'Weekly spending summaries and insights';

  /// Initialize the notification service
  Future<bool> initialize() async {
    try {
      // Ensure local notification service is initialized
      await _localNotificationService.initialize();

      // Create notification channel for weekly summaries
      await _createNotificationChannel();

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing weekly summary notifications: $e');
      }
      return false;
    }
  }

  /// Schedule weekly summary notification for Sunday evening
  ///
  /// Default time: 7 PM local time
  /// Respects quiet hours (10pm-8am)
  Future<bool> scheduleWeeklyNotification({
    TimeOfDay? time,
  }) async {
    try {
      // Default to 7 PM if not specified
      final notificationTime = time ?? const TimeOfDay(hour: 19, minute: 0);

      // Calculate next Sunday at the specified time
      final nextSunday = _getNextSunday(notificationTime);

      // Check if time is in quiet hours (10pm-8am)
      if (_isQuietHours(notificationTime)) {
        if (kDebugMode) {
          debugPrint(
            '⚠️ Notification time is in quiet hours, adjusting to 7 PM',
          );
        }
        // Adjust to 7 PM if in quiet hours
        final adjustedTime = const TimeOfDay(hour: 19, minute: 0);
        final adjustedSunday = _getNextSunday(adjustedTime);
        await _scheduleNotification(adjustedSunday, adjustedTime);
      } else {
        await _scheduleNotification(nextSunday, notificationTime);
      }

      if (kDebugMode) {
        debugPrint('✅ Weekly summary notification scheduled');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error scheduling weekly notification: $e');
      }
      return false;
    }
  }

  /// Send immediate notification with summary message
  ///
  /// Used when backend scheduler generates summary
  Future<bool> sendWeeklySummaryNotification({
    required String message,
    required String summaryId,
  }) async {
    try {
      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notifications.show(
        _generateNotificationId(summaryId),
        'Weekly Summary',
        message,
        notificationDetails,
        payload: 'weekly_summary:$summaryId',
      );

      if (kDebugMode) {
        debugPrint('✅ Weekly summary notification sent: $message');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending weekly summary notification: $e');
      }
      return false;
    }
  }

  /// Cancel scheduled weekly notifications
  Future<void> cancelScheduledNotifications() async {
    try {
      // Cancel the scheduled weekly notification (ID: 9999)
      await _notifications.cancel(_generateScheduledNotificationId());
      if (kDebugMode) {
        debugPrint('✅ Weekly summary notifications cancelled');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error cancelling notifications: $e');
      }
    }
  }

  /// Handle notification tap
  ///
  /// Returns summary ID if payload is valid, null otherwise
  String? handleNotificationTap(String? payload) {
    if (payload == null) return null;

    // Payload format: "weekly_summary:summaryId"
    if (payload.startsWith('weekly_summary:')) {
      return payload.substring('weekly_summary:'.length);
    }

    return null;
  }

  // ========== PRIVATE HELPER METHODS ==========

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
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      if (kDebugMode) {
        debugPrint('✅ Weekly summary notification channel created');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error creating notification channel: $e');
      }
    }
  }

  DateTime _getNextSunday(TimeOfDay time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Find next Sunday
    int daysUntilSunday = (7 - now.weekday) % 7;
    if (daysUntilSunday == 0) {
      // Today is Sunday, check if we should schedule for today or next week
      final todayAtTime = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      if (now.isBefore(todayAtTime)) {
        // Schedule for today
        return todayAtTime;
      }
      // Schedule for next week
      daysUntilSunday = 7;
    }

    final nextSunday = today.add(Duration(days: daysUntilSunday));
    return DateTime(
      nextSunday.year,
      nextSunday.month,
      nextSunday.day,
      time.hour,
      time.minute,
    );
  }

  bool _isQuietHours(TimeOfDay time) {
    final hour = time.hour;
    // Quiet hours: 10 PM (22) to 8 AM (8)
    return hour >= 22 || hour < 8;
  }

  Future<void> _scheduleNotification(
    DateTime scheduledDate,
    TimeOfDay time,
  ) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications.zonedSchedule(
      _generateScheduledNotificationId(),
      'Weekly Summary',
      'Your weekly spending summary is ready',
      tzDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekly_summary',
    );
  }

  int _generateNotificationId(String summaryId) {
    // Generate consistent ID from summary ID
    return summaryId.hashCode.abs() % 100000;
  }

  int _generateScheduledNotificationId() {
    // Use a fixed ID for scheduled weekly notifications
    return 9999; // Fixed ID for weekly summary
  }
}

