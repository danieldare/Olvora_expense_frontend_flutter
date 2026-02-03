import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/expense_entity.dart';
import 'expenses_providers.dart';
import '../../../categories/data/repositories/category_repository.dart';

/// Date range filter options
enum DateRangeFilter {
  all,
  today,
  thisWeek,
  thisMonth,
  thisYear,
  custom,
}

/// Sort options for transactions
enum TransactionSortOption {
  dateNewest,
  dateOldest,
  amountHighest,
  amountLowest,
}

/// Filter state for transactions
class TransactionFilters {
  final String searchQuery;
  final CategoryModel? category; // Now uses CategoryModel from backend
  final DateRangeFilter dateRange;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final double? minAmount;
  final double? maxAmount;
  final TransactionSortOption sortOption;

  const TransactionFilters({
    this.searchQuery = '',
    this.category,
    this.dateRange = DateRangeFilter.all,
    this.customStartDate,
    this.customEndDate,
    this.minAmount,
    this.maxAmount,
    this.sortOption = TransactionSortOption.dateNewest,
  });

  /// Check if any filters are active (excluding sort)
  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      category != null ||
      dateRange != DateRangeFilter.all ||
      minAmount != null ||
      maxAmount != null;

  /// Count of active filters
  int get activeFilterCount {
    int count = 0;
    if (searchQuery.isNotEmpty) count++;
    if (category != null) count++;
    if (dateRange != DateRangeFilter.all) count++;
    if (minAmount != null || maxAmount != null) count++;
    return count;
  }

  TransactionFilters copyWith({
    String? searchQuery,
    CategoryModel? category,
    bool clearCategory = false,
    DateRangeFilter? dateRange,
    DateTime? customStartDate,
    bool clearCustomStartDate = false,
    DateTime? customEndDate,
    bool clearCustomEndDate = false,
    double? minAmount,
    bool clearMinAmount = false,
    double? maxAmount,
    bool clearMaxAmount = false,
    TransactionSortOption? sortOption,
  }) {
    return TransactionFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      category: clearCategory ? null : (category ?? this.category),
      dateRange: dateRange ?? this.dateRange,
      customStartDate: clearCustomStartDate
          ? null
          : (customStartDate ?? this.customStartDate),
      customEndDate:
          clearCustomEndDate ? null : (customEndDate ?? this.customEndDate),
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
      sortOption: sortOption ?? this.sortOption,
    );
  }

  /// Reset all filters to default
  TransactionFilters reset() {
    return const TransactionFilters();
  }
}

/// Notifier for managing transaction filters
class TransactionFiltersNotifier extends StateNotifier<TransactionFilters> {
  TransactionFiltersNotifier() : super(const TransactionFilters());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategory(CategoryModel? category) {
    if (category == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(category: category);
    }
  }

  void setDateRange(DateRangeFilter range) {
    state = state.copyWith(dateRange: range);
  }

  void setCustomDateRange(DateTime start, DateTime end) {
    state = state.copyWith(
      dateRange: DateRangeFilter.custom,
      customStartDate: start,
      customEndDate: end,
    );
  }

  void setAmountRange({double? min, double? max}) {
    state = state.copyWith(
      minAmount: min,
      maxAmount: max,
      clearMinAmount: min == null,
      clearMaxAmount: max == null,
    );
  }

  void setSortOption(TransactionSortOption option) {
    state = state.copyWith(sortOption: option);
  }

  void clearAllFilters() {
    state = state.reset();
  }

  void clearCategory() {
    state = state.copyWith(clearCategory: true);
  }

  void clearDateRange() {
    state = state.copyWith(
      dateRange: DateRangeFilter.all,
      clearCustomStartDate: true,
      clearCustomEndDate: true,
    );
  }

  void clearAmountRange() {
    state = state.copyWith(clearMinAmount: true, clearMaxAmount: true);
  }
}

/// Provider for transaction filters state
final transactionFiltersProvider =
    StateNotifierProvider<TransactionFiltersNotifier, TransactionFilters>((ref) {
  return TransactionFiltersNotifier();
});

/// Provider for filtered and sorted transactions
/// This provider watches both the expenses and filters, returning filtered results
final filteredTransactionsProvider = Provider<AsyncValue<List<ExpenseEntity>>>((ref) {
  final expensesAsync = ref.watch(expensesProvider);
  final filters = ref.watch(transactionFiltersProvider);

  return expensesAsync.whenData((expenses) {
    var filtered = List<ExpenseEntity>.from(expenses);

    // Apply category filter - match by category name (case-insensitive)
    if (filters.category != null) {
      final filterCategoryName = filters.category!.name.toLowerCase();
      filtered = filtered.where((e) =>
        e.category.name.toLowerCase() == filterCategoryName
      ).toList();
    }

    // Apply search filter
    if (filters.searchQuery.isNotEmpty) {
      final query = filters.searchQuery.toLowerCase();
      filtered = filtered.where((e) {
        return e.title.toLowerCase().contains(query) ||
            (e.merchant?.toLowerCase().contains(query) ?? false) ||
            (e.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply date range filter
    filtered = _applyDateRangeFilter(filtered, filters);

    // Apply amount range filter
    if (filters.minAmount != null) {
      filtered = filtered.where((e) => e.amount >= filters.minAmount!).toList();
    }
    if (filters.maxAmount != null) {
      filtered = filtered.where((e) => e.amount <= filters.maxAmount!).toList();
    }

    // Apply sorting
    filtered = _applySorting(filtered, filters.sortOption);

    return filtered;
  });
});

/// Apply date range filter to expenses
List<ExpenseEntity> _applyDateRangeFilter(
  List<ExpenseEntity> expenses,
  TransactionFilters filters,
) {
  if (filters.dateRange == DateRangeFilter.all) {
    return expenses;
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  DateTime startDate;
  DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

  switch (filters.dateRange) {
    case DateRangeFilter.all:
      return expenses;

    case DateRangeFilter.today:
      startDate = today;
      break;

    case DateRangeFilter.thisWeek:
      // Start from Sunday of current week
      final weekday = now.weekday;
      final daysFromSunday = weekday == 7 ? 0 : weekday;
      startDate = today.subtract(Duration(days: daysFromSunday));
      break;

    case DateRangeFilter.thisMonth:
      startDate = DateTime(now.year, now.month, 1);
      break;

    case DateRangeFilter.thisYear:
      startDate = DateTime(now.year, 1, 1);
      break;

    case DateRangeFilter.custom:
      if (filters.customStartDate == null || filters.customEndDate == null) {
        return expenses;
      }
      startDate = DateTime(
        filters.customStartDate!.year,
        filters.customStartDate!.month,
        filters.customStartDate!.day,
      );
      endDate = DateTime(
        filters.customEndDate!.year,
        filters.customEndDate!.month,
        filters.customEndDate!.day,
        23,
        59,
        59,
        999,
      );
      break;
  }

  return expenses.where((e) {
    final expenseDate = DateTime(e.date.year, e.date.month, e.date.day);
    return !expenseDate.isBefore(startDate) && !expenseDate.isAfter(endDate);
  }).toList();
}

/// Apply sorting to expenses
List<ExpenseEntity> _applySorting(
  List<ExpenseEntity> expenses,
  TransactionSortOption sortOption,
) {
  final sorted = List<ExpenseEntity>.from(expenses);

  switch (sortOption) {
    case TransactionSortOption.dateNewest:
      sorted.sort((a, b) => b.date.compareTo(a.date));
      break;
    case TransactionSortOption.dateOldest:
      sorted.sort((a, b) => a.date.compareTo(b.date));
      break;
    case TransactionSortOption.amountHighest:
      sorted.sort((a, b) => b.amount.compareTo(a.amount));
      break;
    case TransactionSortOption.amountLowest:
      sorted.sort((a, b) => a.amount.compareTo(b.amount));
      break;
  }

  return sorted;
}

/// Provider that groups filtered transactions by date
final groupedTransactionsProvider =
    Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final filteredAsync = ref.watch(filteredTransactionsProvider);

  return filteredAsync.whenData((expenses) {
    final Map<DateTime, List<ExpenseEntity>> grouped = {};

    for (final expense in expenses) {
      final dateKey = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(expense);
    }

    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Newest first by default

    return sortedDates
        .map((date) => {'date': date, 'expenses': grouped[date]!})
        .toList();
  });
});
