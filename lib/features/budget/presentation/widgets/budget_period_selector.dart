import 'package:flutter/material.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/selection_pill.dart';
import '../../domain/entities/budget_entity.dart';

/// Reusable Budget Period Selector Widget
///
/// Displays budget period options (Daily, Weekly, Monthly, Quarterly, 6 Months, Annual)
/// with visual feedback for selected and disabled states.
/// Periods are disabled if an enabled budget already exists for that period.
class BudgetPeriodSelector extends StatelessWidget {
  final BudgetType? selectedPeriod;
  final List<BudgetEntity>? existingBudgets; // Filtered list of enabled budgets to check against
  final ValueChanged<BudgetType> onPeriodSelected;
  final bool isDark;

  const BudgetPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.existingBudgets,
    required this.onPeriodSelected,
    required this.isDark,
  });

  // Group periods into short-term and long-term for better UX
  static const List<BudgetType> shortTermPeriods = [
    BudgetType.daily,
    BudgetType.weekly,
    BudgetType.monthly,
  ];

  static const List<BudgetType> longTermPeriods = [
    BudgetType.quarterly,
    BudgetType.semiAnnual,
    BudgetType.annual,
  ];

  String _getPeriodLabel(BudgetType period) {
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

  IconData _getPeriodIcon(BudgetType period) {
    switch (period) {
      case BudgetType.daily:
        return Icons.today_rounded;
      case BudgetType.weekly:
        return Icons.view_week_rounded;
      case BudgetType.monthly:
        return Icons.calendar_month_rounded;
      case BudgetType.quarterly:
        return Icons.event_repeat_rounded;
      case BudgetType.semiAnnual:
        return Icons.calendar_view_month_rounded;
      case BudgetType.annual:
        return Icons.calendar_today_rounded;
    }
  }

  bool _isPeriodAvailable(BudgetType period) {
    // Check if period is available
    // existingBudgets should already be filtered to only include enabled budgets of the correct category type
    // Only consider budgets with amount > 0 as "existing" budgets that block creation
    // Budgets with amount 0 are placeholder/default budgets and shouldn't block creation
    return existingBudgets == null ||
        existingBudgets!.isEmpty ||
        !existingBudgets!.any((b) => b.type == period && b.amount > 0);
  }

  void _showPeriodTooltip(BuildContext context, BudgetType period) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 100,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'A budget already exists for ${_getPeriodLabel(period)}. Please select a different period.',
                style: AppFonts.textStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Remove the overlay after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  Widget _buildPeriodPill(BuildContext context, BudgetType period) {
    final isSelected = selectedPeriod == period;
    final isAvailable = _isPeriodAvailable(period);

    return SelectionPill(
      label: _getPeriodLabel(period),
      icon: _getPeriodIcon(period),
      isSelected: isSelected,
      isDisabled: !isAvailable,
      selectedColor: AppTheme.primaryColor,
      onTap: isAvailable
          ? () => onPeriodSelected(period)
          : () => _showPeriodTooltip(context, period),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SelectionPillGroup(
      label: 'Budget Period',
      spacing: 8,
      children: [
        // Short-term periods
        ...shortTermPeriods.map((period) => _buildPeriodPill(context, period)),
        // Long-term periods
        ...longTermPeriods.map((period) => _buildPeriodPill(context, period)),
      ],
    );
  }
}

