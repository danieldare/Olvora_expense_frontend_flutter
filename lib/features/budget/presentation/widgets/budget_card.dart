import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/models/currency.dart';
import '../../../../core/widgets/bottom_sheet_modal.dart';
import '../../../../core/widgets/bottom_sheet_option_tile.dart';
import '../../domain/entities/budget_entity.dart';

class BudgetCard extends ConsumerWidget {
  final BudgetEntity budget;
  final VoidCallback? onEdit;
  final VoidCallback? onAdd;
  final VoidCallback? onDelete;
  final Function(BudgetEntity)? onDeleteWithCheck; // Enhanced delete with association check
  /// When true, uses smaller padding, fonts, and spacing for a denser card.
  final bool compact;

  const BudgetCard({
    super.key,
    required this.budget,
    this.onEdit,
    this.onAdd,
    this.onDelete,
    this.onDeleteWithCheck,
    this.compact = false,
  });

  Color get _iconColor {
    switch (budget.type) {
      case BudgetType.daily:
        return const Color(0xFF2563EB);
      case BudgetType.weekly:
        return const Color(0xFF7C3AED);
      case BudgetType.monthly:
        return const Color(0xFF22C55E);
      case BudgetType.quarterly:
        return const Color(0xFFF59E0B);
      case BudgetType.semiAnnual:
        return const Color(0xFFEC4899);
      case BudgetType.annual:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData get _icon {
    switch (budget.type) {
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

  String _getPeriodLabel(BudgetType type) {
    switch (type) {
      case BudgetType.daily:
        return 'Daily Budget';
      case BudgetType.weekly:
        return 'Weekly Budget';
      case BudgetType.monthly:
        return 'Monthly Budget';
      case BudgetType.quarterly:
        return 'Quarterly Budget';
      case BudgetType.semiAnnual:
        return '6-Month Budget';
      case BudgetType.annual:
        return 'Annual Budget';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCardBackground : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppTheme.borderColor;

    final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
    final currency =
        selectedCurrencyAsync.valueOrNull ?? Currency.defaultCurrency;

    final hasBudget = budget.amount > 0;

    final cardPadding = compact ? 14.0 : 20.0;
    final borderRadius = compact ? 14.0 : 20.0;
    final iconSize = compact ? 36.0 : 44.0;
    final iconInnerSize = compact ? 18.0 : 22.0;
    final titleFontSize = compact ? (budget.category == BudgetCategory.category ? 14.0 : 16.0) : (budget.category == BudgetCategory.category ? 16.0 : 18.0);
    final spentFontSize = compact ? 13.0 : 15.0;
    final spentSubFontSize = compact ? 12.0 : 14.0;
    final smallFontSize = compact ? 10.0 : 11.0;
    final periodFontSize = compact ? 11.0 : 12.0;
    final footerFontSize = compact ? 12.0 : 13.0;
    final gapSmall = compact ? 4.0 : 6.0;
    final gapMedium = compact ? 8.0 : 12.0;
    final barHeight = compact ? 6.0 : 8.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showMenu(context, isDark),
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: AppShadows.card(
              isDark: isDark,
              blur: AppShadows.cardBlur,
              spread: 0,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Row
                Row(
                  children: [
                    // Modern icon with gradient effect
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _iconColor.withValues(alpha: 0.35),
                            _iconColor.withValues(alpha: 0.25),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(compact ? 10 : 14),
                        boxShadow: [
                          BoxShadow(
                            color: _iconColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(_icon, color: _iconColor, size: iconInnerSize),
                    ),
                    SizedBox(width: compact ? 12 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // For category budgets, category name is the main title
                          if (budget.category == BudgetCategory.category &&
                              budget.categoryName != null) ...[
                            Text(
                              budget.categoryName!,
                              style: AppFonts.textStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                                letterSpacing: -0.3,
                                height: 1.2,
                              ),
                            ),
                          ] else ...[
                            // For general budgets, period type is the main title
                            Text(
                              budget.typeLabel,
                              style: AppFonts.textStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                                letterSpacing: -0.3,
                                height: 1.2,
                              ),
                            ),
                          ],
                          SizedBox(height: gapSmall),
                          if (hasBudget)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      CurrencyFormatter.format(
                                        budget.spent,
                                        currency,
                                      ),
                                      style: AppFonts.textStyle(
                                        fontSize: spentFontSize,
                                        fontWeight: FontWeight.w600,
                                        color: (isDark
                                                ? Colors.white
                                                : AppTheme.textPrimary)
                                            .withValues(alpha: 0.9),
                                      ),
                                    ),
                                    Text(
                                      ' / ${CurrencyFormatter.format(budget.amount, currency)}',
                                      style: AppFonts.textStyle(
                                        fontSize: spentSubFontSize,
                                        fontWeight: FontWeight.w400,
                                        color: (isDark
                                                ? Colors.white
                                                : AppTheme.textSecondary)
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                                // Show relationship info with better visualization
                                if (budget.category == BudgetCategory.general &&
                                    budget.totalAllocatedToCategories != null &&
                                    budget.totalAllocatedToCategories! > 0) ...[
                                  SizedBox(height: compact ? 2 : 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (isDark
                                              ? Colors.white
                                              : AppTheme.borderColor)
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.account_balance_wallet_rounded,
                                          size: 12,
                                          color: (isDark
                                                  ? Colors.white
                                                  : AppTheme.textSecondary)
                                              .withValues(alpha: 0.6),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '${CurrencyFormatter.format(budget.totalAllocatedToCategories!, currency)} allocated',
                                          style: AppFonts.textStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: (isDark
                                                    ? Colors.white
                                                    : AppTheme.textSecondary)
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (budget.availableAfterAllocations !=
                                          null &&
                                      budget.availableAfterAllocations! >
                                          0) ...[
                                    SizedBox(height: 2),
                                    Text(
                                      '${CurrencyFormatter.format(budget.availableAfterAllocations!, currency)} available',
                                      style: AppFonts.textStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(
                                          0xFF22C55E,
                                        ).withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ] else if (budget.category ==
                                    BudgetCategory.category) ...[
                                  if (budget.hasGeneralBudget == true &&
                                      budget.availableFromGeneral != null) ...[
                                    SizedBox(height: 2),
                                    Text(
                                      'From general budget',
                                      style: AppFonts.textStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                        color: (isDark
                                                ? Colors.white
                                                : AppTheme.textSecondary)
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ] else if (budget.isIndependent == true) ...[
                                    SizedBox(height: 2),
                                    Text(
                                      'Independent budget',
                                      style: AppFonts.textStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                        color: (isDark
                                                ? Colors.white
                                                : AppTheme.textSecondary)
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            )
                          else
                                    Text(
                                      'No budget set',
                                      style: AppFonts.textStyle(
                                        fontSize: spentSubFontSize,
                                        fontWeight: FontWeight.w400,
                                        color: (isDark
                                                ? Colors.white
                                                : AppTheme.textSecondary)
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                        ],
                      ),
                    ),
                    if (hasBudget && (onEdit != null || onDelete != null))
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showMenu(context, isDark),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: (isDark
                                      ? Colors.white
                                      : AppTheme.borderColor)
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.more_vert_rounded,
                              color: (isDark
                                      ? Colors.white
                                      : AppTheme.textSecondary)
                                  .withValues(alpha: 0.7),
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (hasBudget) ...[
                  // Allocation breakdown for general budgets
                  if (budget.category == BudgetCategory.general &&
                      budget.totalAllocatedToCategories != null &&
                      budget.totalAllocatedToCategories! > 0) ...[
                    SizedBox(height: compact ? 6 : 8),
                    _buildAllocationBreakdown(budget, currency, isDark, compact),
                    SizedBox(height: compact ? 6 : 8),
                  ] else
                    SizedBox(height: gapMedium),
                  // Modern progress bar with smooth animation
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: budget.progress),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedProgress, child) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final barWidth = constraints.maxWidth;
                          final isOverBudget = animatedProgress > 1.0;
                          final progressColor = budget.isOnTrack
                              ? const Color(0xFF22C55E)
                              : AppTheme.errorColor.withValues(alpha: 0.5);

                          return Stack(
                            children: [
                              // Background with subtle gradient
                              Container(
                                height: barHeight,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      (isDark
                                              ? Colors.white
                                              : AppTheme.borderColor)
                                          .withValues(alpha: isDark ? 0.08 : 0.3),
                                      (isDark
                                              ? Colors.white
                                              : AppTheme.borderColor)
                                          .withValues(alpha: isDark ? 0.12 : 0.4),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              // Budget limit indicator line (100% mark)
                              Positioned(
                                left: barWidth - 1,
                                child: Container(
                                  width: 2,
                                  height: barHeight,
                                  decoration: BoxDecoration(
                                    color: (isDark
                                            ? Colors.white
                                            : AppTheme.borderColor)
                                        .withValues(alpha: isDark ? 0.2 : 0.5),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                              // Spent amount fill with gradient
                              ClipRRect(
                                borderRadius: BorderRadius.circular(barHeight),
                                child: Container(
                                  height: barHeight,
                                  width: (animatedProgress * barWidth).clamp(
                                    0.0,
                                    barWidth * 2,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        progressColor,
                                        progressColor.withValues(alpha: 0.8),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: progressColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Over-budget portion
                              if (isOverBudget)
                                Positioned(
                                  left: barWidth,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(barHeight),
                                      bottomRight: Radius.circular(barHeight),
                                    ),
                                    child: Container(
                                      height: barHeight,
                                      width:
                                          ((animatedProgress - 1.0) * barWidth)
                                              .clamp(0.0, barWidth),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.errorColor.withValues(alpha: 0.5),
                                            AppTheme.errorColor.withValues(alpha: 0.4),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: gapMedium),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (budget.category == BudgetCategory.category &&
                          budget.categoryName != null)
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: (isDark
                                      ? Colors.white
                                      : AppTheme.textSecondary)
                                  .withValues(alpha: 0.5),
                            ),
                            SizedBox(width: 4),
                            Text(
                              _getPeriodLabel(budget.type),
                              style: AppFonts.textStyle(
                                fontSize: periodFontSize,
                                fontWeight: FontWeight.w500,
                                color: (isDark
                                        ? Colors.white
                                        : AppTheme.textSecondary)
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (budget.isOnTrack
                                        ? const Color(0xFF22C55E)
                                        : AppTheme.errorColor)
                                    .withValues(alpha: budget.isOnTrack ? 0.15 : 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: budget.isOnTrack
                                      ? const Color(0xFF22C55E)
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                budget.statusText,
                                style: AppFonts.textStyle(
                                  fontSize: smallFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: budget.isOnTrack
                                      ? const Color(0xFF22C55E)
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                        budget.isOnTrack
                            ? '${CurrencyFormatter.format(budget.remaining, currency)} left'
                            : '${CurrencyFormatter.format(budget.spent - budget.amount, currency)} over',
                        style: AppFonts.textStyle(
                          fontSize: footerFontSize,
                          fontWeight: FontWeight.w600,
                          color: budget.isOnTrack
                              ? (isDark
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : AppTheme.textPrimary)
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllocationBreakdown(
    BudgetEntity budget,
    Currency currency,
    bool isDark, [
    bool compact = false,
  ]) {
    final totalAllocated = budget.totalAllocatedToCategories ?? 0.0;
    final available = budget.availableAfterAllocations ?? 0.0;
    final allocationPercent = budget.amount > 0
        ? (totalAllocated / budget.amount)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : AppTheme.borderColor)
            .withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (isDark ? Colors.white : AppTheme.borderColor)
              .withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Allocation',
                style: AppFonts.textStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: (isDark ? Colors.white : AppTheme.textPrimary)
                      .withValues(alpha: 0.7),
                ),
              ),
              Text(
                '${(allocationPercent * 100).toStringAsFixed(0)}% allocated',
                style: AppFonts.textStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: (isDark ? Colors.white : AppTheme.textSecondary)
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          // Allocation progress bar
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              return Stack(
                children: [
                  // Background
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : AppTheme.borderColor)
                          .withValues(alpha: isDark ? 0.1 : 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  // Allocated portion
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 6,
                      width: (allocationPercent * barWidth).clamp(
                        0.0,
                        barWidth,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  // Available portion
                  if (available > 0)
                    Positioned(
                      left: (allocationPercent * barWidth).clamp(0.0, barWidth),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(3),
                          bottomRight: Radius.circular(3),
                        ),
                        child: Container(
                          height: 6,
                          width: ((available / budget.amount) * barWidth).clamp(
                            0.0,
                            barWidth,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF22C55E,
                            ).withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Allocated: ${CurrencyFormatter.format(totalAllocated, currency)}',
                    style: AppFonts.textStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: (isDark ? Colors.white : AppTheme.textSecondary)
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              if (available > 0)
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Available: ${CurrencyFormatter.format(available, currency)}',
                      style: AppFonts.textStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF22C55E).withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context, bool isDark) {
    BottomSheetModal.show(
      context: context,
      title: budget.category == BudgetCategory.category && budget.categoryName != null
          ? budget.categoryName!
          : budget.typeLabel,
      subtitle: 'Manage your budget',
      borderRadius: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onEdit != null) ...[
            BottomSheetOptionTile(
              icon: Icons.edit_rounded,
              label: 'Edit Budget',
              color: AppTheme.primaryColor,
              onTap: () {
                Navigator.pop(context);
                onEdit?.call();
              },
            ),
            if (onDelete != null) const BottomSheetOptionDivider(),
          ],
          if (onDelete != null) ...[
            BottomSheetOptionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete Budget',
              color: AppTheme.errorColor,
              useColorForText: true,
              onTap: () {
                Navigator.pop(context);
                if (onDeleteWithCheck != null) {
                  onDeleteWithCheck!(budget);
                } else if (onDelete != null) {
                  onDelete!();
                }
              },
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

}

