import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'correction_tracker.dart';
import '../expense_parsing/expense_parsing.dart';

/// A learned pattern that can be applied to future parsing
class LearnedPattern {
  final String id;
  final String textPattern;
  final String? merchantOverride;
  final String? categoryOverride;
  final int timesApplied;
  final int timesConfirmed;
  final DateTime createdAt;
  final DateTime lastUsedAt;
  final double confidenceBoost;

  LearnedPattern({
    required this.id,
    required this.textPattern,
    this.merchantOverride,
    this.categoryOverride,
    this.timesApplied = 0,
    this.timesConfirmed = 0,
    required this.createdAt,
    required this.lastUsedAt,
    this.confidenceBoost = 0.1,
  });

  /// Calculate pattern reliability based on confirmation rate
  double get reliability {
    if (timesApplied == 0) return 0.5;
    return timesConfirmed / timesApplied;
  }

  /// Check if pattern is reliable enough to use
  bool get isReliable => timesApplied >= 2 && reliability >= 0.7;

  LearnedPattern copyWith({
    String? id,
    String? textPattern,
    String? merchantOverride,
    String? categoryOverride,
    int? timesApplied,
    int? timesConfirmed,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    double? confidenceBoost,
  }) {
    return LearnedPattern(
      id: id ?? this.id,
      textPattern: textPattern ?? this.textPattern,
      merchantOverride: merchantOverride ?? this.merchantOverride,
      categoryOverride: categoryOverride ?? this.categoryOverride,
      timesApplied: timesApplied ?? this.timesApplied,
      timesConfirmed: timesConfirmed ?? this.timesConfirmed,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      confidenceBoost: confidenceBoost ?? this.confidenceBoost,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'textPattern': textPattern,
      'merchantOverride': merchantOverride,
      'categoryOverride': categoryOverride,
      'timesApplied': timesApplied,
      'timesConfirmed': timesConfirmed,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt.toIso8601String(),
      'confidenceBoost': confidenceBoost,
    };
  }

  factory LearnedPattern.fromJson(Map<String, dynamic> json) {
    return LearnedPattern(
      id: json['id'] as String,
      textPattern: json['textPattern'] as String,
      merchantOverride: json['merchantOverride'] as String?,
      categoryOverride: json['categoryOverride'] as String?,
      timesApplied: json['timesApplied'] as int? ?? 0,
      timesConfirmed: json['timesConfirmed'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: DateTime.parse(json['lastUsedAt'] as String),
      confidenceBoost: (json['confidenceBoost'] as num?)?.toDouble() ?? 0.1,
    );
  }
}

/// A merchant alias learned from corrections
class MerchantAlias {
  final String originalText;
  final String normalizedMerchant;
  final int frequency;
  final DateTime lastSeen;

  MerchantAlias({
    required this.originalText,
    required this.normalizedMerchant,
    this.frequency = 1,
    required this.lastSeen,
  });

  MerchantAlias copyWith({
    String? originalText,
    String? normalizedMerchant,
    int? frequency,
    DateTime? lastSeen,
  }) {
    return MerchantAlias(
      originalText: originalText ?? this.originalText,
      normalizedMerchant: normalizedMerchant ?? this.normalizedMerchant,
      frequency: frequency ?? this.frequency,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      'normalizedMerchant': normalizedMerchant,
      'frequency': frequency,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }

  factory MerchantAlias.fromJson(Map<String, dynamic> json) {
    return MerchantAlias(
      originalText: json['originalText'] as String,
      normalizedMerchant: json['normalizedMerchant'] as String,
      frequency: json['frequency'] as int? ?? 1,
      lastSeen: DateTime.parse(json['lastSeen'] as String),
    );
  }
}

/// A category assignment learned from corrections
class CategoryAssignment {
  final String merchantOrKeyword;
  final String category;
  final int frequency;
  final DateTime lastSeen;

  CategoryAssignment({
    required this.merchantOrKeyword,
    required this.category,
    this.frequency = 1,
    required this.lastSeen,
  });

  CategoryAssignment copyWith({
    String? merchantOrKeyword,
    String? category,
    int? frequency,
    DateTime? lastSeen,
  }) {
    return CategoryAssignment(
      merchantOrKeyword: merchantOrKeyword ?? this.merchantOrKeyword,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'merchantOrKeyword': merchantOrKeyword,
      'category': category,
      'frequency': frequency,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }

  factory CategoryAssignment.fromJson(Map<String, dynamic> json) {
    return CategoryAssignment(
      merchantOrKeyword: json['merchantOrKeyword'] as String,
      category: json['category'] as String,
      frequency: json['frequency'] as int? ?? 1,
      lastSeen: DateTime.parse(json['lastSeen'] as String),
    );
  }
}

/// Service that learns patterns from user corrections
///
/// Features:
/// - Learns merchant name variations
/// - Learns category assignments
/// - Creates text patterns from repeated corrections
/// - Applies learned patterns to improve future parsing
class PatternLearner {
  static final PatternLearner _instance = PatternLearner._internal();
  factory PatternLearner() => _instance;
  PatternLearner._internal();

  static const String _patternsKey = 'learned_patterns';
  static const String _merchantAliasesKey = 'merchant_aliases';
  static const String _categoryAssignmentsKey = 'category_assignments';

  static const int _minCorrectionsForPattern = 2;
  static const int _maxPatterns = 200;
  static const int _maxMerchantAliases = 500;
  static const int _maxCategoryAssignments = 300;

  final Map<String, LearnedPattern> _patterns = {};
  final Map<String, MerchantAlias> _merchantAliases = {};
  final Map<String, CategoryAssignment> _categoryAssignments = {};

  bool _isInitialized = false;

  /// Initialize the pattern learner
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadAll();
      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('🧠 PatternLearner initialized:');
        debugPrint('   Patterns: ${_patterns.length}');
        debugPrint('   Merchant aliases: ${_merchantAliases.length}');
        debugPrint('   Category assignments: ${_categoryAssignments.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing PatternLearner: $e');
      }
    }
  }

  /// Learn from user corrections
  Future<void> learnFromCorrections() async {
    await initialize();

    final tracker = CorrectionTracker();
    await tracker.initialize();

    // Get common patterns
    final commonPatterns = tracker.getMostCommonPatterns(limit: 50);

    for (final pattern in commonPatterns) {
      if (pattern.frequency >= _minCorrectionsForPattern) {
        await _learnFromPattern(pattern);
      }
    }

    // Learn merchant aliases from merchant corrections
    for (final correction in tracker.merchantCorrections) {
      if (correction.originalMerchant != null &&
          correction.correctedMerchant != null &&
          correction.originalMerchant != correction.correctedMerchant) {
        await _learnMerchantAlias(
          correction.originalMerchant!,
          correction.correctedMerchant!,
        );
      }
    }

    // Learn category assignments
    for (final correction in tracker.categoryCorrections) {
      final merchant = correction.correctedMerchant ?? correction.originalMerchant;
      if (merchant != null && correction.correctedCategory != null) {
        await _learnCategoryAssignment(merchant, correction.correctedCategory!);
      }
    }

    await _saveAll();

    if (kDebugMode) {
      debugPrint('🧠 Learning complete');
    }
  }

  /// Learn from a correction pattern
  Future<void> _learnFromPattern(CorrectionPattern pattern) async {
    final merchant = pattern.mostCommonMerchant;
    final category = pattern.mostCommonCategory;

    if (merchant == null && category == null) return;

    final now = DateTime.now();
    final patternId = _createPatternId(pattern.signature);

    if (_patterns.containsKey(patternId)) {
      // Update existing pattern
      final existing = _patterns[patternId]!;
      _patterns[patternId] = existing.copyWith(
        merchantOverride: merchant ?? existing.merchantOverride,
        categoryOverride: category ?? existing.categoryOverride,
        timesApplied: existing.timesApplied + pattern.frequency,
        lastUsedAt: now,
      );
    } else {
      // Create new pattern
      _patterns[patternId] = LearnedPattern(
        id: patternId,
        textPattern: pattern.signature,
        merchantOverride: merchant,
        categoryOverride: category,
        timesApplied: pattern.frequency,
        createdAt: now,
        lastUsedAt: now,
      );
    }

    // Trim if over limit
    if (_patterns.length > _maxPatterns) {
      _prunePatterns();
    }
  }

  /// Learn a merchant alias
  Future<void> _learnMerchantAlias(String original, String normalized) async {
    final key = original.toLowerCase().trim();
    final now = DateTime.now();

    if (_merchantAliases.containsKey(key)) {
      final existing = _merchantAliases[key]!;
      _merchantAliases[key] = existing.copyWith(
        normalizedMerchant: normalized,
        frequency: existing.frequency + 1,
        lastSeen: now,
      );
    } else {
      _merchantAliases[key] = MerchantAlias(
        originalText: original,
        normalizedMerchant: normalized,
        frequency: 1,
        lastSeen: now,
      );
    }

    // Trim if over limit
    if (_merchantAliases.length > _maxMerchantAliases) {
      _pruneMerchantAliases();
    }
  }

  /// Learn a category assignment
  Future<void> _learnCategoryAssignment(String merchant, String category) async {
    final key = merchant.toLowerCase().trim();
    final now = DateTime.now();

    if (_categoryAssignments.containsKey(key)) {
      final existing = _categoryAssignments[key]!;
      if (existing.category == category) {
        _categoryAssignments[key] = existing.copyWith(
          frequency: existing.frequency + 1,
          lastSeen: now,
        );
      } else if (existing.frequency < 3) {
        // Override if existing is not strong
        _categoryAssignments[key] = existing.copyWith(
          category: category,
          frequency: 1,
          lastSeen: now,
        );
      }
    } else {
      _categoryAssignments[key] = CategoryAssignment(
        merchantOrKeyword: merchant,
        category: category,
        frequency: 1,
        lastSeen: now,
      );
    }

    // Trim if over limit
    if (_categoryAssignments.length > _maxCategoryAssignments) {
      _pruneCategoryAssignments();
    }
  }

  /// Apply learned patterns to a parsed result
  ParsedExpenseResult applyLearnedPatterns(ParsedExpenseResult result) {
    if (!_isInitialized) return result;

    String? merchant = result.merchant;
    String? category = result.category;
    double confidenceBoost = 0;

    // Try to find a matching pattern
    final signature = _createTextSignature(result.rawText);
    final patternId = _createPatternId(signature);

    if (_patterns.containsKey(patternId)) {
      final pattern = _patterns[patternId]!;
      if (pattern.isReliable) {
        merchant = pattern.merchantOverride ?? merchant;
        category = pattern.categoryOverride ?? category;
        confidenceBoost = pattern.confidenceBoost;

        if (kDebugMode) {
          debugPrint('🧠 Applied learned pattern: $patternId');
        }
      }
    }

    // Apply merchant alias if merchant was extracted
    if (merchant != null) {
      final alias = _getMerchantAlias(merchant);
      if (alias != null) {
        merchant = alias.normalizedMerchant;
        confidenceBoost += 0.05;

        if (kDebugMode) {
          debugPrint('🧠 Applied merchant alias: ${alias.originalText} -> ${alias.normalizedMerchant}');
        }
      }
    }

    // Apply category assignment if we have a merchant
    if (merchant != null && category == null) {
      final assignment = _getCategoryAssignment(merchant);
      if (assignment != null && assignment.frequency >= 2) {
        category = assignment.category;
        confidenceBoost += 0.05;

        if (kDebugMode) {
          debugPrint('🧠 Applied category assignment: $merchant -> ${assignment.category}');
        }
      }
    }

    // Return enhanced result
    return result.copyWith(
      merchant: merchant,
      category: category,
      confidence: (result.confidence + confidenceBoost).clamp(0.0, 1.0),
      metadata: {
        ...?result.metadata,
        'learnedPatternsApplied': true,
        'confidenceBoost': confidenceBoost,
      },
    );
  }

  /// Get merchant alias for a given text
  MerchantAlias? _getMerchantAlias(String text) {
    final key = text.toLowerCase().trim();
    return _merchantAliases[key];
  }

  /// Get category assignment for a merchant
  CategoryAssignment? _getCategoryAssignment(String merchant) {
    final key = merchant.toLowerCase().trim();
    return _categoryAssignments[key];
  }

  /// Record when a pattern-applied result is confirmed
  Future<void> confirmPattern(ParsedExpenseResult result) async {
    if (result.metadata?['learnedPatternsApplied'] != true) return;

    final signature = _createTextSignature(result.rawText);
    final patternId = _createPatternId(signature);

    if (_patterns.containsKey(patternId)) {
      final pattern = _patterns[patternId]!;
      _patterns[patternId] = pattern.copyWith(
        timesConfirmed: pattern.timesConfirmed + 1,
      );
      await _savePatterns();
    }
  }

  /// Create normalized text signature
  String _createTextSignature(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[\d,]+\.?\d*'), '#')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Create pattern ID from signature
  String _createPatternId(String signature) {
    return signature.hashCode.abs().toString();
  }

  /// Prune old/unused patterns
  void _prunePatterns() {
    final entries = _patterns.entries.toList()
      ..sort((a, b) => a.value.lastUsedAt.compareTo(b.value.lastUsedAt));

    while (_patterns.length > _maxPatterns * 0.8) {
      if (entries.isNotEmpty) {
        _patterns.remove(entries.removeAt(0).key);
      }
    }
  }

  /// Prune old merchant aliases
  void _pruneMerchantAliases() {
    final entries = _merchantAliases.entries.toList()
      ..sort((a, b) => a.value.lastSeen.compareTo(b.value.lastSeen));

    while (_merchantAliases.length > _maxMerchantAliases * 0.8) {
      if (entries.isNotEmpty) {
        _merchantAliases.remove(entries.removeAt(0).key);
      }
    }
  }

  /// Prune old category assignments
  void _pruneCategoryAssignments() {
    final entries = _categoryAssignments.entries.toList()
      ..sort((a, b) => a.value.lastSeen.compareTo(b.value.lastSeen));

    while (_categoryAssignments.length > _maxCategoryAssignments * 0.8) {
      if (entries.isNotEmpty) {
        _categoryAssignments.remove(entries.removeAt(0).key);
      }
    }
  }

  /// Load all data
  Future<void> _loadAll() async {
    await Future.wait([
      _loadPatterns(),
      _loadMerchantAliases(),
      _loadCategoryAssignments(),
    ]);
  }

  /// Save all data
  Future<void> _saveAll() async {
    await Future.wait([
      _savePatterns(),
      _saveMerchantAliases(),
      _saveCategoryAssignments(),
    ]);
  }

  Future<void> _loadPatterns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_patternsKey);
      if (json != null) {
        final Map<String, dynamic> map = jsonDecode(json) as Map<String, dynamic>;
        _patterns.clear();
        map.forEach((key, value) {
          _patterns[key] = LearnedPattern.fromJson(value as Map<String, dynamic>);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading patterns: $e');
      }
    }
  }

  Future<void> _savePatterns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _patterns.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString(_patternsKey, jsonEncode(map));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving patterns: $e');
      }
    }
  }

  Future<void> _loadMerchantAliases() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_merchantAliasesKey);
      if (json != null) {
        final Map<String, dynamic> map = jsonDecode(json) as Map<String, dynamic>;
        _merchantAliases.clear();
        map.forEach((key, value) {
          _merchantAliases[key] = MerchantAlias.fromJson(value as Map<String, dynamic>);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading merchant aliases: $e');
      }
    }
  }

  Future<void> _saveMerchantAliases() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _merchantAliases.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString(_merchantAliasesKey, jsonEncode(map));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving merchant aliases: $e');
      }
    }
  }

  Future<void> _loadCategoryAssignments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_categoryAssignmentsKey);
      if (json != null) {
        final Map<String, dynamic> map = jsonDecode(json) as Map<String, dynamic>;
        _categoryAssignments.clear();
        map.forEach((key, value) {
          _categoryAssignments[key] = CategoryAssignment.fromJson(value as Map<String, dynamic>);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading category assignments: $e');
      }
    }
  }

  Future<void> _saveCategoryAssignments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _categoryAssignments.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString(_categoryAssignmentsKey, jsonEncode(map));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving category assignments: $e');
      }
    }
  }

  /// Clear all learned data
  Future<void> clearAll() async {
    _patterns.clear();
    _merchantAliases.clear();
    _categoryAssignments.clear();
    await _saveAll();
  }

  /// Get stats about learned data
  Map<String, int> getStats() {
    return {
      'patterns': _patterns.length,
      'reliablePatterns': _patterns.values.where((p) => p.isReliable).length,
      'merchantAliases': _merchantAliases.length,
      'categoryAssignments': _categoryAssignments.length,
    };
  }
}
