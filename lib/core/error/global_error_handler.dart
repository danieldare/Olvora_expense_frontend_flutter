
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Global error handling so the app never terminates from uncaught errors.
///
/// Responsibilities:
/// - Flutter framework errors (FlutterError.onError)
/// - Platform / async errors (PlatformDispatcher.instance.onError)
/// - Friendly error widget instead of red crash screen (ErrorWidget.builder)
/// - Zone error callback for runZonedGuarded
///
/// Call [install] once before [runApp]. Use [onZoneError] as the callback
/// for runZonedGuarded.
class GlobalErrorHandler {
  GlobalErrorHandler._();

  /// Installs global error handlers. Call once at startup before runApp.
  static void install() {
    _installFlutterErrorHandler();
    _installPlatformErrorHandler();
    _installFriendlyErrorWidget();
  }

  /// Callback for runZonedGuarded. Catches uncaught async errors so the app keeps running.
  static void onZoneError(Object error, StackTrace stack) {
    report(error, stack, context: 'zone');
  }

  /// Reports an error (e.g. to logs or crash analytics). Does not rethrow.
  static void report(Object error, StackTrace? stack, {required String context}) {
    if (kDebugMode) {
      debugPrint('[$context] Uncaught error: $error');
      if (stack != null) debugPrint('[$context] Stack: $stack');
    }
    // In production: report to crash analytics here; do not rethrow
  }

  static void _installFlutterErrorHandler() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (kDebugMode) {
        debugPrint('Flutter error: ${details.exception}');
        if (details.stack != null) debugPrint('Stack: ${details.stack}');
      }
      // Do not rethrow – app continues
    };
  }

  static void _installPlatformErrorHandler() {
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      report(error, stack, context: 'platform');
      return true; // We handled it; do not terminate the app
    };
  }

  static void _installFriendlyErrorWidget() {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return _FriendlyErrorWidget(details: details);
    };
  }
}

/// Non-crashing, user-friendly widget shown when a build/layout error occurs.
class _FriendlyErrorWidget extends StatelessWidget {
  const _FriendlyErrorWidget({required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.backgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please try again or restart the app.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
