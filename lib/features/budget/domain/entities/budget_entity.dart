enum BudgetType {
  daily,
  weekly,
  monthly,
  quarterly,
  semiAnnual,
  annual,
}

enum BudgetCategory { general, category }

class BudgetEntity {
  final String id;
  final BudgetType type;
  final BudgetCategory category;
  final String? categoryId; // For category budgets
  final String? categoryName; // Category name for display
  final double amount;
  final double spent;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relationship fields (for hierarchical budgets)
  final bool?
  hasGeneralBudget; // For category budgets: whether a general budget exists
  final double?
  availableFromGeneral; // For category budgets: available amount from general budget
  final String?
  generalBudgetId; // For category budgets: reference to general budget
  final bool?
  isIndependent; // For category budgets: whether it exists independently
  final double?
  totalAllocatedToCategories; // For general budgets: total allocated to categories
  final double?
  availableAfterAllocations; // For general budgets: remaining after category allocations

  BudgetEntity({
    required this.id,
    required this.type,
    required this.category,
    this.categoryId,
    this.categoryName,
    required this.amount,
    required this.spent,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
    this.hasGeneralBudget,
    this.availableFromGeneral,
    this.generalBudgetId,
    this.isIndependent,
    this.totalAllocatedToCategories,
    this.availableAfterAllocations,
  });

  double get remaining => amount - spent;
  double get progress => amount > 0 ? (spent / amount).clamp(0.0, 1.0) : 0.0;
  bool get isOnTrack => spent <= amount;

  String get typeLabel {
    if (category == BudgetCategory.category && categoryName != null) {
      return categoryName!;
    }
    switch (type) {
      case BudgetType.daily:
        return 'Daily Budget';
      case BudgetType.weekly:
        return 'Weekly Budget';
      case BudgetType.monthly:
        return 'Monthly Budget';
      case BudgetType.quarterly:
        return 'Quarterly Budget';
      case BudgetType.semiAnnual:
        return '6-Month Budget';
      case BudgetType.annual:
        return 'Annual Budget';
    }
  }

  String get statusText => isOnTrack ? 'On track' : 'Over budget';
}
