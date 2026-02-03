import 'package:dio/dio.dart';

/// Parses technical errors into user-friendly messages
class ImportErrorParser {
  /// Convert any error to a user-friendly message
  static String parseError(dynamic error) {
    if (error is DioException) {
      return _parseDioError(error);
    }

    final errorString = error.toString();

    // Handle common error patterns
    if (errorString.contains('400') || errorString.contains('Bad Request')) {
      return 'The file format is invalid. Please check that your file has the correct columns (date, amount, description).';
    }

    if (errorString.contains('401') || errorString.contains('Unauthorized')) {
      return 'Please sign in to continue importing expenses.';
    }

    if (errorString.contains('403') || errorString.contains('Forbidden')) {
      return 'You don\'t have permission to import expenses.';
    }

    if (errorString.contains('404') || errorString.contains('Not Found')) {
      return 'The import service is temporarily unavailable. Please try again later.';
    }

    if (errorString.contains('500') ||
        errorString.contains('Internal Server Error')) {
      return 'Something went wrong on our end. Please try again in a few moments.';
    }

    if (errorString.contains('No data found') ||
        errorString.contains('No expenses found')) {
      return 'No expenses were found in your file. Please check that your file contains expense data.';
    }

    if (errorString.contains('Could not detect file structure')) {
      return 'We couldn\'t understand your file format. Please make sure your file has columns for date, amount, and description.';
    }

    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }

    // Default friendly message
    return 'Something went wrong while importing your file. Please try again or contact support if the problem persists.';
  }

  static String _parseDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The request took too long. Please check your internet connection and try again.';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;

        // Try to extract a user-friendly message from the response
        if (responseData is Map<String, dynamic>) {
          final message = responseData['message'] as String?;
          if (message != null && message.isNotEmpty) {
            return _cleanServerMessage(message);
          }

          // Check for validation errors
          final errors = responseData['errors'] as Map<String, dynamic>?;
          if (errors != null && errors.isNotEmpty) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              return _cleanServerMessage(firstError.first.toString());
            }
          }
        }

        // Status code specific messages
        switch (statusCode) {
          case 400:
            return 'The file data is invalid. Please check that all required fields (date, amount, description) are present and correctly formatted.';
          case 401:
            return 'Please sign in to continue importing expenses.';
          case 403:
            return 'You don\'t have permission to import expenses.';
          case 404:
            return 'The import service is temporarily unavailable. Please try again later.';
          case 422:
            return 'Some data in your file couldn\'t be processed. Please check that dates, amounts, and categories are valid.';
          case 500:
          case 502:
          case 503:
            return 'Our servers are experiencing issues. Please try again in a few moments.';
          default:
            return 'Unable to import your file. Please try again or contact support if the problem persists.';
        }

      case DioExceptionType.cancel:
        return 'The import was cancelled.';

      case DioExceptionType.connectionError:
        return 'Unable to connect to our servers. Please check your internet connection and try again.';

      case DioExceptionType.badCertificate:
        return 'There was a security issue connecting to our servers. Please try again.';

      case DioExceptionType.unknown:
      default:
        final message = error.message;
        if (message != null && message.contains('SocketException')) {
          return 'Unable to connect. Please check your internet connection and try again.';
        }
        return 'Something went wrong while importing. Please try again.';
    }
  }

  /// Clean up server error messages to be more user-friendly
  static String _cleanServerMessage(String message) {
    // Remove technical jargon
    message = message.replaceAll('RequestOptions.validateStatus', '');
    message = message.replaceAll('status code of', '');
    message = message.replaceAll('Read more about status codes at', '');
    message = message.replaceAll(RegExp(r'https?://[^\s]+'), '');
    message = message.replaceAll(RegExp(r'\d{3}'), '');

    // Clean up extra whitespace
    message = message.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Capitalize first letter
    if (message.isNotEmpty) {
      message = message[0].toUpperCase() + message.substring(1);
    }

    return message;
  }
}
