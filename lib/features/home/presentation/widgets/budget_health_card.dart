import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../budget/domain/entities/budget_entity.dart';
import '../../../budget/presentation/providers/budget_providers.dart';
import '../../../budget/presentation/screens/budget_screen.dart';

class BudgetHealthCard extends ConsumerWidget {
  const BudgetHealthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppTheme.cardBackground;
    final textColor = AppTheme.textPrimary;
    final subtitleColor = AppTheme.textSecondary;
    final borderColor = isDark
        ? AppTheme.borderColor.withValues(alpha: 0.2)
        : AppTheme.borderColor.withValues(alpha: 0.5);

    final budgetsAsync = ref.watch(generalBudgetsProvider);

    // Use skipLoadingOnRefresh to prevent flickering when data is refreshed
    return budgetsAsync.when(
      skipLoadingOnRefresh: true,
      data: (budgets) {
        final enabledBudgets = budgets.where((b) => b.enabled && b.amount > 0).toList();

        if (enabledBudgets.isEmpty) {
          return const SizedBox.shrink();
        }

        // Calculate budget health
        final onTrackCount = enabledBudgets.where((b) => b.progress < 0.8).length;
        final warningCount = enabledBudgets.where((b) => b.progress >= 0.8 && b.progress < 1.0).length;
        final overBudgetCount = enabledBudgets.where((b) => b.progress >= 1.0).length;
        final totalBudgets = enabledBudgets.length;

        // Calculate overall health score (0-100)
        final healthScore = totalBudgets > 0
            ? ((onTrackCount * 100 + warningCount * 50) / totalBudgets).round()
            : 100;

        // Get budgets that need attention (warning or over)
        final needsAttention = enabledBudgets
            .where((b) => b.progress >= 0.8)
            .toList()
          ..sort((a, b) => b.progress.compareTo(a.progress));

        Color getHealthColor() {
          if (healthScore >= 80) return AppTheme.successColor;
          if (healthScore >= 50) return AppTheme.warningColor;
          return AppTheme.errorColor;
        }

        IconData getHealthIcon() {
          if (healthScore >= 80) return Icons.check_circle_rounded;
          if (healthScore >= 50) return Icons.warning_rounded;
          return Icons.error_rounded;
        }

        String getHealthText() {
          if (healthScore >= 80) return 'All Good';
          if (healthScore >= 50) return 'Needs Attention';
          return 'Critical';
        }

        final healthColor = getHealthColor();
        final healthIcon = getHealthIcon();
        final healthText = getHealthText();

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BudgetScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            child: Container(
              padding: EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: AppSpacing.iconContainerMedium,
                        height: AppSpacing.iconContainerMedium,
                        decoration: BoxDecoration(
                          color: healthColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          healthIcon,
                          color: healthColor,
                          size: AppSpacing.iconSize,
                        ),
                      ),
                      SizedBox(width: AppSpacing.spacingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Budget Health',
                              style: AppFonts.textStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '$onTrackCount of $totalBudgets budgets on track',
                              style: AppFonts.textStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: healthColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              healthIcon,
                              size: 14,
                              color: healthColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              healthText,
                              style: AppFonts.textStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: healthColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Budget status breakdown
                  Row(
                    children: [
                      Expanded(
                        child: _BudgetStatusItem(
                          count: onTrackCount,
                          label: 'On Track',
                          color: AppTheme.successColor,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _BudgetStatusItem(
                          count: warningCount,
                          label: 'Warning',
                          color: AppTheme.warningColor,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _BudgetStatusItem(
                          count: overBudgetCount,
                          label: 'Over',
                          color: AppTheme.errorColor,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                  if (needsAttention.isNotEmpty) ...[
                    SizedBox(height: 16),
                    // Show top budget that needs attention
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: needsAttention.first.progress >= 1.0
                            ? AppTheme.errorColor.withValues(alpha: 0.1)
                            : AppTheme.warningColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: needsAttention.first.progress >= 1.0
                              ? AppTheme.errorColor.withValues(alpha: 0.3)
                              : AppTheme.warningColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            needsAttention.first.progress >= 1.0
                                ? Icons.error_outline_rounded
                                : Icons.warning_amber_rounded,
                            size: 16,
                            color: needsAttention.first.progress >= 1.0
                                ? AppTheme.errorColor
                                : AppTheme.warningColor,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  needsAttention.first.category ==
                                          BudgetCategory.category
                                      ? (needsAttention.first.categoryName ?? 'Category Budget')
                                      : needsAttention.first.typeLabel,
                                  style: AppFonts.textStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: needsAttention.first.progress.clamp(0.0, 1.0),
                                          minHeight: 4,
                                          backgroundColor: AppTheme.borderColor
                                              .withValues(alpha: isDark ? 0.25 : 0.5),
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            needsAttention.first.progress >= 1.0
                                                ? AppTheme.errorColor
                                                : AppTheme.warningColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '${(needsAttention.first.progress * 100).toInt()}%',
                                      style: AppFonts.textStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: needsAttention.first.progress >= 1.0
                                            ? AppTheme.errorColor
                                            : AppTheme.warningColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _BudgetStatusItem extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final Color textColor;
  final Color subtitleColor;

  const _BudgetStatusItem({
    required this.count,
    required this.label,
    required this.color,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: AppFonts.textStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: AppFonts.textStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}

