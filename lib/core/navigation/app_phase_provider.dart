import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Application lifecycle phase enum
///
/// CRITICAL: This represents the one-way lifecycle of the application.
/// Once the app transitions from `bootstrapping` to `running`, it can NEVER go back.
///
/// - `bootstrapping`: Initial app process startup, auth resolution, share intent handling
/// - `running`: Steady-state app lifetime, all normal operations
enum AppPhase {
  /// Initial app startup phase
  ///
  /// During this phase:
  /// - SplashScreen is shown
  /// - Auth state is being resolved
  /// - Share intents and deep links are handled
  /// - App is determining initial navigation destination
  bootstrapping,

  /// Steady-state app lifetime
  ///
  /// During this phase:
  /// - SplashScreen is PERMANENTLY removed from widget tree
  /// - AuthenticatedApp or UnauthenticatedApp handles all navigation
  /// - Token refresh, logout, login, resume operations occur
  /// - SplashScreen is structurally unreachable
  running,
}

/// StateNotifier that manages application phase transitions
///
/// CRITICAL: Phase transitions are ONE-WAY only (bootstrapping → running).
/// There is NO API to revert to bootstrapping. This ensures SplashScreen
/// is structurally impossible to reappear after initialization.
class AppPhaseNotifier extends StateNotifier<AppPhase> {
  AppPhaseNotifier() : super(AppPhase.bootstrapping);

  /// Transition from bootstrapping to running phase
  ///
  /// CRITICAL: This is a write-once, idempotent operation.
  /// - Can only be called when phase is `bootstrapping`
  /// - After transition, phase is permanently `running`
  /// - Multiple calls are safe (idempotent)
  ///
  /// This should be called when:
  /// - Auth state reaches a terminal state (Authenticated or Unauthenticated)
  /// - Initial navigation destination is determined
  /// - Share intents are resolved (if any)
  void transitionToRunning() {
    if (state == AppPhase.bootstrapping) {
      state = AppPhase.running;
    }
    // If already running, do nothing (idempotent)
  }

  /// Check if app is in bootstrapping phase
  bool get isBootstrapping => state == AppPhase.bootstrapping;

  /// Check if app is in running phase
  bool get isRunning => state == AppPhase.running;
}

/// Provider for application phase state
final appPhaseNotifierProvider =
    StateNotifierProvider<AppPhaseNotifier, AppPhase>((ref) {
      return AppPhaseNotifier();
    });

/// Convenience provider to check current app phase
final appPhaseProvider = Provider<AppPhase>((ref) {
  return ref.watch(appPhaseNotifierProvider);
});

/// Convenience provider to check if app is bootstrapping
final isBootstrappingProvider = Provider<bool>((ref) {
  return ref.watch(appPhaseProvider) == AppPhase.bootstrapping;
});

/// Convenience provider to check if app is running
final isRunningProvider = Provider<bool>((ref) {
  return ref.watch(appPhaseProvider) == AppPhase.running;
});
