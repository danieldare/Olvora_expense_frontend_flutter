import 'package:flutter/foundation.dart';
import 'parsed_expense_result.dart';

/// Configuration for confidence scoring weights
class ConfidenceScoringConfig {
  /// Weight for amount detection (0.0 - 1.0)
  final double amountWeight;

  /// Weight for currency detection (0.0 - 1.0)
  final double currencyWeight;

  /// Weight for merchant detection (0.0 - 1.0)
  final double merchantWeight;

  /// Weight for date detection (0.0 - 1.0)
  final double dateWeight;

  /// Weight for category detection (0.0 - 1.0)
  final double categoryWeight;

  /// Bonus for historical pattern match (0.0 - 1.0)
  final double historicalBonus;

  const ConfidenceScoringConfig({
    this.amountWeight = 0.40,
    this.currencyWeight = 0.15,
    this.merchantWeight = 0.20,
    this.dateWeight = 0.15,
    this.categoryWeight = 0.10,
    this.historicalBonus = 0.10,
  });

  /// Default configuration
  static const ConfidenceScoringConfig defaultConfig = ConfidenceScoringConfig();

  /// Strict configuration requiring more fields
  static const ConfidenceScoringConfig strict = ConfidenceScoringConfig(
    amountWeight: 0.35,
    currencyWeight: 0.15,
    merchantWeight: 0.25,
    dateWeight: 0.15,
    categoryWeight: 0.10,
    historicalBonus: 0.05,
  );
}

/// Service for calculating confidence scores for parsed expenses
///
/// The confidence score is a value from 0.0 to 1.0 that indicates
/// how confident we are in the parsed expense data. Higher scores
/// mean more fields were extracted successfully.
class ConfidenceScorer {
  final ConfidenceScoringConfig _config;

  /// Callback to check if a pattern was seen before
  final Future<bool> Function(String contentHash)? _hasSeenPattern;

  /// Callback to get historical accuracy for a merchant
  final Future<double> Function(String merchant)? _getMerchantAccuracy;

  ConfidenceScorer({
    ConfidenceScoringConfig? config,
    Future<bool> Function(String contentHash)? hasSeenPattern,
    Future<double> Function(String merchant)? getMerchantAccuracy,
  })  : _config = config ?? ConfidenceScoringConfig.defaultConfig,
        _hasSeenPattern = hasSeenPattern,
        _getMerchantAccuracy = getMerchantAccuracy;

  /// Calculate confidence score for a parsed expense result
  ///
  /// Returns a score from 0.0 to 1.0 based on:
  /// - Which fields were extracted (amount, currency, merchant, date, category)
  /// - Quality of extraction (e.g., amount precision)
  /// - Historical pattern matching
  Future<double> calculateConfidence(ParsedExpenseResult result) async {
    double score = 0.0;
    final extractedFields = <String>[];
    final missingFields = <String>[];

    // Amount: Most important field (40% weight by default)
    if (result.amount != null && result.amount! > 0) {
      score += _config.amountWeight;
      extractedFields.add('amount');

      // Bonus for reasonable amount (not too small, not astronomical)
      if (result.amount! >= 0.01 && result.amount! < 1000000000) {
        score += 0.02; // Small bonus for sanity
      }
    } else {
      missingFields.add('amount');
    }

    // Currency: 15% weight
    if (result.currency != null || result.currencySymbol != null) {
      score += _config.currencyWeight;
      extractedFields.add('currency');
    } else {
      missingFields.add('currency');
    }

    // Merchant: 20% weight
    if (result.merchant != null && result.merchant!.isNotEmpty) {
      score += _config.merchantWeight;
      extractedFields.add('merchant');

      // Bonus for merchant with reasonable length
      if (result.merchant!.length >= 2 && result.merchant!.length <= 50) {
        score += 0.02;
      }

      // Check historical accuracy for this merchant
      if (_getMerchantAccuracy != null) {
        final accuracy = await _getMerchantAccuracy(result.merchant!);
        score += accuracy * 0.05; // Up to 5% bonus
      }
    } else {
      missingFields.add('merchant');
    }

    // Date: 15% weight
    if (result.date != null) {
      score += _config.dateWeight;
      extractedFields.add('date');

      // Bonus for recent date (within last 30 days)
      final daysDiff = DateTime.now().difference(result.date!).inDays;
      if (daysDiff >= 0 && daysDiff <= 30) {
        score += 0.02;
      }
    } else {
      missingFields.add('date');
    }

    // Category: 10% weight
    if (result.category != null && result.category!.isNotEmpty) {
      score += _config.categoryWeight;
      extractedFields.add('category');
    } else {
      missingFields.add('category');
    }

    // Historical pattern bonus
    if (result.contentHash != null && _hasSeenPattern != null) {
      final hasSeen = await _hasSeenPattern(result.contentHash!);
      if (hasSeen) {
        score += _config.historicalBonus;
        extractedFields.add('historicalMatch');
      }
    }

    // Clamp to valid range
    final finalScore = score.clamp(0.0, 1.0);

    if (kDebugMode) {
      debugPrint('📊 Confidence Score: ${(finalScore * 100).round()}%');
      debugPrint('   Extracted: ${extractedFields.join(", ")}');
      debugPrint('   Missing: ${missingFields.join(", ")}');
    }

    return finalScore;
  }

  /// Calculate confidence and return updated result with score
  Future<ParsedExpenseResult> scoreResult(ParsedExpenseResult result) async {
    final confidence = await calculateConfidence(result);

    final extractedFields = <String>[];
    final missingFields = <String>[];

    if (result.amount != null) {
      extractedFields.add('amount');
    } else {
      missingFields.add('amount');
    }

    if (result.currency != null || result.currencySymbol != null) {
      extractedFields.add('currency');
    } else {
      missingFields.add('currency');
    }

    if (result.merchant != null) {
      extractedFields.add('merchant');
    } else {
      missingFields.add('merchant');
    }

    if (result.date != null) {
      extractedFields.add('date');
    } else {
      missingFields.add('date');
    }

    if (result.category != null) {
      extractedFields.add('category');
    } else {
      missingFields.add('category');
    }

    return result.copyWith(
      confidence: confidence,
      extractedFields: extractedFields,
      missingFields: missingFields,
      contentHash: ParsedExpenseResult.generateContentHash(
        result.rawText,
        result.amount,
        result.merchant,
      ),
    );
  }

  /// Get recommended action based on confidence level
  static ConfidenceAction getRecommendedAction(double confidence) {
    if (confidence >= 0.90) {
      return ConfidenceAction.autoCreate;
    } else if (confidence >= 0.70) {
      return ConfidenceAction.showPreview;
    } else if (confidence >= 0.50) {
      return ConfidenceAction.showNotification;
    } else {
      return ConfidenceAction.logOnly;
    }
  }

  /// Get color for confidence level (for UI display)
  static ConfidenceColor getConfidenceColor(double confidence) {
    if (confidence >= 0.90) {
      return ConfidenceColor.green;
    } else if (confidence >= 0.70) {
      return ConfidenceColor.yellow;
    } else if (confidence >= 0.50) {
      return ConfidenceColor.orange;
    } else {
      return ConfidenceColor.red;
    }
  }
}

/// Recommended action based on confidence level
enum ConfidenceAction {
  /// 90%+ confidence: Auto-create expense (if user enabled)
  autoCreate,

  /// 70-89% confidence: Show preview modal for confirmation
  showPreview,

  /// 50-69% confidence: Show subtle notification
  showNotification,

  /// Below 50%: Log for learning, don't interrupt user
  logOnly,
}

/// Color indicator for confidence level
enum ConfidenceColor {
  /// 90%+ - High confidence
  green,

  /// 70-89% - Medium confidence
  yellow,

  /// 50-69% - Low confidence
  orange,

  /// Below 50% - Very low confidence
  red,
}
