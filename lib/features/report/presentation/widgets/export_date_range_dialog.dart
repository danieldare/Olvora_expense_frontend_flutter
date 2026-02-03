import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_option_row.dart';
import '../providers/report_providers.dart';

/// Dialog for selecting date range for export
class ExportDateRangeDialog extends ConsumerStatefulWidget {
  final ReportDateRangeParams? currentPeriod;
  final Function(DateTime startDate, DateTime endDate) onConfirm;
  /// Called when Back is tapped; e.g. pop sheet and show export options again
  final VoidCallback? onBack;

  const ExportDateRangeDialog({
    super.key,
    this.currentPeriod,
    required this.onConfirm,
    this.onBack,
  });

  @override
  ConsumerState<ExportDateRangeDialog> createState() => _ExportDateRangeDialogState();
}

class _ExportDateRangeDialogState extends ConsumerState<ExportDateRangeDialog> {
  ExportDateRangeOption _selectedOption = ExportDateRangeOption.currentPeriod;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _customStartDate = DateTime.now().subtract(const Duration(days: 30));
    _customEndDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Option: Current Period
        AppOptionRow(
          title: 'Current Period',
          subtitle: _getCurrentPeriodLabel(),
          icon: Icons.calendar_today_rounded,
          color: AppTheme.primaryColor,
          onTap: () => setState(() => _selectedOption = ExportDateRangeOption.currentPeriod),
          trailing: _buildSelectionTrailing(_selectedOption == ExportDateRangeOption.currentPeriod),
          dense: true,
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.borderColor.withValues(alpha: 0.3),
        ),
        // Option: Custom Range
        AppOptionRow(
          title: 'Custom Range',
          subtitle: _getCustomRangeLabel(),
          icon: Icons.date_range_rounded,
          color: AppTheme.primaryColor,
          onTap: () => setState(() => _selectedOption = ExportDateRangeOption.customRange),
          trailing: _buildSelectionTrailing(_selectedOption == ExportDateRangeOption.customRange),
          dense: true,
        ),
        // Custom date pickers (shown when custom range is selected)
        if (_selectedOption == ExportDateRangeOption.customRange) ...[
          const SizedBox(height: 12),
          _buildDatePicker(
            context,
            isDark,
            'Start Date',
            _customStartDate!,
            (date) => setState(() => _customStartDate = date),
          ),
          const SizedBox(height: 12),
          _buildDatePicker(
            context,
            isDark,
            'End Date',
            _customEndDate!,
            (date) => setState(() => _customEndDate = date),
          ),
          const SizedBox(height: 12),
        ],
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.borderColor.withValues(alpha: 0.3),
        ),
        // Option: All Time
        AppOptionRow(
          title: 'All Time',
          subtitle: 'Export all expenses',
          icon: Icons.all_inclusive_rounded,
          color: AppTheme.primaryColor,
          onTap: () => setState(() => _selectedOption = ExportDateRangeOption.allTime),
          trailing: _buildSelectionTrailing(_selectedOption == ExportDateRangeOption.allTime),
          dense: true,
        ),
        SizedBox(height: AppSpacing.sectionMedium),
        // Action buttons: Back + Export (like add expense screen)
        Row(
          children: [
            IconButton(
              onPressed: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else {
                  Navigator.pop(context);
                }
              },
              icon: Icon(
                Icons.chevron_left,
                color: isDark ? Colors.white : AppTheme.textPrimary,
                size: 20,
              ),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppTheme.borderColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _handleConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Export',
                  style: AppFonts.textStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 24 + MediaQuery.of(context).viewPadding.bottom,
        ),
      ],
    );
  }

  Widget _buildSelectionTrailing(bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppTheme.primaryColor;
    final borderColor = isSelected
        ? color
        : (isDark
            ? Colors.white.withValues(alpha: 0.6)
            : AppTheme.textSecondary);
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        color: isSelected ? color : Colors.transparent,
      ),
      child: isSelected
          ? Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }

  Widget _buildDatePicker(
    BuildContext context,
    bool isDark,
    String label,
    DateTime selectedDate,
    Function(DateTime) onDateSelected,
  ) {
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppTheme.textSecondary;

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppTheme.primaryColor,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.textStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(selectedDate),
                  style: AppFonts.textStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.calendar_today_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentPeriodLabel() {
    if (widget.currentPeriod == null) {
      return 'Use current report period';
    }
    final period = widget.currentPeriod!.period;
    final offset = widget.currentPeriod!.periodOffset;
    
    String periodLabel;
    switch (period) {
      case ReportPeriod.week:
        periodLabel = 'Week';
        break;
      case ReportPeriod.month:
        periodLabel = 'Month';
        break;
      case ReportPeriod.quarter:
        periodLabel = 'Quarter';
        break;
      case ReportPeriod.year:
        periodLabel = 'Year';
        break;
      case ReportPeriod.allTime:
        periodLabel = 'All Time';
        break;
    }
    
    if (offset != 0) {
      final direction = offset > 0 ? 'next' : 'previous';
      final count = offset.abs();
      return '$count ${count == 1 ? periodLabel.toLowerCase() : '${periodLabel.toLowerCase()}s'} $direction';
    }
    
    return 'Current $periodLabel';
  }

  String _getCustomRangeLabel() {
    if (_customStartDate == null || _customEndDate == null) {
      return 'Select start and end dates';
    }
    return '${_formatDate(_customStartDate!)} to ${_formatDate(_customEndDate!)}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _handleConfirm() {
    DateTime startDate;
    DateTime endDate;

    switch (_selectedOption) {
      case ExportDateRangeOption.currentPeriod:
        if (widget.currentPeriod != null) {
          // Use the reportDateRangeProvider to get the exact dates
          final dateRange = ref.read(reportDateRangeProvider(widget.currentPeriod!));
          if (dateRange != null) {
            startDate = dateRange['start']!;
            endDate = dateRange['end']!;
          } else {
            // All time fallback
            startDate = DateTime(2000, 1, 1);
            endDate = DateTime.now();
          }
        } else {
          // Fallback to last 30 days
          endDate = DateTime.now();
          startDate = endDate.subtract(const Duration(days: 30));
        }
        break;
      case ExportDateRangeOption.customRange:
        startDate = _customStartDate!;
        endDate = _customEndDate!;
        break;
      case ExportDateRangeOption.allTime:
        startDate = DateTime(2000, 1, 1);
        endDate = DateTime.now();
        break;
    }

    widget.onConfirm(startDate, endDate);
    Navigator.pop(context);
  }
}

enum ExportDateRangeOption {
  currentPeriod,
  customRange,
  allTime,
}
