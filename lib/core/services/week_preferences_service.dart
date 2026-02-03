import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/user_preferences/presentation/providers/user_preferences_providers.dart';
import '../../features/user_preferences/domain/entities/user_preferences_entity.dart';

/// Service for managing week-related preferences
///
/// DEPRECATED: This service now delegates to UserPreferencesService (backend API)
/// Kept for backward compatibility during migration
///
/// Features:
/// - Week start day (Sunday or Monday)
/// - Backend is the single source of truth
/// - Default value handling
/// - Singleton pattern for shared cache
///
/// NOTE: This service requires Riverpod Ref to access providers.
/// For new code, use userPreferencesProvider or userPreferencesNotifierProvider directly.
class WeekPreferencesService {
  /// Default week start day (Sunday = 0, Monday = 1)
  static const int defaultWeekStartDay = 0; // Sunday

  /// Singleton instance
  static final WeekPreferencesService _instance = WeekPreferencesService._internal();

  /// Factory constructor returns singleton
  factory WeekPreferencesService() => _instance;

  /// Private constructor
  WeekPreferencesService._internal();

  /// Get the week start day from backend
  /// Returns 0 for Sunday, 1 for Monday
  /// Falls back to default if request fails
  ///
  /// NOTE: This method requires a Ref. For new code, use:
  /// ```dart
  /// final preferences = ref.watch(userPreferencesProvider);
  /// final weekStartDay = preferences.value?.weekStartDay.toNumber() ?? 0;
  /// ```
  Future<int> getWeekStartDay({ProviderRef? ref}) async {
    try {
      if (ref == null) {
        if (kDebugMode) {
          debugPrint('⚠️ WeekPreferencesService.getWeekStartDay() called without ref');
          debugPrint('⚠️ Using default: $defaultWeekStartDay');
        }
        return defaultWeekStartDay;
      }

      final service = ref.read(userPreferencesServiceProvider);
      final preferences = await service.getPreferences();
      return preferences.weekStartDay.toNumber();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error reading week start day from backend: $e');
        debugPrint('⚠️ Falling back to default: $defaultWeekStartDay');
      }
      return defaultWeekStartDay;
    }
  }

  /// Set the week start day via backend API
  /// 0 = Sunday, 1 = Monday
  ///
  /// NOTE: This method requires a Ref. For new code, use:
  /// ```dart
  /// ref.read(userPreferencesNotifierProvider.notifier).updatePreferences(
  ///   weekStartDay: WeekStartDay.fromNumber(day),
  /// );
  /// ```
  Future<bool> setWeekStartDay(int day, {ProviderRef? ref}) async {
    try {
      if (day != 0 && day != 1) {
        throw ArgumentError('Week start day must be 0 (Sunday) or 1 (Monday)');
      }

      if (ref == null) {
        if (kDebugMode) {
          debugPrint('❌ WeekPreferencesService.setWeekStartDay() called without ref');
        }
        return false;
      }

      final service = ref.read(userPreferencesServiceProvider);
      final weekStartDay = WeekStartDay.fromNumber(day);
      await service.updatePreferences(weekStartDay: weekStartDay);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error setting week start day: $e');
      }
      return false;
    }
  }

  /// Check if week starts on Sunday
  Future<bool> isWeekStartSunday({ProviderRef? ref}) async {
    final day = await getWeekStartDay(ref: ref);
    return day == 0;
  }

  /// Check if week starts on Monday
  Future<bool> isWeekStartMonday({ProviderRef? ref}) async {
    final day = await getWeekStartDay(ref: ref);
    return day == 1;
  }
}

