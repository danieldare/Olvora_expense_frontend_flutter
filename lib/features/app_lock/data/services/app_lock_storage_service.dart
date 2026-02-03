import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lock timeout options in seconds
enum LockTimeout {
  immediate(0, 'Immediately'),
  oneMinute(60, '1 minute'),
  fiveMinutes(300, '5 minutes');

  final int seconds;
  final String displayName;

  const LockTimeout(this.seconds, this.displayName);

  static LockTimeout fromSeconds(int seconds) {
    return LockTimeout.values.firstWhere(
      (t) => t.seconds == seconds,
      orElse: () => LockTimeout.immediate,
    );
  }
}

/// Service for storing app lock settings
///
/// Uses SharedPreferences for non-sensitive settings:
/// - App lock enabled state
/// - Biometric enabled state
/// - Lock timeout duration
/// - Last activity timestamp
/// - PIN setup complete flag
class AppLockStorageService {
  // Storage keys
  static const String _appLockEnabledKey = 'app_lock_enabled';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lockTimeoutKey = 'app_lock_timeout';
  static const String _lastActivityKey = 'last_activity_timestamp';
  static const String _pinSetupCompleteKey = 'pin_setup_complete';

  SharedPreferences? _prefs;

  /// Initialize the service
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Ensure prefs is initialized
  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ============================================================
  // App Lock Enabled
  // ============================================================

  /// Check if app lock is enabled
  Future<bool> isAppLockEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_appLockEnabledKey) ?? false;
  }

  /// Set app lock enabled state
  Future<void> setAppLockEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_appLockEnabledKey, enabled);
    if (kDebugMode) {
      debugPrint('🔐 [AppLockStorage] App lock enabled: $enabled');
    }
  }

  // ============================================================
  // Biometric Enabled
  // ============================================================

  /// Check if biometric unlock is enabled
  Future<bool> isBiometricEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Set biometric enabled state
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_biometricEnabledKey, enabled);
    if (kDebugMode) {
      debugPrint('🔐 [AppLockStorage] Biometric enabled: $enabled');
    }
  }

  // ============================================================
  // Lock Timeout
  // ============================================================

  /// Get lock timeout in seconds
  Future<int> getLockTimeoutSeconds() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_lockTimeoutKey) ?? LockTimeout.immediate.seconds;
  }

  /// Get lock timeout as enum
  Future<LockTimeout> getLockTimeout() async {
    final seconds = await getLockTimeoutSeconds();
    return LockTimeout.fromSeconds(seconds);
  }

  /// Set lock timeout in seconds
  Future<void> setLockTimeoutSeconds(int seconds) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_lockTimeoutKey, seconds);
    if (kDebugMode) {
      debugPrint('🔐 [AppLockStorage] Lock timeout: ${seconds}s');
    }
  }

  /// Set lock timeout from enum
  Future<void> setLockTimeout(LockTimeout timeout) async {
    await setLockTimeoutSeconds(timeout.seconds);
  }

  // ============================================================
  // Last Activity Timestamp
  // ============================================================

  /// Get last activity timestamp (Unix milliseconds)
  Future<int?> getLastActivityTimestamp() async {
    final prefs = await _getPrefs();
    final value = prefs.getInt(_lastActivityKey);
    return value;
  }

  /// Update last activity timestamp to now
  Future<void> updateLastActivity() async {
    final prefs = await _getPrefs();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_lastActivityKey, now);
  }

  /// Clear last activity timestamp (used on unlock)
  Future<void> clearLastActivity() async {
    final prefs = await _getPrefs();
    await prefs.remove(_lastActivityKey);
  }

  /// Check if lock should be triggered based on timeout
  ///
  /// Returns true if:
  /// - App lock is enabled
  /// - Time since last activity exceeds timeout
  Future<bool> shouldLock() async {
    final isEnabled = await isAppLockEnabled();
    if (!isEnabled) return false;

    final lastActivity = await getLastActivityTimestamp();
    if (lastActivity == null) {
      // No last activity recorded - should lock
      return true;
    }

    final timeoutSeconds = await getLockTimeoutSeconds();
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedSeconds = (now - lastActivity) / 1000;

    final shouldLock = elapsedSeconds >= timeoutSeconds;
    if (kDebugMode) {
      debugPrint(
        '🔐 [AppLockStorage] Elapsed: ${elapsedSeconds.toStringAsFixed(1)}s, '
        'Timeout: ${timeoutSeconds}s, Should lock: $shouldLock',
      );
    }

    return shouldLock;
  }

  // ============================================================
  // PIN Setup Complete
  // ============================================================

  /// Check if PIN setup is complete
  Future<bool> isPinSetupComplete() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_pinSetupCompleteKey) ?? false;
  }

  /// Set PIN setup complete flag
  Future<void> setPinSetupComplete(bool complete) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_pinSetupCompleteKey, complete);
    if (kDebugMode) {
      debugPrint('🔐 [AppLockStorage] PIN setup complete: $complete');
    }
  }

  // ============================================================
  // Clear All
  // ============================================================

  /// Clear all app lock settings
  ///
  /// Used during logout or when disabling app lock
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await Future.wait([
      prefs.remove(_appLockEnabledKey),
      prefs.remove(_biometricEnabledKey),
      prefs.remove(_lockTimeoutKey),
      prefs.remove(_lastActivityKey),
      prefs.remove(_pinSetupCompleteKey),
    ]);
    if (kDebugMode) {
      debugPrint('🧹 [AppLockStorage] All settings cleared');
    }
  }
}
