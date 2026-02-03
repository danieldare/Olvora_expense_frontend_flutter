import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/models/currency.dart';
import '../../../budget/domain/entities/budget_entity.dart';
import '../../../budget/presentation/providers/budget_providers.dart';
import '../../../../core/navigation/nav_item.dart';
import '../../../../core/navigation/navigation_providers.dart';
import '../providers/spending_summary_providers.dart';
import '../providers/dismissed_budget_messages_provider.dart';
import '../providers/hide_spending_amounts_provider.dart';

class SpendingSummaryCard extends ConsumerStatefulWidget {
  /// When true, uses smaller spacing and fonts for the content part (label, amount, budget, progress bar).
  final bool compact;

  const SpendingSummaryCard({super.key, this.compact = false});

  @override
  ConsumerState<SpendingSummaryCard> createState() =>
      _SpendingSummaryCardState();
}

class _SpendingSummaryCardState extends ConsumerState<SpendingSummaryCard> {
  BudgetType _selectedPeriod = BudgetType.weekly;

  BudgetEntity? _getBudgetForPeriod(List<BudgetEntity> budgets) {
    try {
      // Find budget for the selected period, prefer enabled ones
      final enabledBudgets = budgets
          .where((b) => b.type == _selectedPeriod && b.enabled)
          .toList();
      if (enabledBudgets.isNotEmpty) return enabledBudgets.first;

      // If no enabled budget, return any budget for the period
      return budgets.firstWhere((b) => b.type == _selectedPeriod);
    } catch (e) {
      return null;
    }
  }

  String get _periodLabel {
    switch (_selectedPeriod) {
      case BudgetType.daily:
        return 'Daily Spending';
      case BudgetType.weekly:
        return 'Weekly Spending';
      case BudgetType.monthly:
        return 'Monthly Spending';
      case BudgetType.quarterly:
        return 'Quarterly Spending';
      case BudgetType.semiAnnual:
        return '6-Month Spending';
      case BudgetType.annual:
        return 'Annual Spending';
    }
  }

  /// Short period name for messages, e.g. "daily", "weekly".
  String get _periodShort {
    switch (_selectedPeriod) {
      case BudgetType.daily:
        return 'daily';
      case BudgetType.weekly:
        return 'weekly';
      case BudgetType.monthly:
        return 'monthly';
      case BudgetType.quarterly:
        return 'quarterly';
      case BudgetType.semiAnnual:
        return '6-month';
      case BudgetType.annual:
        return 'annual';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use valueOrNull to avoid nested when calls - prevents flickering
    // This approach ensures we only rebuild once when all data is ready
    final budgetsAsync = ref.watch(generalBudgetsProvider);
    final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
    final spendingAsync = ref.watch(periodSpendingProvider(_selectedPeriod));

    // Get values directly - this prevents multiple rebuilds
    final currency =
        selectedCurrencyAsync.valueOrNull ?? Currency.defaultCurrency;
    final currentSpent = spendingAsync.valueOrNull ?? 0.0;
    final budgets = budgetsAsync.valueOrNull;

    // Only show loading if ALL providers are loading and we have no cached data
    // This prevents flickering when one provider resolves before others
    final isLoading =
        (selectedCurrencyAsync.isLoading &&
            currency == Currency.defaultCurrency) ||
        (spendingAsync.isLoading && currentSpent == 0.0) ||
        (budgetsAsync.isLoading && budgets == null);

    if (isLoading) {
      final hideAmounts = ref.watch(hideSpendingAmountsProvider);
      return _buildCardWithActions(
        currency,
        0.0,
        0.0,
        0.0,
        hideAmounts: hideAmounts,
        hasNoBudget: false,
        budgetsLoaded: false,
      );
    }

    // Calculate values only when we have budget data
    final budget = budgets != null ? _getBudgetForPeriod(budgets) : null;
    final currentBudget = budget?.amount ?? 0.0;

    // Memoize progress calculation - prevents recalculation on every build
    final progress = currentBudget > 0
        ? (currentSpent / currentBudget).clamp(0.0, 1.0)
        : 0.0;

    final isOverBudget = currentBudget > 0 && currentSpent > currentBudget;
    final overBudgetAmount = isOverBudget ? currentSpent - currentBudget : 0.0;
    final hasNoBudget = budgets != null && currentBudget == 0.0;

    final hideAmounts = ref.watch(hideSpendingAmountsProvider);

    return _buildCardWithActions(
      currency,
      currentSpent,
      currentBudget,
      progress,
      hideAmounts: hideAmounts,
      isOverBudget: isOverBudget,
      overBudgetAmount: overBudgetAmount,
      hasNoBudget: hasNoBudget,
      budgetsLoaded: budgets != null,
    );
  }

  static const String _maskedAmount = '******';

  Widget _buildCardWithActions(
    Currency? selectedCurrency,
    double currentSpent,
    double currentBudget,
    double progress, {
    bool hideAmounts = false,
    bool isOverBudget = false,
    double overBudgetAmount = 0.0,
    bool hasNoBudget = false,
    bool budgetsLoaded = false,
  }) {
    final currency = selectedCurrency ?? Currency.defaultCurrency;
    // Use provider instead of local state - prevents setState rebuilds
    final dismissedState = ref.watch(dismissedBudgetMessagesProvider);
    final isDismissed = dismissedState.isPeriodDismissed(_selectedPeriod);
    // Only show "no budget" message when budgets are actually loaded AND budget is 0
    // This prevents showing the message during loading or error states
    final shouldShowNoBudgetMessage =
        budgetsLoaded && hasNoBudget && !isDismissed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCard(
          selectedCurrency,
          currentSpent,
          currentBudget,
          progress,
          hideAmounts: hideAmounts,
          isOverBudget: isOverBudget,
          overBudgetAmount: overBudgetAmount,
        ),
        SizedBox(height: AppSpacing.sectionMedium),
        // Over-budget message (outside the card)
        if (isOverBudget)
          _buildOverBudgetMessage(currency, overBudgetAmount, hideAmounts),
        // No budget message (shown right after over budget message, or alone if not over budget)
        if (shouldShowNoBudgetMessage)
          _buildNoBudgetMessage(currency, isOverBudget),
      ],
    );
  }

  Widget _buildCard(
    Currency? selectedCurrency,
    double currentSpent,
    double currentBudget,
    double progress, {
    bool hideAmounts = false,
    bool isOverBudget = false,
    double overBudgetAmount = 0.0,
  }) {
    final currency = selectedCurrency ?? Currency.defaultCurrency;

    // Use dynamic theme colors for elegant gradient blend
    final gradientColors = AppTheme.walletGradient;
    final primaryColor = AppTheme.primaryColor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPadding,
        vertical: AppSpacing.cardPaddingSmall,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors.length >= 2
              ? [gradientColors[0], gradientColors[1]]
              : [primaryColor, primaryColor],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Spending Summary Header with visibility toggle
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Spending Summary',
                    style: AppFonts.textStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Material(
                type: MaterialType.transparency,
                child: IconButton(
                  onPressed: () =>
                      ref.read(hideSpendingAmountsProvider.notifier).toggle(),
                  icon: Icon(
                    hideAmounts
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 22,
                  ),
                  tooltip: hideAmounts ? 'Show amounts' : 'Hide amounts',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: widget.compact ? 10 : 12),
          // Period Tabs Container (slightly reduced)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color.fromARGB(84, 21, 18, 39),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _PeriodTab(
                    label: 'Daily',
                    isSelected: _selectedPeriod == BudgetType.daily,
                    onTap: () =>
                        setState(() => _selectedPeriod = BudgetType.daily),
                  ),
                ),
                SizedBox(width: 3),
                Expanded(
                  child: _PeriodTab(
                    label: 'Weekly',
                    isSelected: _selectedPeriod == BudgetType.weekly,
                    onTap: () =>
                        setState(() => _selectedPeriod = BudgetType.weekly),
                  ),
                ),
                SizedBox(width: 3),
                Expanded(
                  child: _PeriodTab(
                    label: 'Monthly',
                    isSelected: _selectedPeriod == BudgetType.monthly,
                    onTap: () =>
                        setState(() => _selectedPeriod = BudgetType.monthly),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: widget.compact
                ? AppSpacing.sectionMedium
                : AppSpacing.sectionLarge,
          ),
          // Spending Label (compact: smaller font and gaps below)
          Text(
            _periodLabel,
            textAlign: TextAlign.center,
            style: AppFonts.textStyle(
              fontSize: widget.compact ? 13 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
          SizedBox(height: widget.compact ? 5 : 8),
          // Spending Amount (masked when hide amounts is on)
          Text(
            hideAmounts
                ? _maskedAmount
                : CurrencyFormatter.format(currentSpent, currency),
            textAlign: TextAlign.center,
            style: AppFonts.textStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          SizedBox(height: widget.compact ? 2 : 4),
          // Budget Info (masked when hide amounts is on)
          Text.rich(
            TextSpan(
              text: 'out of ',
              style: AppFonts.textStyle(
                fontSize: widget.compact ? 13 : 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.70),
              ),
              children: [
                TextSpan(
                  text: hideAmounts
                      ? _maskedAmount
                      : CurrencyFormatter.format(currentBudget, currency),
                  style: AppFonts.textStyle(
                    fontSize: widget.compact ? 13 : 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
                TextSpan(
                  text: ' budget',
                  style: AppFonts.textStyle(
                    fontSize: widget.compact ? 13 : 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.70),
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: widget.compact
                ? AppSpacing.sectionSmall
                : AppSpacing.sectionMedium,
          ),
          // Progress Bar
          _ProgressBar(
            progress: progress,
            isOverBudget: isOverBudget,
            compact: widget.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildOverBudgetMessage(
    Currency currency,
    double overBudgetAmount,
    bool hideAmounts,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.transparent : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final amountText = hideAmounts
        ? _maskedAmount
        : CurrencyFormatter.format(overBudgetAmount, currency);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.messageRowPaddingHorizontal,
        vertical: AppSpacing.messageRowPaddingVertical,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(
          color: AppTheme.errorColor.withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppSpacing.iconSizeSmall,
            height: AppSpacing.iconSizeSmall,
            child: Center(
              child: Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.errorColor,
                size: AppSpacing.iconSizeSmall,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.spacingXSmall),
          Expanded(
            child: Text(
              'Over budget by $amountText',
              style: AppFonts.textStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.spacingXXSmall),
          TextButton(
            onPressed: () {
              ref
                  .read(currentNavItemProvider.notifier)
                  .navigateTo(NavItem.budget);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'View Budget',
              style: AppFonts.textStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoBudgetMessage(Currency currency, bool hasOverBudgetMessage) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.transparent : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppTheme.borderColor.withValues(alpha: 0.5);
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.messageRowPaddingHorizontal,
        vertical: AppSpacing.messageRowPaddingVertical,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppSpacing.iconSizeSmall,
            height: AppSpacing.iconSizeSmall,
            child: Center(
              child: Icon(
                Icons.info_outline_rounded,
                color: AppTheme.warningColor,
                size: AppSpacing.iconSizeSmall,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.spacingXSmall),
          Expanded(
            child: Text(
              'No $_periodShort budget set',
              style: AppFonts.textStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.spacingXXSmall),
          TextButton(
            onPressed: () {
              ref
                  .read(currentNavItemProvider.notifier)
                  .navigateTo(NavItem.budget);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Set Budget',
              style: AppFonts.textStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.spacingXSmall),
          SizedBox(
            width: AppSpacing.iconSizeSmall,
            height: AppSpacing.iconSizeSmall,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => ref
                    .read(dismissedBudgetMessagesProvider.notifier)
                    .dismissPeriod(_selectedPeriod),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXSmall),
                child: Center(
                  child: Icon(
                    Icons.close_rounded,
                    size: AppSpacing.iconSizeSmall,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Optimized progress bar widget - prevents unnecessary rebuilds
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.progress,
    required this.isOverBudget,
    this.compact = false,
  });

  final double progress;
  final bool isOverBudget;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Match budget screen: same error red (0.5→0.8 gradient end) so both bars look identical
    return ClipRRect(
      borderRadius: BorderRadius.circular(compact ? 6 : 8),
      child: LinearProgressIndicator(
        value: isOverBudget ? 1.0 : progress.clamp(0.0, 1.0),
        minHeight: compact ? 6 : 8,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        valueColor: AlwaysStoppedAnimation<Color>(
          isOverBudget
              ? AppTheme.errorColor.withValues(alpha: 0.8)
              : AppTheme.warningColor,
        ),
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.complementaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppFonts.textStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF1A1A1A) // Black text for active tab
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
