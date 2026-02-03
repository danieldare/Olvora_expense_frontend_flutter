import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'notification_detection_service.dart';
import 'notification_preferences_service.dart';
import 'expense_parsing/expense_parsing.dart';

/// Platform-specific service for notification/SMS detection
///
/// Handles:
/// - Platform channel communication
/// - Permission management
/// - State persistence
/// - Error handling and recovery
class PlatformNotificationService {
  static const MethodChannel _channel = MethodChannel(
    'com.trackspend/notifications',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.trackspend/notifications/stream',
  );

  StreamSubscription<dynamic>? _subscription;
  final NotificationDetectionService _detectionService =
      NotificationDetectionService();
  final NotificationPreferencesService _preferencesService =
      NotificationPreferencesService();

  bool _isInitialized = false;
  bool _isEnabled = false;

  /// Initialize the platform service
  /// Loads saved preferences and sets up listeners
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load saved enabled state
      _isEnabled = await _preferencesService.isEnabled();

      if (_isEnabled) {
        // Request permissions if needed
        final hasPermission = await checkPermission();
        if (!hasPermission) {
          final granted = await requestPermission();
          if (!granted) {
            _isEnabled = false;
            await _preferencesService.setEnabled(false);
            return;
          }
        }

        // Start listening to notifications/SMS
        _startListening();
        await _detectionService.enable();
      }

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing platform notification service: $e');
      }
      _isEnabled = false;
      await _preferencesService.setEnabled(false);
    }
  }

  /// Enable notification detection
  Future<bool> enable() async {
    if (_isEnabled) return true;

    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        final granted = await requestPermission();
        if (!granted) {
          return false;
        }
      }

      _isEnabled = true;
      await _preferencesService.setEnabled(true);
      await _detectionService.enable();
      _startListening();

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error enabling notification detection: $e');
      }
      _isEnabled = false;
      await _preferencesService.setEnabled(false);
      return false;
    }
  }

  /// Disable notification detection
  Future<void> disable() async {
    if (!_isEnabled) return;

    try {
      _isEnabled = false;
      await _preferencesService.setEnabled(false);
      _detectionService.disable();
      stop();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error disabling notification detection: $e');
      }
    }
  }

  /// Check if notification detection is enabled
  bool get isEnabled => _isEnabled;

  /// Check if permission is granted
  Future<bool> checkPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkPermission');
      return result ?? false;
    } on MissingPluginException {
      if (kDebugMode) {
        debugPrint(
          '⚠️ Platform channel not available. Please rebuild the app after adding native code.',
        );
      }
      return false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Platform error checking permission: ${e.message}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking permission: $e');
      }
      return false;
    }
  }

  /// Request permission
  Future<bool> requestPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermission');
      return result ?? false;
    } on MissingPluginException {
      if (kDebugMode) {
        debugPrint(
          '⚠️ Platform channel not available. Please rebuild the app after adding native code.',
        );
      }
      return false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Platform error requesting permission: ${e.message}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error requesting permission: $e');
      }
      return false;
    }
  }

  /// Open system settings for notification access
  Future<void> openSettings() async {
    try {
      await _channel.invokeMethod('openSettings');
    } on MissingPluginException {
      if (kDebugMode) {
        debugPrint(
          '⚠️ Platform channel not available. Please rebuild the app after adding native code.',
        );
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Platform error opening settings: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error opening settings: $e');
      }
    }
  }

  /// Start listening to notifications
  void _startListening() {
    _subscription?.cancel();

    try {
      _subscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map) {
            final title = event['title'] as String? ?? '';
            final body = event['body'] as String? ?? '';
            final packageName = event['packageName'] as String?;

            // Validate input
            if (title.isEmpty && body.isEmpty) return;

            // Process the notification through detection service
            _detectionService.processNotification(
              title,
              body,
              packageName: packageName,
            );
          }
        },
        onError: (error) {
          if (kDebugMode) {
            if (error is MissingPluginException) {
              debugPrint(
                '⚠️ Platform channel not available. Please rebuild the app after adding native code.',
              );
            } else if (error is PlatformException) {
              debugPrint('❌ Platform error: ${error.message}');
            } else {
              debugPrint('❌ Error listening to notifications: $error');
            }
          }
        },
        cancelOnError: false, // Continue listening even on error
      );
    } on MissingPluginException {
      if (kDebugMode) {
        debugPrint(
          '⚠️ Platform channel not available. Please rebuild the app after adding native code.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error starting notification listener: $e');
      }
    }
  }

  /// Stop listening
  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Get the parsed expense results stream (preferred - use this for new code)
  Stream<ParsedExpenseResult> get expenseResults =>
      _detectionService.expenseResults;

  /// Get the detection service stream (legacy - for backward compatibility)
  @Deprecated('Use expenseResults instead')
  Stream<DetectedExpense> get detectedExpenses =>
      // ignore: deprecated_member_use_from_same_package
      _detectionService.detectedExpenses;

  /// Reload preferences and reinitialize if needed
  Future<void> reload() async {
    final wasEnabled = _isEnabled;
    _isInitialized = false;
    await initialize();

    // If state changed, update accordingly
    if (wasEnabled != _isEnabled) {
      if (_isEnabled) {
        await enable();
      } else {
        await disable();
      }
    }
  }

  void dispose() {
    stop();
    _detectionService.dispose();
  }
}
