import 'package:dio/dio.dart';

/// Utility for handling auth-related errors in API calls
///
/// This is a simplified handler for non-auth features that need
/// to detect authentication failures in API responses.
class AuthErrorHandler {
  /// Check if the error is an authentication error (401/403)
  static bool isAuthError(dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      return statusCode == 401 || statusCode == 403;
    }
    return false;
  }

  /// Handle auth error - logs error and throws exception
  ///
  /// Generic method that returns a Future of the expected type.
  /// Used in providers to handle auth errors and return empty results.
  static Future<T> handleAuthError<T>(
    dynamic error,
    StackTrace stackTrace, {
    String? tag,
  }) async {
    // Log the error if needed
    if (tag != null) {
      // Could add logging here
    }
    // Throw an exception with the auth error message
    throw Exception(getAuthErrorMessage(error));
  }

  /// Get user-friendly error message for auth errors
  static String getAuthErrorMessage([dynamic error]) {
    if (error != null && error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        return 'Your session has expired. Please log in again.';
      }
      if (statusCode == 403) {
        return 'You do not have permission to perform this action.';
      }
    }
    return 'Your session has expired. Please log in again.';
  }

  /// Extract error message from various error types
  static String extractErrorMessage(dynamic error) {
    if (error is DioException) {
      // Try to get message from response data
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final message = responseData['message'] ?? responseData['error'];
        if (message != null) {
          return message.toString();
        }
      }
      // Fallback to status message or generic error
      return error.response?.statusMessage ?? error.message ?? 'Request failed';
    }
    return error?.toString() ?? 'An unexpected error occurred';
  }
}
