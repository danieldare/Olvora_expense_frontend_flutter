import '../../../../features/expenses/domain/entities/expense_entity.dart';

/// An expense parsed from the import file (before mapping to Olvora categories)
class ParsedExpense {
  final String id;                  // Temporary ID for preview
  final String title;
  final double amount;
  final String originalCategory;    // From file
  final String? mappedCategoryName;   // After mapping (category name)
  final DateTime date;
  final String? merchant;
  final String? notes;
  final int sourceRow;              // For debugging/reference
  final String? sourceMonth;        // For pivot: "January"
  final String? currency;           // Currency code detected from file (e.g., 'USD', 'NGN')

  const ParsedExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.originalCategory,
    this.mappedCategoryName,
    required this.date,
    this.merchant,
    this.notes,
    required this.sourceRow,
    this.sourceMonth,
    this.currency,
  });

  ParsedExpense copyWithCategory(String categoryName) {
    return ParsedExpense(
      id: id,
      title: title,
      amount: amount,
      originalCategory: originalCategory,
      mappedCategoryName: categoryName,
      date: date,
      merchant: merchant,
      notes: notes,
      sourceRow: sourceRow,
      sourceMonth: sourceMonth,
      currency: currency,
    );
  }

  /// Convert to ExpenseCategory enum
  ExpenseCategory? get categoryEnum {
    if (mappedCategoryName == null) return null;
    final name = mappedCategoryName!.toLowerCase();
    return ExpenseCategory.values.firstWhere(
      (e) => e.name == name,
      orElse: () => ExpenseCategory.other,
    );
  }
}
