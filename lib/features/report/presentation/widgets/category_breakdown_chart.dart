import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/chart_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/models/currency.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../providers/report_providers.dart';

class CategoryBreakdownChart extends ConsumerStatefulWidget {
  final ReportDateRangeParams dateRangeParams;
  final Currency currency;

  const CategoryBreakdownChart({
    super.key,
    required this.dateRangeParams,
    required this.currency,
  });

  @override
  ConsumerState<CategoryBreakdownChart> createState() =>
      _CategoryBreakdownChartState();
}

class _CategoryBreakdownChartState extends ConsumerState<CategoryBreakdownChart> {
  // Cache previous data to prevent flickering during refresh
  Map<ExpenseCategory, double>? _lastCategoryTotals;
  bool _hasInitialData = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final breakdownAsync = ref.watch(
      categoryBreakdownProvider(widget.dateRangeParams),
    );

    // Show error state only if there's an error AND no cached data
    if (breakdownAsync.hasError && !_hasInitialData) {
      return _buildErrorState(context, isDark);
    }

    // Get current data or fall back to cached data
    final categoryTotals = breakdownAsync.valueOrNull ?? _lastCategoryTotals;

    // Only show empty state on initial load with no data
    if (categoryTotals == null) {
      if (breakdownAsync.isLoading) {
        // Show a minimal loading placeholder on first load
        return _buildLoadingState(isDark);
      }
      return _buildEmptyState();
    }

    // Cache the data for future refreshes
    if (breakdownAsync.hasValue) {
      _lastCategoryTotals = breakdownAsync.value;
      _hasInitialData = true;
    }

    // Calculate total
    final total = categoryTotals.values.fold<double>(0.0, (a, b) => a + b);

    if (total == 0) {
      return _buildEmptyState();
    }

    // Filter and sort categories
    final sortedCategories = List<MapEntry<ExpenseCategory, double>>.from(
      categoryTotals.entries.where((e) => e.value > 0),
    )..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
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
            // Pie Chart
            SizedBox(
              height: 200,
              width: double.infinity,
              child: RepaintBoundary(
                child: CustomPaint(
                  size: const Size(double.infinity, 200),
                  painter: _CategoryPieChartPainter(
                    categories: sortedCategories,
                    total: total,
                    isDark: isDark,
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            // Legend
            ...sortedCategories.map((entry) {
              final percentage = (entry.value / total * 100);
              return _CategoryLegendItem(
                category: entry.key,
                amount: entry.value,
                percentage: percentage,
                currency: widget.currency,
                isDark: isDark,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: EmptyStateWidget.compact(
        icon: Icons.pie_chart_outline_rounded,
        title: 'No spending data',
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.borderColor,
            width: 1,
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
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
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 32,
              color: AppTheme.errorColor,
            ),
            SizedBox(height: 12),
            Text(
              'Failed to load category breakdown',
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(
                categoryBreakdownProvider(widget.dateRangeParams),
              ),
              icon: Icon(Icons.refresh_rounded, size: 16),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPieChartPainter extends CustomPainter {
  final List<MapEntry<ExpenseCategory, double>> categories;
  final double total;
  final bool isDark;

  static final List<Color> _colors = ChartColors.categoryPalette;

  _CategoryPieChartPainter({
    required this.categories,
    required this.total,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2; // Start from top

    for (int i = 0; i < categories.length; i++) {
      final entry = categories[i];
      final sweepAngle = (entry.value / total) * 2 * math.pi;
      final color = _colors[i % _colors.length];

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_CategoryPieChartPainter oldDelegate) {
    if (oldDelegate.categories.length != categories.length ||
        oldDelegate.total != total ||
        oldDelegate.isDark != isDark) {
      return true;
    }

    // Compare category values
    for (int i = 0; i < categories.length; i++) {
      if (oldDelegate.categories[i].key != categories[i].key ||
          oldDelegate.categories[i].value != categories[i].value) {
        return true;
      }
    }

    return false;
  }
}

class _CategoryLegendItem extends StatelessWidget {
  final ExpenseCategory category;
  final double amount;
  final double percentage;
  final Currency currency;
  final bool isDark;

  const _CategoryLegendItem({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.currency,
    required this.isDark,
  });

  static final List<Color> _colors = ChartColors.categoryPalette;

  Color _getCategoryColor(int index) {
    return _colors[index % _colors.length];
  }

  String _getCategoryName(ExpenseCategory category) {
    return category.name[0].toUpperCase() +
        category.name.substring(1).replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final categoryIndex = ExpenseCategory.values.indexOf(category);
    final color = _getCategoryColor(categoryIndex);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _getCategoryName(category),
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppTheme.textSecondary,
            ),
          ),
          SizedBox(width: 12),
          Text(
            CurrencyFormatter.format(amount, currency),
            style: AppFonts.textStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
