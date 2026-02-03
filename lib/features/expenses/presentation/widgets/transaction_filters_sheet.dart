import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bottom_sheet_modal.dart';
import '../../../../core/widgets/category_selection_widget.dart';
import '../../../../core/widgets/selection_pill.dart';
import '../providers/transaction_filters_provider.dart';

class TransactionFiltersSheet extends ConsumerStatefulWidget {
  const TransactionFiltersSheet({super.key});

  @override
  ConsumerState<TransactionFiltersSheet> createState() =>
      _TransactionFiltersSheetState();
}

class _TransactionFiltersSheetState
    extends ConsumerState<TransactionFiltersSheet> {
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(transactionFiltersProvider);
    _minAmountController = TextEditingController(
      text: filters.minAmount?.toStringAsFixed(0) ?? '',
    );
    _maxAmountController = TextEditingController(
      text: filters.maxAmount?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final labelColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : AppTheme.textSecondary;
    final filters = ref.watch(transactionFiltersProvider);
    final notifier = ref.read(transactionFiltersProvider.notifier);

    return BottomSheetModal(
      title: 'Filters',
      subtitle: filters.hasActiveFilters
          ? '${filters.activeFilterCount} filter${filters.activeFilterCount > 1 ? 's' : ''} active'
          : 'Refine your transactions',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clear All button when filters active
          if (filters.hasActiveFilters) ...[
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  notifier.clearAllFilters();
                  _minAmountController.clear();
                  _maxAmountController.clear();
                },
                icon: Icon(
                  Icons.filter_alt_off_rounded,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                label: Text(
                  'Clear All',
                  style: AppFonts.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ),
          ],
          SizedBox(height: 8),

          // Date Range Section
          _buildSectionLabel('Date Range', labelColor),
          SizedBox(height: 12),
          _buildDateRangeField(filters, notifier, isDark, labelColor),
          SizedBox(height: 20),

          // Category Section
          _buildSectionLabel('Category', labelColor),
          SizedBox(height: 12),
          CategorySelectionWidget(
            selectedCategory: filters.category,
            onCategorySelected: (category) {
              notifier.setCategory(category);
            },
            showAddButton: false,
            showNoneOption: true,
            selectedColor: AppTheme.primaryColor,
            textColor: isDark
                ? Colors.white.withValues(alpha: 0.9)
                : AppTheme.textPrimary,
          ),
          SizedBox(height: 20),

          // Amount Range Section
          _buildSectionLabel('Amount Range', labelColor),
          SizedBox(height: 12),
          _buildAmountRangeField(filters, notifier, isDark, textColor, labelColor),
          SizedBox(height: 20),

          // Sort Section
          _buildSectionLabel('Sort By', labelColor),
          SizedBox(height: 12),
          _buildSortField(filters, notifier, isDark),
          SizedBox(height: 32),

          // Apply button
          _buildApplyButton(),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Section label matching NewCategoryBudgetModal style
  Widget _buildSectionLabel(String title, Color labelColor) {
    return Text(
      title,
      style: AppFonts.textStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: labelColor,
      ),
    );
  }

  Widget _buildDateRangeField(
    TransactionFilters filters,
    TransactionFiltersNotifier notifier,
    bool isDark,
    Color? labelColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DateRangeFilter.values
              .where((f) => f != DateRangeFilter.custom)
              .map((range) => SelectionPill(
                    label: _getDateRangeLabel(range),
                    isSelected: filters.dateRange == range,
                    onTap: () => notifier.setDateRange(range),
                    selectedColor: AppTheme.primaryColor,
                  ))
              .toList(),
        ),
        SizedBox(height: 12),
        // Custom date range button
        _buildCustomDateRangeButton(filters, isDark, labelColor),
      ],
    );
  }

  Widget _buildCustomDateRangeButton(
    TransactionFilters filters,
    bool isDark,
    Color? labelColor,
  ) {
    final isSelected = filters.dateRange == DateRangeFilter.custom;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCustomDateRangePicker(context),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : AppTheme.borderColor),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.date_range_rounded,
                size: 18,
                color: isSelected
                    ? AppTheme.primaryColor
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppTheme.textSecondary),
              ),
              SizedBox(width: 8),
              Text(
                isSelected && filters.customStartDate != null
                    ? '${DateFormat('MMM d').format(filters.customStartDate!)} - ${DateFormat('MMM d').format(filters.customEndDate!)}'
                    : 'Custom Range',
                style: AppFonts.textStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppTheme.textPrimary),
                  letterSpacing: isSelected ? 0.2 : 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountRangeField(
    TransactionFilters filters,
    TransactionFiltersNotifier notifier,
    bool isDark,
    Color textColor,
    Color? labelColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildAmountTextField(
            controller: _minAmountController,
            hint: 'Min',
            isDark: isDark,
            textColor: textColor,
            labelColor: labelColor,
            onChanged: (value) {
              final amount = double.tryParse(value);
              notifier.setAmountRange(
                min: amount,
                max: filters.maxAmount,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'to',
            style: AppFonts.textStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
        ),
        Expanded(
          child: _buildAmountTextField(
            controller: _maxAmountController,
            hint: 'Max',
            isDark: isDark,
            textColor: textColor,
            labelColor: labelColor,
            onChanged: (value) {
              final amount = double.tryParse(value);
              notifier.setAmountRange(
                min: filters.minAmount,
                max: amount,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAmountTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    required Color textColor,
    required Color? labelColor,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : AppTheme.borderColor,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppFonts.textStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : AppTheme.textSecondary,
          ),
          prefixText: '\$ ',
          prefixStyle: AppFonts.textStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
        style: AppFonts.textStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildSortField(
    TransactionFilters filters,
    TransactionFiltersNotifier notifier,
    bool isDark,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TransactionSortOption.values
          .map((option) => SelectionPill(
                label: _getSortLabel(option),
                isSelected: filters.sortOption == option,
                onTap: () => notifier.setSortOption(option),
                icon: _getSortIcon(option),
                selectedColor: AppTheme.primaryColor,
              ))
          .toList(),
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          'Apply Filters',
          style: AppFonts.textStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _showCustomDateRangePicker(BuildContext context) async {
    final filters = ref.read(transactionFiltersProvider);
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: filters.customStartDate != null
          ? DateTimeRange(
              start: filters.customStartDate!,
              end: filters.customEndDate ?? now,
            )
          : DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(transactionFiltersProvider.notifier).setCustomDateRange(
            picked.start,
            picked.end,
          );
    }
  }

  String _getDateRangeLabel(DateRangeFilter range) {
    switch (range) {
      case DateRangeFilter.all:
        return 'All Time';
      case DateRangeFilter.today:
        return 'Today';
      case DateRangeFilter.thisWeek:
        return 'This Week';
      case DateRangeFilter.thisMonth:
        return 'This Month';
      case DateRangeFilter.thisYear:
        return 'This Year';
      case DateRangeFilter.custom:
        return 'Custom';
    }
  }

  String _getSortLabel(TransactionSortOption option) {
    switch (option) {
      case TransactionSortOption.dateNewest:
        return 'Newest';
      case TransactionSortOption.dateOldest:
        return 'Oldest';
      case TransactionSortOption.amountHighest:
        return 'Highest';
      case TransactionSortOption.amountLowest:
        return 'Lowest';
    }
  }

  IconData _getSortIcon(TransactionSortOption option) {
    switch (option) {
      case TransactionSortOption.dateNewest:
        return Icons.arrow_downward_rounded;
      case TransactionSortOption.dateOldest:
        return Icons.arrow_upward_rounded;
      case TransactionSortOption.amountHighest:
        return Icons.trending_up_rounded;
      case TransactionSortOption.amountLowest:
        return Icons.trending_down_rounded;
    }
  }
}

/// Helper function to show the filters sheet
Future<void> showTransactionFiltersSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const TransactionFiltersSheet(),
  );
}
