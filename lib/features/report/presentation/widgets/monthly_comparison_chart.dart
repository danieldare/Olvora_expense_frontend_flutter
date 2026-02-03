import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/models/currency.dart';
import '../providers/report_providers.dart';

class MonthlyComparisonChart extends ConsumerWidget {
  final Currency currency;

  const MonthlyComparisonChart({super.key, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthlyAsync = ref.watch(monthlyComparisonProvider);

    // Use skipLoadingOnRefresh to prevent flickering when data refreshes
    return monthlyAsync.when(
      skipLoadingOnRefresh: true,
      data: (months) {
        if (kDebugMode) {
          debugPrint('Monthly comparison data: $months');
          debugPrint('Monthly comparison count: ${months.length}');
        }

        if (months.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
            child: EmptyStateWidget.compact(
              icon: Icons.bar_chart_rounded,
              title: 'No Comparison Data',
              subtitle: 'Start tracking expenses to see monthly comparisons',
            ),
          );
        }

        // Check if all months have zero totals (no data)
        final allZero = months.every((m) => (m['total'] as double) == 0.0);

        if (allZero) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
            child: EmptyStateWidget.compact(
              icon: Icons.bar_chart_rounded,
              title: 'No Comparison Data',
              subtitle: 'Start tracking expenses to see monthly comparisons',
            ),
          );
        }

        final maxAmount = months
            .map((m) => m['total'] as double)
            .reduce(math.max);

        if (kDebugMode) {
          debugPrint('Monthly comparison maxAmount: $maxAmount');
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
          child: Container(
            padding: EdgeInsets.all(AppSpacing.screenHorizontal),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBackground : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppTheme.borderColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: const Size(double.infinity, 200),
                      painter: _MonthlyBarChartPainter(
                        months: months,
                        maxAmount: maxAmount,
                        isDark: isDark,
                        currency: currency,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                // Month labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: months.map((month) {
                    final monthDate = month['month'] as DateTime;
                    final shortLabel = DateFormat('MMM').format(monthDate);
                    return Expanded(
                      child: Center(
                        child: Text(
                          shortLabel,
                          style: AppFonts.textStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
        child: Container(
          height: 250,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardBackground : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: LoadingSpinner.medium(color: AppTheme.primaryColor),
          ),
        ),
      ),
      error: (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('Monthly comparison error: $error');
        }
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
          child: Container(
            padding: EdgeInsets.all(AppSpacing.cardPadding * 2),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBackground : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppTheme.borderColor,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppTheme.errorColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Error loading monthly data',
                    style: AppFonts.textStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MonthlyBarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> months;
  final double maxAmount;
  final bool isDark;
  final Currency currency;

  _MonthlyBarChartPainter({
    required this.months,
    required this.maxAmount,
    required this.isDark,
    required this.currency,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (months.isEmpty || maxAmount == 0) return;

    // Chart area with padding
    final chartPadding = EdgeInsets.only(left: 0, right: 0, top: 8, bottom: 0);
    final chartArea = Rect.fromLTWH(
      chartPadding.left,
      chartPadding.top,
      size.width - chartPadding.left - chartPadding.right,
      size.height - chartPadding.top - chartPadding.bottom,
    );

    // Draw grid lines
    _drawGridLines(canvas, chartArea, isDark);

    final barWidth = chartArea.width / months.length;
    final maxBarHeight = chartArea.height;

    final gradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [AppTheme.primaryColor, AppTheme.accentColor],
    );

    for (int i = 0; i < months.length; i++) {
      final month = months[i];
      final amount = month['total'] as double;
      final barHeight = maxAmount > 0
          ? (amount / maxAmount) * maxBarHeight
          : 0.0;
      final x = chartArea.left + (i * barWidth) + (barWidth / 2);
      final y = chartArea.bottom;

      // Draw bar with spacing
      final barSpacing = barWidth * 0.15; // 15% spacing on each side
      final rect = Rect.fromLTWH(
        x - (barWidth / 2) + barSpacing,
        y - barHeight,
        barWidth - (barSpacing * 2),
        barHeight,
      );

      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.fill;

      // Rounded top corners
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

      canvas.drawRRect(rrect, paint);

      // Draw amount label on top of bar
      if (barHeight > 25) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: CurrencyFormatter.formatCompact(amount, currency),
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            x - (textPainter.width / 2),
            y - barHeight - textPainter.height - 6,
          ),
        );
      }
    }
  }

  void _drawGridLines(Canvas canvas, Rect chartArea, bool isDark) {
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
      ..strokeWidth = 1;

    // Draw horizontal grid lines (4 lines for 5 sections)
    for (int i = 0; i <= 4; i++) {
      final y = chartArea.top + (chartArea.height / 4) * i;
      canvas.drawLine(
        Offset(chartArea.left, y),
        Offset(chartArea.right, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_MonthlyBarChartPainter oldDelegate) {
    if (oldDelegate.months.length != months.length ||
        oldDelegate.maxAmount != maxAmount ||
        oldDelegate.isDark != isDark) {
      return true;
    }

    // Compare month values
    for (int i = 0; i < months.length; i++) {
      final oldMonth = oldDelegate.months[i];
      final newMonth = months[i];
      if (oldMonth['total'] != newMonth['total'] ||
          oldMonth['month'] != newMonth['month']) {
        return true;
      }
    }

    return false;
  }
}
