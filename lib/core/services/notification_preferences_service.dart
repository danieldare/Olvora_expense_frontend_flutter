import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing notification detection preferences
class NotificationPreferencesService {
  static const String _enabledKey = 'notification_detection_enabled';
  static const String _lastProcessedNotificationKey =
      'last_processed_notification';
  static const String _lastProcessedTimestampKey = 'last_processed_timestamp';

  /// Check if notification detection is enabled
  Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_enabledKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Enable notification detection
  Future<void> setEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, enabled);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Store last processed notification to prevent duplicates
  Future<void> setLastProcessedNotification(
    String notificationText,
    DateTime timestamp,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastProcessedNotificationKey, notificationText);
      await prefs.setString(
        _lastProcessedTimestampKey,
        timestamp.toIso8601String(),
      );
    } catch (e) {
      // Handle error silently
    }
  }

  /// Check if notification was recently processed (within last 30 seconds)
  /// This prevents duplicate detection of the same notification
  Future<bool> wasRecentlyProcessed(String notificationText) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastText = prefs.getString(_lastProcessedNotificationKey);
      final lastTimestampStr = prefs.getString(_lastProcessedTimestampKey);

      if (lastText == notificationText && lastTimestampStr != null) {
        final lastTimestamp = DateTime.parse(lastTimestampStr);
        final now = DateTime.now();
        final difference = now.difference(lastTimestamp);

        // If same notification within 30 seconds, consider it duplicate
        return difference.inSeconds < 30;
      }
    } catch (e) {
      // If error, allow processing
    }
    return false;
  }

  /// Clear stored preferences
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_enabledKey);
      await prefs.remove(_lastProcessedNotificationKey);
      await prefs.remove(_lastProcessedTimestampKey);
    } catch (e) {
      // Handle error silently
    }
  }
}
