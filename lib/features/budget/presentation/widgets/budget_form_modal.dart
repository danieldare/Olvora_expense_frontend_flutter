import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/models/currency.dart';
import '../../../../core/widgets/bottom_sheet_modal.dart';
import '../../../../core/widgets/amount_input_field.dart';
import '../../../../core/widgets/category_selection_widget.dart';
import '../../domain/entities/budget_entity.dart';
import '../providers/budget_providers.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import 'budget_period_selector.dart';

/// Unified Budget Form Modal
///
/// Handles both creating new budgets and editing existing ones.
/// Automatically adapts UI based on mode (create vs edit).
class BudgetFormModal extends ConsumerStatefulWidget {
  final BudgetEntity? existingBudget; // null = create mode
  final BudgetType? initialPeriod; // for create mode
  final String? initialCategoryId; // for create mode (null = general budget)
  final BudgetCategory? budgetCategory; // Explicitly specify if creating general or category budget
  final List<BudgetEntity>? existingBudgets; // for checking duplicates
  final String? title; // Custom title (overrides default)
  final String? subtitle; // Custom subtitle (overrides default)
  final Function(
    BudgetType? period, // null in edit mode
    String? categoryId, // null for general budgets
    double amount,
    bool enabled,
  ) onSave;

  const BudgetFormModal({
    super.key,
    this.existingBudget,
    this.initialPeriod,
    this.initialCategoryId,
    this.budgetCategory, // Use this to explicitly indicate category vs general budget
    this.existingBudgets,
    this.title,
    this.subtitle,
    required this.onSave,
  });

  bool get isEditMode => existingBudget != null;
  bool get isGeneralBudget {
    if (existingBudget != null) {
      return existingBudget!.category == BudgetCategory.general;
    }
    // In create mode, use budgetCategory if provided, otherwise infer from initialCategoryId
    if (budgetCategory != null) {
      return budgetCategory == BudgetCategory.general;
    }
    // Default to general if no category ID provided
    return initialCategoryId == null;
  }

  @override
  ConsumerState<BudgetFormModal> createState() => _BudgetFormModalState();
}

class _BudgetFormModalState extends ConsumerState<BudgetFormModal> {
  late TextEditingController _amountController;
  late bool _enabled;
  BudgetType? _selectedPeriod;
  CategoryModel? _selectedCategory;

  @override
  void initState() {
    super.initState();

    if (widget.isEditMode) {
      // Edit mode: pre-fill from existing budget
      _amountController = TextEditingController(
        text: widget.existingBudget!.amount > 0
            ? NumberFormat('#,##0').format(widget.existingBudget!.amount.toInt())
            : '',
      );
      _enabled = widget.existingBudget!.enabled;
      _selectedPeriod = widget.existingBudget!.type;
    } else {
      // Create mode: start fresh
      _amountController = TextEditingController();
      _enabled = true;
      
      // Auto-select first available period
      _selectedPeriod = _getFirstAvailablePeriod();
    }

    _amountController.addListener(() {
      setState(() {}); // Rebuild for impact feedback
    });
  }

  BudgetType _getFirstAvailablePeriod() {
    // Helper to check if a period is available
    // existingBudgets should already be filtered to only include enabled budgets with amount > 0
    bool isPeriodAvailable(BudgetType period) {
      if (widget.existingBudgets == null || widget.existingBudgets!.isEmpty) {
        return true;
      }
      
      // Only consider budgets with amount > 0 as "existing" budgets that block creation
      // Budgets with amount 0 are placeholder/default budgets and shouldn't block creation
      return !widget.existingBudgets!.any((b) => b.type == period && b.amount > 0);
    }
    
    // If initial period is provided and available, use it
    if (widget.initialPeriod != null) {
      if (isPeriodAvailable(widget.initialPeriod!)) {
        return widget.initialPeriod!;
      }
    }
    
    // Otherwise, find the first available period
    for (final period in BudgetType.values) {
      if (isPeriodAvailable(period)) {
        return period;
      }
    }
    
    // Default to monthly if all are taken (shouldn't happen, but fallback)
    return BudgetType.monthly;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BottomSheetModal(
      title: widget.title ?? (widget.isEditMode ? 'Edit Budget' : 'Create Budget'),
      subtitle: widget.subtitle,
      borderRadius: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount input - world-class centered design
          _buildAmountField(isDark),

          // Period selector (create mode only)
          // Show for both general and category budgets
          if (!widget.isEditMode) ...[
            SizedBox(height: 24),
            _buildPeriodField(isDark),
            // Show duplicate error message if exists (for category budgets)
            if (widget.budgetCategory == BudgetCategory.category &&
                _isDuplicateCategoryBudget()) ...[
              SizedBox(height: 12),
              _buildDuplicateError(),
            ],
          ],

          // Category selector (create mode, category budgets only)
          // Show ONLY if explicitly creating a category budget (not a general/duration-based budget)
          if (!widget.isEditMode && 
              widget.budgetCategory == BudgetCategory.category) ...[
            SizedBox(height: 24),
            _buildCategoryField(isDark),
          ],

          // Show impact feedback for general budgets
          if (widget.isGeneralBudget) ...[
            SizedBox(height: 16),
            _buildImpactFeedback(),
          ],

          SizedBox(height: 28),

          // Enable toggle
          _buildEnableToggle(isDark),

          SizedBox(height: 32),

          // Action buttons
          _buildActionButtons(isDark),

          SizedBox(height: 24),
        ],
      ),
    );
  }


  Widget _buildAmountField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AmountInputField(
          controller: _amountController,
          placeholder: '0',
          label: 'Budget Amount',
          textColor: isDark ? Colors.white : AppTheme.textPrimary,
          fontSize: 36,
          enabled: true,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 12),
        // Current budget info (edit mode only)
        if (widget.isEditMode && widget.existingBudget!.amount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppTheme.borderColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppTheme.borderColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppTheme.textSecondary,
                ),
                SizedBox(width: 8),
                Builder(
                  builder: (context) {
                    final selectedCurrencyAsync =
                        ref.watch(selectedCurrencyProvider);
                    final currency = selectedCurrencyAsync.valueOrNull ??
                        Currency.defaultCurrency;
                    return Text(
                      'Current: ${CurrencyFormatter.format(widget.existingBudget!.amount, currency)}',
                      style: AppFonts.textStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppTheme.textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPeriodField(bool isDark) {
    // For category budgets, NO periods should be disabled
    // User can select any period, we only check for duplicates when both category and period are selected
    final isCategoryBudget = widget.budgetCategory == BudgetCategory.category ||
        widget.initialCategoryId != null;
    
    // For category budgets, pass null so no periods are disabled
    // For general budgets, use the provided existingBudgets to disable periods that already exist
    return BudgetPeriodSelector(
      selectedPeriod: _selectedPeriod,
      existingBudgets: isCategoryBudget ? null : widget.existingBudgets,
      onPeriodSelected: (period) {
        setState(() {
          _selectedPeriod = period;
        });
      },
      isDark: isDark,
    );
  }

  Widget _buildCategoryField(bool isDark) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        // Initialize category if initialCategoryId provided
        if (_selectedCategory == null && widget.initialCategoryId != null) {
          final category = categories.firstWhere(
            (c) => c.id == widget.initialCategoryId,
            orElse: () => categories.isNotEmpty ? categories.first : categories.first,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedCategory = category;
              });
            }
          });
        }

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
                });
              },
              selectedColor: AppTheme.secondaryColor,
              textColor: isDark
                  ? Colors.white.withValues(alpha: 0.9)
                  : AppTheme.textPrimary,
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
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
        return '6 Months';
      case BudgetType.annual:
        return 'Annual';
    }
  }

  Widget _buildDuplicateError() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: Colors.red,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'A budget already exists for ${_selectedCategory?.name ?? "this category"} in ${_getPeriodDisplayName(_selectedPeriod ?? BudgetType.monthly)}. Please select a different category or period.',
              style: AppFonts.textStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactFeedback() {
    final cleanedText = _amountController.text
        .replaceAll(',', '')
        .replaceAll(RegExp(r'[^\d.]'), '');
    final newAmount = double.tryParse(cleanedText) ?? 0.0;

    if (widget.isEditMode) {
      final oldAmount = widget.existingBudget!.amount;
      final difference = newAmount - oldAmount;

      if (difference == 0 || newAmount == 0) {
        return const SizedBox.shrink();
      }

      // Show impact for general budgets in edit mode
      final categoryBudgetsAsync = ref.watch(categoryBudgetsProvider);
      final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
      final currency =
          selectedCurrencyAsync.valueOrNull ?? Currency.defaultCurrency;

      return categoryBudgetsAsync.when(
        data: (categoryBudgets) {
          final periodCategoryBudgets = categoryBudgets
              .where(
                (b) =>
                    b.type == widget.existingBudget!.type &&
                    b.enabled &&
                    b.hasGeneralBudget == true,
              )
              .toList();

          if (periodCategoryBudgets.isEmpty) {
            return const SizedBox.shrink();
          }

          final totalAllocated = periodCategoryBudgets.fold<double>(
            0.0,
            (sum, budget) => sum + budget.amount,
          );

          final currentAvailable = oldAmount - totalAllocated;
          final newAvailable = newAmount - totalAllocated;
          final availableChange = newAvailable - currentAvailable;

          final isIncrease = difference > 0;
          final willExceed = newAvailable < 0;

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: willExceed
                  ? Colors.red.withValues(alpha: 0.1)
                  : isIncrease
                      ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: willExceed
                    ? Colors.red.withValues(alpha: 0.3)
                    : isIncrease
                        ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      willExceed
                          ? Icons.warning_rounded
                          : isIncrease
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                      size: 16,
                      color: willExceed
                          ? Colors.red
                          : isIncrease
                              ? const Color(0xFF22C55E)
                              : Colors.orange,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Impact on Category Budgets',
                      style: AppFonts.textStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                if (willExceed) ...[
                  Text(
                    'Warning: New amount is less than allocated to categories (${CurrencyFormatter.format(totalAllocated, currency)})',
                    style: AppFonts.textStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                ] else ...[
                  Text(
                    'Available for categories: ${CurrencyFormatter.format(newAvailable, currency)}',
                    style: AppFonts.textStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  if (availableChange != 0) ...[
                    SizedBox(height: 4),
                    Text(
                      '${isIncrease ? '+' : ''}${CurrencyFormatter.format(availableChange, currency)} ${isIncrease ? 'more' : 'less'} available',
                      style: AppFonts.textStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: isIncrease
                            ? const Color(0xFF22C55E)
                            : Colors.orange,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      );
    }

    // For create mode, show available budget info if needed
    return const SizedBox.shrink();
  }

  Widget _buildEnableToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppTheme.borderColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _enabled ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 20,
                color: _enabled
                    ? AppTheme.primaryColor
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppTheme.textSecondary),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enable Budget',
                    style: AppFonts.textStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    _enabled
                        ? 'Budget is active and tracking'
                        : 'Budget is paused',
                    style: AppFonts.textStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          CupertinoSwitch(
            value: _enabled,
            activeTrackColor: AppTheme.primaryColor,
            onChanged: (value) {
              setState(() {
                _enabled = value;
              });
            },
          ),
        ],
      ),
    );
  }

  bool _isDuplicateCategoryBudget() {
    // Check if a category budget already exists for this period + category combination
    if (widget.budgetCategory != BudgetCategory.category &&
        widget.initialCategoryId == null) {
      return false; // Not a category budget
    }

    if (_selectedCategory == null || _selectedPeriod == null) {
      return false; // Can't check without both
    }

    final categoryBudgetsAsync = ref.read(categoryBudgetsProvider);
    return categoryBudgetsAsync.when(
      data: (categoryBudgets) {
        return categoryBudgets.any(
          (budget) =>
              budget.type == _selectedPeriod &&
              budget.categoryId == _selectedCategory!.id &&
              budget.enabled &&
              budget.amount > 0 &&
              // Exclude current budget if in edit mode
              (widget.isEditMode ? budget.id != widget.existingBudget?.id : true),
        );
      },
      loading: () => false,
      error: (_, __) => false,
    );
  }

  Widget _buildActionButtons(bool isDark) {
    final cleanedText = _amountController.text
        .replaceAll(',', '')
        .replaceAll(RegExp(r'[^\d.]'), '');
    final amount = double.tryParse(cleanedText) ?? 0.0;
    
    // Validation: 
    // - Edit mode: just need amount > 0
    // - Create mode: need amount > 0, period selected, and if category budget, category must be selected
    final isCategoryBudget = widget.budgetCategory == BudgetCategory.category || 
                             widget.initialCategoryId != null;
    
    // Check for duplicate category budget
    final hasDuplicate = _isDuplicateCategoryBudget();
    
    final isValid = amount > 0 &&
        !hasDuplicate &&
        (widget.isEditMode || 
         (_selectedPeriod != null && 
          (widget.isGeneralBudget || (isCategoryBudget && _selectedCategory != null))));

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isValid
            ? () {
                widget.onSave(
                  _selectedPeriod,
                  _selectedCategory?.id,
                  amount,
                  _enabled,
                );
              }
            : null,
        icon: Icon(
          widget.isEditMode ? Icons.check_rounded : Icons.add_rounded,
          size: 20,
        ),
        label: Text(
          widget.isEditMode ? 'Save Changes' : 'Create Budget',
          style: AppFonts.textStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              AppTheme.primaryColor.withValues(alpha: 0.3),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: isValid ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

