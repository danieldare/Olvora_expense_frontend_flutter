import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../../core/widgets/app_option_row.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/models/currency.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/services/export_service.dart';
import '../../../budget/presentation/providers/budget_providers.dart';
import '../../../budget/domain/entities/budget_entity.dart';
import '../../../expenses/presentation/widgets/quick_add_expense_modal.dart';
import '../providers/report_providers.dart';
import '../providers/export_providers.dart';
import '../widgets/export_date_range_dialog.dart';

// Export ReportDateRangeParams for use in widgets
export '../providers/report_providers.dart' show ReportDateRangeParams;
import '../widgets/category_breakdown_chart.dart';
import '../widgets/monthly_comparison_chart.dart';
import '../widgets/spending_overview_cards.dart';
import '../widgets/top_expenses_list.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen>
    with AutomaticKeepAliveClientMixin {
  ReportPeriod _selectedPeriod = ReportPeriod.month;
  int _periodOffset = 0;

  @override
  bool get wantKeepAlive => true;

  /// Get the current date range parameters
  ReportDateRangeParams get _dateRangeParams => ReportDateRangeParams(
    period: _selectedPeriod,
    periodOffset: _periodOffset,
  );

  void _changePeriod(ReportPeriod period) {
    if (_selectedPeriod == period) return;
    setState(() {
      _selectedPeriod = period;
      _periodOffset = 0;
    });
  }

  void _navigatePeriod(int delta) {
    setState(() {
      _periodOffset += delta;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppTheme.screenBackgroundColor;
    final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        // Use skipLoadingOnRefresh to prevent flickering when data refreshes
        child: selectedCurrencyAsync.when(
          skipLoadingOnRefresh: true,
          data: (currency) => _buildContent(currency, isDark),
          loading: () =>
              Center(child: LoadingSpinner.large(color: AppTheme.primaryColor)),
          error: (_, __) => _buildErrorState(isDark),
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.cardPadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : AppTheme.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'Unable to load reports',
              style: AppFonts.textStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Invalidate all report providers to trigger refresh
                ref.invalidate(spendingOverviewProvider(_dateRangeParams));
                ref.invalidate(categoryBreakdownProvider(_dateRangeParams));
                ref.invalidate(monthlyComparisonProvider);
              },
              icon: Icon(Icons.refresh_rounded, size: 18),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Currency currency, bool isDark) {
    final cardColor = isDark
        ? AppTheme.darkCardBackground
        : AppTheme.cardBackground;
    final textColor = AppTheme.textPrimary;
    final subtitleColor = AppTheme.textSecondary;

    return Consumer(
      builder: (context, ref, _) {
        // Check if there's any expense data for all time
        final allTimeOverviewAsync = ref.watch(
          spendingOverviewProvider(
            const ReportDateRangeParams(period: ReportPeriod.allTime),
          ),
        );

        final hasAnyExpenses = allTimeOverviewAsync.maybeWhen(
          data: (data) {
            final transactions = data['transactions'] as List;
            return transactions.isNotEmpty;
          },
          orElse: () => true, // Assume there's data to prevent flicker
        );

        // Check if any provider is loading
        final overviewAsync = ref.watch(
          spendingOverviewProvider(_dateRangeParams),
        );
        final categoryAsync = ref.watch(
          categoryBreakdownProvider(_dateRangeParams),
        );
        final isLoading = overviewAsync.isLoading || categoryAsync.isLoading;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ═══════════════════════════════════════════════════════════════
            // HEADER
            // ═══════════════════════════════════════════════════════════════
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  16,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: _buildHeader(
                  isDark,
                  textColor,
                  subtitleColor,
                  isLoading,
                  hasAnyExpenses,
                ),
              ),
            ),

            // Show empty state if no expenses at all
            if (!hasAnyExpenses) ...[
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(isDark, textColor, subtitleColor),
              ),
            ] else ...[
              // ═══════════════════════════════════════════════════════════════
              // PERIOD SELECTOR (Sticky behavior would be ideal but keeping simple)
              // ═══════════════════════════════════════════════════════════════
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    16,
                    AppSpacing.screenHorizontal,
                    0,
                  ),
                  child: _buildPeriodSelector(
                    isDark,
                    cardColor,
                    textColor,
                    subtitleColor,
                  ),
                ),
              ),

              // ═══════════════════════════════════════════════════════════════
              // SECTION: PERIOD-SPECIFIC INSIGHTS
              // ═══════════════════════════════════════════════════════════════
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    20,
                    AppSpacing.screenHorizontal,
                    10,
                  ),
                  child: _buildSectionLabel(
                    'Period Insights',
                    'Data for selected time range',
                    textColor,
                    subtitleColor,
                  ),
                ),
              ),

              // Overview Cards - with key to prevent flicker
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: SpendingOverviewCards(
                    key: ValueKey(
                      'overview_${_selectedPeriod.name}_$_periodOffset',
                    ),
                    dateRangeParams: _dateRangeParams,
                    currency: currency,
                    compact: true,
                  ),
                ),
              ),

              // Category Breakdown
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    16,
                    AppSpacing.screenHorizontal,
                    10,
                  ),
                  child: _buildSubSectionHeader(
                    'Category Breakdown',
                    isDark,
                    textColor,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: CategoryBreakdownChart(
                    key: ValueKey(
                      'category_${_selectedPeriod.name}_$_periodOffset',
                    ),
                    dateRangeParams: _dateRangeParams,
                    currency: currency,
                  ),
                ),
              ),

              // Top Expenses
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    18,
                    AppSpacing.screenHorizontal,
                    10,
                  ),
                  child: _buildSubSectionHeader(
                    'Top Expenses',
                    isDark,
                    textColor,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: TopExpensesList(
                    key: ValueKey('top_${_selectedPeriod.name}_$_periodOffset'),
                    dateRangeParams: _dateRangeParams,
                    currency: currency,
                  ),
                ),
              ),

              // ═══════════════════════════════════════════════════════════════
              // DIVIDER - Visual separation between period-dependent and independent
              // ═══════════════════════════════════════════════════════════════
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                    vertical: 24,
                  ),
                  child: _buildDivider(isDark),
                ),
              ),

              // ═══════════════════════════════════════════════════════════════
              // SECTION: OVERALL INSIGHTS (Independent of period selector)
              // ═══════════════════════════════════════════════════════════════
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    0,
                    AppSpacing.screenHorizontal,
                    12,
                  ),
                  child: _buildSectionLabel(
                    'Overall Insights',
                    'Your complete financial picture',
                    textColor,
                    subtitleColor,
                  ),
                ),
              ),

              // Budget Health Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    0,
                    AppSpacing.screenHorizontal,
                    12,
                  ),
                  child: _BudgetHealthCard(currency: currency, isDark: isDark),
                ),
              ),

              // Monthly Comparison
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    12,
                    AppSpacing.screenHorizontal,
                    10,
                  ),
                  child: _buildSubSectionHeader(
                    'Monthly Trend',
                    isDark,
                    textColor,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: MonthlyComparisonChart(
                    key: const ValueKey('monthly_comparison'),
                    currency: currency,
                  ),
                ),
              ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.bottomNavPadding),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark, Color textColor, Color subtitleColor) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: 20,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compact icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.bar_chart_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'No expenses yet',
              style: AppFonts.textStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Start tracking your expenses to see detailed reports and insights about your spending.',
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.grey[300]!
                    : AppTheme.textSecondary.withValues(alpha: 0.9),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => QuickAddExpenseModal.show(context: context),
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 10),
                        Text(
                          'Add your first expense',
                          style: AppFonts.textStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    bool isDark,
    Color textColor,
    Color subtitleColor,
    bool isLoading,
    bool hasAnyExpenses,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Reports',
                    style: AppFonts.textStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -1.0,
                    ),
                  ),
                  if (isLoading) ...[
                    SizedBox(width: 10),
                    LoadingSpinner.small(color: AppTheme.primaryColor),
                  ],
                ],
              ),
              SizedBox(height: 2),
              Text(
                'Track your financial health',
                style: AppFonts.textStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.grey[300]!
                      : AppTheme.textSecondary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
        if (hasAnyExpenses)
          IconButton(
            onPressed: () => _showExportOptions(context, isDark),
            icon: Icon(
              Icons.ios_share_rounded,
              color: isDark ? Colors.white : AppTheme.primaryColor,
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.25)
                  : AppTheme.primaryColor.withValues(alpha: 0.25),
              padding: const EdgeInsets.all(8),
            ),
          ),
      ],
    );
  }

  Widget _buildPeriodSelector(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    final isCurrentPeriod = _periodOffset == 0;
    final canNavigate = _selectedPeriod != ReportPeriod.allTime;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : AppShadows.card(
                isDark: isDark,
                color: AppTheme.textPrimary,
                alphaDark: 0.25,
                blur: 22,
                spread: -4,
              ),
      ),
      child: Column(
        children: [
          // Period Tabs
          Padding(
            padding: const EdgeInsets.all(6),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.borderColor.withValues(alpha: 0.25)
                    : AppTheme.darkCardBackground.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: ReportPeriod.values.map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _changePeriod(period),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isSelected && !isDark
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            _getPeriodLabel(period),
                            style: AppFonts.textStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected ? Colors.white : textColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Date Navigator
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.borderColor.withValues(alpha: 0.25)
                    : AppTheme.darkCardBackground.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Only show left arrow if not "All Time"
                  if (canNavigate)
                    _NavButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: () => _navigatePeriod(-1),
                      isDark: isDark,
                    ),
                  Expanded(
                    child: _buildDateRangeContent(
                      isDark: isDark,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      isCurrentPeriod: isCurrentPeriod,
                    ),
                  ),
                  // Only show right arrow if not "All Time" and not current period
                  if (canNavigate && !isCurrentPeriod)
                    _NavButton(
                      icon: Icons.chevron_right_rounded,
                      onTap: () => _navigatePeriod(1),
                      isDark: isDark,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeContent({
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
    required bool isCurrentPeriod,
  }) {
    // Get date range synchronously from provider
    final dateRange = ref.read(reportDateRangeProvider(_dateRangeParams));

    if (dateRange == null) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.all_inclusive_rounded,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 6),
              Text(
                'All Time',
                style: AppFonts.textStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 2),
          Text(
            'Complete history',
            style: AppFonts.textStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
          ),
        ],
      );
    }

    final startDate = dateRange['start'] as DateTime;
    final endDate = dateRange['end'] as DateTime;
    final now = DateTime.now();
    final isCurrentYear =
        startDate.year == now.year && endDate.year == now.year;

    final startFormatted = isCurrentYear
        ? DateFormat('MMM d').format(startDate)
        : DateFormat('MMM d, yy').format(startDate);
    final endFormatted = isCurrentYear
        ? DateFormat('MMM d').format(endDate)
        : DateFormat('MMM d, yy').format(endDate);

    final daysDiff = endDate.difference(startDate).inDays + 1;
    final daysLabel = daysDiff == 1 ? '1 day' : '$daysDiff days';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$startFormatted – $endFormatted',
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            if (isCurrentPeriod) ...[
              SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Now',
                  style: AppFonts.textStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 2),
        Text(
          daysLabel,
          style: AppFonts.textStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: subtitleColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(
    String title,
    String subtitle,
    Color textColor,
    Color subtitleColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppFonts.textStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.3,
          ),
        ),
        Text(
          subtitle,
          style: AppFonts.textStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: subtitleColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSubSectionHeader(String title, bool isDark, Color textColor) {
    return Text(
      title,
      style: AppFonts.textStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.25),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Big Picture',
              style: AppFonts.textStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getPeriodLabel(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.week:
        return 'Week';
      case ReportPeriod.month:
        return 'Month';
      case ReportPeriod.quarter:
        return 'Quarter';
      case ReportPeriod.year:
        return 'Year';
      case ReportPeriod.allTime:
        return 'All';
    }
  }

  void _showExportOptions(BuildContext context, bool isDark) {
    final screenHeight = MediaQuery.of(context).size.height;
    final viewPadding = MediaQuery.of(context).viewPadding;
    final safeMaxHeight = (screenHeight - viewPadding.top) * 0.45;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          constraints: BoxConstraints(maxHeight: safeMaxHeight),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardBackground : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.textPrimary.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, -2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppTheme.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Export Report',
                            style: AppFonts.textStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Choose format and date range',
                            style: AppFonts.textStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: isDark
                            ? Colors.white
                            : AppTheme.textPrimary,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppOptionRow(
                          icon: Icons.table_chart_rounded,
                          title: 'Export as XLS',
                          subtitle: 'Excel spreadsheet with expenses and summary',
                          color: AppTheme.primaryColor,
                          onTap: () {
                            Navigator.pop(context);
                            _showExportDateRangeDialog(context, isDark, 'xls');
                          },
                          dense: true,
                        ),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppTheme.borderColor.withValues(alpha: 0.3),
                        ),
                        AppOptionRow(
                          icon: Icons.description_rounded,
                          title: 'Export as CSV',
                          subtitle: 'Comma-separated values file',
                          color: AppTheme.secondaryColor,
                          onTap: () {
                            Navigator.pop(context);
                            _showExportDateRangeDialog(context, isDark, 'csv');
                          },
                          dense: true,
                        ),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppTheme.borderColor.withValues(alpha: 0.3),
                        ),
                        AppOptionRow(
                          icon: Icons.image_outlined,
                          title: 'Export as Image',
                          subtitle: 'Save as PNG',
                          color: AppTheme.accentColor,
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Coming soon!'),
                                backgroundColor: AppTheme.primaryColor,
                              ),
                            );
                          },
                          dense: true,
                        ),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppTheme.borderColor.withValues(alpha: 0.3),
                        ),
                        AppOptionRow(
                          icon: Icons.picture_as_pdf_outlined,
                          title: 'Export as PDF',
                          subtitle: 'Full report document',
                          color: AppTheme.errorColor,
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Coming soon!'),
                                backgroundColor: AppTheme.primaryColor,
                              ),
                            );
                          },
                          dense: true,
                        ),
                        SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportDateRangeDialog(
    BuildContext context,
    bool isDark,
    String format,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final viewPadding = MediaQuery.of(context).viewPadding;
    final safeMaxHeight = (screenHeight - viewPadding.top) * 0.55;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          constraints: BoxConstraints(maxHeight: safeMaxHeight),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardBackground : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.textPrimary.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, -2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppTheme.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Date Range',
                            style: AppFonts.textStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Choose period for export',
                            style: AppFonts.textStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: isDark
                            ? Colors.white
                            : AppTheme.textPrimary,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ExportDateRangeDialog(
                      currentPeriod: _dateRangeParams,
                      onConfirm: (startDate, endDate) {
                        _handleExport(context, format, startDate, endDate);
                      },
                      onBack: () {
                        Navigator.pop(context);
                        _showExportOptions(context, isDark);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleExport(
    BuildContext context,
    String format,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkCardBackground
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LoadingSpinner.medium(color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text(
                'Preparing export...',
                style: AppFonts.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    bool dialogClosed = false;

    try {
      final currencyAsync = ref.read(selectedCurrencyProvider);
      final currency = currencyAsync.valueOrNull ?? Currency.defaultCurrency;

      // Fetch data
      final dateRange = {'start': startDate, 'end': endDate};
      final expensesAsync = await ref.read(exportExpensesProvider(dateRange).future);
      final reportSummaryAsync =
          await ref.read(exportReportSummaryProvider(dateRange).future);
      final categoryBreakdownAsync =
          await ref.read(exportCategoryBreakdownProvider(dateRange).future);

      if (expensesAsync.isEmpty) {
        if (context.mounted && !dialogClosed) {
          Navigator.pop(context);
          dialogClosed = true;
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No data to export for the selected period'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
        }
        return;
      }

      // Generate file
      final exportService = ExportService();
      final file = format == 'xls'
          ? await exportService.exportReportToXLS(
              expenses: expensesAsync,
              reportSummary: reportSummaryAsync,
              categoryBreakdown: categoryBreakdownAsync,
              startDate: startDate,
              endDate: endDate,
              currency: currency,
            )
          : await exportService.exportReportToCSV(
              expenses: expensesAsync,
              reportSummary: reportSummaryAsync,
              categoryBreakdown: categoryBreakdownAsync,
              startDate: startDate,
              endDate: endDate,
              currency: currency,
            );

      // Close loading dialog before showing share sheet
      if (context.mounted && !dialogClosed) {
        Navigator.pop(context);
        dialogClosed = true;
      }

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Expense Report Export',
      );

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export completed successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted && !dialogClosed) {
        Navigator.pop(context);
        dialogClosed = true;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      // Ensure dialog is closed even if something unexpected happens
      if (context.mounted && !dialogClosed) {
        Navigator.pop(context);
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BUDGET HEALTH CARD - Shows overall budget status
// ═══════════════════════════════════════════════════════════════════════════

class _BudgetHealthCard extends ConsumerWidget {
  final Currency currency;
  final bool isDark;

  const _BudgetHealthCard({required this.currency, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generalBudgetsAsync = ref.watch(generalBudgetsProvider);
    final categoryBudgetsAsync = ref.watch(categoryBudgetsProvider);

    // Get values with fallback to prevent flickering
    final generalBudgets = generalBudgetsAsync.valueOrNull;
    final categoryBudgets = categoryBudgetsAsync.valueOrNull;

    // Only show loading on initial load (both are null)
    final isLoading = generalBudgetsAsync.isLoading && generalBudgets == null ||
        categoryBudgetsAsync.isLoading && categoryBudgets == null;

    if (isLoading) {
      return _buildLoadingCard();
    }

    // If we have any data, show the card
    if (generalBudgets != null || categoryBudgets != null) {
      return _buildCard(
        context,
        generalBudgets ?? [],
        categoryBudgets ?? [],
      );
    }

    // Only show empty card on error with no cached data
    return _buildEmptyCard();
  }

  Widget _buildLoadingCard() {
    final cardColor = AppTheme.cardBackground;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(child: LoadingSpinner.small(color: AppTheme.primaryColor)),
    );
  }

  Widget _buildEmptyCard() {
    final cardColor = AppTheme.cardBackground;
    final textColor = AppTheme.textPrimary;
    final subtitleColor = AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 32,
            color: subtitleColor,
          ),
          SizedBox(height: 12),
          Text(
            'No budgets set',
            style: AppFonts.textStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Create budgets to track your spending',
            style: AppFonts.textStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    List<BudgetEntity> generalBudgets,
    List<BudgetEntity> categoryBudgets,
  ) {
    final cardColor = AppTheme.cardBackground;
    final textColor = AppTheme.textPrimary;

    final allBudgets = [
      ...generalBudgets,
      ...categoryBudgets,
    ].where((b) => b.enabled).toList();

    if (allBudgets.isEmpty) return _buildEmptyCard();

    // Calculate health metrics
    int onTrack = 0;
    int overBudget = 0;
    int nearLimit = 0; // 80-100%
    double totalBudget = 0;
    double totalSpent = 0;

    for (final budget in allBudgets) {
      final spent = budget.spent;
      final amount = budget.amount;
      final percentage = amount > 0 ? (spent / amount) * 100 : 0;

      totalBudget += amount;
      totalSpent += spent;

      if (percentage > 100) {
        overBudget++;
      } else if (percentage >= 80) {
        nearLimit++;
      } else {
        onTrack++;
      }
    }

    final overallPercentage = totalBudget > 0
        ? (totalSpent / totalBudget) * 100
        : 0;
    final healthScore = _calculateHealthScore(
      onTrack,
      nearLimit,
      overBudget,
      allBudgets.length,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? null
            : AppShadows.card(
                isDark: isDark,
                color: AppTheme.textPrimary,
                alphaDark: 0.25,
                blur: 22,
                spread: -4,
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getHealthColor(
                    healthScore,
                  ).withValues(alpha: isDark ? 0.35 : 0.25),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: _getHealthColor(
                              healthScore,
                            ).withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                            spreadRadius: 0,
                          ),
                        ],
                ),
                child: Icon(
                  _getHealthIcon(healthScore),
                  size: 20,
                  color: _getHealthColor(healthScore),
                ),
              ),
              SizedBox(width: 12),
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
                      ),
                    ),
                    Text(
                      _getHealthLabel(healthScore),
                      style: AppFonts.textStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? textColor
                            : _getHealthColor(healthScore),
                      ),
                    ),
                  ],
                ),
              ),
              // Health Score Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getHealthColor(healthScore).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${healthScore.toStringAsFixed(0)}%',
                  style: AppFonts.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _getHealthColor(healthScore),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Overall Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Overall Usage',
                    style: AppFonts.textStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '${CurrencyFormatter.format(totalSpent, currency)} / ${CurrencyFormatter.format(totalBudget, currency)}',
                    style: AppFonts.textStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (overallPercentage / 100).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getHealthColor(healthScore),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Budget Status Pills
          Row(
            children: [
              Expanded(
                child: _StatusPill(
                  count: onTrack,
                  label: 'On Track',
                  color: AppTheme.successColor,
                  isDark: isDark,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _StatusPill(
                  count: nearLimit,
                  label: 'Near Limit',
                  color: AppTheme.warningColor,
                  isDark: isDark,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _StatusPill(
                  count: overBudget,
                  label: 'Over',
                  color: AppTheme.errorColor,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateHealthScore(
    int onTrack,
    int nearLimit,
    int overBudget,
    int total,
  ) {
    if (total == 0) return 100;
    // On track = 100%, Near limit = 50%, Over budget = 0%
    final score =
        ((onTrack * 100) + (nearLimit * 50) + (overBudget * 0)) / total;
    return score.clamp(0, 100);
  }

  Color _getHealthColor(double score) {
    if (score >= 80) return AppTheme.successColor;
    if (score >= 50) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  IconData _getHealthIcon(double score) {
    if (score >= 80) return Icons.check_circle_rounded;
    if (score >= 50) return Icons.warning_rounded;
    return Icons.error_rounded;
  }

  String _getHealthLabel(double score) {
    if (score >= 80) return 'Looking great!';
    if (score >= 50) return 'Needs attention';
    return 'Over budget';
  }
}

class _StatusPill extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final bool isDark;

  const _StatusPill({
    required this.count,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.35 : 0.25),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: AppFonts.textStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : color,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: AppFonts.textStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.9)
                  : color.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SUPPORTING WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;

  const _NavButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isEnabled ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isEnabled && !isDark
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isEnabled ? Colors.white : AppTheme.textSecondary,
        ),
      ),
    );
  }
}

