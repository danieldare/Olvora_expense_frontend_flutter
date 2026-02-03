import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../domain/models/voice_expense_session.dart';

/// Beautiful field-by-field progress indicator
class FieldProgressIndicator extends StatelessWidget {
  final AccumulatedExpenseData data;
  final bool isDark;

  const FieldProgressIndicator({
    super.key,
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fields = [
      _FieldData(
        label: 'Amount',
        icon: Icons.attach_money_rounded,
        isComplete: data.amount.isPresent,
      ),
      _FieldData(
        label: 'Merchant',
        icon: Icons.store_rounded,
        isComplete: data.merchant.isPresent,
      ),
      _FieldData(
        label: 'Date',
        icon: Icons.calendar_today_rounded,
        isComplete: data.date.isPresent,
      ),
      _FieldData(
        label: 'Category',
        icon: Icons.category_rounded,
        isComplete: data.category.isPresent,
      ),
    ];

    final completedCount = fields.where((f) => f.isComplete).length;
    final totalCount = fields.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey[850]!.withOpacity(0.4)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress header - Compact
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Progress',
                    style: AppFonts.textStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$completedCount/$totalCount',
                  style: AppFonts.textStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          // Progress bar - Modern and compact
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: completedCount / totalCount,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              minHeight: 4,
            ),
          ),
          SizedBox(height: 10),
          // Field indicators - Compact
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: fields.map((field) {
              return Expanded(
                child: _buildFieldIndicator(field, isDark),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldIndicator(_FieldData field, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: field.isComplete
                ? AppTheme.primaryColor.withOpacity(0.12)
                : (isDark ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[200]!.withOpacity(0.6)),
            shape: BoxShape.circle,
            border: Border.all(
              color: field.isComplete
                  ? AppTheme.primaryColor.withOpacity(0.3)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Icon(
            field.icon,
            size: 16,
            color: field.isComplete
                ? AppTheme.primaryColor
                : (isDark ? Colors.grey[500] : Colors.grey[400]),
          ),
        ),
        SizedBox(height: 4),
        Text(
          field.label,
          style: AppFonts.textStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: field.isComplete
                ? AppTheme.primaryColor
                : (isDark ? Colors.grey[500] : Colors.grey[600]),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _FieldData {
  final String label;
  final IconData icon;
  final bool isComplete;

  _FieldData({
    required this.label,
    required this.icon,
    required this.isComplete,
  });
}
