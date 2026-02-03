import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../expense_parsing/expense_parsing.dart';

/// Represents a user correction to a parsed expense
class ExpenseCorrection {
  final String id;
  final DateTime timestamp;
  final ParsingSource source;

  // Original parsed values
  final double? originalAmount;
  final String? originalCurrency;
  final String? originalMerchant;
  final String? originalCategory;
  final DateTime? originalDate;

  // Corrected values
  final double? correctedAmount;
  final String? correctedCurrency;
  final String? correctedMerchant;
  final String? correctedCategory;
  final DateTime? correctedDate;

  // Raw text that was parsed
  final String rawText;

  // Content hash for pattern matching
  final String? contentHash;

  // Which fields were corrected
  final Set<String> correctedFields;

  ExpenseCorrection({
    required this.id,
    required this.timestamp,
    required this.source,
    this.originalAmount,
    this.originalCurrency,
    this.originalMerchant,
    this.originalCategory,
    this.originalDate,
    this.correctedAmount,
    this.correctedCurrency,
    this.correctedMerchant,
    this.correctedCategory,
    this.correctedDate,
    required this.rawText,
    this.contentHash,
    required this.correctedFields,
  });

  /// Check if a specific field was corrected
  bool wasFieldCorrected(String field) => correctedFields.contains(field);

  /// Check if amount was corrected
  bool get amountCorrected => wasFieldCorrected('amount');

  /// Check if merchant was corrected
  bool get merchantCorrected => wasFieldCorrected('merchant');

  /// Check if category was corrected
  bool get categoryCorrected => wasFieldCorrected('category');

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'source': source.name,
      'originalAmount': originalAmount,
      'originalCurrency': originalCurrency,
      'originalMerchant': originalMerchant,
      'originalCategory': originalCategory,
      'originalDate': originalDate?.toIso8601String(),
      'correctedAmount': correctedAmount,
      'correctedCurrency': correctedCurrency,
      'correctedMerchant': correctedMerchant,
      'correctedCategory': correctedCategory,
      'correctedDate': correctedDate?.toIso8601String(),
      'rawText': rawText,
      'contentHash': contentHash,
      'correctedFields': correctedFields.toList(),
    };
  }

  factory ExpenseCorrection.fromJson(Map<String, dynamic> json) {
    return ExpenseCorrection(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      source: ParsingSource.values.firstWhere(
        (s) => s.name == json['source'],
        orElse: () => ParsingSource.manual,
      ),
      originalAmount: json['originalAmount'] as double?,
      originalCurrency: json['originalCurrency'] as String?,
      originalMerchant: json['originalMerchant'] as String?,
      originalCategory: json['originalCategory'] as String?,
      originalDate: json['originalDate'] != null
          ? DateTime.parse(json['originalDate'] as String)
          : null,
      correctedAmount: json['correctedAmount'] as double?,
      correctedCurrency: json['correctedCurrency'] as String?,
      correctedMerchant: json['correctedMerchant'] as String?,
      correctedCategory: json['correctedCategory'] as String?,
      correctedDate: json['correctedDate'] != null
          ? DateTime.parse(json['correctedDate'] as String)
          : null,
      rawText: json['rawText'] as String,
      contentHash: json['contentHash'] as String?,
      correctedFields: Set<String>.from(json['correctedFields'] as List),
    );
  }
}

/// Service to track user corrections for ML learning
///
/// Features:
/// - Records all user corrections to parsed expenses
/// - Persists corrections for offline learning
/// - Provides analytics on correction patterns
/// - Feeds into PatternLearner for improvement
class CorrectionTracker {
  static final CorrectionTracker _instance = CorrectionTracker._internal();
  factory CorrectionTracker() => _instance;
  CorrectionTracker._internal();

  static const String _correctionsKey = 'expense_corrections';
  static const int _maxCorrections = 500; // Keep last 500 corrections
  static const Duration _correctionRetention = Duration(days: 90);

  final List<ExpenseCorrection> _corrections = [];
  bool _isInitialized = false;

  /// Initialize the tracker
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadCorrections();
      await _pruneOldCorrections();
      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('📊 CorrectionTracker initialized with ${_corrections.length} corrections');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing CorrectionTracker: $e');
      }
    }
  }

  /// Track a correction when user edits a parsed expense
  Future<void> trackCorrection({
    required ParsedExpenseResult original,
    required double? correctedAmount,
    required String? correctedCurrency,
    required String? correctedMerchant,
    required String? correctedCategory,
    required DateTime? correctedDate,
  }) async {
    await initialize();

    // Determine which fields were corrected
    final correctedFields = <String>{};

    if (correctedAmount != null && correctedAmount != original.amount) {
      correctedFields.add('amount');
    }
    if (correctedCurrency != null && correctedCurrency != original.currency) {
      correctedFields.add('currency');
    }
    if (correctedMerchant != null && correctedMerchant != original.merchant) {
      correctedFields.add('merchant');
    }
    if (correctedCategory != null && correctedCategory != original.category) {
      correctedFields.add('category');
    }
    if (correctedDate != null && correctedDate != original.date) {
      correctedFields.add('date');
    }

    // Only track if there were actual corrections
    if (correctedFields.isEmpty) {
      if (kDebugMode) {
        debugPrint('📊 No corrections made, skipping tracking');
      }
      return;
    }

    final correction = ExpenseCorrection(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_corrections.length}',
      timestamp: DateTime.now(),
      source: original.source,
      originalAmount: original.amount,
      originalCurrency: original.currency,
      originalMerchant: original.merchant,
      originalCategory: original.category,
      originalDate: original.date,
      correctedAmount: correctedAmount,
      correctedCurrency: correctedCurrency,
      correctedMerchant: correctedMerchant,
      correctedCategory: correctedCategory,
      correctedDate: correctedDate,
      rawText: original.rawText,
      contentHash: original.contentHash,
      correctedFields: correctedFields,
    );

    _corrections.add(correction);

    // Trim if over limit
    if (_corrections.length > _maxCorrections) {
      _corrections.removeRange(0, _corrections.length - _maxCorrections);
    }

    await _saveCorrections();

    if (kDebugMode) {
      debugPrint('📊 Tracked correction: ${correctedFields.join(", ")}');
    }
  }

  /// Track when user accepts a parsed expense without changes
  Future<void> trackAcceptance(ParsedExpenseResult result) async {
    await initialize();

    // We don't store acceptances, but we can use this for analytics
    // In the future, this could be used to reinforce good patterns

    if (kDebugMode) {
      debugPrint('📊 User accepted expense without corrections (confidence: ${result.confidencePercentage})');
    }
  }

  /// Get all corrections
  List<ExpenseCorrection> get corrections => List.unmodifiable(_corrections);

  /// Get corrections for a specific source
  List<ExpenseCorrection> getCorrectionsForSource(ParsingSource source) {
    return _corrections.where((c) => c.source == source).toList();
  }

  /// Get corrections for a specific field
  List<ExpenseCorrection> getCorrectionsForField(String field) {
    return _corrections.where((c) => c.correctedFields.contains(field)).toList();
  }

  /// Get merchant corrections (for learning merchant patterns)
  List<ExpenseCorrection> get merchantCorrections =>
      getCorrectionsForField('merchant');

  /// Get category corrections (for learning category assignments)
  List<ExpenseCorrection> get categoryCorrections =>
      getCorrectionsForField('category');

  /// Get correction rate by source
  Map<ParsingSource, CorrectionStats> getCorrectionStatsBySource() {
    final stats = <ParsingSource, CorrectionStats>{};

    for (final source in ParsingSource.values) {
      final sourceCorrections = getCorrectionsForSource(source);
      if (sourceCorrections.isNotEmpty) {
        stats[source] = CorrectionStats.fromCorrections(sourceCorrections);
      }
    }

    return stats;
  }

  /// Get most common correction patterns
  List<CorrectionPattern> getMostCommonPatterns({int limit = 10}) {
    final patterns = <String, CorrectionPattern>{};

    for (final correction in _corrections) {
      // Create pattern key from raw text signature
      final signature = _createTextSignature(correction.rawText);

      if (patterns.containsKey(signature)) {
        patterns[signature]!.addCorrection(correction);
      } else {
        patterns[signature] = CorrectionPattern(signature: signature)
          ..addCorrection(correction);
      }
    }

    // Sort by frequency and return top N
    final sortedPatterns = patterns.values.toList()
      ..sort((a, b) => b.frequency.compareTo(a.frequency));

    return sortedPatterns.take(limit).toList();
  }

  /// Create a normalized signature for pattern matching
  String _createTextSignature(String text) {
    // Normalize: lowercase, remove numbers, collapse whitespace
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[\d,]+\.?\d*'), '#')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Load corrections from persistent storage
  Future<void> _loadCorrections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_correctionsKey);

      if (json != null) {
        final List<dynamic> list = jsonDecode(json) as List<dynamic>;
        _corrections.clear();
        _corrections.addAll(
          list.map((item) =>
              ExpenseCorrection.fromJson(item as Map<String, dynamic>)),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading corrections: $e');
      }
    }
  }

  /// Save corrections to persistent storage
  Future<void> _saveCorrections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_corrections.map((c) => c.toJson()).toList());
      await prefs.setString(_correctionsKey, json);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving corrections: $e');
      }
    }
  }

  /// Remove old corrections
  Future<void> _pruneOldCorrections() async {
    final cutoff = DateTime.now().subtract(_correctionRetention);
    final originalCount = _corrections.length;

    _corrections.removeWhere((c) => c.timestamp.isBefore(cutoff));

    if (_corrections.length != originalCount) {
      await _saveCorrections();
      if (kDebugMode) {
        debugPrint('📊 Pruned ${originalCount - _corrections.length} old corrections');
      }
    }
  }

  /// Clear all corrections
  Future<void> clearAll() async {
    _corrections.clear();
    await _saveCorrections();
  }
}

/// Statistics about corrections
class CorrectionStats {
  final int totalCorrections;
  final int amountCorrections;
  final int merchantCorrections;
  final int categoryCorrections;
  final int dateCorrections;

  CorrectionStats({
    required this.totalCorrections,
    required this.amountCorrections,
    required this.merchantCorrections,
    required this.categoryCorrections,
    required this.dateCorrections,
  });

  factory CorrectionStats.fromCorrections(List<ExpenseCorrection> corrections) {
    return CorrectionStats(
      totalCorrections: corrections.length,
      amountCorrections:
          corrections.where((c) => c.amountCorrected).length,
      merchantCorrections:
          corrections.where((c) => c.merchantCorrected).length,
      categoryCorrections:
          corrections.where((c) => c.categoryCorrected).length,
      dateCorrections:
          corrections.where((c) => c.wasFieldCorrected('date')).length,
    );
  }

  double get amountCorrectionRate =>
      totalCorrections > 0 ? amountCorrections / totalCorrections : 0;

  double get merchantCorrectionRate =>
      totalCorrections > 0 ? merchantCorrections / totalCorrections : 0;

  double get categoryCorrectionRate =>
      totalCorrections > 0 ? categoryCorrections / totalCorrections : 0;
}

/// A pattern of corrections that occurs frequently
class CorrectionPattern {
  final String signature;
  final List<ExpenseCorrection> _corrections = [];

  CorrectionPattern({required this.signature});

  void addCorrection(ExpenseCorrection correction) {
    _corrections.add(correction);
  }

  int get frequency => _corrections.length;

  List<ExpenseCorrection> get corrections => List.unmodifiable(_corrections);

  /// Get the most common corrected merchant for this pattern
  String? get mostCommonMerchant {
    final merchants = <String, int>{};
    for (final c in _corrections) {
      if (c.correctedMerchant != null) {
        merchants[c.correctedMerchant!] =
            (merchants[c.correctedMerchant!] ?? 0) + 1;
      }
    }
    if (merchants.isEmpty) return null;

    return merchants.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get the most common corrected category for this pattern
  String? get mostCommonCategory {
    final categories = <String, int>{};
    for (final c in _corrections) {
      if (c.correctedCategory != null) {
        categories[c.correctedCategory!] =
            (categories[c.correctedCategory!] ?? 0) + 1;
      }
    }
    if (categories.isEmpty) return null;

    return categories.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}
