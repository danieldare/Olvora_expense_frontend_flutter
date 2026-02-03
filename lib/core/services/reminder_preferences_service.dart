import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service for managing expense tracking reminder preferences
/// 
/// Features:
/// - Type-safe preference storage
/// - Default value handling
/// - Error handling with fallbacks
/// - Validation of stored values
class ReminderPreferencesService {
  static const String _enabledKey = 'expense_reminder_enabled';
  static const String _reminderTimeKey = 'expense_reminder_time';
  static const String _reminderMessageKey = 'expense_reminder_message';
  static const String _lastReminderDateKey = 'last_reminder_date';

  /// Default reminder message
  static const String defaultMessage = "Don't forget to track your expenses today?";

  /// Default reminder time (6:00 PM)
  static const String defaultTime = '18:00';

  /// Maximum message length
  static const int maxMessageLength = 200;

  /// Check if reminders are enabled
  Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_enabledKey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error reading reminder enabled state: $e');
      }
      return false;
    }
  }

  /// Enable or disable reminders
  Future<bool> setEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_enabledKey, enabled);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error setting reminder enabled state: $e');
      }
      return false;
    }
  }

  /// Get the reminder time (format: "HH:mm")
  /// Returns default time if invalid or missing
  Future<String> getReminderTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString(_reminderTimeKey);
      
      if (timeString == null) {
        return defaultTime;
      }

      // Validate time format
      if (!_isValidTimeFormat(timeString)) {
        if (kDebugMode) {
          debugPrint('⚠️ Invalid time format stored: $timeString, using default');
        }
        return defaultTime;
      }

      return timeString;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error reading reminder time: $e');
      }
      return defaultTime;
    }
  }

  /// Set the reminder time (format: "HH:mm")
  /// Validates format before saving
  Future<bool> setReminderTime(String time) async {
    // Validate time format
    if (!_isValidTimeFormat(time)) {
      if (kDebugMode) {
        debugPrint('❌ Invalid time format: $time');
      }
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_reminderTimeKey, time);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error setting reminder time: $e');
      }
      return false;
    }
  }

  /// Validate time format (HH:mm)
  bool _isValidTimeFormat(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return false;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return false;
    if (hour < 0 || hour > 23) return false;
    if (minute < 0 || minute > 59) return false;

    return true;
  }

  /// Get the reminder message
  /// Returns default message if invalid or missing
  Future<String> getReminderMessage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final message = prefs.getString(_reminderMessageKey);
      
      if (message == null || message.trim().isEmpty) {
        return defaultMessage;
      }

      // Truncate if too long (shouldn't happen, but safety check)
      if (message.length > maxMessageLength) {
        if (kDebugMode) {
          debugPrint('⚠️ Message too long, truncating: ${message.length} > $maxMessageLength');
        }
        return message.substring(0, maxMessageLength);
      }

      return message;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error reading reminder message: $e');
      }
      return defaultMessage;
    }
  }

  /// Set the reminder message
  /// Validates length before saving
  Future<bool> setReminderMessage(String message) async {
    final trimmedMessage = message.trim();
    
    // Validate message
    if (trimmedMessage.isEmpty) {
      if (kDebugMode) {
        debugPrint('❌ Cannot set empty reminder message');
      }
      return false;
    }

    if (trimmedMessage.length > maxMessageLength) {
      if (kDebugMode) {
        debugPrint('❌ Message too long: ${trimmedMessage.length} > $maxMessageLength');
      }
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_reminderMessageKey, trimmedMessage);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error setting reminder message: $e');
      }
      return false;
    }
  }

  /// Get the last date a reminder was sent (to prevent duplicates)
  Future<DateTime?> getLastReminderDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateString = prefs.getString(_lastReminderDateKey);
      
      if (dateString == null) {
        return null;
      }

      try {
        return DateTime.parse(dateString);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Invalid date format stored: $dateString');
        }
        // Clear invalid date
        await prefs.remove(_lastReminderDateKey);
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error reading last reminder date: $e');
      }
      return null;
    }
  }

  /// Set the last reminder date
  Future<bool> setLastReminderDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(
        _lastReminderDateKey,
        date.toIso8601String(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error setting last reminder date: $e');
      }
      return false;
    }
  }

  /// Clear all reminder preferences
  Future<bool> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final results = await Future.wait([
        prefs.remove(_enabledKey),
        prefs.remove(_reminderTimeKey),
        prefs.remove(_reminderMessageKey),
        prefs.remove(_lastReminderDateKey),
      ]);
      
      return results.every((result) => result == true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing reminder preferences: $e');
      }
      return false;
    }
  }

  /// Get all reminder preferences as a map (for debugging)
  Future<Map<String, dynamic>> getAllPreferences() async {
    try {
      return {
        'enabled': await isEnabled(),
        'time': await getReminderTime(),
        'message': await getReminderMessage(),
        'lastReminderDate': await getLastReminderDate(),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting all preferences: $e');
      }
      return {};
    }
  }
}
