import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/state/auth_state.dart';
import '../../features/user_preferences/presentation/providers/user_preferences_providers.dart';

const _onboardingCompletedKey = 'onboarding_completed';

/// Provider that checks if onboarding has been completed
///
/// Logic:
/// - For authenticated users: checks server (UserPreferences API) first, falls back to local
/// - For unauthenticated users: checks local SharedPreferences only
///
/// This ensures:
/// - Cross-device sync: logging in on new device fetches status from server
/// - Offline support: local cache works when server is unavailable
/// - New users: default to false (show onboarding)
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final authState = ref.watch(authNotifierProvider);

  // For authenticated users, try to fetch from server first
  if (authState is AuthStateAuthenticated) {
    try {
      final userPrefs = await ref.watch(userPreferencesProvider.future);
      final serverValue = userPrefs.onboardingCompleted;

      if (kDebugMode) {
        debugPrint('🎯 [Onboarding] Server value: $serverValue');
      }

      // Sync server value to local cache
      if (serverValue) {
        await _setLocalOnboardingCompleted(true);
      }

      return serverValue;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🎯 [Onboarding] Server fetch failed, using local: $e');
      }
      // Fall back to local if server fails
      return await _getLocalOnboardingCompleted();
    }
  }

  // For unauthenticated users, use local storage only
  return await _getLocalOnboardingCompleted();
});

/// Provider to mark onboarding as completed
///
/// This marks completion both locally and on the server (if authenticated).
/// Local is always updated first for immediate effect.
final markOnboardingCompletedProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    // Always update local first (immediate effect)
    await _setLocalOnboardingCompleted(true);

    if (kDebugMode) {
      debugPrint('🎯 [Onboarding] Marked complete locally');
    }

    // If authenticated, also sync to server
    final authState = ref.read(authNotifierProvider);
    if (authState is AuthStateAuthenticated) {
      try {
        final service = ref.read(userPreferencesServiceProvider);
        await service.markOnboardingCompleted();

        if (kDebugMode) {
          debugPrint('🎯 [Onboarding] Synced to server');
        }
      } catch (e) {
        // Server sync failed, but local is updated
        // Will retry on next app launch when authenticated
        if (kDebugMode) {
          debugPrint('🎯 [Onboarding] Server sync failed (will retry): $e');
        }
      }
    }

    // Invalidate to refresh the completed status
    ref.invalidate(onboardingCompletedProvider);
  };
});

/// Syncs local onboarding status to server
///
/// Called when user authenticates to ensure server has the correct value.
/// If local says completed but server says not, we update server.
final syncOnboardingToServerProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthStateAuthenticated) {
      return; // Can't sync without auth
    }

    try {
      final localCompleted = await _getLocalOnboardingCompleted();
      final serverPrefs = await ref.read(userPreferencesProvider.future);
      final serverCompleted = serverPrefs.onboardingCompleted;

      if (kDebugMode) {
        debugPrint('🎯 [Onboarding] Sync check - Local: $localCompleted, Server: $serverCompleted');
      }

      // If local is true but server is false, sync to server
      if (localCompleted && !serverCompleted) {
        final service = ref.read(userPreferencesServiceProvider);
        await service.markOnboardingCompleted();

        if (kDebugMode) {
          debugPrint('🎯 [Onboarding] Synced local→server (marked complete)');
        }
      }

      // If server is true but local is false, sync to local
      if (serverCompleted && !localCompleted) {
        await _setLocalOnboardingCompleted(true);

        if (kDebugMode) {
          debugPrint('🎯 [Onboarding] Synced server→local (marked complete)');
        }
      }

      // Invalidate to refresh
      ref.invalidate(onboardingCompletedProvider);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🎯 [Onboarding] Sync failed: $e');
      }
    }
  };
});

// ============================================================================
// Local Storage Helpers
// ============================================================================

Future<bool> _getLocalOnboardingCompleted() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_onboardingCompletedKey) ?? false;
}

Future<void> _setLocalOnboardingCompleted(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_onboardingCompletedKey, value);
}
