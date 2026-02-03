import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'parsed_expense_result.dart';
import 'confidence_scorer.dart';
import 'generic_expense_parser.dart';
import 'ai_expense_parser.dart';
import '../api_service_v2.dart';
import '../ml_learning/ml_learning.dart';

/// Configuration for the hybrid parser
class HybridParserConfig {
  /// Confidence threshold below which to try AI parsing
  final double aiParsingThreshold;

  /// Whether to prefer AI parsing for specific sources
  final Set<ParsingSource> preferAIForSources;

  /// Maximum text length for AI parsing (longer texts are truncated)
  final int maxTextLengthForAI;

  /// Whether to enable offline mode (skip AI parsing when offline)
  final bool respectConnectivity;

  /// Whether to apply ML learned patterns to improve results
  final bool applyLearnedPatterns;

  const HybridParserConfig({
    this.aiParsingThreshold = 0.70,
    this.preferAIForSources = const {ParsingSource.voice},
    this.maxTextLengthForAI = 2000,
    this.respectConnectivity = true,
    this.applyLearnedPatterns = true,
  });

  static const HybridParserConfig defaultConfig = HybridParserConfig();

  /// Config that prefers generic parsing (faster, offline)
  static const HybridParserConfig offlineFirst = HybridParserConfig(
    aiParsingThreshold: 0.50,
    preferAIForSources: {},
    respectConnectivity: true,
    applyLearnedPatterns: true,
  );

  /// Config that prefers AI parsing (more accurate)
  static const HybridParserConfig aiFirst = HybridParserConfig(
    aiParsingThreshold: 0.90,
    preferAIForSources: {
      ParsingSource.sms,
      ParsingSource.clipboard,
      ParsingSource.voice,
    },
    respectConnectivity: true,
    applyLearnedPatterns: true,
  );
}

/// Hybrid expense parser that combines generic, AI, and ML learning
///
/// This parser uses a multi-stage approach:
/// 1. Try generic pattern parsing first (fast, works offline)
/// 2. Apply ML learned patterns (improves from user corrections)
/// 3. If confidence is below threshold, try AI parsing (accurate, needs network)
///
/// The result with higher confidence is returned.
class HybridExpenseParser {
  final GenericExpenseParser _genericParser;
  final AIExpenseParser? _aiParser;
  final ConfidenceScorer _confidenceScorer;
  final PatternLearner _patternLearner;
  final HybridParserConfig _config;

  HybridExpenseParser({
    GenericExpenseParser? genericParser,
    AIExpenseParser? aiParser,
    ConfidenceScorer? confidenceScorer,
    PatternLearner? patternLearner,
    HybridParserConfig? config,
  })  : _genericParser = genericParser ?? GenericExpenseParser(),
        _aiParser = aiParser,
        _confidenceScorer = confidenceScorer ?? ConfidenceScorer(),
        _patternLearner = patternLearner ?? PatternLearner(),
        _config = config ?? HybridParserConfig.defaultConfig;

  /// Create a hybrid parser with API service for AI parsing
  factory HybridExpenseParser.withApiService(
    ApiServiceV2 apiService, {
    HybridParserConfig? config,
  }) {
    return HybridExpenseParser(
      genericParser: GenericExpenseParser(),
      aiParser: AIExpenseParser(apiService),
      confidenceScorer: ConfidenceScorer(),
      patternLearner: PatternLearner(),
      config: config,
    );
  }

  /// Parse expense text using hybrid approach
  ///
  /// Flow:
  /// 1. Try generic patterns first (fast, offline)
  /// 2. Apply ML learned patterns (improves from user corrections)
  /// 3. Calculate confidence score
  /// 4. If confidence < threshold AND online, try AI parsing
  /// 5. Return result with higher confidence
  Future<ParsedExpenseResult> parse(String text, ParsingSource source) async {
    if (text.trim().isEmpty) {
      return ParsedExpenseResult(
        rawText: text,
        confidence: 0.0,
        source: source,
      );
    }

    if (kDebugMode) {
      debugPrint('🔄 HybridParser: Starting parse for ${source.name}');
    }

    // Step 1: Generic parsing (always runs first - fast, offline)
    var result = _genericParser.parse(text, source);

    // Step 2: Apply ML learned patterns (if enabled)
    if (_config.applyLearnedPatterns) {
      await _patternLearner.initialize();
      result = _patternLearner.applyLearnedPatterns(result);

      if (kDebugMode && result.metadata?['learnedPatternsApplied'] == true) {
        debugPrint('🧠 HybridParser: Applied learned patterns (boost: ${result.metadata?['confidenceBoost']})');
      }
    }

    // Step 3: Calculate confidence
    result = await _confidenceScorer.scoreResult(result);

    if (kDebugMode) {
      debugPrint('🔄 HybridParser: Generic result confidence: ${result.confidencePercentage}');
    }

    // Step 4: Check if we should try AI parsing
    final shouldTryAI = _shouldTryAIParsing(result, source);

    if (shouldTryAI && _aiParser != null) {
      if (kDebugMode) {
        debugPrint('🔄 HybridParser: Trying AI parsing...');
      }

      // Check connectivity if configured
      if (_config.respectConnectivity) {
        final hasConnectivity = await _hasConnectivity();
        if (!hasConnectivity) {
          if (kDebugMode) {
            debugPrint('🔄 HybridParser: No connectivity, skipping AI parsing');
          }
          return result;
        }
      }

      // Truncate text if too long
      final textForAI = text.length > _config.maxTextLengthForAI
          ? text.substring(0, _config.maxTextLengthForAI)
          : text;

      // Try AI parsing
      var aiResult = await _aiParser.parse(textForAI, source);

      // Apply learned patterns to AI result too
      if (_config.applyLearnedPatterns) {
        aiResult = _patternLearner.applyLearnedPatterns(aiResult);
      }

      aiResult = await _confidenceScorer.scoreResult(aiResult);

      if (kDebugMode) {
        debugPrint('🔄 HybridParser: AI result confidence: ${aiResult.confidencePercentage}');
      }

      // Step 5: Return result with higher confidence
      if (aiResult.confidence > result.confidence) {
        if (kDebugMode) {
          debugPrint('🔄 HybridParser: Using AI result (higher confidence)');
        }
        return aiResult;
      }
    }

    if (kDebugMode) {
      debugPrint('🔄 HybridParser: Using generic result');
    }

    return result;
  }

  /// Determine if we should try AI parsing
  bool _shouldTryAIParsing(ParsedExpenseResult genericResult, ParsingSource source) {
    // If AI parser is not available, don't try
    if (_aiParser == null) return false;

    // If confidence is already high, don't need AI
    if (genericResult.confidence >= 0.90) return false;

    // If source prefers AI parsing, try it
    if (_config.preferAIForSources.contains(source)) {
      return true;
    }

    // If confidence is below threshold, try AI
    if (genericResult.confidence < _config.aiParsingThreshold) {
      return true;
    }

    return false;
  }

  /// Check network connectivity
  Future<bool> _hasConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (_) {
      // Assume connected if check fails
      return true;
    }
  }

  /// Parse for debit transactions only
  ///
  /// Returns null if the text doesn't appear to be a debit transaction.
  Future<ParsedExpenseResult?> parseDebitOnly(
    String text,
    ParsingSource source,
  ) async {
    // First check if it looks like a debit transaction
    if (!_genericParser.isDebitTransaction(text)) {
      if (kDebugMode) {
        debugPrint('🔄 HybridParser: Not a debit transaction, skipping');
      }
      return null;
    }

    return parse(text, source);
  }

  /// Get the generic parser instance
  GenericExpenseParser get genericParser => _genericParser;

  /// Get the AI parser instance (may be null)
  AIExpenseParser? get aiParser => _aiParser;

  /// Get the confidence scorer instance
  ConfidenceScorer get confidenceScorer => _confidenceScorer;

  /// Get the pattern learner instance
  PatternLearner get patternLearner => _patternLearner;

  /// Track a correction for ML learning
  ///
  /// Call this when a user edits a parsed expense.
  Future<void> trackCorrection({
    required ParsedExpenseResult original,
    required double? correctedAmount,
    required String? correctedCurrency,
    required String? correctedMerchant,
    required String? correctedCategory,
    required DateTime? correctedDate,
  }) async {
    await CorrectionTracker().trackCorrection(
      original: original,
      correctedAmount: correctedAmount,
      correctedCurrency: correctedCurrency,
      correctedMerchant: correctedMerchant,
      correctedCategory: correctedCategory,
      correctedDate: correctedDate,
    );
  }

  /// Confirm that a pattern-applied result was correct
  ///
  /// Call this when a user accepts a parsed expense without changes.
  Future<void> confirmPattern(ParsedExpenseResult result) async {
    await _patternLearner.confirmPattern(result);
  }

  /// Trigger learning from accumulated corrections
  ///
  /// Call this periodically (e.g., when app goes to background).
  Future<void> learnFromCorrections() async {
    await _patternLearner.learnFromCorrections();
  }
}
