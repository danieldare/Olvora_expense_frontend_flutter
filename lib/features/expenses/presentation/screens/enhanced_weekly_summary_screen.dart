import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/models/currency.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import '../../domain/entities/detailed_weekly_summary_entity.dart';
import '../../domain/entities/weekly_summary_entity.dart';
import '../providers/weekly_summary_providers.dart';
import 'expense_type_selection_screen.dart';
import 'daily_breakdown_detail_screen.dart';
import '../../../budget/presentation/screens/budget_screen.dart';

/// World-Class Weekly Summary Screen
///
/// Design Principles:
/// - Answer "How did I do?" in under 3 seconds
/// - Visual-first, text-second approach
/// - Emotional, supportive feedback
/// - Progressive disclosure of details
class EnhancedWeeklySummaryScreen extends ConsumerStatefulWidget {
  const EnhancedWeeklySummaryScreen({super.key});

  @override
  ConsumerState<EnhancedWeeklySummaryScreen> createState() =>
      _EnhancedWeeklySummaryScreenState();
}

class _EnhancedWeeklySummaryScreenState
    extends ConsumerState<EnhancedWeeklySummaryScreen> {
  DateTime? _selectedWeekStart;

  @override
  void initState() {
    super.initState();
    // Always fetch fresh data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(detailedWeeklySummaryProvider);
    });
  }

  Future<void> _onRefresh() async {
    if (_selectedWeekStart != null) {
      ref.invalidate(detailedWeeklySummaryForWeekProvider(_selectedWeekStart!));
    } else {
      ref.invalidate(detailedWeeklySummaryProvider);
    }
    // Wait for the provider to complete
    if (_selectedWeekStart != null) {
      await ref.read(detailedWeeklySummaryForWeekProvider(_selectedWeekStart!).future);
    } else {
      await ref.read(detailedWeeklySummaryProvider.future);
    }
  }

  void _navigateToPreviousWeek(DateTime currentWeekStart) {
    final previousWeekStart = currentWeekStart.subtract(const Duration(days: 7));
    setState(() {
      _selectedWeekStart = previousWeekStart;
    });
    ref.invalidate(detailedWeeklySummaryForWeekProvider(previousWeekStart));
  }

  void _navigateToNextWeek(DateTime currentWeekStart) {
    final nextWeekStart = currentWeekStart.add(const Duration(days: 7));
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final nextWeekStartOnly = DateTime(nextWeekStart.year, nextWeekStart.month, nextWeekStart.day);

    // Don't allow navigating to future weeks (week hasn't started yet)
    if (nextWeekStartOnly.isAfter(todayOnly)) {
      return; // Don't navigate to future weeks
    }

    // Check if we're navigating to the current week (today falls within this week)
    final nextWeekEndOnly = nextWeekStartOnly.add(const Duration(days: 6));
    final isCurrentWeek = !todayOnly.isBefore(nextWeekStartOnly) && !todayOnly.isAfter(nextWeekEndOnly);

    setState(() {
      // Reset to null when navigating to current week to use default provider
      _selectedWeekStart = isCurrentWeek ? null : nextWeekStart;
    });

    if (isCurrentWeek) {
      ref.invalidate(detailedWeeklySummaryProvider);
    } else {
      ref.invalidate(detailedWeeklySummaryForWeekProvider(nextWeekStart));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.screenBackgroundColor;
    final summaryAsync = _selectedWeekStart != null
        ? ref.watch(detailedWeeklySummaryForWeekProvider(_selectedWeekStart!))
        : ref.watch(detailedWeeklySummaryProvider);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: summaryAsync.when(
          data: (summary) => RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppTheme.primaryColor,
            child: _WeeklySummaryContent(
              summary: summary,
              onPreviousWeek: () => _navigateToPreviousWeek(summary.weekStartDate),
              onNextWeek: () => _navigateToNextWeek(summary.weekStartDate),
            ),
          ),
          loading: () => _LoadingState(),
          error: (error, stack) => _ErrorState(error: error),
        ),
      ),
    );
  }
}

/// Main Content
class _WeeklySummaryContent extends ConsumerWidget {
  final DetailedWeeklySummaryEntity summary;
  final VoidCallback? onPreviousWeek;
  final VoidCallback? onNextWeek;

  const _WeeklySummaryContent({
    required this.summary,
    this.onPreviousWeek,
    this.onNextWeek,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
    final currency =
        selectedCurrencyAsync.valueOrNull ?? Currency.defaultCurrency;

    // Format week period
    final weekStart = DateFormat('MMM d').format(summary.weekStartDate);
    final weekEnd = DateFormat('MMM d').format(summary.weekEndDate);

    // Check if this is the current week (today falls within the summary's week range)
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final summaryWeekStartOnly = DateTime(summary.weekStartDate.year, summary.weekStartDate.month, summary.weekStartDate.day);
    final summaryWeekEndOnly = DateTime(summary.weekEndDate.year, summary.weekEndDate.month, summary.weekEndDate.day);

    final isCurrentWeek = !todayOnly.isBefore(summaryWeekStartOnly) && !todayOnly.isAfter(summaryWeekEndOnly);

    // Check if we can navigate forward (allow if next week has already started)
    final nextWeekStart = summary.weekStartDate.add(const Duration(days: 7));
    final nextWeekStartOnly = DateTime(nextWeekStart.year, nextWeekStart.month, nextWeekStart.day);
    // Allow forward navigation if next week start is on or before today
    final canNavigateForward = !nextWeekStartOnly.isAfter(todayOnly);

    // Check if empty (no transactions)
    final hasNoData = summary.transactionCount == 0;
    final isFirstWeek = summary.type == SummaryType.firstWeek;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        // Custom App Bar with Week Navigation
        SliverToBoxAdapter(
          child: _WeekHeader(
            weekStart: weekStart,
            weekEnd: weekEnd,
            isDark: isDark,
            isCurrentWeek: isCurrentWeek,
            canNavigateForward: canNavigateForward,
            onPreviousWeek: onPreviousWeek,
            onNextWeek: onNextWeek,
          ),
        ),

        // Show empty state OR full content
        if (hasNoData) ...[
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                0,
                AppSpacing.screenHorizontal,
                AppSpacing.bottomNavPadding,
              ),
              child: _EmptyWeekState(
                isCurrentWeek: isCurrentWeek,
                isFirstWeek: isFirstWeek,
              ),
            ),
          ),
        ] else ...[
          // Hero Status Card - The emotional centerpiece
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                8,
                AppSpacing.screenHorizontal,
                0,
              ),
              child: _HeroStatusCard(
                summary: summary,
                currency: currency,
                isDark: isDark,
              ),
            ),
          ),

          // Smart Insights - Key takeaways (Moved up for better visibility)
          if (summary.insights.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  12,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: _InsightsSection(
                  insights: summary.insights,
                  isDark: isDark,
                ),
              ),
            ),

          // Quick Stats Row
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                10,
                AppSpacing.screenHorizontal,
                0,
              ),
              child: _QuickStatsRow(
                overview: summary.overview,
                currency: currency,
                isDark: isDark,
              ),
            ),
          ),

          // Daily Spending Chart - Visual bar chart
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                12,
                AppSpacing.screenHorizontal,
                0,
              ),
              child: _DailySpendingChart(
                dailyBreakdown: summary.dailyBreakdown,
                dailyAverage: summary.overview.dailyAverage,
                currency: currency,
                isDark: isDark,
              ),
            ),
          ),

          // Category Breakdown - Visual distribution
          if (summary.categoryInsights.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  12,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: _CategoryBreakdownCard(
                  categoryInsights: summary.categoryInsights,
                  totalSpent: summary.overview.totalSpent,
                  currency: currency,
                  isDark: isDark,
                ),
              ),
            ),

          // Recommendations - Actionable next steps
          if (summary.recommendations.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  12,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: _RecommendationsSection(
                  recommendations: summary.recommendations,
                  isDark: isDark,
                ),
              ),
            ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.bottomNavPadding),
          ),
        ],
      ],
    );
  }
}

/// Compact, world-class empty state for weekly summary (no data).
class _EmptyWeekState extends StatelessWidget {
  const _EmptyWeekState({
    required this.isCurrentWeek,
    this.isFirstWeek = false,
  });

  final bool isCurrentWeek;
  final bool isFirstWeek;

  String get _title {
    if (isFirstWeek) return 'No summary yet';
    if (isCurrentWeek) return 'No expenses this week';
    return 'No expenses';
  }

  String get _subtitle {
    if (isFirstWeek) return 'Add an expense to see your weekly summary.';
    if (isCurrentWeek) return 'Add an expense to see your breakdown.';
    return 'No spending recorded for this week.';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.textPrimary;
    final subtextColor = AppTheme.textSecondary;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 32,
              color: subtextColor,
            ),
            const SizedBox(height: 8),
            Text(
              _title,
              style: AppFonts.textStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _subtitle,
              style: AppFonts.textStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: subtextColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (isCurrentWeek || isFirstWeek) ...[
              const SizedBox(height: 14),
              _AddExpenseButton(isFirstWeek: isFirstWeek),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddExpenseButton extends StatelessWidget {
  const _AddExpenseButton({required this.isFirstWeek});

  final bool isFirstWeek;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ExpenseTypeSelectionScreen(),
          ),
        );
      },
      icon: Icon(Icons.add_rounded, size: 16, color: AppTheme.primaryColor),
      label: Text(
        'Add expense',
        style: AppFonts.textStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}

/// Week Header with Navigation
class _WeekHeader extends StatelessWidget {
  final String weekStart;
  final String weekEnd;
  final bool isDark;
  final bool isCurrentWeek;
  final bool canNavigateForward;
  final VoidCallback? onPreviousWeek;
  final VoidCallback? onNextWeek;

  const _WeekHeader({
    required this.weekStart,
    required this.weekEnd,
    required this.isDark,
    this.isCurrentWeek = true,
    this.canNavigateForward = false,
    this.onPreviousWeek,
    this.onNextWeek,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with back button
          Row(
            children: [
              AppBackButton(),
              Text(
                'Weekly Summary',
                style: AppFonts.textStyle(
                  fontSize: 18.scaledText(context),
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.scaledVertical(context)),
          // Week Navigator - Clean inline design
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.grey[200]!,
                borderRadius: BorderRadius.circular(12.scaled(context)),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.grey[300]!.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Previous week button
                  _NavButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: onPreviousWeek,
                    isDark: isDark,
                  ),
                  // Date range - tappable center
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Show week picker
                      },
                      child: Center(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$weekStart - $weekEnd',
                                style: AppFonts.textStyle(
                                  fontSize: 14.scaledText(context),
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                ),
                              ),
                              if (isCurrentWeek) ...[
                                TextSpan(
                                  text: '  (Current week)',
                                  style: AppFonts.textStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Next week button (disabled if can't navigate forward)
                  _NavButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: onNextWeek,
                    isDark: isDark,
                    disabled: !canNavigateForward,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;
  final bool disabled;

  const _NavButton({
    required this.icon,
    this.onTap,
    required this.isDark,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.transparent
              : isDark
              ? AppTheme.cardBackground.withValues(alpha: 0.3)
              : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(8),
          boxShadow: disabled
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.textPrimary.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: disabled
              ? (isDark ? Colors.grey[600] : AppTheme.textSecondary)
              : (isDark ? Colors.white : AppTheme.textPrimary),
        ),
      ),
    );
  }
}

/// Hero Status Card - The emotional centerpiece (Enhanced)
class _HeroStatusCard extends StatefulWidget {
  final DetailedWeeklySummaryEntity summary;
  final Currency currency;
  final bool isDark;

  const _HeroStatusCard({
    required this.summary,
    required this.currency,
    required this.isDark,
  });

  @override
  State<_HeroStatusCard> createState() => _HeroStatusCardState();
}

class _HeroStatusCardState extends State<_HeroStatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasData = widget.summary.transactionCount > 0;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppTheme.walletGradient.length >= 2
                    ? AppTheme.walletGradient
                    : [
                        AppTheme.walletGradient.first,
                        AppTheme.walletGradient.first,
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.walletGradient.isNotEmpty
                      ? AppTheme.walletGradient.first.withValues(alpha: 0.3)
                      : AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with icon and label
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total amount spent this week',
                        style: AppFonts.textStyle(
                          fontSize: 13.scaledText(context),
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.scaledVertical(context)),
                // Large amount
                if (hasData)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CurrencyFormatter.format(
                          widget.summary.overview.totalSpent,
                          widget.currency,
                        ),
                        style: AppFonts.textStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1.5,
                          height: 1.0,
                        ),
                      ),
                      if (widget.summary.overview.comparisonWithBudget !=
                          null) ...[
                        SizedBox(height: 4),
                        Text(
                          'out of ${CurrencyFormatter.format(widget.summary.overview.comparisonWithBudget!.budgetAmount, widget.currency)} budget',
                          style: AppFonts.textStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ],
                  )
                else
                  Text(
                    widget.summary.headline,
                    style: AppFonts.textStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Quick Stats Row - Horizontal Scrollable
class _QuickStatsRow extends StatelessWidget {
  final WeekOverview overview;
  final Currency currency;
  final bool isDark;

  const _QuickStatsRow({
    required this.overview,
    required this.currency,
    required this.isDark,
  });

  String _getComparisonText(ComparisonWithPreviousWeek comparison) {
    final change = comparison.change.abs();
    final direction = comparison.change > 0 ? 'more' : 'less';
    return '${change.toStringAsFixed(0)}% $direction';
  }

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _QuickStatCard(
        label: 'Daily average',
        value: CurrencyFormatter.format(overview.dailyAverage, currency),
        subValue: 'per day',
        icon: Icons.calendar_today_rounded,
        color: AppTheme.accentColor,
        isDark: isDark,
      ),
      if (overview.highestSpendingDay != null)
        _QuickStatCard(
          label: 'Peak day',
          value: overview.highestSpendingDay!.dayName,
          subValue: CurrencyFormatter.format(
            overview.highestSpendingDay!.amount,
            currency,
          ),
          icon: Icons.trending_up_rounded,
          color: AppTheme.primaryColor,
          isDark: isDark,
        ),
      if (overview.comparisonWithPreviousWeek != null)
        _QuickStatCard(
          label: 'vs Last week',
          value: _getComparisonText(overview.comparisonWithPreviousWeek!),
          subValue: overview.comparisonWithPreviousWeek!.change > 0
              ? 'Spending up'
              : 'Spending down',
          icon: overview.comparisonWithPreviousWeek!.change > 0
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded,
          color: overview.comparisonWithPreviousWeek!.change > 0
              ? AppTheme.primaryColor
              : AppTheme.successColor,
          isDark: isDark,
        ),
    ];

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: cards.length,
        separatorBuilder: (context, index) => SizedBox(width: 10),
        itemBuilder: (context, index) => SizedBox(
          width: MediaQuery.of(context).size.width * 0.45,
          child: cards[index],
        ),
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _QuickStatCard({
    required this.label,
    required this.value,
    this.subValue,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.borderColor.withValues(alpha: 0.3)
              : AppTheme.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: isDark ? 0.1 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon and label row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: AppFonts.textStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.grey[400]
                        : AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.scaledVertical(context)),
          // Value
          Text(
            value,
            style: AppFonts.textStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Sub value (always reserve space for consistency)
          SizedBox(height: 1),
          Text(
            subValue ?? '',
            style: AppFonts.textStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: subValue != null ? color : Colors.transparent,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Daily Spending Chart - Enhanced visual bar representation
class _DailySpendingChart extends StatefulWidget {
  final List<DailyBreakdown> dailyBreakdown;
  final double dailyAverage;
  final Currency currency;
  final bool isDark;

  const _DailySpendingChart({
    required this.dailyBreakdown,
    required this.dailyAverage,
    required this.currency,
    required this.isDark,
  });

  @override
  State<_DailySpendingChart> createState() => _DailySpendingChartState();
}

class _DailySpendingChartState extends State<_DailySpendingChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxSpent = widget.dailyBreakdown.fold<double>(
      0,
      (max, day) => math.max(max, day.totalSpent),
    );

    // Find peak and lowest days
    final peakDay = widget.dailyBreakdown.reduce(
      (a, b) => a.totalSpent > b.totalSpent ? a : b,
    );
    final lowestDay = widget.dailyBreakdown
        .where((d) => d.totalSpent > 0)
        .reduce((a, b) => a.totalSpent < b.totalSpent ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with insights
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Spending',
                    style: AppFonts.textStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: widget.isDark ? Colors.white : AppTheme.textPrimary,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap a day to see detailed breakdown',
                    style: AppFonts.textStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: widget.isDark 
                          ? Colors.grey[400]
                          : AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        // Chart bars
        ...widget.dailyBreakdown.asMap().entries.map((entry) {
          final index = entry.key;
          final day = entry.value;
          return _DailyBar(
            day: day,
            maxSpent: maxSpent,
            dailyAverage: widget.dailyAverage,
            currency: widget.currency,
            isDark: widget.isDark,
            animationController: _animationController,
            animationDelay: index * 0.1,
            isPeakDay: day.date == peakDay.date,
            isLowestDay: day.date == lowestDay.date,
            onTap: () {
              // Navigate to daily breakdown detail screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DailyBreakdownDetailScreen(
                    day: day,
                    currency: widget.currency,
                  ),
                ),
              );
            },
          );
        }),
        SizedBox(height: 4),
      ],
    );
  }
}

class _DailyBar extends StatelessWidget {
  final DailyBreakdown day;
  final double maxSpent;
  final double dailyAverage;
  final Currency currency;
  final bool isDark;
  final AnimationController animationController;
  final double animationDelay;
  final bool isPeakDay;
  final bool isLowestDay;
  final VoidCallback onTap;

  const _DailyBar({
    required this.day,
    required this.maxSpent,
    required this.dailyAverage,
    required this.currency,
    required this.isDark,
    required this.animationController,
    required this.animationDelay,
    required this.isPeakDay,
    required this.isLowestDay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxSpent > 0 ? (day.totalSpent / maxSpent) : 0.0;
    final isAboveAverage = day.totalSpent > dailyAverage;
    final hasSpending = day.totalSpent > 0;

    // Enhanced color logic
    Color barColor;
    if (!hasSpending) {
      barColor = isDark
          ? AppTheme.borderColor.withValues(alpha: 0.2)
          : AppTheme.borderColor;
    } else if (isPeakDay) {
      barColor = AppTheme.primaryColor;
    } else if (isLowestDay) {
      barColor = AppTheme.successColor;
    } else if (isAboveAverage) {
      barColor = AppTheme.warningColor;
    } else {
      barColor = AppTheme.accentColor;
    }

    // Animated progress
    final animatedProgress = Tween<double>(begin: 0.0, end: progress).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(
          animationDelay.clamp(0.0, 0.8),
          (animationDelay + 0.3).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Day label with indicators - fixed width column
            SizedBox(
              width: 52,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        day.dayName.substring(0, 3),
                        style: AppFonts.textStyle(
                          fontSize: 13.scaledText(context),
                          fontWeight: FontWeight.w700,
                          color: hasSpending
                              ? (isDark ? Colors.white : AppTheme.textPrimary)
                              : (isDark 
                                  ? Colors.grey[500]
                                  : AppTheme.textSecondary),
                          height: 1.3,
                        ),
                      ),
                      if (isPeakDay) ...[
                        SizedBox(width: 3),
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 12,
                          color: AppTheme.primaryColor,
                        ),
                      ] else if (isLowestDay && hasSpending) ...[
                        SizedBox(width: 3),
                        Icon(
                          Icons.eco_rounded,
                          size: 12,
                          color: AppTheme.successColor,
                        ),
                      ],
                    ],
                  ),
                  if (hasSpending) ...[
                    SizedBox(height: 2),
                    Text(
                      '${day.transactionCount} ${day.transactionCount == 1 ? 'txn' : 'txns'}',
                      style: AppFonts.textStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.grey[400]
                            : AppTheme.textSecondary.withValues(alpha: 0.9),
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 10),
            // Bar with animation - flexible column, vertically centered
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 26,
                      width: constraints.maxWidth,
                      child: Stack(
                        children: [
                          // Background
                          Container(
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppTheme.borderColor.withValues(
                                alpha: 0.4,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          // Average line indicator
                          if (hasSpending && maxSpent > 0)
                            Positioned(
                              left:
                                  (dailyAverage / maxSpent) *
                                  constraints.maxWidth,
                              child: Container(
                                width: 2,
                                height: 26,
                                color: AppTheme.textSecondary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                          // Animated filled bar
                          AnimatedBuilder(
                            animation: animatedProgress,
                            builder: (context, child) {
                              return FractionallySizedBox(
                                widthFactor: animatedProgress.value.clamp(
                                  0.0,
                                  1.0,
                                ),
                                child: Container(
                                  height: 26,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        barColor,
                                        barColor.withValues(alpha: 0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: hasSpending
                                        ? [
                                            BoxShadow(
                                              color: barColor.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 10),
            // Amount - fixed width column, vertically centered
            SizedBox(
              width: 100,
              child:               Text(
                hasSpending
                    ? CurrencyFormatter.format(day.totalSpent, currency)
                    : '—',
                textAlign: TextAlign.right,
                style: AppFonts.textStyle(
                  fontSize: 14.scaledText(context),
                  fontWeight: FontWeight.w800,
                  color: hasSpending
                      ? (isDark ? Colors.white : AppTheme.textPrimary)
                      : (isDark 
                          ? Colors.grey[500]
                          : AppTheme.textSecondary),
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category Breakdown Card - Enhanced with visualizations
class _CategoryBreakdownCard extends StatefulWidget {
  final List<CategoryInsight> categoryInsights;
  final double totalSpent;
  final Currency currency;
  final bool isDark;

  const _CategoryBreakdownCard({
    required this.categoryInsights,
    required this.totalSpent,
    required this.currency,
    required this.isDark,
  });

  @override
  State<_CategoryBreakdownCard> createState() => _CategoryBreakdownCardState();
}

class _CategoryBreakdownCardState extends State<_CategoryBreakdownCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  static const _categoryColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFF97316), // Orange
    Color(0xFF06B6D4), // Cyan
  ];

  @override
  Widget build(BuildContext context) {
    final topCategories = widget.categoryInsights.take(5).toList();
    final othersTotal = widget.categoryInsights
        .skip(5)
        .fold<double>(0.0, (sum, insight) => sum + insight.amount);
    final othersPercentage = widget.totalSpent > 0
        ? (othersTotal / widget.totalSpent * 100)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Where it went',
                  style: AppFonts.textStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${topCategories.length} top categories',
                  style: AppFonts.textStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            // Visual pie chart indicator
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                children: topCategories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final insight = entry.value;
                  final color = _categoryColors[index % _categoryColors.length];
                  final startAngle = topCategories
                      .take(index)
                      .fold<double>(
                        0.0,
                        (sum, i) => sum + (i.percentage / 100 * 2 * math.pi),
                      );
                  final sweepAngle = (insight.percentage / 100 * 2 * math.pi);

                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(48, 48),
                        painter: _CategoryPiePainter(
                          color: color,
                          startAngle: startAngle,
                          sweepAngle: sweepAngle * _animationController.value,
                          isDark: widget.isDark,
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        // Category list
        ...topCategories.asMap().entries.map((entry) {
          final index = entry.key;
          final insight = entry.value;
          final color = _categoryColors[index % _categoryColors.length];
          return _CategoryRow(
            insight: insight,
            color: color,
            currency: widget.currency,
            isDark: widget.isDark,
            animationController: _animationController,
            animationDelay: index * 0.1,
            isExpanded: _expandedIndex == index,
            onTap: () {
              setState(() {
                _expandedIndex = _expandedIndex == index ? null : index;
              });
            },
          );
        }),
        // Others category (if exists)
        if (othersTotal > 0) ...[
          SizedBox(height: 4),
          _CategoryRow(
            insight: CategoryInsight(
              category: 'Others',
              amount: othersTotal,
              percentage: othersPercentage,
              isUnusualIncrease: false,
              exceededBudget: false,
            ),
            color: AppTheme.textSecondary,
            currency: widget.currency,
            isDark: widget.isDark,
            animationController: _animationController,
            animationDelay: 0.5,
            isExpanded: false,
            onTap: () {},
          ),
        ],
      ],
    );
  }
}

/// Custom painter for category pie chart
class _CategoryPiePainter extends CustomPainter {
  final Color color;
  final double startAngle;
  final double sweepAngle;
  final bool isDark;

  _CategoryPiePainter({
    required this.color,
    required this.startAngle,
    required this.sweepAngle,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle - math.pi / 2,
      sweepAngle,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CategoryPiePainter oldDelegate) {
    return oldDelegate.startAngle != startAngle ||
        oldDelegate.sweepAngle != sweepAngle;
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryInsight insight;
  final Color color;
  final Currency currency;
  final bool isDark;
  final AnimationController animationController;
  final double animationDelay;
  final bool isExpanded;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.insight,
    required this.color,
    required this.currency,
    required this.isDark,
    required this.animationController,
    required this.animationDelay,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final animatedProgress =
        Tween<double>(begin: 0.0, end: insight.percentage / 100).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Interval(
              animationDelay.clamp(0.0, 0.8),
              (animationDelay + 0.3).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          ),
        );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(isExpanded ? 10 : 0),
        decoration: BoxDecoration(
          color: isExpanded
              ? (isDark
                    ? AppTheme.borderColor.withValues(alpha: 0.1)
                    : AppTheme.borderColor.withValues(alpha: 0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Color indicator with icon
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(insight.category),
                    color: color,
                    size: 18,
                  ),
                ),
                SizedBox(width: 10),
                // Category name & percentage
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _formatCategoryName(insight.category),
                              style: AppFonts.textStyle(
                                fontSize: 14.scaledText(context),
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (insight.exceededBudget) ...[
                            SizedBox(width: 6),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFEF4444,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Over',
                                style: AppFonts.textStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${insight.percentage.toStringAsFixed(1)}% of total',
                              style: AppFonts.textStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (insight.changeVsLastWeek != null) ...[
                            SizedBox(width: 10),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: insight.changeVsLastWeek! > 0
                                    ? const Color(
                                        0xFFF59E0B,
                                      ).withValues(alpha: 0.15)
                                    : const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    insight.changeVsLastWeek! > 0
                                        ? Icons.trending_up_rounded
                                        : Icons.trending_down_rounded,
                                    size: 10,
                                    color: insight.changeVsLastWeek! > 0
                                        ? AppTheme.primaryColor
                                        : AppTheme.successColor,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    '${insight.changeVsLastWeek!.abs().toStringAsFixed(0)}%',
                                    style: AppFonts.textStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: insight.changeVsLastWeek! > 0
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      CurrencyFormatter.format(insight.amount, currency),
                      style: AppFonts.textStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (insight.budgetAmount != null) ...[
                      SizedBox(height: 2),
                      Text(
                        'of ${CurrencyFormatter.format(insight.budgetAmount!, currency)}',
                        style: AppFonts.textStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            SizedBox(height: 6),
            // Animated progress bar
            Stack(
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.borderColor.withValues(alpha: 0.2)
                        : AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                AnimatedBuilder(
                  animation: animatedProgress,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      widthFactor: animatedProgress.value,
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.8)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            // Expanded details
            if (isExpanded) ...[
              SizedBox(height: 8.scaledVertical(context)),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.cardBackground.withValues(alpha: 0.03)
                      : AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    if (insight.budgetAmount != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Budget',
                            style: AppFonts.textStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppTheme.textPrimary.withValues(alpha: 0.6)
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(
                              insight.budgetAmount!,
                              currency,
                            ),
                            style: AppFonts.textStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.textPrimary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    if (insight.isUnusualIncrease) ...[
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Unusual increase this week',
                              style: AppFonts.textStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('food') || lower.contains('restaurant')) {
      return Icons.restaurant_rounded;
    } else if (lower.contains('transport') || lower.contains('travel')) {
      return Icons.directions_car_rounded;
    } else if (lower.contains('shopping') || lower.contains('retail')) {
      return Icons.shopping_bag_rounded;
    } else if (lower.contains('entertainment') || lower.contains('fun')) {
      return Icons.movie_rounded;
    } else if (lower.contains('bills') || lower.contains('utilities')) {
      return Icons.receipt_rounded;
    } else if (lower.contains('health') || lower.contains('medical')) {
      return Icons.local_hospital_rounded;
    } else {
      return Icons.category_rounded;
    }
  }

  String _formatCategoryName(String category) {
    return category[0].toUpperCase() + category.substring(1).toLowerCase();
  }
}

/// Insights Section
class _InsightsSection extends StatelessWidget {
  final List<SmartInsight> insights;
  final bool isDark;

  const _InsightsSection({required this.insights, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_rounded,
                color: AppTheme.primaryColor,
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'Insights',
                style: AppFonts.textStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        ...insights
            .take(3)
            .map((insight) => _InsightCard(insight: insight, isDark: isDark)),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final SmartInsight insight;
  final bool isDark;

  const _InsightCard({required this.insight, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.borderColor.withValues(alpha: 0.3)
              : AppTheme.borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              insight.text,
              style: AppFonts.textStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppTheme.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Recommendations Section
class _RecommendationsSection extends StatelessWidget {
  final List<ActionableRecommendation> recommendations;
  final bool isDark;

  const _RecommendationsSection({
    required this.recommendations,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(
                Icons.tips_and_updates_rounded,
                color: AppTheme.primaryColor,
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'What you can do',
                style: AppFonts.textStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        ...recommendations
            .take(2)
            .map(
              (rec) => _RecommendationCard(recommendation: rec, isDark: isDark),
            ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final ActionableRecommendation recommendation;
  final bool isDark;

  const _RecommendationCard({
    required this.recommendation,
    required this.isDark,
  });

  void _handleAction(BuildContext context) {
    if (recommendation.type.toLowerCase().contains('budget') ||
        recommendation.title.toLowerCase().contains('budget') ||
        recommendation.actionLabel.toLowerCase().contains('budget')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BudgetScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action: ${recommendation.actionLabel}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleAction(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppTheme.primaryColor.withValues(alpha: 0.15),
                    AppTheme.primaryColor.withValues(alpha: 0.08),
                  ]
                : [
                    AppTheme.primaryColor.withValues(alpha: 0.08),
                    AppTheme.primaryColor.withValues(alpha: 0.04),
                  ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.title,
                    style: AppFonts.textStyle(
                      fontSize: 14.scaledText(context),
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    recommendation.description,
                    style: AppFonts.textStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                recommendation.actionLabel,
                style: AppFonts.textStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading State
class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingSpinner.large(color: AppTheme.primaryColor),
          SizedBox(height: 14),
          Text(
            'Crunching your numbers...',
            style: AppFonts.textStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppTheme.textSecondary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorMessage = error.toString().replaceAll('Exception: ', '');
    final isRetryable = !errorMessage.contains('Authentication required');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16.scaled(context)),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: AppTheme.errorColor,
              ),
            ),
            SizedBox(height: 16.scaledVertical(context)),
            Text(
              'Couldn\'t load your summary',
              style: AppFonts.textStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6),
            Text(
              errorMessage,
              style: AppFonts.textStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.textSecondary : AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (isRetryable) ...[
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(detailedWeeklySummaryProvider);
                },
                icon: Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Try Again',
                  style: AppFonts.textStyle(
                    fontSize: 14.scaledText(context),
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.textPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
