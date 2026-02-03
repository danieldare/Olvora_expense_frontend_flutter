import '../../domain/entities/budget_suggestion_entity.dart';
import '../../domain/entities/budget_entity.dart';

class BudgetSuggestionModel {
  final String id;
  final SuggestionType type;
  final BudgetType? budgetType;
  final String? categoryId;
  final String? categoryName;
  final String? budgetId;
  final double? suggestedAmount;
  final double? currentAmount;
  final String reasonCode;
  final String reasonText;
  final double confidenceScore;
  final int basedOnMonths;
  final SuggestionStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? appliedAt;
  final DateTime? dismissedAt;

  BudgetSuggestionModel({
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

  factory BudgetSuggestionModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is String) return DateTime.parse(dateValue);
      if (dateValue is DateTime) return dateValue;
      throw FormatException('Invalid date format: $dateValue');
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    BudgetType? parseBudgetType(String? type) {
      if (type == null) return null;
      switch (type.toLowerCase()) {
        case 'daily':
          return BudgetType.daily;
        case 'weekly':
          return BudgetType.weekly;
        case 'monthly':
          return BudgetType.monthly;
        case 'quarterly':
          return BudgetType.quarterly;
        case 'semi_annual':
          return BudgetType.semiAnnual;
        case 'annual':
          return BudgetType.annual;
        default:
          return null;
      }
    }

    return BudgetSuggestionModel(
      id: json['id'] as String,
      type: json['suggestionType'] == 'new_budget'
          ? SuggestionType.newBudget
          : SuggestionType.adjustAmount,
      budgetType: parseBudgetType(json['budgetType']?.toString()),
      categoryId: json['categoryId']?.toString(),
      categoryName: json['category']?.toString() ?? json['categoryName']?.toString(),
      budgetId: json['budgetId']?.toString(),
      suggestedAmount: parseDouble(json['suggestedAmount']),
      currentAmount: parseDouble(json['currentAmount']),
      reasonCode: json['reasonCode'] as String,
      reasonText: json['reasonText'] as String,
      confidenceScore: parseDouble(json['confidenceScore']) ?? 0.0,
      basedOnMonths: json['basedOnMonths'] as int? ?? 3,
      status: _parseStatus(json['status']?.toString() ?? 'pending'),
      createdAt: parseDate(json['createdAt']),
      expiresAt: json['expiresAt'] != null ? parseDate(json['expiresAt']) : null,
      appliedAt: json['appliedAt'] != null ? parseDate(json['appliedAt']) : null,
      dismissedAt: json['dismissedAt'] != null ? parseDate(json['dismissedAt']) : null,
    );
  }

  static SuggestionStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'applied':
        return SuggestionStatus.applied;
      case 'dismissed':
        return SuggestionStatus.dismissed;
      default:
        return SuggestionStatus.pending;
    }
  }

  BudgetSuggestionEntity toEntity() {
    return BudgetSuggestionEntity(
      id: id,
      type: type,
      budgetType: budgetType,
      categoryId: categoryId,
      categoryName: categoryName,
      budgetId: budgetId,
      suggestedAmount: suggestedAmount,
      currentAmount: currentAmount,
      reasonCode: reasonCode,
      reasonText: reasonText,
      confidenceScore: confidenceScore,
      basedOnMonths: basedOnMonths,
      status: status,
      createdAt: createdAt,
      expiresAt: expiresAt,
      appliedAt: appliedAt,
      dismissedAt: dismissedAt,
    );
  }
}
