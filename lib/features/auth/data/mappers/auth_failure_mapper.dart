import '../../domain/failures/auth_failure.dart';
import '../exceptions/auth_exceptions.dart';

/// Maps technical exceptions to domain failures - Data Layer
///
/// CRITICAL: This is the boundary where technical details are transformed
/// into semantic domain failures that the rest of the app understands.
///
/// Technical exceptions NEVER escape this mapper.
class AuthFailureMapper {
  const AuthFailureMapper._();

  /// Map any exception to an appropriate [AuthFailure]
  ///
  /// Also extracts and stores the exception message for use in error messages.
  /// The message can be accessed via [getLastExceptionMessage()].
  ///
  /// Mapping rules:
  /// - [SignInCancelledException] → [UserCancelledFailure]
  /// - [NetworkException] → [NetworkFailure]
  /// - [UnauthorizedException] → [UnauthorizedFailure]
  /// - [ServerException] with 5xx → [ServerFailure]
  /// - Everything else → [UnknownAuthFailure]
  static String? _lastExceptionMessage;

  /// Get the last exception message that was mapped
  /// This allows the notifier to use specific error messages from exceptions
  static String? getLastExceptionMessage() => _lastExceptionMessage;

  static AuthFailure mapException(Object exception) {
    // Extract exception message if it's an AuthException
    if (exception is AuthException) {
      _lastExceptionMessage = exception.message;
      return _mapAuthException(exception);
    }

    // Handle common Dart/Flutter exceptions
    if (exception is FormatException) {
      _lastExceptionMessage = exception.message;
      return const ServerFailure(); // Invalid response format
    }

    if (exception is TypeError) {
      _lastExceptionMessage = exception.toString();
      return const ServerFailure(); // Invalid data type
    }

    // Extract message from exception toString
    _lastExceptionMessage = exception.toString();
    
    // Catch-all for unknown exceptions
    return const UnknownAuthFailure();
  }

  /// Map [AuthException] subtypes to domain failures
  static AuthFailure _mapAuthException(AuthException exception) {
    // Extract exception message for use in error messages
    _lastExceptionMessage = exception.message;
    
    return switch (exception) {
      SignInCancelledException() => const UserCancelledFailure(),
      NetworkException() => const NetworkFailure(),
      UnauthorizedException() => const UnauthorizedFailure(),
      ServerException(statusCode: final code)
          when code != null && code >= 500 =>
        const ServerFailure(),
      ServerException() => const ServerFailure(),
      StorageException() => const UnknownAuthFailure(),
      GoogleSignInException() => _mapGoogleSignInException(exception),
      AppleSignInException() => const UnknownAuthFailure(),
      FirebaseAuthException(code: final code) => _mapFirebaseAuthCode(code),
    };
  }

  /// Map Google Sign-In exceptions to appropriate failures
  static AuthFailure _mapGoogleSignInException(
    GoogleSignInException exception,
  ) {
    final message = exception.message.toLowerCase();
    final causeString = exception.cause?.toString().toLowerCase() ?? '';
    final errorString = '$message $causeString';

    // Check for network-related errors
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('unreachable') ||
        errorString.contains('socket')) {
      return const NetworkFailure();
    }

    // Check for authentication/authorization errors (including getTokenWithDetails)
    if (errorString.contains('unauthorized') ||
        errorString.contains('invalid') ||
        errorString.contains('credential') ||
        errorString.contains('token') ||
        errorString.contains('gettokenwithdetails') ||
        errorString.contains('authentication')) {
      return const UnauthorizedFailure();
    }

    // Check for Google Play Services errors
    if (errorString.contains('play services') ||
        errorString.contains('api_not_available') ||
        errorString.contains('sign_in_failed')) {
      return const ServerFailure();
    }

    // Default to unknown for other Google Sign-In errors
    return const UnknownAuthFailure();
  }

  /// Map Firebase Auth error codes to domain failures
  static AuthFailure _mapFirebaseAuthCode(String? code) {
    return switch (code) {
      'user-disabled' => const UnauthorizedFailure(),
      'user-not-found' => const UnauthorizedFailure(),
      'wrong-password' => const UnauthorizedFailure(),
      'invalid-credential' => const UnauthorizedFailure(),
      'account-exists-with-different-credential' => const UnauthorizedFailure(),
      'network-request-failed' => const NetworkFailure(),
      'too-many-requests' => const ServerFailure(),
      _ => const UnknownAuthFailure(),
    };
  }
}
