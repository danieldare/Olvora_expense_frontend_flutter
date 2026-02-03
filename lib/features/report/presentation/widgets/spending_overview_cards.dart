import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/models/currency.dart';
import '../providers/report_providers.dart';

class SpendingOverviewCards extends ConsumerStatefulWidget {
  final ReportDateRangeParams dateRangeParams;
  final Currency currency;

  /// When true, uses smaller padding and fonts for a compact layout.
  final bool compact;

  const SpendingOverviewCards({
    super.key,
    required this.dateRangeParams,
    required this.currency,
    this.compact = false,
  });

  @override
  ConsumerState<SpendingOverviewCards> createState() =>
      _SpendingOverviewCardsState();
}

class _SpendingOverviewCardsState extends ConsumerState<SpendingOverviewCards> {
  // Preserve previous values during loading
  double _lastTotal = 0.0;
  double _lastAverage = 0.0;
  int _lastCount = 0;
  double _lastHighest = 0.0;
  double _lastLowest = 0.0;
  bool _hasInitialData = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overviewAsync = ref.watch(
      spendingOverviewProvider(widget.dateRangeParams),
    );

    return overviewAsync.maybeWhen(
      data: (data) {
        final total = data['total'] as double;
        final average = data['average'] as double;
        final count = data['count'] as int;
        final highest = data['highest'] as double;
        final lowest = data['lowest'] as double;

        // Update preserved values when we have new data
        _lastTotal = total;
        _lastAverage = average;
        _lastCount = count;
        _lastHighest = highest;
        _lastLowest = lowest;
        _hasInitialData = true;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Column(
            children: [
              // Total Spending Card
              _buildCard(
                context,
                isDark,
                'Total Spending',
                Text(
                  CurrencyFormatter.format(total, widget.currency),
                  style: AppFonts.textStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Icons.account_balance_wallet_rounded,
                AppTheme.primaryColor,
              ),
              SizedBox(height: 12),
              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildCard(
                      context,
                      isDark,
                      'Transactions',
                      Text(
                        count.toString(),
                        style: AppFonts.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      Icons.receipt_long_rounded,
                      AppTheme.accentColor,
                      isSmall: true,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildCard(
                      context,
                      isDark,
                      'Average',
                      Text(
                        CurrencyFormatter.format(average, widget.currency),
                        style: AppFonts.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      Icons.trending_up_rounded,
                      AppTheme.successColor,
                      isSmall: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildCard(
                      context,
                      isDark,
                      'Highest',
                      Text(
                        CurrencyFormatter.format(highest, widget.currency),
                        style: AppFonts.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      Icons.arrow_upward_rounded,
                      AppTheme.warningColor,
                      isSmall: true,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildCard(
                      context,
                      isDark,
                      'Lowest',
                      Text(
                        CurrencyFormatter.format(lowest, widget.currency),
                        style: AppFonts.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      Icons.arrow_downward_rounded,
                      AppTheme.errorColor,
                      isSmall: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      orElse: () {
        final total = _hasInitialData ? _lastTotal : 0.0;
        final average = _hasInitialData ? _lastAverage : 0.0;
        final count = _hasInitialData ? _lastCount : 0;
        final highest = _hasInitialData ? _lastHighest : 0.0;
        final lowest = _hasInitialData ? _lastLowest : 0.0;
        final gap = widget.compact ? 8.0 : 12.0;
        final totalFontSize = widget.compact ? 22.0 : 24.0;
        final smallFontSize = widget.compact ? 14.0 : 16.0;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Column(
            children: [
              _buildCard(
                context,
                isDark,
                'Total Spending',
                Text(
                  CurrencyFormatter.format(total, widget.currency),
                  style: AppFonts.textStyle(
                    fontSize: totalFontSize,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Icons.account_balance_wallet_rounded,
                AppTheme.primaryColor,
              ),
              SizedBox(height: gap),
              Row(
                children: [
                  Expanded(
                    child: _buildCard(
                      context,
                      isDark,
                      'Transactions',
                      Text(
                        count.toString(),
                        style: AppFonts.textStyle(
                          fontSize: smallFontSize,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      Icons.receipt_long_rounded,
                      AppTheme.accentColor,
                      isSmall: true,
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: _buildCard(
                      context,
                      isDark,
                      'Average',
                      Text(
                        CurrencyFormatter.format(average, widget.currency),
                        style: AppFonts.textStyle(
                          fontSize: smallFontSize,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      Icons.trending_up_rounded,
                      AppTheme.successColor,
                      isSmall: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: gap),
              Row(
                children: [
                  Expanded(
                    child: _buildCard(
                      context,
                      isDark,
                      'Highest',
                      Text(
                        CurrencyFormatter.format(highest, widget.currency),
                        style: AppFonts.textStyle(
                          fontSize: smallFontSize,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      Icons.arrow_upward_rounded,
                      AppTheme.warningColor,
                      isSmall: true,
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: _buildCard(
                      context,
                      isDark,
                      'Lowest',
                      Text(
                        CurrencyFormatter.format(lowest, widget.currency),
                        style: AppFonts.textStyle(
                          fontSize: smallFontSize,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      Icons.arrow_downward_rounded,
                      AppTheme.errorColor,
                      isSmall: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    bool isDark,
    String label,
    Widget value,
    IconData icon,
    Color color, {
    bool isSmall = false,
  }) {
    final compact = widget.compact;
    final padding = compact
        ? (isSmall ? 12.0 : 14.0)
        : (isSmall ? 16.0 : 20.0);
    final radius = compact ? 16.0 : 20.0;
    final iconSize = compact ? (isSmall ? 18.0 : 20.0) : (isSmall ? 20.0 : 24.0);
    final iconPadding = compact ? 10.0 : 12.0;
    final labelFontSize = compact ? 11.0 : 12.0;
    final totalLabelFontSize = compact ? 12.0 : 13.0;
    final gapAfterIcon = compact ? 12.0 : 16.0;
    final gapSmall = compact ? 6.0 : 8.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.borderColor,
          width: 1,
        ),
        boxShadow: AppShadows.card(
          isDark: isDark,
          blur: isDark ? 8 : AppShadows.cardBlur,
          offsetY: 2,
          spread: 0,
        ),
      ),
      child: isSmall
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: iconSize),
                SizedBox(height: gapSmall),
                Text(
                  label,
                  style: AppFonts.textStyle(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.grey[300]!
                        : AppTheme.textSecondary.withValues(alpha: 0.9),
                  ),
                ),
                SizedBox(height: 4),
                value,
              ],
            )
          : Row(
              children: [
                Container(
                  padding: EdgeInsets.all(iconPadding),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.35 : 0.25),
                    borderRadius: BorderRadius.circular(compact ? 10 : 12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: isDark ? 0.2 : 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: iconSize),
                ),
                SizedBox(width: gapAfterIcon),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppFonts.textStyle(
                          fontSize: totalLabelFontSize,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.grey[300]!
                              : AppTheme.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                      SizedBox(height: 4),
                      value,
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
