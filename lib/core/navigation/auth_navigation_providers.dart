import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/state/auth_state.dart';
import '../../features/app_lock/presentation/providers/app_lock_providers.dart';
import '../../features/app_lock/domain/entities/app_lock_state.dart';
import '../../core/providers/app_providers.dart';
import '../providers/api_providers_v2.dart';
import 'app_phase_provider.dart';

/// Auth destination enum for navigation
enum AuthDestination { splash, auth, pinSetup, home, gracePeriod }

/// Provider that determines the current navigation destination based on auth state
///
/// CRITICAL: Navigation logic must handle loading states carefully:
/// - AuthStateInitializing = startup/boot phase, show splash ONLY during bootstrapping
/// - AuthStateUnauthenticated = not logged in, go to auth
/// - AuthStateAuthenticating = operation in progress, stay on auth screen
/// - AuthStateEstablishingSession = fetching token, show splash ONLY during bootstrapping
/// - AuthStateAuthenticated = logged in, go to home (if token available)
/// - AuthStateError = error, go to auth (show error there)
/// - AuthStateLoggingOut = logout in progress, stay on current screen
///
/// CRITICAL: SplashScreen is shown ONLY during `bootstrapping` phase.
/// After app transitions to `running` phase, SplashScreen is PERMANENTLY removed.
/// This ensures splash is structurally impossible to reappear after initialization.
final authNavigationProvider = Provider<AuthDestination>((ref) {
  final firebaseState = ref.watch(firebaseInitializationProvider);
  final authState = ref.watch(authNotifierProvider);
  final appPhase = ref.watch(appPhaseProvider);

  // CRITICAL: This provider is PURE - it only computes navigation destination.
  // Phase transitions are handled by a listener in AppRoot (see app_root.dart).
  // This ensures providers remain pure and don't violate Riverpod rules.

  if (kDebugMode) {
    debugPrint('🧭 [Navigation] Firebase loading: ${firebaseState.isLoading}');
    debugPrint('🧭 [Navigation] AuthState: ${authState.runtimeType}');
  }

  // PRIORITY 1: Initializing state - show splash ONLY during bootstrapping phase
  // CRITICAL: SplashScreen exists ONLY in bootstrapping phase.
  // Once app transitions to running phase, splash is structurally unreachable.
  if (authState is AuthStateInitializing) {
    if (appPhase == AppPhase.bootstrapping) {
      if (kDebugMode) {
        debugPrint(
          '🧭 [Navigation] → SPLASH (initializing during bootstrapping)',
        );
      }
      return AuthDestination.splash;
    } else {
      // App is in running phase - splash is unreachable, navigate to auth
      if (kDebugMode) {
        debugPrint('🧭 [Navigation] → AUTH (initializing but app is running)');
      }
      return AuthDestination.auth;
    }
  }

  // PRIORITY 2: EstablishingSession - show splash ONLY during bootstrapping phase
  // CRITICAL: SplashScreen exists ONLY in bootstrapping phase.
  // During running phase, session establishment shows auth screen (user login).
  if (authState is AuthStateEstablishingSession) {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    // During bootstrapping phase AND startup, show splash
    if (appPhase == AppPhase.bootstrapping && authNotifier.isStartupPhase) {
      if (kDebugMode) {
        debugPrint(
          '🧭 [Navigation] → SPLASH (establishing session during bootstrapping)',
        );
      }
      return AuthDestination.splash;
    } else {
      // Either app is running OR user-initiated login - show auth screen
      if (kDebugMode) {
        if (appPhase == AppPhase.running) {
          debugPrint(
            '🧭 [Navigation] → AUTH (establishing session but app is running)',
          );
        } else {
          debugPrint(
            '🧭 [Navigation] → AUTH (establishing session - user login)',
          );
        }
      }
      return AuthDestination.auth;
    }
  }

  // PRIORITY 3: Grace period - account pending deletion (show grace period, never HOME)
  if (authState is AuthStateGracePeriod) {
    if (kDebugMode) {
      debugPrint('🧭 [Navigation] → GRACE_PERIOD (account pending deletion)');
    }
    return AuthDestination.gracePeriod;
  }

  // PRIORITY 4: Authenticated state - check PIN setup, then go to home if token available
  // CRITICAL: Phase transition is handled centrally above.
  // This branch only determines navigation destination.
  if (authState is AuthStateAuthenticated) {
    // Check if token is available before navigating to home
    // This ensures API calls will work immediately
    final tokenManager = ref.read(tokenManagerServiceProvider);
    final hasToken = tokenManager.hasToken;

    if (hasToken) {
      // Check if PIN setup is required
      final appLockState = ref.watch(appLockNotifierProvider);
      if (appLockState is AppLockStatePinSetupRequired) {
        if (kDebugMode) {
          debugPrint('🧭 [Navigation] → PIN_SETUP (authenticated, PIN required)');
        }
        return AuthDestination.pinSetup;
      }

      if (kDebugMode) {
        debugPrint('🧭 [Navigation] → HOME (authenticated with token)');
      }
      return AuthDestination.home;
    } else {
      // Token not available yet - show auth screen to prevent 401 errors
      if (kDebugMode) {
        debugPrint('🧭 [Navigation] → AUTH (authenticated but no token)');
      }
      return AuthDestination.auth;
    }
  }

  // PRIORITY 4: Wait for Firebase to initialize - show splash ONLY during bootstrapping
  // CRITICAL: SplashScreen exists ONLY in bootstrapping phase.
  // During running phase, Firebase loading shows auth screen.
  if (firebaseState.isLoading) {
    if (appPhase == AppPhase.bootstrapping) {
      if (kDebugMode) {
        debugPrint(
          '🧭 [Navigation] → SPLASH (Firebase loading during bootstrapping)',
        );
      }
      return AuthDestination.splash;
    } else {
      // App is running - splash is unreachable, show auth
      if (kDebugMode) {
        debugPrint(
          '🧭 [Navigation] → AUTH (Firebase loading but app is running)',
        );
      }
      return AuthDestination.auth;
    }
  }

  // PRIORITY 5: If Firebase failed, still check auth state (graceful degradation)
  if (firebaseState.hasError || firebaseState.value == false) {
    // If authenticated, still allow home (graceful degradation)
    if (authState is AuthStateAuthenticated) {
      return AuthDestination.home;
    }
    return AuthDestination.auth;
  }

  // PRIORITY 6: For all other states (Unauthenticated, Authenticating, Error, LoggingOut) - show auth screen
  // CRITICAL: Phase transition is handled centrally above for terminal states.
  // This branch handles non-terminal states and determines navigation destination.
  // AuthStateAuthenticating: user initiated login, stay on auth screen (it shows loading indicator)
  // AuthStateUnauthenticated: user is not logged in (terminal - phase transition handled above)
  // AuthStateError: show auth screen with error message (terminal - phase transition handled above)
  // AuthStateLoggingOut: stay on current screen (usually auth)

  if (kDebugMode) {
    debugPrint('🧭 [Navigation] → AUTH (${authState.runtimeType})');
  }
  return AuthDestination.auth;
});
