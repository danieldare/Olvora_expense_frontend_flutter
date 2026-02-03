import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/models/currency.dart';
import '../../domain/entities/spending_forecast_entity.dart';

class ForecastCard extends ConsumerWidget {
  final SpendingForecastEntity forecast;

  const ForecastCard({
    super.key,
    required this.forecast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final currency = currencyAsync.value ?? Currency.defaultCurrency;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final progress = forecast.utilizationPercent / 100;
    final projectedProgress = forecast.projectedUtilizationPercent / 100;

    Color getProgressColor() {
      if (forecast.hasExceeded) return AppTheme.errorColor;
      if (forecast.isProjectedToExceed) return AppTheme.warningColor;
      if (progress > 0.8) return AppTheme.warningColor;
      return AppTheme.successColor;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppTheme.textPrimary.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: getProgressColor().withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    forecast.hasExceeded
                        ? Icons.error_outline_rounded
                        : forecast.isProjectedToExceed
                            ? Icons.warning_amber_rounded
                            : Icons.trending_up_rounded,
                    size: 22,
                    color: getProgressColor(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    forecast.budgetName,
                    style: AppFonts.textStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (forecast.confidence > 0.7
                            ? AppTheme.successColor
                            : AppTheme.warningColor)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${(forecast.confidence * 100).toInt()}%',
                    style: AppFonts.textStyle(
                      color: forecast.confidence > 0.7
                          ? AppTheme.successColor
                          : AppTheme.warningColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bars
            _buildProgressSection(
              context,
              'Current',
              progress,
              forecast.currentSpent,
              forecast.budgetAmount,
              currency,
              getProgressColor(),
            ),
            const SizedBox(height: 12),
            _buildProgressSection(
              context,
              'Projected',
              projectedProgress.clamp(0.0, 1.0),
              forecast.projectedSpent,
              forecast.budgetAmount,
              currency,
              forecast.isProjectedToExceed
                  ? AppTheme.warningColor
                  : AppTheme.successColor,
            ),

            // Key metrics
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetric(
                    context,
                    'Daily Rate',
                    CurrencyFormatter.format(forecast.dailyBurnRate, currency),
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    context,
                    'Safe Daily',
                    CurrencyFormatter.format(forecast.safeDailySpend, currency),
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    context,
                    'Days Left',
                    '${forecast.daysRemaining}',
                  ),
                ),
              ],
            ),

            // Trend indicator
            if (forecast.trend != SpendingTrend.steady) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    forecast.trend == SpendingTrend.accelerating
                        ? Icons.trending_up
                        : Icons.trending_down,
                    size: 16,
                    color: forecast.trend == SpendingTrend.accelerating
                        ? AppTheme.warningColor
                        : AppTheme.successColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    forecast.trend == SpendingTrend.accelerating
                        ? 'Spending accelerating'
                        : 'Spending improving',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: forecast.trend == SpendingTrend.accelerating
                              ? AppTheme.warningColor
                              : AppTheme.successColor,
                        ),
                  ),
                ],
              ),
            ],

            // Projected overage/underage
            if (forecast.projectedOverage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.errorColor.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Projected to exceed by ${CurrencyFormatter.format(forecast.projectedOverage!, currency)}',
                        style: TextStyle(
                          color: AppTheme.errorColor.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (forecast.projectedUnderage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.successColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Projected to be under by ${CurrencyFormatter.format(forecast.projectedUnderage!, currency)}',
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(
    BuildContext context,
    String label,
    double progress,
    double spent,
    double budget,
    Currency currency,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppFonts.textStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : AppTheme.textSecondary,
              ),
            ),
            Text(
              '${CurrencyFormatter.format(spent, currency)} / ${CurrencyFormatter.format(budget, currency)}',
              style: AppFonts.textStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : AppTheme.borderColor.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.textStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppFonts.textStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
