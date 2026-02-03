import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/models/currency.dart';
import '../../../../core/widgets/amount_input_field.dart';
import '../../../../core/widgets/bottom_sheet_modal.dart';
import '../../domain/entities/budget_entity.dart';

class NewGeneralBudgetModal extends ConsumerStatefulWidget {
  final List<BudgetEntity> existingBudgets;
  final Function(BudgetType period, double amount, bool enabled) onSave;

  const NewGeneralBudgetModal({
    super.key,
    this.existingBudgets = const [],
    required this.onSave,
  });

  @override
  ConsumerState<NewGeneralBudgetModal> createState() =>
      _NewGeneralBudgetModalState();
}

class _NewGeneralBudgetModalState extends ConsumerState<NewGeneralBudgetModal> {
  BudgetType _selectedPeriod = BudgetType.monthly;
  final TextEditingController _amountController = TextEditingController();
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    // Set initial period to first available type
    final availableTypes = BudgetType.values
        .where((type) => !widget.existingBudgets.any((b) => b.type == type))
        .toList();
    if (availableTypes.isNotEmpty) {
      _selectedPeriod = availableTypes.first;
    }
  }

  bool _isPeriodAvailable(BudgetType type) {
    return !widget.existingBudgets.any((b) => b.type == type);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetModal(
      title: 'Create General Budget',
      borderRadius: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8),
          _buildAmountField(),
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
        GestureDetector(
          onTap: () => _showPeriodPicker(),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(12),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppTheme.primaryColor,
                  size: 20,
                ),
                SizedBox(width: 12),
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
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppTheme.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AmountInputField(
          controller: _amountController,
          placeholder: '0.00',
          label: 'Budget Amount',
          onChanged: (_) => setState(() {}), // Trigger rebuild for button state
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 8),
        // Show period-specific limit
        Builder(
          builder: (context) {
            final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
            final currency =
                selectedCurrencyAsync.valueOrNull ?? Currency.defaultCurrency;

            // Get existing budget for this period to show current limit
            final existingBudget = widget.existingBudgets
                .where((b) => b.type == _selectedPeriod)
                .firstOrNull;

            if (existingBudget != null) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.warningColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: AppTheme.warningColor,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Current ${_getPeriodDisplayName(_selectedPeriod).toLowerCase()} budget: ${CurrencyFormatter.format(existingBudget.amount, currency)}',
                        style: AppFonts.textStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Text(
              '${_getPeriodDisplayName(_selectedPeriod)} budget limit: Not set',
              style: AppFonts.textStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : AppTheme.textSecondary,
              ),
            );
          },
        ),
      ],
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
          onChanged: (value) {
            setState(() {
              _enabled = value;
            });
          },
          activeTrackColor: AppTheme.accentColor,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final canSave =
        _isPeriodAvailable(_selectedPeriod) &&
        _amountController.text.isNotEmpty &&
        double.tryParse(_amountController.text) != null &&
        double.parse(_amountController.text) > 0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSave
            ? () {
                final amount =
                    double.tryParse(
                      _amountController.text.replaceAll(',', ''),
                    ) ??
                    0.0;
                if (amount > 0 && _isPeriodAvailable(_selectedPeriod)) {
                  widget.onSave(_selectedPeriod, amount, _enabled);
                  Navigator.pop(context);
                } else if (!_isPeriodAvailable(_selectedPeriod)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'A ${_getPeriodDisplayName(_selectedPeriod).toLowerCase()} budget already exists. Please select a different period.',
                      ),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
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
          'Save',
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
    final availableTypes = BudgetType.values.where(_isPeriodAvailable).toList();

    if (availableTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'All budget types already exist. You can only have one budget per period.',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    BottomSheetModal.show(
      context: context,
      title: 'Select Period',
      borderRadius: 20,
      showHandle: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 16),
          ...BudgetType.values.map((period) {
            final isAvailable = _isPeriodAvailable(period);
            final isSelected = _selectedPeriod == period;
            return ListTile(
              enabled: isAvailable,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: Icon(
                isAvailable
                    ? Icons.calendar_today_rounded
                    : Icons.lock_rounded,
                color: isAvailable
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppTheme.textSecondary)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : AppTheme.textSecondary.withValues(alpha: 0.5)),
              ),
              title: Row(
                children: [
                  Text(
                    _getPeriodDisplayName(period),
                    style: AppFonts.textStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isAvailable
                          ? (isDark ? Colors.white : AppTheme.textPrimary)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.4)
                              : AppTheme.textSecondary.withValues(alpha: 0.5)),
                    ),
                  ),
                  if (!isAvailable) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : AppTheme.borderColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Already exists',
                        style: AppFonts.textStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              trailing: isSelected
                  ? Icon(Icons.check_rounded, color: AppTheme.accentColor)
                  : null,
              onTap: isAvailable
                  ? () {
                      setState(() {
                        _selectedPeriod = period;
                      });
                      Navigator.pop(context);
                      // Rebuild to show period-specific limit
                      setState(() {});
                    }
                  : null,
            );
          }),
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
