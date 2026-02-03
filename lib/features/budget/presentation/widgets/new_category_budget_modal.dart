import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/models/currency.dart';
import '../../../../core/widgets/amount_input_field.dart';
import '../../../../core/widgets/category_selection_widget.dart';
import '../../../../core/widgets/bottom_sheet_modal.dart';
import '../../domain/entities/budget_entity.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../categories/presentation/screens/manage_categories_screen.dart';
import '../providers/budget_providers.dart';

class NewCategoryBudgetModal extends ConsumerStatefulWidget {
  final Function(
    String? categoryId, // Optional - null for general budgets
    BudgetType period,
    double amount,
    bool enabled,
  )
  onSave;
  final BudgetType? initialPeriod;

  const NewCategoryBudgetModal({
    super.key,
    required this.onSave,
    this.initialPeriod,
  });

  @override
  ConsumerState<NewCategoryBudgetModal> createState() =>
      _NewCategoryBudgetModalState();
}

class _NewCategoryBudgetModalState
    extends ConsumerState<NewCategoryBudgetModal> {
  CategoryModel? _selectedCategory;
  BudgetType _selectedPeriod = BudgetType.monthly;
  final TextEditingController _amountController = TextEditingController();
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    // Set initial period if provided
    if (widget.initialPeriod != null) {
      _selectedPeriod = widget.initialPeriod!;
    }
    // Amount field remains empty until user manually enters a value
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String value) {
    // Trigger rebuild for button state and validation
    setState(() {});
  }

  /// Calculates available budget amount for the selected period and category
  /// Returns null if no general budget exists for the period
  double? _calculateAvailableBudget() {
    if (_selectedCategory == null) return null;

    final generalBudgetsAsync = ref.read(generalBudgetsProvider);
    final categoryBudgetsAsync = ref.read(categoryBudgetsProvider);

    return generalBudgetsAsync.maybeWhen(
      data: (generalBudgets) {
        final generalBudget = generalBudgets
            .where((b) => b.type == _selectedPeriod && b.enabled)
            .firstOrNull;

        if (generalBudget == null) return null;

        return categoryBudgetsAsync.maybeWhen(
          data: (categoryBudgets) {
            final periodCategoryBudgets = categoryBudgets
                .where((b) => b.type == _selectedPeriod && b.enabled)
                .toList();
            final totalAllocated = periodCategoryBudgets.fold<double>(
              0.0,
              (sum, budget) => sum + budget.amount,
            );
            return generalBudget.amount - totalAllocated;
          },
          orElse: () => null,
        );
      },
      orElse: () => null,
    );
  }

  /// Checks if the entered amount exceeds available budget
  bool _doesAmountExceedAvailable() {
    if (_selectedCategory == null) return false;

    final availableAmount = _calculateAvailableBudget();
    if (availableAmount == null || availableAmount <= 0) return false;

    final enteredAmount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    return enteredAmount > availableAmount && enteredAmount > 0;
  }

  /// Checks if the amount input should be disabled
  bool _isAmountInputDisabled() {
    if (_selectedCategory == null) return false;

    // Disable if duplicate budget exists
    if (_isDuplicateBudget(_selectedPeriod, _selectedCategory?.id)) {
      return true;
    }

    // Disable if no available budget
    final availableAmount = _calculateAvailableBudget();
    return availableAmount == null || availableAmount <= 0;
  }

  /// Builds the amount input field with consistent configuration
  Widget _buildAmountInputField({required bool enabled}) {
    return AmountInputField(
      controller: _amountController,
      placeholder: '0.00',
      label: 'Budget Amount',
      enabled: enabled,
      onChanged: _onAmountChanged,
      keyboardType: TextInputType.number,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetModal(
      title: 'New Budget',
      subtitle: 'Set up your spending limit',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          _buildAmountField(),
          SizedBox(height: 20),
          _buildCategoryField(),
          SizedBox(height: 20),
          _buildPeriodField(),
          SizedBox(height: 20),
          _buildEnableToggle(),
          SizedBox(height: 32),
          _buildActionButtons(),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoryField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: AppFonts.textStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : AppTheme.textSecondary,
          ),
        ),
        SizedBox(height: 12),
        CategorySelectionWidget(
          selectedCategory: _selectedCategory,
          onCategorySelected: (category) {
            setState(() {
              _selectedCategory = category;
              if (category == null) {
                _amountController.clear();
              }
              // Amount field remains empty - user must manually enter value
            });
          },
          onAddCategory: () {
            Navigator.pop(context); // Close current modal
            // Navigate to manage categories screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ManageCategoriesScreen(),
              ),
            );
          },
          showAddButton: true,
          showNoneOption: true,
          selectedColor: AppTheme.warningColor,
          textColor: isDark
              ? Colors.white.withValues(alpha: 0.9)
              : AppTheme.textPrimary,
        ),
      ],
    );
  }

  Widget _buildPeriodField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Period',
          style: AppFonts.textStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : AppTheme.textSecondary,
          ),
        ),
        SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showPeriodPicker(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppTheme.borderColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : AppTheme.borderColor,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _getPeriodDisplayName(_selectedPeriod),
                      style: AppFonts.textStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : AppTheme.textSecondary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isDuplicateBudget(BudgetType period, String? categoryId) {
    if (categoryId == null) return false;

    final categoryBudgetsAsync = ref.read(categoryBudgetsProvider);
    return categoryBudgetsAsync.when(
      data: (categoryBudgets) {
        return categoryBudgets.any(
          (budget) =>
              budget.type == period &&
              budget.categoryId == categoryId &&
              budget.enabled,
        );
      },
      loading: () => false,
      error: (_, __) => false,
    );
  }

  Widget _buildAmountField() {
    // Watch providers to reactively update the field state
    ref.watch(generalBudgetsProvider);
    ref.watch(categoryBudgetsProvider);

    final isDisabled = _isAmountInputDisabled();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildAmountInputField(enabled: !isDisabled),
        SizedBox(height: 8),
        // Show available amount from general budget and validation errors (only when category is selected)
        if (_selectedCategory != null) _buildValidationSection(),
      ],
    );
  }

  /// Builds the validation section showing available budget and error messages
  Widget _buildValidationSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
    final currency =
        selectedCurrencyAsync.valueOrNull ?? Currency.defaultCurrency;

    final isDuplicate = _isDuplicateBudget(
      _selectedPeriod,
      _selectedCategory?.id,
    );
    final availableAmount = _calculateAvailableBudget();
    final exceedsAvailable = _doesAmountExceedAvailable();

    // Collect all validation errors
    final List<String> errors = [];
    if (isDuplicate) {
      errors.add(
        'A ${_getPeriodDisplayName(_selectedPeriod).toLowerCase()} budget already exists for this category',
      );
    }
    if (exceedsAvailable) {
      errors.add('Amount exceeds available budget');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (availableAmount != null)
          Text(
            'Available budget: ${CurrencyFormatter.format(availableAmount, currency)}',
            style: AppFonts.textStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: exceedsAvailable
                  ? AppTheme.errorColor
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppTheme.textSecondary),
            ),
          )
        else if (!isDuplicate)
          Text(
            'No general budget for this period (independent mode)',
            style: AppFonts.textStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : AppTheme.textSecondary,
            ),
          ),
        if (errors.isNotEmpty) ...[
          if (availableAmount != null || isDuplicate) SizedBox(height: 8),
          ...errors.map((error) => _buildErrorWidget(error)),
        ],
      ],
    );
  }

  /// Builds a single error message widget
  Widget _buildErrorWidget(String error) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.errorColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 14,
              color: AppTheme.errorColor,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                error,
                style: AppFonts.textStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.errorColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnableToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Enable Budget',
          style: AppFonts.textStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        CupertinoSwitch(
          value: _enabled,
          activeTrackColor: AppTheme.accentColor,
          onChanged: (value) {
            setState(() {
              _enabled = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    // Watch providers to reactively update button state
    ref.watch(generalBudgetsProvider);
    ref.watch(categoryBudgetsProvider);

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;

    final isDuplicate =
        _selectedCategory != null &&
        _isDuplicateBudget(_selectedPeriod, _selectedCategory?.id);
    final exceedsAvailable = _doesAmountExceedAvailable();

    final canSave =
        amount > 0 &&
        !exceedsAvailable &&
        !isDuplicate &&
        _selectedCategory != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSave
            ? () {
                widget.onSave(
                  _selectedCategory?.id, // Can be null for general budgets
                  _selectedPeriod,
                  amount,
                  _enabled,
                );
                Navigator.pop(context);
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canSave
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          'Create Budget',
          style: AppFonts.textStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showPeriodPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    BottomSheetModal.show(
      context: context,
      title: 'Select Period',
      borderRadius: 20,
      showHandle: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 16),
          ...BudgetType.values.map(
            (period) => ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: Icon(
                Icons.calendar_today_rounded,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppTheme.textSecondary,
              ),
              title: Text(
                _getPeriodDisplayName(period),
                style: AppFonts.textStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              trailing: _selectedPeriod == period
                  ? Icon(Icons.check_rounded, color: AppTheme.accentColor)
                  : null,
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
                Navigator.pop(context);
                // Rebuild to show period-specific validation
                // User's input is always preserved
                setState(() {});
              },
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  String _getPeriodDisplayName(BudgetType period) {
    switch (period) {
      case BudgetType.daily:
        return 'Daily';
      case BudgetType.weekly:
        return 'Weekly';
      case BudgetType.monthly:
        return 'Monthly';
      case BudgetType.quarterly:
        return 'Quarterly';
      case BudgetType.semiAnnual:
        return '6-Month';
      case BudgetType.annual:
        return 'Annual';
    }
  }
}
