/// Expense Parsing Module
///
/// This module provides unified parsing infrastructure for expenses
/// detected from SMS, clipboard, voice, and receipt sources.
///
/// Key components:
/// - [ParsedExpenseResult] - Unified expense data model
/// - [ConfidenceScorer] - Calculates confidence scores
/// - [GenericExpenseParser] - Pattern-based parser (fast, offline)
/// - [AIExpenseParser] - AI-powered parser (accurate, needs network)
/// - [HybridExpenseParser] - Combines generic and AI parsing
/// - [ParsingSource] - Enum for expense sources
/// - [ConfidenceLevel] - Enum for confidence levels

library;

export 'parsed_expense_result.dart';
export 'confidence_scorer.dart';
export 'generic_expense_parser.dart';
export 'ai_expense_parser.dart';
export 'hybrid_parser.dart';
