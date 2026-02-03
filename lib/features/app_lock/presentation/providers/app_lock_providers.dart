import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../data/services/pin_service.dart';
import '../../data/services/biometric_service.dart';
import '../../data/services/app_lock_storage_service.dart';
import '../../domain/entities/app_lock_state.dart';

// =============================================================================
// Service Providers
// =============================================================================

/// PIN service provider
final pinServiceProvider = Provider<PinService>((ref) {
  return PinService();
});

/// Biometric service provider
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

/// App lock storage service provider
final appLockStorageServiceProvider = Provider<AppLockStorageService>((ref) {
  return AppLockStorageService();
});

// =============================================================================
// App Lock State Notifier
// =============================================================================

/// App lock state notifier - manages app lock state machine
///
/// State Machine:
/// - PinSetupRequired → (on PIN saved) → Unlocked
/// - Unlocked → (on app resume after timeout) → Locked
/// - Locked → (on correct PIN/biometric) → Unlocked
/// - Locked → (on 5 failed attempts) → Lockout
/// - Lockout → (triggers logout) → handled by auth system
class AppLockNotifier extends StateNotifier<AppLockState> {
  final PinService _pinService;
  final BiometricService _biometricService;
  final AppLockStorageService _storageService;

  AppLockNotifier({
    required PinService pinService,
    required BiometricService biometricService,
    required AppLockStorageService storageService,
  })  : _pinService = pinService,
        _biometricService = biometricService,
        _storageService = storageService,
        super(const AppLockStateUnlocked()) {
    // Initialize will be called separately after user is authenticated
  }

  /// Initialize app lock state after authentication
  ///
  /// Call this after user successfully authenticates (Google/Apple sign-in)
  /// to determine if PIN setup is required
  Future<void> initialize() async {
    await _storageService.init();

    final hasPinSetup = await _pinService.hasPinSetup();
    final isPinSetupComplete = await _storageService.isPinSetupComplete();

    if (kDebugMode) {
      debugPrint(
        '🔐 [AppLock] Initialize: hasPinSetup=$hasPinSetup, '
        'isPinSetupComplete=$isPinSetupComplete',
      );
    }

    if (!hasPinSetup || !isPinSetupComplete) {
      // First login or PIN not set up - require PIN setup
      state = const AppLockStatePinSetupRequired();
    } else {
      // PIN already set up - app is unlocked initially
      // (Lock screen will be shown on resume if needed)
      state = const AppLockStateUnlocked();
      // Clear last activity to start fresh
      await _storageService.clearLastActivity();
    }
  }

  /// Check if PIN setup is required
  Future<bool> isPinSetupRequired() async {
    final hasPinSetup = await _pinService.hasPinSetup();
    final isPinSetupComplete = await _storageService.isPinSetupComplete();
    return !hasPinSetup || !isPinSetupComplete;
  }

  /// Complete PIN setup
  ///
  /// Call this after user has successfully created their PIN
  Future<void> completePinSetup(String pin) async {
    await _pinService.savePin(pin);
    await _storageService.setPinSetupComplete(true);
    await _storageService.setAppLockEnabled(true);
    await _storageService.clearLastActivity();

    if (kDebugMode) {
      debugPrint('🔐 [AppLock] PIN setup completed');
    }

    state = const AppLockStateUnlocked();
  }

  /// Lock the app
  ///
  /// Called when app resumes after timeout or manually
  void lock() {
    if (state is AppLockStateUnlocked) {
      if (kDebugMode) {
        debugPrint('🔐 [AppLock] App locked');
      }
      state = const AppLockStateLocked();
    }
  }

  /// Attempt to unlock with PIN
  ///
  /// Returns true if unlock successful, false otherwise
  /// Handles failed attempt counting and lockout
  Future<bool> unlockWithPin(String pin) async {
    if (state is! AppLockStateLocked) return true; // Already unlocked

    final currentState = state as AppLockStateLocked;
    final isValid = await _pinService.verifyPin(pin);

    if (isValid) {
      if (kDebugMode) {
        debugPrint('🔐 [AppLock] PIN unlock successful');
      }
      await _storageService.clearLastActivity();
      state = const AppLockStateUnlocked();
      return true;
    } else {
      // Increment failed attempts
      final newState = currentState.withFailedAttempt();

      if (newState.failedAttempts >= AppLockStateLocked.maxFailedAttempts) {
        if (kDebugMode) {
          debugPrint('🔐 [AppLock] Max failed attempts - lockout triggered');
        }
        state = const AppLockStateLockout();
      } else {
        if (kDebugMode) {
          debugPrint(
            '🔐 [AppLock] PIN failed - ${newState.remainingAttempts} attempts remaining',
          );
        }
        state = newState;
      }
      return false;
    }
  }

  /// Attempt to unlock with biometrics
  ///
  /// Returns true if unlock successful, false otherwise
  Future<bool> unlockWithBiometrics() async {
    if (state is! AppLockStateLocked) return true; // Already unlocked

    final isBiometricEnabled = await _storageService.isBiometricEnabled();
    if (!isBiometricEnabled) {
      if (kDebugMode) {
        debugPrint('🔐 [AppLock] Biometric unlock not enabled');
      }
      return false;
    }

    final success = await _biometricService.authenticate(
      reason: 'Unlock Olvora',
    );

    if (success) {
      if (kDebugMode) {
        debugPrint('🔐 [AppLock] Biometric unlock successful');
      }
      await _storageService.clearLastActivity();
      state = const AppLockStateUnlocked();
      return true;
    }

    return false;
  }

  /// Check if app should be locked on resume
  ///
  /// Call this in app lifecycle handler when app resumes
  Future<bool> shouldLockOnResume() async {
    // Only lock if currently unlocked
    if (state is! AppLockStateUnlocked) return false;

    final shouldLock = await _storageService.shouldLock();
    return shouldLock;
  }

  /// Update last activity timestamp
  ///
  /// Call this when app goes to background
  Future<void> updateLastActivity() async {
    final isEnabled = await _storageService.isAppLockEnabled();
    if (isEnabled) {
      await _storageService.updateLastActivity();
    }
  }

  /// Reset to unlocked state (used after logout/re-auth)
  void reset() {
    state = const AppLockStateUnlocked();
  }

  /// Clear all app lock data (used during logout)
  Future<void> clearAll() async {
    await _pinService.clearPin();
    await _storageService.clearAll();
    state = const AppLockStateUnlocked();
    if (kDebugMode) {
      debugPrint('🔐 [AppLock] All data cleared');
    }
  }
}

/// App lock notifier provider
final appLockNotifierProvider =
    StateNotifierProvider<AppLockNotifier, AppLockState>((ref) {
  return AppLockNotifier(
    pinService: ref.watch(pinServiceProvider),
    biometricService: ref.watch(biometricServiceProvider),
    storageService: ref.watch(appLockStorageServiceProvider),
  );
});

// =============================================================================
// Convenience Providers
// =============================================================================

/// Provider to check if app is locked
final isAppLockedProvider = Provider<bool>((ref) {
  final state = ref.watch(appLockNotifierProvider);
  return state is AppLockStateLocked;
});

/// Provider to check if PIN setup is required
final isPinSetupRequiredProvider = Provider<bool>((ref) {
  final state = ref.watch(appLockNotifierProvider);
  return state is AppLockStatePinSetupRequired;
});

/// Provider to check if app is in lockout state
final isLockoutProvider = Provider<bool>((ref) {
  final state = ref.watch(appLockNotifierProvider);
  return state is AppLockStateLockout;
});

/// Provider for remaining attempts (when locked)
final remainingAttemptsProvider = Provider<int?>((ref) {
  final state = ref.watch(appLockNotifierProvider);
  if (state is AppLockStateLocked) {
    return state.remainingAttempts;
  }
  return null;
});

/// Provider to check if biometric is available and enabled
final isBiometricUnlockAvailableProvider = FutureProvider<bool>((ref) async {
  final biometricService = ref.watch(biometricServiceProvider);
  final storageService = ref.watch(appLockStorageServiceProvider);

  final isAvailable = await biometricService.isBiometricAvailable();
  if (!isAvailable) return false;

  await storageService.init();
  final isEnabled = await storageService.isBiometricEnabled();
  return isEnabled;
});

/// Provider for biometric type (for UI display)
final biometricTypeProvider = FutureProvider<BiometricType?>((ref) async {
  final biometricService = ref.watch(biometricServiceProvider);
  return biometricService.getPrimaryBiometricType();
});

/// Provider for app lock enabled state
final appLockEnabledProvider = FutureProvider<bool>((ref) async {
  final storageService = ref.watch(appLockStorageServiceProvider);
  await storageService.init();
  return storageService.isAppLockEnabled();
});

/// Provider for biometric enabled state
final biometricEnabledProvider = FutureProvider<bool>((ref) async {
  final storageService = ref.watch(appLockStorageServiceProvider);
  await storageService.init();
  return storageService.isBiometricEnabled();
});

/// Provider for lock timeout
final lockTimeoutProvider = FutureProvider<LockTimeout>((ref) async {
  final storageService = ref.watch(appLockStorageServiceProvider);
  await storageService.init();
  return storageService.getLockTimeout();
});

/// Provider to check if PIN has been set up
final hasPinSetupProvider = FutureProvider<bool>((ref) async {
  final pinService = ref.watch(pinServiceProvider);
  return pinService.hasPinSetup();
});
