import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../navigation/navigator_service.dart';
import '../widgets/expense_preview_modal.dart';
import '../../features/expenses/presentation/screens/add_expense_screen.dart';
import '../../features/expenses/domain/entities/expense_entity.dart';
import 'notification_detection_service.dart';
import 'expense_parsing/expense_parsing.dart';

/// Configuration for expense modal behavior
class ExpenseModalConfig {
  /// Confidence threshold for auto-creating expenses (default: 0.90)
  final double autoCreateThreshold;

  /// Confidence threshold for showing preview modal (default: 0.50)
  final double previewThreshold;

  /// Whether auto-create is enabled (user setting)
  final bool autoCreateEnabled;

  /// Whether to show toast for auto-created expenses
  final bool showAutoCreateToast;

  const ExpenseModalConfig({
    this.autoCreateThreshold = 0.90,
    this.previewThreshold = 0.50,
    this.autoCreateEnabled = false, // Disabled by default for safety
    this.showAutoCreateToast = true,
  });

  static const ExpenseModalConfig defaultConfig = ExpenseModalConfig();
}

/// Service for managing expense verification modals with confidence-based flow
///
/// Features:
/// - Confidence-based decision making:
///   - 90%+ confidence: Auto-create (if enabled) or show preview
///   - 50-89% confidence: Show preview modal
///   - Below 50%: Log only, don't interrupt user
/// - Non-blocking modal display
/// - Event-driven architecture
/// - Efficient queue management
class ExpenseModalService {
  static final ExpenseModalService _instance = ExpenseModalService._internal();
  factory ExpenseModalService() => _instance;
  ExpenseModalService._internal();

  final List<ParsedExpenseResult> _queue = [];
  bool _isShowing = false;
  ExpenseModalConfig _config = ExpenseModalConfig.defaultConfig;

  // Track patterns user marked as "don't ask again"
  final Set<String> _trustedPatterns = {};

  // Callback for auto-creating expenses
  Future<bool> Function(ParsedExpenseResult)? _autoCreateCallback;

  /// Initialize the service
  void initialize({ExpenseModalConfig? config}) {
    _config = config ?? ExpenseModalConfig.defaultConfig;
    _ensureNavigatorReady();
  }

  /// Update configuration
  void updateConfig(ExpenseModalConfig config) {
    _config = config;
  }

  /// Set callback for auto-creating expenses
  void setAutoCreateCallback(Future<bool> Function(ParsedExpenseResult) callback) {
    _autoCreateCallback = callback;
  }

  /// Add a trusted pattern (for "don't ask again" feature)
  void addTrustedPattern(String contentHash) {
    _trustedPatterns.add(contentHash);
  }

  /// Check if pattern is trusted
  bool isPatternTrusted(String? contentHash) {
    if (contentHash == null) return false;
    return _trustedPatterns.contains(contentHash);
  }

  /// Ensure Navigator is ready
  void _ensureNavigatorReady() {
    if (NavigatorService.isAvailable) {
      _processQueue();
      return;
    }

    scheduleMicrotask(() {
      if (NavigatorService.isAvailable) {
        _processQueue();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (NavigatorService.isAvailable) {
            _processQueue();
          }
        });
      }
    });
  }

  /// Show expense based on parsed result (new API)
  ///
  /// Uses confidence-based decision making:
  /// - 90%+ or trusted pattern: Auto-create (if enabled) or show preview
  /// - 50-89%: Show preview modal
  /// - Below 50%: Log only, don't show anything
  void showExpenseResult(ParsedExpenseResult result) {
    if (kDebugMode) {
      debugPrint('📋 ExpenseModalService: Received expense ${result.formattedAmount}');
      debugPrint('   Confidence: ${result.confidencePercentage}');
    }

    final action = _determineAction(result);

    switch (action) {
      case _ExpenseAction.autoCreate:
        _handleAutoCreate(result);
        break;
      case _ExpenseAction.showPreview:
        _queue.add(result);
        if (NavigatorService.isAvailable && !_isShowing) {
          scheduleMicrotask(() => _processQueue());
        } else {
          _ensureNavigatorReady();
        }
        break;
      case _ExpenseAction.logOnly:
        if (kDebugMode) {
          debugPrint('📋 ExpenseModalService: Low confidence, logging only');
        }
        // Could emit to a learning stream here for ML training
        break;
    }
  }

  /// Show expense from legacy DetectedExpense (backward compatible)
  @Deprecated('Use showExpenseResult instead')
  void showExpense(DetectedExpense expense) {
    showExpenseResult(expense.toExpenseResult());
  }

  /// Determine action based on confidence and settings
  _ExpenseAction _determineAction(ParsedExpenseResult result) {
    final confidence = result.confidence;
    final isTrusted = isPatternTrusted(result.contentHash);

    // If pattern is trusted or very high confidence, consider auto-create
    if ((isTrusted || confidence >= _config.autoCreateThreshold) &&
        _config.autoCreateEnabled &&
        _autoCreateCallback != null) {
      return _ExpenseAction.autoCreate;
    }

    // If confidence is above preview threshold, show preview
    if (confidence >= _config.previewThreshold || isTrusted) {
      return _ExpenseAction.showPreview;
    }

    // Low confidence - log only
    return _ExpenseAction.logOnly;
  }

  /// Handle auto-create action
  Future<void> _handleAutoCreate(ParsedExpenseResult result) async {
    if (_autoCreateCallback == null) {
      // Fallback to preview if no callback
      _queue.add(result);
      _ensureNavigatorReady();
      return;
    }

    try {
      final success = await _autoCreateCallback!(result);

      if (success) {
        if (kDebugMode) {
          debugPrint('✅ ExpenseModalService: Auto-created expense ${result.formattedAmount}');
        }

        // Show toast if enabled
        if (_config.showAutoCreateToast && NavigatorService.context != null) {
          _showAutoCreateToast(result);
        }
      } else {
        // Auto-create failed, show preview instead
        _queue.add(result);
        _ensureNavigatorReady();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ExpenseModalService: Auto-create failed: $e');
      }
      // Fallback to preview
      _queue.add(result);
      _ensureNavigatorReady();
    }
  }

  /// Show toast for auto-created expense
  void _showAutoCreateToast(ParsedExpenseResult result) {
    final context = NavigatorService.context;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Added: ${result.formattedAmount}${result.merchant != null ? " at ${result.merchant}" : ""}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Could navigate to recent transactions
          },
        ),
      ),
    );
  }

  /// Process the queue
  void _processQueue() {
    if (_queue.isEmpty || _isShowing) return;
    if (!NavigatorService.isAvailable) {
      _ensureNavigatorReady();
      return;
    }

    final result = _queue.removeAt(0);
    _isShowing = true;

    final context = NavigatorService.context;
    if (context == null) {
      _isShowing = false;
      _queue.insert(0, result);
      _ensureNavigatorReady();
      return;
    }

    scheduleMicrotask(() {
      _showPreviewModal(context, result);
    });
  }

  /// Show the preview modal
  Future<void> _showPreviewModal(BuildContext context, ParsedExpenseResult result) async {
    try {
      final previewResult = await ExpensePreviewModal.show(
        context: context,
        result: result,
        showDontAskAgain: result.confidence >= 0.85,
      );

      if (previewResult != null) {
        if (previewResult.confirmed) {
          // User confirmed - navigate to AddExpenseScreen
          _navigateToAddExpense(context, previewResult.result);

          // Handle "don't ask again"
          if (previewResult.dontAskAgain && previewResult.result.contentHash != null) {
            addTrustedPattern(previewResult.result.contentHash!);
          }
        } else {
          if (kDebugMode) {
            debugPrint('📋 ExpenseModalService: User dismissed expense');
          }
        }
      }

      // Reset and process next
      _resetAndProcessNext();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ExpenseModalService: Error showing preview: $e');
      }
      _isShowing = false;
      _queue.insert(0, result);
      _ensureNavigatorReady();
    }
  }

  /// Navigate to AddExpenseScreen with parsed result
  void _navigateToAddExpense(BuildContext context, ParsedExpenseResult result) {
    try {
      // Convert to legacy format for AddExpenseScreen compatibility
      final detectedExpense = DetectedExpense.fromExpenseResult(result);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddExpenseScreen(
            detectedExpense: detectedExpense,
            entryMode: EntryMode.notification,
          ),
        ),
      );

      if (kDebugMode) {
        debugPrint('✅ ExpenseModalService: Navigated to AddExpenseScreen');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ExpenseModalService: Error navigating: $e');
      }
    }
  }

  /// Reset state and process next in queue
  void _resetAndProcessNext() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _isShowing = false;
      if (_queue.isNotEmpty) {
        scheduleMicrotask(() => _processQueue());
      }
    });
  }

  /// Clear the queue
  void clear() {
    _queue.clear();
    _isShowing = false;
  }

  /// Get queue size
  int get queueSize => _queue.length;

  /// Check if showing a modal
  bool get isShowing => _isShowing;

  /// Get current configuration
  ExpenseModalConfig get config => _config;
}

/// Internal enum for expense actions
enum _ExpenseAction {
  autoCreate,
  showPreview,
  logOnly,
}
