/// Technical exceptions for auth operations - Data Layer
///
/// These are INTERNAL to the data layer.
/// They are caught by the repository and mapped to domain failures.
///
/// CRITICAL: These must NEVER escape the data layer.
/// UI and domain code should never see these.
library;

/// Base class for auth-related exceptions
sealed class AuthException implements Exception {
  final String message;
  final Object? cause;

  const AuthException(this.message, [this.cause]);

  @override
  String toString() => '$runtimeType: $message';
}

/// User cancelled the sign-in flow
class SignInCancelledException extends AuthException {
  const SignInCancelledException([super.message = 'Sign-in was cancelled']);
}

/// Network connectivity issue
class NetworkException extends AuthException {
  const NetworkException([super.message = 'Network error', super.cause]);
}

/// Server returned an error response
class ServerException extends AuthException {
  final int? statusCode;

  const ServerException({
    String message = 'Server error',
    this.statusCode,
    Object? cause,
  }) : super(message, cause);
}

/// Invalid or expired credentials
class UnauthorizedException extends AuthException {
  const UnauthorizedException([super.message = 'Unauthorized', super.cause]);
}

/// Secure storage operation failed
class StorageException extends AuthException {
  const StorageException([super.message = 'Storage error', super.cause]);
}

/// Google Sign-In SDK error
class GoogleSignInException extends AuthException {
  const GoogleSignInException([
    super.message = 'Google Sign-In error',
    super.cause,
  ]);
}

/// Apple Sign-In SDK error
class AppleSignInException extends AuthException {
  const AppleSignInException([
    super.message = 'Apple Sign-In error',
    super.cause,
  ]);
}

/// Firebase Auth error
class FirebaseAuthException extends AuthException {
  final String? code;

  const FirebaseAuthException({
    String message = 'Firebase Auth error',
    this.code,
    Object? cause,
  }) : super(message, cause);
}
