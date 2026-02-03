import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/models/currency.dart';
import '../../domain/entities/weekly_summary_entity.dart';
import '../providers/weekly_summary_providers.dart';
import 'enhanced_weekly_summary_screen.dart';

/// World-class Weekly Summary screen
///
/// Design principles:
/// - Calm, supportive tone (no guilt, no shaming)
/// - Clear, scannable information
/// - Actionable insights only when confidence is high
/// - Beautiful, modern UI with data visualization
///
/// NOTE: This screen now uses the enhanced detailed summary
class WeeklySummaryScreen extends ConsumerWidget {
  const WeeklySummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the enhanced detailed summary screen
    return const EnhancedWeeklySummaryScreen();
  }
}

class _SummaryContent extends ConsumerWidget {
  final WeeklySummaryEntity summary;

  const _SummaryContent({required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
    final currency = selectedCurrencyAsync.valueOrNull ?? Currency.defaultCurrency;

    // Format week period
    final weekStart = DateFormat('MMM d').format(summary.weekStartDate);
    final weekEnd = DateFormat('MMM d, yyyy').format(summary.weekEndDate);
    final weekPeriod = '$weekStart - $weekEnd';

    // Calculate average daily spending
    final daysInWeek = summary.weekEndDate.difference(summary.weekStartDate).inDays + 1;
    final averageDaily = summary.totalSpent / daysInWeek;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: ScreenHeader(
              title: 'Weekly Summary',
              subtitle: weekPeriod,
              padding: EdgeInsets.zero,
            ),
          ),
        ),

        // Hero Section - Total Spent
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _HeroCard(
              totalSpent: summary.totalSpent,
              averageDaily: averageDaily,
              weekOverWeekChange: summary.weekOverWeekChange,
              previousWeekTotal: summary.previousWeekTotal,
              type: summary.type,
              currency: currency,
              isDark: isDark,
            ),
          ),
        ),

        // Budget Progress (if available)
        if (summary.budgetAmount != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _BudgetProgressCard(
                budgetAmount: summary.budgetAmount!,
                budgetSpent: summary.budgetSpent ?? 0,
                isWithinBudget: summary.isWithinBudget,
                currency: currency,
                isDark: isDark,
              ),
            ),
          ),

        // Category Breakdown Chart
        if (summary.categoryBreakdown.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _CategoryBreakdownCard(
                categoryBreakdown: summary.categoryBreakdown,
                totalSpent: summary.totalSpent,
                currency: currency,
                isDark: isDark,
              ),
            ),
          ),

        // Key Metrics Grid
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _KeyMetricsGrid(
              transactionCount: summary.transactionCount,
              topCategory: summary.topCategory,
              topCategoryAmount: summary.topCategoryAmount,
              averageDaily: averageDaily,
              weekOverWeekChange: summary.weekOverWeekChange,
              currency: currency,
              isDark: isDark,
            ),
          ),
        ),

        // Insight Card (only if confidence is high)
        if (summary.insightText != null && summary.confidenceScore >= 0.7)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _InsightCard(
                insight: summary.insightText!,
                isDark: isDark,
              ),
            ),
          ),

        // Action Card (only if suggested)
        if (summary.suggestedAction != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _ActionCard(
                action: summary.suggestedAction!,
                isDark: isDark,
              ),
            ),
          ),

        // Bottom spacing
        const SliverToBoxAdapter(
          child: SizedBox(height: 40),
        ),
      ],
    );
  }
}

/// Hero Card - Prominently displays total spent
class _HeroCard extends StatelessWidget {
  final double totalSpent;
  final double averageDaily;
  final double? weekOverWeekChange;
  final double? previousWeekTotal;
  final SummaryType type;
  final Currency currency;
  final bool isDark;

  const _HeroCard({
    required this.totalSpent,
    required this.averageDaily,
    this.weekOverWeekChange,
    this.previousWeekTotal,
    required this.type,
    required this.currency,
    required this.isDark,
  });

  Color _getGradientColor() {
    switch (type) {
      case SummaryType.goodWeek:
        return AppTheme.successColor;
      case SummaryType.overspendWeek:
        return AppTheme.warningColor;
      case SummaryType.firstWeek:
        return AppTheme.primaryColor;
      default:
        return AppTheme.accentColor;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case SummaryType.goodWeek:
        return Icons.check_circle_rounded;
      case SummaryType.overspendWeek:
        return Icons.trending_up_rounded;
      case SummaryType.firstWeek:
        return Icons.waving_hand_rounded;
      case SummaryType.noTransactions:
        return Icons.inbox_rounded;
      default:
        return Icons.insights_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradientColor = _getGradientColor();

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  gradientColor.withValues(alpha: 0.2),
                  gradientColor.withValues(alpha: 0.1),
                ]
              : [
                  gradientColor.withValues(alpha: 0.15),
                  gradientColor.withValues(alpha: 0.08),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: gradientColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColor.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and type indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: gradientColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIcon(),
                  color: gradientColor,
                  size: 24,
                ),
              ),
              const Spacer(),
              if (weekOverWeekChange != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: weekOverWeekChange! > 0
                        ? AppTheme.warningColor.withValues(alpha: 0.15)
                        : AppTheme.successColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        weekOverWeekChange! > 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 14,
                        color: weekOverWeekChange! > 0
                            ? AppTheme.warningColor
                            : AppTheme.successColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${weekOverWeekChange! > 0 ? '+' : ''}${weekOverWeekChange!.toStringAsFixed(1)}%',
                        style: AppFonts.textStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: weekOverWeekChange! > 0
                              ? AppTheme.warningColor
                              : AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 24),
          // Total Spent
          Text(
            CurrencyFormatter.format(totalSpent, currency),
            style: AppFonts.textStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppTheme.textPrimary,
              letterSpacing: -2,
            ),
          ),
          SizedBox(height: 8),
          // Average Daily
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : AppTheme.textSecondary,
              ),
              SizedBox(width: 6),
              Text(
                '${CurrencyFormatter.format(averageDaily, currency)} per day on average',
                style: AppFonts.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          if (previousWeekTotal != null && previousWeekTotal! > 0) ...[
            SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.compare_arrows_rounded,
                    size: 16,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppTheme.textSecondary,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Last week: ${CurrencyFormatter.format(previousWeekTotal!, currency)}',
                      style: AppFonts.textStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Budget Progress Card
class _BudgetProgressCard extends StatelessWidget {
  final double budgetAmount;
  final double budgetSpent;
  final bool isWithinBudget;
  final Currency currency;
  final bool isDark;

  const _BudgetProgressCard({
    required this.budgetAmount,
    required this.budgetSpent,
    required this.isWithinBudget,
    required this.currency,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (budgetSpent / budgetAmount).clamp(0.0, 1.0);
    final remaining = (budgetAmount - budgetSpent).clamp(0.0, budgetAmount);
    final isOverBudget = budgetSpent > budgetAmount;

    Color progressColor;
    if (progress >= 1.0) {
      progressColor = AppTheme.errorColor;
    } else if (progress >= 0.8) {
      progressColor = AppTheme.warningColor;
    } else {
      progressColor = AppTheme.successColor;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppTheme.borderColor,
          width: 1,
        ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget Progress',
                style: AppFonts.textStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isWithinBudget
                      ? AppTheme.successColor.withValues(alpha: 0.15)
                      : AppTheme.warningColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isWithinBudget ? 'On Track' : 'Over Budget',
                  style: AppFonts.textStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isWithinBudget
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppTheme.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          SizedBox(height: 16),
          // Amounts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spent',
                    style: AppFonts.textStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(budgetSpent, currency),
                    style: AppFonts.textStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isOverBudget ? 'Over by' : 'Remaining',
                    style: AppFonts.textStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(
                        isOverBudget ? (budgetSpent - budgetAmount) : remaining,
                        currency),
                    style: AppFonts.textStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isOverBudget
                          ? AppTheme.errorColor
                          : AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          // Total budget
          Center(
            child: Text(
              'of ${CurrencyFormatter.format(budgetAmount, currency)} total',
              style: AppFonts.textStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Category Breakdown Card with Pie Chart
class _CategoryBreakdownCard extends StatelessWidget {
  final Map<String, double> categoryBreakdown;
  final double totalSpent;
  final Currency currency;
  final bool isDark;

  const _CategoryBreakdownCard({
    required this.categoryBreakdown,
    required this.totalSpent,
    required this.currency,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Sort categories by amount
    final sortedCategories = categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 5 categories
    final topCategories = sortedCategories.take(5).toList();
    final otherAmount = sortedCategories
        .skip(5)
        .fold<double>(0.0, (sum, entry) => sum + entry.value);

    final displayCategories = topCategories;
    if (otherAmount > 0) {
      displayCategories.add(MapEntry('Other', otherAmount));
    }

    return Container(
      padding: EdgeInsets.all(AppSpacing.screenHorizontal),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppTheme.borderColor,
          width: 1,
        ),
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
          Text(
            'Spending by Category',
            style: AppFonts.textStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 24),
          // Pie Chart
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _CategoryPieChartPainter(
                categories: displayCategories,
                total: totalSpent,
                isDark: isDark,
              ),
            ),
          ),
          SizedBox(height: 24),
          // Legend
          ...displayCategories.asMap().entries.map((entry) {
            final index = entry.key;
            final categoryEntry = entry.value;
            final percentage = (categoryEntry.value / totalSpent * 100);
            final color = _getCategoryColor(index);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatCategoryName(categoryEntry.key),
                      style: AppFonts.textStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: AppFonts.textStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    CurrencyFormatter.format(categoryEntry.value, currency),
                    style: AppFonts.textStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.accentColor,
      AppTheme.successColor,
      AppTheme.warningColor,
      AppTheme.errorColor,
      const Color(0xFFEC4899), // Pink
      const Color(0xFF06B6D4), // Cyan
    ];
    return colors[index % colors.length];
  }

  String _formatCategoryName(String name) {
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }
}

/// Category Pie Chart Painter
class _CategoryPieChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> categories;
  final double total;
  final bool isDark;

  static final List<Color> _colors = [
    AppTheme.primaryColor,
    AppTheme.accentColor,
    AppTheme.successColor,
    AppTheme.warningColor,
    AppTheme.errorColor,
    const Color(0xFFEC4899), // Pink
    const Color(0xFF06B6D4), // Cyan
  ];

  _CategoryPieChartPainter({
    required this.categories,
    required this.total,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2; // Start from top

    for (int i = 0; i < categories.length; i++) {
      final entry = categories[i];
      final sweepAngle = (entry.value / total) * 2 * math.pi;
      final color = _colors[i % _colors.length];

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_CategoryPieChartPainter oldDelegate) {
    return oldDelegate.categories != categories ||
        oldDelegate.total != total ||
        oldDelegate.isDark != isDark;
  }
}

/// Key Metrics Grid
class _KeyMetricsGrid extends StatelessWidget {
  final int transactionCount;
  final String? topCategory;
  final double? topCategoryAmount;
  final double averageDaily;
  final double? weekOverWeekChange;
  final Currency currency;
  final bool isDark;

  const _KeyMetricsGrid({
    required this.transactionCount,
    this.topCategory,
    this.topCategoryAmount,
    required this.averageDaily,
    this.weekOverWeekChange,
    required this.currency,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _MetricCard(
          icon: Icons.receipt_long_rounded,
          iconColor: AppTheme.primaryColor,
          label: 'Transactions',
          value: '$transactionCount',
          subtitle: 'this week',
          isDark: isDark,
        ),
        if (topCategory != null && topCategoryAmount != null)
          _MetricCard(
            icon: Icons.category_rounded,
            iconColor: AppTheme.accentColor,
            label: 'Top Category',
            value: _formatCategoryName(topCategory!),
            subtitle: CurrencyFormatter.format(topCategoryAmount!, currency),
            isDark: isDark,
          )
        else
          _MetricCard(
            icon: Icons.category_rounded,
            iconColor: AppTheme.accentColor,
            label: 'Top Category',
            value: 'N/A',
            subtitle: 'No data',
            isDark: isDark,
          ),
        _MetricCard(
          icon: Icons.trending_up_rounded,
          iconColor: AppTheme.successColor,
          label: 'Daily Average',
          value: CurrencyFormatter.format(averageDaily, currency),
          subtitle: 'per day',
          isDark: isDark,
        ),
        if (weekOverWeekChange != null)
          _MetricCard(
            icon: weekOverWeekChange! > 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            iconColor: weekOverWeekChange! > 0
                ? AppTheme.warningColor
                : AppTheme.successColor,
            label: 'vs Last Week',
            value: '${weekOverWeekChange! > 0 ? '+' : ''}${weekOverWeekChange!.toStringAsFixed(1)}%',
            subtitle: weekOverWeekChange! > 0 ? 'Increase' : 'Decrease',
            isDark: isDark,
          )
        else
          _MetricCard(
            icon: Icons.compare_arrows_rounded,
            iconColor: AppTheme.textSecondary,
            label: 'vs Last Week',
            value: 'N/A',
            subtitle: 'No comparison',
            isDark: isDark,
          ),
      ],
    );
  }

  String _formatCategoryName(String category) {
    return category[0].toUpperCase() + category.substring(1).toLowerCase();
  }
}

/// Metric Card
class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;
  final bool isDark;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppTheme.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppFonts.textStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: AppFonts.textStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2),
              Text(
                subtitle,
                style: AppFonts.textStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Insight Card
class _InsightCard extends StatelessWidget {
  final String insight;
  final bool isDark;

  const _InsightCard({
    required this.insight,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppTheme.accentColor.withValues(alpha: 0.15),
                  AppTheme.accentColor.withValues(alpha: 0.08),
                ]
              : [
                  AppTheme.accentColor.withValues(alpha: 0.1),
                  AppTheme.accentColor.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lightbulb_rounded,
              color: AppTheme.accentColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insight',
                  style: AppFonts.textStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentColor,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  insight,
                  style: AppFonts.textStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Action Card
class _ActionCard extends StatelessWidget {
  final String action;
  final bool isDark;

  const _ActionCard({
    required this.action,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppTheme.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.tips_and_updates_rounded,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested Action',
                  style: AppFonts.textStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  action,
                  style: AppFonts.textStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Error State
class _ErrorState extends ConsumerWidget {
  final Object error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorMessage = error.toString().replaceAll('Exception: ', '');
    final isRetryable = !errorMessage.contains('Authentication required');

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppTheme.errorColor,
            ),
            SizedBox(height: 16),
            Text(
              'Unable to load weekly summary',
              style: AppFonts.textStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              errorMessage,
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (isRetryable) ...[
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(currentWeekSummaryProvider);
                },
                icon: Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
