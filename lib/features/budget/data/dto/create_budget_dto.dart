import '../../domain/entities/budget_entity.dart';

/// DTO for creating a new budget
class CreateBudgetDto {
  final BudgetType type;
  final double amount;
  final bool enabled;
  final String? categoryId; // null for general budgets

  CreateBudgetDto({
    required this.type,
    required this.amount,
    this.enabled = true,
    this.categoryId,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'amount': amount,
      'enabled': enabled,
      if (categoryId != null) 'categoryId': categoryId,
    };
  }
}
