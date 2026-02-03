import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../../expenses/data/services/intent_classification_service.dart';
import '../../../expenses/presentation/screens/add_expense_screen.dart';
import '../../../expenses/presentation/screens/add_recurring_expense_screen.dart';
import '../../../expenses/presentation/screens/add_future_expense_screen.dart';
import '../../../expenses/presentation/screens/expense_type_selection_screen.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../receipts/domain/models/parsed_receipt.dart';

/// Service to handle routing based on intent classification
class IntentRoutingService {
  final IntentClassificationService _intentService;
  static const double _minConfidenceThreshold = 0.7;

  IntentRoutingService(this._intentService);

  /// Classify intent and route to appropriate screen
  /// Returns true if routing was successful, false if user should choose manually
  Future<bool> classifyAndRoute({
    required BuildContext context,
    required String text,
    required String source, // 'voice' or 'receipt'
    ParsedReceipt? parsedReceipt,
    EntryMode? entryMode,
  }) async {
    try {
      // Classify intent
      final classification = await _intentService.classifyIntent(text, source);

      // Only auto-route if confidence is high enough
      if (classification.confidence < _minConfidenceThreshold) {
        // Low confidence - show type selection screen
        _showTypeSelectionScreen(context);
        return false;
      }

      // Route based on intent type
      switch (classification.intentType) {
        case ExpenseIntentType.expense:
          _navigateToExpenseScreen(
            context,
            parsedReceipt: parsedReceipt,
            entryMode: entryMode ?? EntryMode.manual,
            extractedData: classification.extractedData,
          );
          break;

        case ExpenseIntentType.recurring:
          _navigateToRecurringScreen(
            context,
            extractedData: classification.extractedData,
          );
          break;

        case ExpenseIntentType.future:
          _navigateToFutureScreen(
            context,
            extractedData: classification.extractedData,
          );
          break;
      }

      return true;
    } catch (e) {
      // On error, show type selection screen
      debugPrint('Intent classification failed: $e');
      _showTypeSelectionScreen(context);
      return false;
    }
  }

  void _navigateToExpenseScreen(
    BuildContext context, {
    ParsedReceipt? parsedReceipt,
    required EntryMode entryMode,
    Map<String, dynamic>? extractedData,
  }) {
    // Use PageRouteBuilder for scan mode to maintain animation
    if (entryMode == EntryMode.scan) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              AddExpenseScreen(
                preFilledData: parsedReceipt,
                entryMode: entryMode,
                extractedData: extractedData,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.0, 0.1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AddExpenseScreen(
            preFilledData: parsedReceipt,
            entryMode: entryMode,
            extractedData: extractedData,
          ),
        ),
      );
    }
  }

  void _navigateToRecurringScreen(
    BuildContext context, {
    Map<String, dynamic>? extractedData,
  }) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AddRecurringExpenseScreen(
          extractedData: extractedData,
        ),
      ),
    );
  }

  void _navigateToFutureScreen(
    BuildContext context, {
    Map<String, dynamic>? extractedData,
  }) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AddFutureExpenseScreen(
          extractedData: extractedData,
        ),
      ),
    );
  }

  void _showTypeSelectionScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const ExpenseTypeSelectionScreen(),
      ),
    );
  }
}

/// Provider for IntentRoutingService
final intentRoutingServiceProvider = Provider<IntentRoutingService>((ref) {
  final apiService = ref.watch(apiServiceV2Provider);
  final intentService = IntentClassificationService(apiService);
  return IntentRoutingService(intentService);
});

