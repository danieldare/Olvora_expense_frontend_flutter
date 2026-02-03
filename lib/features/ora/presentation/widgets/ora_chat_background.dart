import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Subtle patterned background for Ora chat (cross/plus pattern).
/// Gives a soft, wallpaper-like texture without distracting from messages.
class OraChatBackground extends StatelessWidget {
  final Widget child;

  const OraChatBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = AppTheme.screenBackgroundColor;
    final patternColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : AppTheme.textSecondary.withValues(alpha: 0.08);

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: baseColor),
        CustomPaint(
          painter: _ChatPatternPainter(
            color: patternColor,
            spacing: 36,
            crossSize: 3,
            strokeWidth: 0.8,
          ),
        ),
        child,
      ],
    );
  }
}

class _ChatPatternPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double crossSize;
  final double strokeWidth;

  _ChatPatternPainter({
    required this.color,
    this.spacing = 36,
    this.crossSize = 3,
    this.strokeWidth = 0.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    var x = spacing / 2;
    while (x < size.width) {
      var y = spacing / 2;
      while (y < size.height) {
        final center = Offset(x, y);
        // Horizontal line of cross
        canvas.drawLine(
          center - Offset(crossSize, 0),
          center + Offset(crossSize, 0),
          paint,
        );
        // Vertical line of cross
        canvas.drawLine(
          center - Offset(0, crossSize),
          center + Offset(0, crossSize),
          paint,
        );
        y += spacing;
      }
      x += spacing;
    }
  }

  @override
  bool shouldRepaint(covariant _ChatPatternPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.spacing != spacing ||
        oldDelegate.crossSize != crossSize ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
