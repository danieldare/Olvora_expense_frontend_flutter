enum ReallocationStatus {
  pending,
  applied,
  dismissed,
}

class ReallocationSuggestionEntity {
  final String id;
  final BudgetInfo fromBudget;
  final BudgetInfo toBudget;
  final double suggestedAmount;
  final String reasoning;
  final double confidence; // 0.0 to 1.0
  final DateTime? expiresAt;
  final ReallocationStatus status;
  final DateTime createdAt;
  final DateTime? appliedAt;
  final DateTime? dismissedAt;

  ReallocationSuggestionEntity({
    required this.id,
    required this.fromBudget,
    required this.toBudget,
    required this.suggestedAmount,
    required this.reasoning,
    required this.confidence,
    this.expiresAt,
    required this.status,
    required this.createdAt,
    this.appliedAt,
    this.dismissedAt,
  });

  bool get canApply => status == ReallocationStatus.pending;
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
}

class BudgetInfo {
  final String id;
  final String name;
  final double amount;
  final double spent;
  final double projectedSpent;
  final double projectedUnused; // For source budget
  final double projectedOverage; // For target budget

  BudgetInfo({
    required this.id,
    required this.name,
    required this.amount,
    required this.spent,
    required this.projectedSpent,
    required this.projectedUnused,
    required this.projectedOverage,
  });
}
