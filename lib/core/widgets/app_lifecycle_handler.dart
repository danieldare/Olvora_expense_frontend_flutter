import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/clipboard_monitor_service.dart';
import '../providers/notification_detection_providers.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/state/auth_state.dart';
import '../../features/app_lock/presentation/providers/app_lock_providers.dart';

/// Widget that handles app lifecycle events for notification detection
///
/// Features:
/// - Monitors clipboard when app becomes active (for SMS workaround)
/// - Reinitializes notification service on app resume
/// - Handles app state changes gracefully
class AppLifecycleHandler extends ConsumerStatefulWidget {
  final Widget child;

  const AppLifecycleHandler({super.key, required this.child});

  @override
  ConsumerState<AppLifecycleHandler> createState() =>
      _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends ConsumerState<AppLifecycleHandler>
    with WidgetsBindingObserver {
  final ClipboardMonitorService _clipboardService = ClipboardMonitorService();
  bool _isMonitoringClipboard = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // CRITICAL: Set auth check callback to prevent navigation during auth flows
    _clipboardService.setAuthCheckCallback(() => _isAuthenticated());

    _checkClipboardOnStart();
  }

  @override
  void dispose() {
    // Clear auth check callback on dispose
    _clipboardService.clearAuthCheckCallback();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - check clipboard and reinitialize services
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        // App went to background
        _onAppPaused();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is inactive or hidden
        break;
    }
  }

  Future<void> _checkClipboardOnStart() async {
    // Small delay to ensure app is fully initialized
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      await _checkClipboardIfEnabled();
    }
  }

  /// Check if user is authenticated
  ///
  /// CRITICAL: Clipboard monitoring must only run when user is authenticated.
  /// This prevents navigation during login/logout flows.
  bool _isAuthenticated() {
    final authState = ref.read(authNotifierProvider);
    return authState is AuthStateAuthenticated;
  }

  Future<void> _onAppResumed() async {
    // Check if app should be locked on resume
    await _checkAppLockOnResume();

    // Refresh state to ensure it's in sync
    try {
      final stateNotifier = ref.read(
        notificationDetectionStateProvider.notifier,
      );
      await stateNotifier.refresh();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error refreshing notification state: $e');
      }
    }

    // Check clipboard when app comes to foreground
    // This catches SMS that user copied while app was closed
    await _checkClipboardIfEnabled();

    // Reinitialize notification service to ensure it's active
    try {
      final notificationService = ref.read(platformNotificationServiceProvider);
      await notificationService.reload();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error reloading notification service: $e');
      }
    }
  }

  void _onAppPaused() {
    // App went to background - update last activity for app lock timeout
    _updateAppLockLastActivity();
  }

  /// Check if app should be locked on resume
  ///
  /// CRITICAL: Only check when user is authenticated
  Future<void> _checkAppLockOnResume() async {
    if (!_isAuthenticated()) return;

    try {
      final appLockNotifier = ref.read(appLockNotifierProvider.notifier);
      final shouldLock = await appLockNotifier.shouldLockOnResume();

      if (shouldLock) {
        if (kDebugMode) {
          debugPrint('🔐 [Lifecycle] Locking app on resume (timeout exceeded)');
        }
        appLockNotifier.lock();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error checking app lock on resume: $e');
      }
    }
  }

  /// Update last activity timestamp when app goes to background
  void _updateAppLockLastActivity() {
    if (!_isAuthenticated()) return;

    try {
      ref.read(appLockNotifierProvider.notifier).updateLastActivity();
      if (kDebugMode) {
        debugPrint('🔐 [Lifecycle] Updated last activity timestamp');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error updating last activity: $e');
      }
    }
  }

  Future<void> _checkClipboardIfEnabled() async {
    try {
      // CRITICAL: Only check clipboard when user is authenticated
      // This prevents navigation during login/logout flows
      if (!_isAuthenticated()) {
        if (kDebugMode) {
          debugPrint('📋 Clipboard check skipped: User not authenticated');
        }
        return;
      }

      // Use the reactive state provider instead of reading preferences directly
      final isEnabled = ref.read(notificationDetectionStateProvider);

      if (kDebugMode) {
        debugPrint(
          '📋 Clipboard check: isEnabled=$isEnabled, isMonitoring=$_isMonitoringClipboard, authenticated=${_isAuthenticated()}',
        );
      }

      if (isEnabled && !_isMonitoringClipboard) {
        _isMonitoringClipboard = true;

        // Use microtask for non-blocking execution
        // Navigator check happens in modal service (event-driven)
        scheduleMicrotask(() async {
          if (mounted && _isAuthenticated()) {
            await _clipboardService.checkClipboard();
          }
          _isMonitoringClipboard = false;
        });
      } else if (!isEnabled && kDebugMode) {
        debugPrint('⚠️ Clipboard monitoring disabled in settings');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error checking clipboard: $e');
      }
      _isMonitoringClipboard = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
