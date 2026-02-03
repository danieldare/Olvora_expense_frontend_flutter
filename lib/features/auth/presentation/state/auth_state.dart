import '../../domain/entities/auth_session.dart';
import '../../domain/failures/auth_failure.dart';

/// Authentication state - Presentation Layer
///
/// State Machine:
/// Initializing → (Unauthenticated | Authenticated)
/// Unauthenticated → Authenticating → EstablishingSession → Authenticated
///
/// Represents the current authentication state for UI consumption.
/// Uses sealed class for exhaustive pattern matching.
sealed class AuthState {
  const AuthState();
}

/// Initializing state - app startup/boot phase
///
/// CRITICAL: This is the initial state on app start and hot restart.
/// SplashScreen is shown during this state.
/// After auth checks complete, transitions to either Authenticated or Unauthenticated.
/// This state ensures SplashScreen is always shown first, preventing flicker.
class AuthStateInitializing extends AuthState {
  const AuthStateInitializing();
}

/// Unauthenticated state - user is not logged in
class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

/// Authenticating state - Firebase sign-in in progress
class AuthStateAuthenticating extends AuthState {
  const AuthStateAuthenticating();
}

/// Establishing session state - fetching ID token, calling /auth/session, storing token
///
/// This state ensures the token is available before marking user as authenticated.
/// Prevents race conditions where API calls happen before token is ready.
class AuthStateEstablishingSession extends AuthState {
  const AuthStateEstablishingSession();
}

/// Logging out state - logout in progress
///
/// CRITICAL: During this state, all API requests must be blocked.
/// This prevents race conditions where API calls happen during logout cleanup.
class AuthStateLoggingOut extends AuthState {
  const AuthStateLoggingOut();
}

/// Authenticated state - user is logged in
/// Token is available and stored.
class AuthStateAuthenticated extends AuthState {
  final AuthSession session;

  const AuthStateAuthenticated(this.session);

  /// Convenience getters for UI
  String get userId => session.userId;
  String get email => session.email;
}

/// Grace period state - user is authenticated but account is pending deletion
///
/// Shown immediately after session establishment when account is pending_deletion,
/// so we never show HOME for such accounts.
class AuthStateGracePeriod extends AuthState {
  final AuthSession session;
  final int daysRemaining;
  final bool canRestore;
  final bool canStartAfresh;
  final DateTime? recoveryDeadline;
  final DateTime? deletedAt;

  const AuthStateGracePeriod({
    required this.session,
    required this.daysRemaining,
    this.canRestore = true,
    this.canStartAfresh = true,
    this.recoveryDeadline,
    this.deletedAt,
  });

  String get userId => session.userId;
  String get email => session.email;
}

/// Error state - authentication operation failed
class AuthStateError extends AuthState {
  final AuthFailure failure;
  final String message;

  const AuthStateError({required this.failure, required this.message});
}
