import '../../domain/entities/budget_entity.dart';

/// Data model for budget serialization/deserialization
class BudgetModel {
  final String id;
  final BudgetType type;
  final BudgetCategory category;
  final String? categoryId;
  final String? categoryName;
  final double amount;
  final double spent;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relationship fields (for hierarchical budgets)
  final bool? hasGeneralBudget;
  final double? availableFromGeneral;
  final String? generalBudgetId;
  final bool? isIndependent;
  final double? totalAllocatedToCategories;
  final double? availableAfterAllocations;

  BudgetModel({
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

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    try {
      // Handle both string and DateTime for date fields
      DateTime parseDate(dynamic dateValue) {
        if (dateValue is String) {
          return DateTime.parse(dateValue);
        } else if (dateValue is DateTime) {
          return dateValue;
        } else {
          throw FormatException('Invalid date format: $dateValue');
        }
      }

      // Helper function to safely parse numeric values (handles both String and num)
      double parseNumeric(dynamic value) {
        if (value == null) return 0.0;
        if (value is num) return value.toDouble();
        if (value is String) {
          final parsed = double.tryParse(value);
          return parsed ?? 0.0;
        }
        return 0.0;
      }

      return BudgetModel(
        id: json['id'] as String? ?? '',
        type: _parseBudgetType(json['type']?.toString() ?? 'monthly'),
        category:
            json['categoryId'] != null &&
                json['categoryId'].toString().isNotEmpty
            ? BudgetCategory.category
            : BudgetCategory.general,
        categoryId: json['categoryId']?.toString(),
        categoryName: json['categoryName']?.toString(),
        amount: parseNumeric(json['amount']),
        spent: parseNumeric(json['spent']),
        enabled: json['enabled'] as bool? ?? true,
        createdAt: parseDate(json['createdAt']),
        updatedAt: parseDate(json['updatedAt']),
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'categoryId': categoryId,
      'amount': amount,
      'spent': spent,
      'enabled': enabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BudgetEntity toEntity() {
    return BudgetEntity(
      id: id,
      type: type,
      category: category,
      categoryId: categoryId,
      categoryName: categoryName,
      amount: amount,
      spent: spent,
      enabled: enabled,
      createdAt: createdAt,
      updatedAt: updatedAt,
      hasGeneralBudget: hasGeneralBudget,
      availableFromGeneral: availableFromGeneral,
      generalBudgetId: generalBudgetId,
      isIndependent: isIndependent,
      totalAllocatedToCategories: totalAllocatedToCategories,
      availableAfterAllocations: availableAfterAllocations,
    );
  }

  static BudgetType _parseBudgetType(String type) {
    switch (type.toLowerCase()) {
      case 'daily':
        return BudgetType.daily;
      case 'weekly':
        return BudgetType.weekly;
      case 'monthly':
        return BudgetType.monthly;
      default:
        return BudgetType.monthly;
    }
  }
}
