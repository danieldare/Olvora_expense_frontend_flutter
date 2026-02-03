import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/platform_notification_service.dart';
import '../services/notification_detection_service.dart';
import '../services/expense_modal_service.dart';
import '../services/expense_parsing/expense_parsing.dart';
import '../providers/notification_detection_providers.dart';

/// Widget that listens to detected expenses and shows verification modal
///
/// Features:
/// - Confidence-based flow using ParsedExpenseResult
/// - Uses ExpensePreviewModal for medium confidence
/// - Auto-create option for high confidence patterns
/// - Prevents duplicate modals
/// - Handles errors gracefully
/// - Auto-initializes service on mount
class NotificationDetectionListener extends ConsumerStatefulWidget {
  final Widget child;

  const NotificationDetectionListener({super.key, required this.child});

  @override
  ConsumerState<NotificationDetectionListener> createState() =>
      _NotificationDetectionListenerState();
}

class _NotificationDetectionListenerState
    extends ConsumerState<NotificationDetectionListener> {
  // New: Listen to ParsedExpenseResult stream
  StreamSubscription<ParsedExpenseResult>? _resultSubscription;

  // Legacy: Keep for backward compatibility during transition
  StreamSubscription<DetectedExpense>? _legacySubscription;

  bool _isListening = false;
  DateTime? _lastModalShown;
  String? _lastProcessedHash;
  final ExpenseModalService _modalService = ExpenseModalService();

  @override
  void initState() {
    super.initState();
    // Initialize modal service with config
    _modalService.initialize(
      config: const ExpenseModalConfig(
        autoCreateThreshold: 0.90,
        previewThreshold: 0.50,
        autoCreateEnabled: false, // Can be enabled via settings
        showAutoCreateToast: true,
      ),
    );

    // Start listening immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndStartListening();
    });
  }

  Future<void> _initializeAndStartListening() async {
    final isEnabled = ref.watch(notificationDetectionStateProvider);
    final service = ref.read(platformNotificationServiceProvider);

    if (isEnabled && !_isListening) {
      _startListening(service);
    } else if (!isEnabled && _isListening) {
      _stopListening();
    }
  }

  void _startListening(PlatformNotificationService service) {
    if (_isListening) return;

    // Cancel any existing subscriptions
    _resultSubscription?.cancel();
    _legacySubscription?.cancel();

    // Listen to new ParsedExpenseResult stream (preferred)
    _resultSubscription = service.expenseResults.listen(
      (result) => _handleExpenseResult(result),
      onError: (error) {
        if (kDebugMode) {
          debugPrint('Error in expense result stream: $error');
        }
      },
    );

    // Also listen to legacy stream for backward compatibility
    // This can be removed once all code uses expenseResults
    _legacySubscription = service.detectedExpenses.listen(
      (detectedExpense) {
        // Convert to ParsedExpenseResult if not already handled
        // The new stream should handle most cases, this is a fallback
      },
      onError: (error) {
        if (kDebugMode) {
          debugPrint('Error in legacy detection stream: $error');
        }
      },
    );

    _isListening = true;

    if (kDebugMode) {
      debugPrint('🔔 NotificationDetectionListener: Started listening with confidence-based flow');
    }
  }

  void _stopListening() {
    _resultSubscription?.cancel();
    _resultSubscription = null;
    _legacySubscription?.cancel();
    _legacySubscription = null;
    _isListening = false;

    if (kDebugMode) {
      debugPrint('🔕 NotificationDetectionListener: Stopped listening');
    }
  }

  /// Handle parsed expense result with confidence-based flow
  void _handleExpenseResult(ParsedExpenseResult result) {
    if (!mounted) return;

    // Prevent showing duplicate modals within 2 seconds
    final now = DateTime.now();
    final contentHash = result.contentHash;

    if (contentHash != null &&
        _lastProcessedHash == contentHash &&
        _lastModalShown != null &&
        now.difference(_lastModalShown!).inSeconds < 2) {
      if (kDebugMode) {
        debugPrint('⚠️ Duplicate expense ignored: $contentHash');
      }
      return;
    }

    _lastProcessedHash = contentHash;
    _lastModalShown = now;

    if (kDebugMode) {
      debugPrint('✅ Expense detected: ${result.formattedAmount}');
      debugPrint('   Confidence: ${result.confidencePercentage}');
      debugPrint('   Level: ${result.confidenceLevel.name}');
    }

    // Delegate to modal service (handles confidence-based flow)
    _modalService.showExpenseResult(result);
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch state changes to start/stop listening reactively
    final isEnabled = ref.watch(notificationDetectionStateProvider);
    final service = ref.read(platformNotificationServiceProvider);

    // React to state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (isEnabled && !_isListening) {
        _startListening(service);
      } else if (!isEnabled && _isListening) {
        _stopListening();
      }
    });

    return widget.child;
  }
}
