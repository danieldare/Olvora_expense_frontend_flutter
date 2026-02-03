import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'notification_detection_service.dart';
import 'expense_parsing/expense_parsing.dart';
import 'api_service_v2.dart';
import '../navigation/navigator_service.dart';
import '../widgets/expense_preview_modal.dart';
import '../../features/expenses/presentation/screens/add_expense_screen.dart';
import '../../features/expenses/domain/entities/expense_entity.dart';

/// Configuration for clipboard monitoring behavior
class ClipboardMonitorConfig {
  /// Minimum confidence to show preview modal (default: 0.40)
  final double minConfidenceToShow;

  /// Whether to auto-show modal or wait for explicit action
  final bool autoShowModal;

  /// Cooldown between checks of the same content (seconds)
  final int duplicateCheckCooldown;

  const ClipboardMonitorConfig({
    this.minConfidenceToShow = 0.40,
    this.autoShowModal = true,
    this.duplicateCheckCooldown = 5,
  });

  static const ClipboardMonitorConfig defaultConfig = ClipboardMonitorConfig();
}

/// Service to monitor clipboard for expense-related content
///
/// Features:
/// - Uses HybridParser for intelligent parsing (generic + AI)
/// - Shows ExpensePreviewModal with confidence indicator
/// - Multi-currency support (30+ currencies globally)
/// - Duplicate content detection with cooldown
/// - Authentication-aware navigation
class ClipboardMonitorService {
  static final ClipboardMonitorService _instance =
      ClipboardMonitorService._internal();
  factory ClipboardMonitorService() => _instance;
  ClipboardMonitorService._internal();

  final NotificationDetectionService _detectionService =
      NotificationDetectionService();

  // Parsers
  HybridExpenseParser? _hybridParser;
  GenericExpenseParser? _genericParser;

  // Configuration
  ClipboardMonitorConfig _config = ClipboardMonitorConfig.defaultConfig;

  // State tracking
  String? _lastClipboardContent;
  DateTime? _lastCheckTime;
  bool _isShowingModal = false;

  /// Optional callback to check if user is authenticated
  bool Function()? _isAuthenticatedCallback;

  /// Stream controller for parsed clipboard expenses
  final StreamController<ParsedExpenseResult> _clipboardExpenseController =
      StreamController<ParsedExpenseResult>.broadcast();

  /// Stream of parsed clipboard expenses
  Stream<ParsedExpenseResult> get clipboardExpenses =>
      _clipboardExpenseController.stream;

  /// Initialize with API service for AI parsing
  void initializeWithApiService(ApiServiceV2 apiService) {
    _hybridParser = HybridExpenseParser.withApiService(
      apiService,
      config: const HybridParserConfig(
        aiParsingThreshold: 0.65,
        preferAIForSources: {ParsingSource.clipboard},
        respectConnectivity: true,
      ),
    );
    _genericParser = _hybridParser!.genericParser;

    if (kDebugMode) {
      debugPrint('📋 ClipboardMonitorService initialized with HybridParser');
    }
  }

  /// Initialize with generic parser only (offline mode)
  void initializeOffline() {
    _genericParser = GenericExpenseParser();
    _hybridParser = HybridExpenseParser(genericParser: _genericParser);

    if (kDebugMode) {
      debugPrint('📋 ClipboardMonitorService initialized in offline mode');
    }
  }

  /// Update configuration
  void updateConfig(ClipboardMonitorConfig config) {
    _config = config;
  }

  /// Set the authentication check callback
  void setAuthCheckCallback(bool Function() callback) {
    _isAuthenticatedCallback = callback;
  }

  /// Clear the authentication check callback
  void clearAuthCheckCallback() {
    _isAuthenticatedCallback = null;
  }

  /// Check clipboard for expense content
  ///
  /// Should be called when app becomes active.
  /// Only works if notification detection is enabled in settings.
  Future<void> checkClipboard() async {
    try {
      // Don't process if detection is not enabled
      if (!_detectionService.isEnabled) {
        if (kDebugMode) {
          debugPrint('⚠️ Clipboard monitoring skipped: Detection not enabled');
        }
        return;
      }

      // Don't process if already showing modal
      if (_isShowingModal) {
        if (kDebugMode) {
          debugPrint('⚠️ Clipboard monitoring skipped: Modal already showing');
        }
        return;
      }

      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final clipboardText = clipboardData?.text?.trim();

      if (clipboardText == null || clipboardText.isEmpty) {
        if (kDebugMode) {
          debugPrint('📋 Clipboard is empty');
        }
        return;
      }

      // Avoid checking the same content multiple times within cooldown period
      if (clipboardText == _lastClipboardContent) {
        if (_lastCheckTime != null &&
            DateTime.now().difference(_lastCheckTime!).inSeconds <
                _config.duplicateCheckCooldown) {
          if (kDebugMode) {
            debugPrint('📋 Clipboard content unchanged, skipping check');
          }
          return;
        }
      }

      _lastClipboardContent = clipboardText;
      _lastCheckTime = DateTime.now();

      if (kDebugMode) {
        final preview = clipboardText.length > 100
            ? '${clipboardText.substring(0, 100)}...'
            : clipboardText;
        debugPrint('📋 Checking clipboard content: $preview');
      }

      // Parse clipboard content using HybridParser
      final result = await _parseClipboardContent(clipboardText);

      if (result != null) {
        // Emit to stream
        _clipboardExpenseController.add(result);

        if (kDebugMode) {
          debugPrint('✅ Clipboard expense detected: ${result.formattedAmount}');
          debugPrint('   Confidence: ${result.confidencePercentage}');
        }

        // Show preview modal if auto-show is enabled and confidence is sufficient
        if (_config.autoShowModal &&
            result.confidence >= _config.minConfidenceToShow) {
          _showPreviewModal(result);
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Clipboard content does not contain valid expense');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking clipboard: $e');
      }
    }
  }

  /// Parse clipboard content using HybridParser
  Future<ParsedExpenseResult?> _parseClipboardContent(String text) async {
    // Initialize parser if needed
    _genericParser ??= GenericExpenseParser();
    _hybridParser ??= HybridExpenseParser(genericParser: _genericParser);

    // Quick check: does it look like financial text?
    if (!_looksLikeExpenseText(text)) {
      return null;
    }

    // Parse using hybrid parser (debit only for clipboard)
    final result = await _hybridParser!.parseDebitOnly(text, ParsingSource.clipboard);

    // Return null if no valid amount found
    if (result == null || !result.hasAmount) {
      return null;
    }

    return result;
  }

  /// Quick heuristic check if text might contain expense data
  bool _looksLikeExpenseText(String text) {
    if (text.trim().isEmpty || text.length < 10) return false;

    // Use GenericExpenseParser's debit detection
    _genericParser ??= GenericExpenseParser();

    // Check for debit indicators OR any financial pattern
    if (_genericParser!.isDebitTransaction(text)) {
      return true;
    }

    // Also check for general financial patterns (currency symbols/codes + numbers)
    final hasFinancialPattern = RegExp(
      r'[₦$₹€£¥₩₱฿₫₪₴₸]|(?:NGN|USD|EUR|GBP|INR|JPY|CAD|AUD|CNY|KRW|BRL|MXN|ZAR|AED|SAR|PHP|THB|VND|ILS|UAH|KZT)\s*:?\s*[\d,]+',
      caseSensitive: false,
    ).hasMatch(text);

    return hasFinancialPattern;
  }

  /// Show preview modal for parsed expense
  Future<void> _showPreviewModal(ParsedExpenseResult result) async {
    // Check authentication
    if (_isAuthenticatedCallback != null && !_isAuthenticatedCallback!()) {
      if (kDebugMode) {
        debugPrint('⚠️ Preview modal skipped: User not authenticated');
      }
      return;
    }

    // Wait for Navigator to be available
    if (!NavigatorService.isAvailable) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (NavigatorService.isAvailable) {
          _showPreviewModal(result);
        }
      });
      return;
    }

    final context = NavigatorService.context;
    if (context == null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _showPreviewModal(result);
      });
      return;
    }

    // Mark as showing modal
    _isShowingModal = true;

    try {
      final previewResult = await ExpensePreviewModal.show(
        context: context,
        result: result,
        showDontAskAgain: result.confidence >= 0.85,
      );

      if (previewResult != null && previewResult.confirmed) {
        // User confirmed - navigate to AddExpenseScreen
        _navigateToAddExpense(context, previewResult.result);
      } else {
        if (kDebugMode) {
          debugPrint('📋 User dismissed clipboard expense');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error showing preview modal: $e');
      }
    } finally {
      _isShowingModal = false;
    }
  }

  /// Navigate to AddExpenseScreen with parsed result
  void _navigateToAddExpense(BuildContext context, ParsedExpenseResult result) {
    // Final auth check
    if (_isAuthenticatedCallback != null && !_isAuthenticatedCallback!()) {
      if (kDebugMode) {
        debugPrint('⚠️ Navigation cancelled: User not authenticated');
      }
      return;
    }

    try {
      // Convert to legacy format for AddExpenseScreen compatibility
      final detectedExpense = DetectedExpense.fromExpenseResult(result);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddExpenseScreen(
            detectedExpense: detectedExpense,
            entryMode: EntryMode.clipboard,
          ),
        ),
      );

      if (kDebugMode) {
        debugPrint('✅ Navigated to AddExpenseScreen from clipboard');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error navigating to AddExpenseScreen: $e');
      }
    }
  }

  /// Clear clipboard monitoring state
  void clear() {
    _lastClipboardContent = null;
    _lastCheckTime = null;
  }

  /// Force check clipboard (ignores duplicate check)
  Future<void> forceCheckClipboard() async {
    _lastClipboardContent = null;
    _lastCheckTime = null;
    await checkClipboard();
  }

  /// Parse clipboard text without showing modal (for external use)
  ///
  /// Useful when you want to check clipboard content programmatically
  /// without triggering the modal flow.
  Future<ParsedExpenseResult?> parseClipboardText(String text) async {
    return _parseClipboardContent(text);
  }

  /// Get the hybrid parser instance
  HybridExpenseParser? get hybridParser => _hybridParser;

  /// Get the generic parser instance
  GenericExpenseParser? get genericParser => _genericParser;

  /// Get the detection service stream (legacy)
  @Deprecated('Use clipboardExpenses instead')
  Stream<DetectedExpense> get detectedExpenses =>
      // ignore: deprecated_member_use_from_same_package
      _detectionService.detectedExpenses;

  /// Dispose resources
  void dispose() {
    _clipboardExpenseController.close();
  }
}
