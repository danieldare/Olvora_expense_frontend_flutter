import '../../data/matchers/category_matcher.dart';
import '../../domain/entities/category_mapping.dart';
import '../../domain/entities/parsed_expense.dart';

/// Use case: Match categories for parsed expenses
class MatchCategories {
  final CategoryMatcher _matcher;

  MatchCategories({
    required CategoryMatcher matcher,
  }) : _matcher = matcher;

  /// Match categories for all unique category names
  Future<List<CategoryMapping>> execute(List<String> originalCategories) async {
    return await _matcher.matchAll(originalCategories);
  }

  /// Match category for a single expense and update it
  Future<ParsedExpense> matchAndUpdateExpense(ParsedExpense expense) async {
    final mapping = await _matcher.match(expense.originalCategory);
    return expense.copyWithCategory(mapping.mappedCategoryName ?? 'other');
  }

  /// Match categories for all expenses
  Future<List<ParsedExpense>> matchAllExpenses(List<ParsedExpense> expenses) async {
    final updated = <ParsedExpense>[];
    for (final expense in expenses) {
      updated.add(await matchAndUpdateExpense(expense));
    }
    return updated;
  }
}
