import 'budget_entity.dart';

enum SuggestionType {
  newBudget,
  adjustAmount,
}

enum SuggestionStatus {
  pending,
  applied,
  dismissed,
}

class BudgetSuggestionEntity {
  final String id;
  final SuggestionType type;
  final BudgetType? budgetType;
  final String? categoryId;
  final String? categoryName;
  final String? budgetId; // For adjust_amount type
  final double? suggestedAmount;
  final double? currentAmount; // For adjust_amount type
  final String reasonCode;
  final String reasonText;
  final double confidenceScore; // 0.0 to 1.0
  final int basedOnMonths;
  final SuggestionStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? appliedAt;
  final DateTime? dismissedAt;

  BudgetSuggestionEntity({
    required this.id,
    required this.type,
    this.budgetType,
    this.categoryId,
    this.categoryName,
    this.budgetId,
    this.suggestedAmount,
    this.currentAmount,
    required this.reasonCode,
    required this.reasonText,
    required this.confidenceScore,
    required this.basedOnMonths,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.appliedAt,
    this.dismissedAt,
  });

  bool get isHighConfidence => confidenceScore >= 0.7;
  bool get canApply => status == SuggestionStatus.pending;
}
