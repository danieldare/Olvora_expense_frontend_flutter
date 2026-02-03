import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../domain/entities/budget_health_entity.dart';

class HealthScoreBadge extends StatelessWidget {
  final HealthGrade grade;
  final double score;
  final bool showScore;

  const HealthScoreBadge({
    super.key,
    required this.grade,
    required this.score,
    this.showScore = false,
  });

  Color getGradeColor() {
    switch (grade) {
      case HealthGrade.a:
        return AppTheme.successColor;
      case HealthGrade.b:
        return const Color(0xFF22C55E);
      case HealthGrade.c:
        return AppTheme.warningColor;
      case HealthGrade.d:
        return const Color(0xFFF59E0B);
      case HealthGrade.f:
        return AppTheme.errorColor;
    }
  }

  String getGradeText() {
    return grade.name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = getGradeColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            getGradeText(),
            style: AppFonts.textStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          if (showScore) ...[
            const SizedBox(width: 6),
            Text(
              '${score.toInt()}%',
              style: AppFonts.textStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
