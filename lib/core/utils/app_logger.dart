import 'package:flutter/foundation.dart';

/// Production-safe logging utility.
///
/// In release builds, all logging is stripped by Dart's tree-shaking
/// when using this wrapper instead of raw print() statements.
///
/// Usage:
/// ```dart
/// AppLogger.d('Debug message');
/// AppLogger.i('Info message');
/// AppLogger.w('Warning message');
/// AppLogger.e('Error message', error: exception, stackTrace: stack);
/// ```
class AppLogger {
  static const String _tag = 'Olvora';

  /// Debug log - only in debug mode
  static void d(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] $message');
    }
  }

  /// Info log - only in debug mode
  static void i(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('ℹ️ [$_tag${tag != null ? ':$tag' : ''}] $message');
    }
  }

  /// Warning log - only in debug mode
  static void w(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('⚠️ [$_tag${tag != null ? ':$tag' : ''}] $message');
    }
  }

  /// Error log - only in debug mode
  static void e(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      debugPrint('❌ [$_tag${tag != null ? ':$tag' : ''}] $message');
      if (error != null) {
        debugPrint('   Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('   Stack: $stackTrace');
      }
    }
  }

  /// Log only in debug mode with custom prefix
  static void log(String message, {String prefix = ''}) {
    if (kDebugMode) {
      debugPrint('$prefix$message');
    }
  }
}

/// Extension to conditionally execute code only in debug mode
extension DebugOnly on void Function() {
  void debugOnly() {
    if (kDebugMode) {
      this();
    }
  }
}
