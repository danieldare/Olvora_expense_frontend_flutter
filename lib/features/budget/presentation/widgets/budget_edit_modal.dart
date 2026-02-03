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
import '../../domain/entities/budget_entity.dart';
import '../providers/budget_providers.dart';

class BudgetEditModal extends ConsumerStatefulWidget {
  final BudgetEntity budget;
  final Function(double amount, bool enabled) onSave;

  const BudgetEditModal({
    super.key,
    required this.budget,
    required this.onSave,
  });

  @override
  ConsumerState<BudgetEditModal> createState() => _BudgetEditModalState();
}

class _BudgetEditModalState extends ConsumerState<BudgetEditModal> {
  late TextEditingController _amountController;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.budget.amount > 0
          ? NumberFormat('#,##0.00').format(widget.budget.amount)
          : '',
    );
    _amountController.addListener(() {
      setState(() {}); // Rebuild to show impact feedback
    });
    _enabled = widget.budget.enabled;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetModal(
      title: 'Edit Budget',
      borderRadius: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.budget.typeLabel,
            style: AppFonts.textStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 24),
          _buildAmountField(),
          // Show impact feedback for general budgets
          if (widget.budget.category == BudgetCategory.general) ...[
            SizedBox(height: 12),
            _buildImpactFeedback(),
          ],
          SizedBox(height: 20),
          _buildEnableToggle(),
          SizedBox(height: 32),
          _buildActionButtons(),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Amount',
          style: AppFonts.textStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _amountController,
            style: AppFonts.textStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixIcon: Builder(
                builder: (context) {
                  final selectedCurrencyAsync = ref.watch(
                    selectedCurrencyProvider,
                  );
                  final currency =
                      selectedCurrencyAsync.valueOrNull ??
                      Currency.defaultCurrency;
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: Text(
                      currency.symbol,
                      style: AppFonts.textStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  );
                },
              ),
              hintText: 'Budget Amount',
              hintStyle: AppFonts.textStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImpactFeedback() {
    final newAmount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    final oldAmount = widget.budget.amount;
    final difference = newAmount - oldAmount;

    // Get category budgets for this period
    final categoryBudgetsAsync = ref.watch(categoryBudgetsProvider);
    final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
    final currency =
        selectedCurrencyAsync.valueOrNull ?? Currency.defaultCurrency;

    if (difference == 0 || newAmount == 0) {
      return const SizedBox.shrink();
    }

    return categoryBudgetsAsync.when(
      data: (categoryBudgets) {
        final periodCategoryBudgets = categoryBudgets
            .where(
              (b) =>
                  b.type == widget.budget.type &&
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

  Widget _buildEnableToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Enable Budget',
          style: AppFonts.textStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
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
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppFonts.textStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentColor,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () {
              final amount =
                  double.tryParse(_amountController.text.replaceAll(',', '')) ??
                  0.0;
              widget.onSave(amount, _enabled);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Save',
              style: AppFonts.textStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
