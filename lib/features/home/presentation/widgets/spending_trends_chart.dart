import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../providers/spending_trends_providers.dart';

class SpendingTrendsChart extends ConsumerStatefulWidget {
  /// When true, uses smaller header and fonts for a compact layout.
  final bool compact;

  const SpendingTrendsChart({super.key, this.compact = false});

  @override
  ConsumerState<SpendingTrendsChart> createState() =>
      _SpendingTrendsChartState();
}

class _SpendingTrendsChartState extends ConsumerState<SpendingTrendsChart> {
  TimePeriod _selectedPeriod = TimePeriod.day; // Default: last 7 days
  bool _isExpanded = true;

  String _getPeriodLabel(TimePeriod period) {
    switch (period) {
      case TimePeriod.day:
        return 'Last 7 Days';
      case TimePeriod.week:
        return 'Last 4 Weeks';
      case TimePeriod.month:
        return 'Last 6 Months';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark ? Colors.grey[400] : AppTheme.textSecondary;

    // Fetch spending trends data based on selected period
    final trendsAsync = ref.watch(spendingTrendsProvider(_selectedPeriod));
    final titleSize = widget.compact ? 14.0 : 16.0;
    final subtitleSize = widget.compact ? 11.0 : 12.0;
    final iconSize = widget.compact ? 18.0 : 20.0;
    final iconPadding = widget.compact ? 6.0 : 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spending Trends',
                        style: AppFonts.textStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: -0.8,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        _getPeriodLabel(_selectedPeriod),
                        style: AppFonts.textStyle(
                          fontSize: subtitleSize,
                          color: subtitleColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  SizedBox(width: iconPadding),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: EdgeInsets.all(iconPadding),
                        child: Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: iconSize,
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            // Time period selector - Segmented Control Style
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TimePeriodButton(
                    label: 'D',
                    period: TimePeriod.day,
                    selected: _selectedPeriod == TimePeriod.day,
                    onTap: () =>
                        setState(() => _selectedPeriod = TimePeriod.day),
                    isFirst: true,
                    isLast: false,
                  ),
                  _TimePeriodButton(
                    label: 'W',
                    period: TimePeriod.week,
                    selected: _selectedPeriod == TimePeriod.week,
                    onTap: () =>
                        setState(() => _selectedPeriod = TimePeriod.week),
                    isFirst: false,
                    isLast: false,
                  ),
                  _TimePeriodButton(
                    label: 'M',
                    period: TimePeriod.month,
                    selected: _selectedPeriod == TimePeriod.month,
                    onTap: () =>
                        setState(() => _selectedPeriod = TimePeriod.month),
                    isFirst: false,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        // Chart with collapse/expand
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: EdgeInsets.only(top: AppSpacing.sectionMedium),
            child: SizedBox(
              height: AppSpacing.chartHeight,
              // Use skipLoadingOnRefresh to prevent flickering when data refreshes
              child: trendsAsync.when(
                skipLoadingOnRefresh: true,
                data: (data) => _buildChart(data, isDark),
                loading: () => Center(
                  child: LoadingSpinner.medium(color: AppTheme.primaryColor),
                ),
                error: (error, stack) => _buildChart(
                  _getPlaceholderData(_selectedPeriod),
                  isDark,
                ),
              ),
            ),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }

  /// Placeholder data for when there is no spending data: flat line at zero.
  List<Map<String, dynamic>> _getPlaceholderData(TimePeriod period) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> placeholder = [];
    switch (period) {
      case TimePeriod.day:
        for (int i = 0; i < 7; i++) {
          placeholder.add({
            'date': now.subtract(Duration(days: 6 - i)),
            'amount': 0.0,
          });
        }
        break;
      case TimePeriod.week:
        for (int i = 0; i < 4; i++) {
          placeholder.add({
            'date': now.subtract(Duration(days: (3 - i) * 7)),
            'amount': 0.0,
          });
        }
        break;
      case TimePeriod.month:
        for (int i = 5; i >= 0; i--) {
          placeholder.add({
            'date': DateTime(now.year, now.month - i, 1),
            'amount': 0.0,
          });
        }
        break;
    }
    return placeholder;
  }

  Widget _buildChart(List<Map<String, dynamic>> data, bool isDark) {
    final chartData =
        data.isEmpty ? _getPlaceholderData(_selectedPeriod) : data;

    final amounts = chartData.map((e) => e['amount'] as double).toList();
    final maxAmount =
        amounts.isEmpty ? 0.0 : amounts.reduce((a, b) => a > b ? a : b);
    const minAmount = 0.0;
    final range = (maxAmount - minAmount).clamp(0.0, double.infinity);
    final effectiveRange = range > 0 ? range : 1.0;

    return _InteractiveChart(
      data: chartData,
      maxAmount: maxAmount,
      minAmount: minAmount,
      range: effectiveRange,
      color: AppTheme.primaryColor,
      isDark: isDark,
    );
  }
}

class _InteractiveChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final double maxAmount;
  final double minAmount;
  final double range;
  final Color color;
  final bool isDark;

  const _InteractiveChart({
    required this.data,
    required this.maxAmount,
    required this.minAmount,
    required this.range,
    required this.color,
    required this.isDark,
  });

  @override
  State<_InteractiveChart> createState() => _InteractiveChartState();
}

class _InteractiveChartState extends State<_InteractiveChart> {
  int? _selectedIndex;
  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        final RenderBox? box =
            _key.currentContext?.findRenderObject() as RenderBox?;
        if (box == null) return;

        final localPosition = box.globalToLocal(details.globalPosition);

        // Calculate which point was tapped (must match painter's calculation)
        final chartPadding = EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 50,
        );
        final chartArea = Rect.fromLTWH(
          chartPadding.left,
          chartPadding.top,
          box.size.width - chartPadding.left - chartPadding.right,
          box.size.height - chartPadding.top - chartPadding.bottom,
        );

        // Match the horizontal margin used in painter
        final horizontalMargin = 8.0;
        final effectiveWidth = chartArea.width - (horizontalMargin * 2);
        final stepX = widget.data.length > 1
            ? effectiveWidth / (widget.data.length - 1)
            : effectiveWidth / 2;

        int? tappedIndex;
        double minDistance = double.infinity;

        for (int i = 0; i < widget.data.length; i++) {
          final amount = widget.data[i]['amount'] as double;
          final normalizedHeight = widget.range > 0
              ? ((amount - widget.minAmount) / widget.range) * chartArea.height
              : 0.0;

          final x = widget.data.length > 1
              ? chartArea.left + horizontalMargin + (i * stepX)
              : chartArea.left + chartArea.width / 2;
          final y = chartArea.bottom - normalizedHeight;

          final point = Offset(x, y);
          final distance = (localPosition - point).distance;

          if (distance < 40 && distance < minDistance) {
            minDistance = distance;
            tappedIndex = i;
          }
        }

        setState(() {
          // If tapping the same point, deselect it
          // If tapping outside all points, deselect
          if (_selectedIndex == tappedIndex || tappedIndex == null) {
            _selectedIndex = null;
          } else {
            _selectedIndex = tappedIndex;
          }
        });
      },
      child: CustomPaint(
        key: _key,
        painter: _SpendingChartPainter(
          data: widget.data,
          maxAmount: widget.maxAmount,
          minAmount: widget.minAmount,
          range: widget.range,
          color: widget.color,
          isDark: widget.isDark,
          selectedIndex: _selectedIndex,
        ),
        // Add padding to prevent clipping of edges
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        ),
      ),
    );
  }
}

class _TimePeriodButton extends StatelessWidget {
  final String label;
  final TimePeriod period;
  final bool selected;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _TimePeriodButton({
    required this.label,
    required this.period,
    required this.selected,
    required this.onTap,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.warningColor : Colors.transparent,
          borderRadius: selected
              ? BorderRadius.circular(18)
              : BorderRadius.only(
                  topLeft: isFirst ? const Radius.circular(13) : Radius.zero,
                  bottomLeft: isFirst ? const Radius.circular(13) : Radius.zero,
                  topRight: isLast ? const Radius.circular(13) : Radius.zero,
                  bottomRight: isLast ? const Radius.circular(13) : Radius.zero,
                ),
        ),
        child: Text(
          label,
          style: AppFonts.textStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.black
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}

class _SpendingChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double maxAmount;
  final double minAmount;
  final double range;
  final Color color;
  final bool isDark;
  final int? selectedIndex;

  _SpendingChartPainter({
    required this.data,
    required this.maxAmount,
    required this.minAmount,
    required this.range,
    required this.color,
    required this.isDark,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Padding adjusted for compact design
    final chartPadding = EdgeInsets.only(
      left: 16,
      right: 16,
      top: 16,
      bottom: 40,
    );
    final chartArea = Rect.fromLTWH(
      chartPadding.left,
      chartPadding.top,
      size.width - chartPadding.left - chartPadding.right,
      size.height - chartPadding.top - chartPadding.bottom,
    );

    // Draw grid lines
    _drawGridLines(canvas, chartArea, isDark);

    // Calculate points for area chart
    // Add extra margin so first and last points aren't at the very edge
    final horizontalMargin = 8.0; // Space for data point circles
    final effectiveWidth = chartArea.width - (horizontalMargin * 2);
    final stepX = data.length > 1
        ? effectiveWidth / (data.length - 1)
        : effectiveWidth / 2;
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final amount = data[i]['amount'] as double;
      final normalizedHeight = range > 0
          ? ((amount - minAmount) / range) * chartArea.height
          : 0.0;

      final x = data.length > 1
          ? chartArea.left + horizontalMargin + (i * stepX)
          : chartArea.left + chartArea.width / 2;
      final y = chartArea.bottom - normalizedHeight;
      points.add(Offset(x, y));
    }

    // Draw area fill with gradient
    _drawAreaFill(canvas, points, chartArea);

    // Draw smooth line
    _drawSmoothLine(canvas, points);

    // Draw data point indicators
    _drawDataPoints(canvas, points);

    // Draw amount label if a point is selected
    if (selectedIndex != null && selectedIndex! < points.length) {
      _drawAmountLabel(
        canvas,
        points[selectedIndex!],
        data[selectedIndex!]['amount'] as double,
        isDark,
      );
    }

    // Draw X-axis labels (dates)
    _drawXAxisLabels(canvas, points, chartArea, isDark);
  }

  void _drawGridLines(Canvas canvas, Rect chartArea, bool isDark) {
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..strokeWidth = 1;

    // Draw horizontal grid lines (4 lines)
    for (int i = 0; i <= 4; i++) {
      final y = chartArea.top + (chartArea.height / 4) * i;
      canvas.drawLine(
        Offset(chartArea.left, y),
        Offset(chartArea.right, y),
        gridPaint,
      );
    }
  }

  void _drawAreaFill(Canvas canvas, List<Offset> points, Rect chartArea) {
    if (points.isEmpty) return;

    final fillPath = Path();
    fillPath.moveTo(points.first.dx, chartArea.bottom);
    fillPath.lineTo(points.first.dx, points.first.dy);

    // Create smooth curve through points using cubic bezier
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : points[i + 1];

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

      fillPath.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    fillPath.lineTo(points.last.dx, chartArea.bottom);
    fillPath.close();

    // Draw area with vibrant gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.4),
          color.withValues(alpha: 0.2),
          color.withValues(alpha: 0.05),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(chartArea)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  void _drawSmoothLine(Canvas canvas, List<Offset> points) {
    if (points.length < 2) return;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    // Create smooth curve through points using cubic bezier
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : points[i + 1];

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    canvas.drawPath(path, linePaint);
  }

  void _drawDataPoints(Canvas canvas, List<Offset> points) {
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final isSelected = selectedIndex == i;

      final outerPaint = Paint()
        ..color = isDark ? const Color(0xFF1E293B) : Colors.white
        ..style = PaintingStyle.fill;

      final pointPaint = Paint()
        ..color = isSelected ? color : color.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;

      // Draw outer circle (larger if selected)
      canvas.drawCircle(point, isSelected ? 9 : 7, outerPaint);
      // Draw inner colored circle (larger if selected)
      canvas.drawCircle(point, isSelected ? 7 : 5, pointPaint);
    }
  }

  void _drawAmountLabel(
    Canvas canvas,
    Offset point,
    double amount,
    bool isDark,
  ) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    );

    String label;
    if (amount >= 1000) {
      label = '\$${(amount / 1000).toStringAsFixed(1)}k';
    } else {
      label = '\$${amount.toStringAsFixed(0)}';
    }

    textPainter.text = TextSpan(
      text: label,
      style: TextStyle(
        fontSize: 12,
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    );
    textPainter.layout();

    // Draw background bubble
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(point.dx, point.dy - 25),
        width: textPainter.width + 16,
        height: textPainter.height + 8,
      ),
      const Radius.circular(12),
    );

    final bubblePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRRect(bubbleRect, bubblePaint);

    // Draw text
    textPainter.paint(
      canvas,
      Offset(
        point.dx - textPainter.width / 2,
        point.dy - 25 - textPainter.height / 2,
      ),
    );

    // Draw small triangle pointer
    final path = Path();
    path.moveTo(point.dx - 6, point.dy - 17);
    path.lineTo(point.dx + 6, point.dy - 17);
    path.lineTo(point.dx, point.dy - 11);
    path.close();

    canvas.drawPath(path, bubblePaint);
  }

  void _drawXAxisLabels(
    Canvas canvas,
    List<Offset> points,
    Rect chartArea,
    bool isDark,
  ) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    );

    for (int i = 0; i < data.length; i++) {
      final date = data[i]['date'] as DateTime;
      String formattedDate;

      // Format date based on data density
      if (data.length <= 7) {
        formattedDate = DateFormat('MMM d').format(date);
      } else if (data.length <= 12) {
        formattedDate = DateFormat('MMM d').format(date);
      } else {
        formattedDate = DateFormat('MMM').format(date);
      }

      textPainter.text = TextSpan(
        text: formattedDate,
        style: TextStyle(
          fontSize: 10,
          color: isDark
              ? Colors.white.withValues(alpha: 0.6)
              : Colors.grey[600],
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();

      final x = points[i].dx;
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chartArea.bottom + 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
