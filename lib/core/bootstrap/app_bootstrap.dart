import 'dart:async';

import 'package:flutter/material.dart';

import '../error/global_error_handler.dart';

/// App startup: binding, error handling, and running the app in a guarded zone.
///
/// Single responsibility: ensure the app is initialized correctly and runs
/// inside runZonedGuarded so uncaught errors are handled and the app does not terminate.
///
/// Font Loading Strategy:
/// Fonts declared in pubspec.yaml with explicit weights are automatically bundled
/// and registered by Flutter. No manual FontLoader is needed - in fact, using
/// FontLoader without weight specification would override the correct weight
/// mappings and cause fonts to not render with proper weights.
class AppBootstrap {
  AppBootstrap._();

  /// Runs the app with world-class initialization and error handling.
  ///
  /// 1. Ensures Flutter binding is initialized.
  /// 2. Installs global error handlers (FlutterError, PlatformDispatcher, ErrorWidget).
  /// 3. Runs [runApp] inside runZonedGuarded so async errors are caught.
  ///
  /// Note: Fonts are NOT loaded manually here. Fonts declared in pubspec.yaml
  /// with weight mappings are automatically available. Manual FontLoader usage
  /// would break the weight mappings (FontLoader doesn't support weights).
  static void run(void Function() runApp) {
    runZonedGuarded<Future<void>>(() async {
      WidgetsFlutterBinding.ensureInitialized();
      GlobalErrorHandler.install();
      runApp();
    }, GlobalErrorHandler.onZoneError);
  }
}
