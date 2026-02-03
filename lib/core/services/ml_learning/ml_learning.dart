/// ML Learning System for Expense Parsing
///
/// This module provides machine learning capabilities that improve
/// expense parsing accuracy over time by learning from user corrections.
///
/// ## Components
///
/// - **CorrectionTracker**: Records user corrections to parsed expenses
/// - **PatternLearner**: Learns patterns from corrections to improve future parsing
///
/// ## How It Works
///
/// 1. When a user edits a parsed expense, the correction is recorded
/// 2. Periodically, the PatternLearner analyzes corrections to find patterns
/// 3. Learned patterns are applied to future parsing to improve accuracy
///
/// ## Usage
///
/// ```dart
/// // Track a correction
/// await CorrectionTracker().trackCorrection(
///   original: parsedResult,
///   correctedMerchant: 'Starbucks',
///   correctedCategory: 'Food & Dining',
/// );
///
/// // Learn from corrections
/// await PatternLearner().learnFromCorrections();
///
/// // Apply learned patterns to new parsing
/// final enhanced = PatternLearner().applyLearnedPatterns(parsedResult);
/// ```
///
/// ## Data Retention
///
/// - Corrections: Last 500 corrections, up to 90 days
/// - Patterns: Up to 200 patterns
/// - Merchant aliases: Up to 500 aliases
/// - Category assignments: Up to 300 assignments
library;

export 'correction_tracker.dart';
export 'pattern_learner.dart';
