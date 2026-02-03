/// Authentication failures - Domain Layer
///
/// Semantic failure types for authentication operations.
/// These represent WHAT went wrong, not HOW or WHERE.
///
/// CRITICAL: No strings, no HTTP codes, no SDK types.
/// Technical details stay in the data layer.
///
/// No Flutter dependencies.
sealed class AuthFailure {
  const AuthFailure();
}

/// Network connectivity failure
///
/// Represents: no internet, timeout, DNS failure, etc.
/// User action: Check connection and retry
class NetworkFailure extends AuthFailure {
  const NetworkFailure();
}

/// User cancelled the authentication flow
///
/// Represents: user dismissed sign-in dialog, pressed back, etc.
/// User action: None required (intentional)
class UserCancelledFailure extends AuthFailure {
  const UserCancelledFailure();
}

/// Authentication credentials rejected
///
/// Represents: invalid token, expired token, revoked access, etc.
/// User action: Try again or use different account
class UnauthorizedFailure extends AuthFailure {
  const UnauthorizedFailure();
}

/// Server-side error
///
/// Represents: 5xx errors, backend down, service unavailable
/// User action: Wait and retry later
class ServerFailure extends AuthFailure {
  const ServerFailure();
}

/// Unknown/unexpected authentication error
///
/// Represents: any error not covered by other failure types
/// User action: Contact support if persists
class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure();
}
