import '../../domain/failures/auth_failure.dart';

/// Maps domain failures to user-friendly messages - Presentation Layer
///
/// This is the ONLY place where failure types are converted to strings.
/// Messages should be:
/// - User-friendly (no technical jargon)
/// - Actionable (tell user what to do)
/// - Localization-ready (could be keys instead of strings)
class AuthFailureMessageMapper {
  const AuthFailureMessageMapper._();

  /// Map [AuthFailure] to user-friendly message
  static String mapToMessage(AuthFailure failure) {
    return switch (failure) {
      NetworkFailure() =>
        'Unable to connect. Please check your internet connection and try again.',
      UserCancelledFailure() =>
        'Sign in was cancelled.',
      UnauthorizedFailure() =>
        'Authentication failed. Please check your credentials and try again. If you\'re registering, the email may already be in use.',
      ServerFailure() =>
        'Our servers are temporarily unavailable. Please try again later.',
      UnknownAuthFailure() =>
        'Sign-in didn\'t complete. Tap "Continue with Google" again to retry. If it keeps failing, check your connection or try a different sign-in method.',
    };
  }

  /// Check if the failure should be shown to the user
  ///
  /// Some failures (like user cancellation) don't need to be displayed.
  static bool shouldShowError(AuthFailure failure) {
    return switch (failure) {
      UserCancelledFailure() => false, // User intentionally cancelled
      _ => true,
    };
  }
}
