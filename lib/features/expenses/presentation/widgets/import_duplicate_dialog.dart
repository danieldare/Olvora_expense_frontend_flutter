import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/import_service.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/currency.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/providers/currency_providers.dart';

/// Dialog to handle duplicate expenses during import
class ImportDuplicateDialog {
  static Future<DuplicateAction?> show(
    BuildContext context,
    List<ImportExpense> duplicates,
  ) {
    return showDialog<DuplicateAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DuplicateDialogContent(duplicates: duplicates),
    );
  }
}

enum DuplicateAction {
  skip,
  import,
}

class _DuplicateDialogContent extends ConsumerStatefulWidget {
  final List<ImportExpense> duplicates;

  const _DuplicateDialogContent({required this.duplicates});

  @override
  ConsumerState<_DuplicateDialogContent> createState() => _DuplicateDialogContentState();
}

class _DuplicateDialogContentState extends ConsumerState<_DuplicateDialogContent> {
  DuplicateAction _selectedAction = DuplicateAction.skip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final currency = currencyAsync.valueOrNull ?? Currency.defaultCurrency;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.warningColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Duplicate Expenses Found',
                          style: AppFonts.textStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.duplicates.length} expense(s) appear to already exist',
                          style: AppFonts.textStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white.withValues(alpha: 0.7) : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'What would you like to do?',
                style: AppFonts.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildOption(
                context,
                DuplicateAction.skip,
                'Skip duplicates',
                'Only import expenses that don\'t already exist',
                Icons.skip_next_rounded,
                isDark,
              ),
              const SizedBox(height: 12),
              _buildOption(
                context,
                DuplicateAction.import,
                'Import all',
                'Import all expenses, including duplicates',
                Icons.add_circle_outline_rounded,
                isDark,
              ),
              const SizedBox(height: 24),
              // Preview of duplicates
              if (widget.duplicates.length <= 5) ...[
                Text(
                  'Preview:',
                  style: AppFonts.textStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white.withValues(alpha: 0.7) : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.duplicates.length,
                    itemBuilder: (context, index) {
                      final expense = widget.duplicates[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 6,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                expense.title,
                                style: AppFonts.textStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white.withValues(alpha: 0.8) : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(expense.amount, currency),
                              style: AppFonts.textStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white.withValues(alpha: 0.8) : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, _selectedAction),
                    child: Text(
                      'Continue',
                      style: AppFonts.textStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    DuplicateAction action,
    String title,
    String subtitle,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _selectedAction == action;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedAction = action;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withValues(alpha: 0.2)
                    : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.textStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppFonts.textStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white.withValues(alpha: 0.7) : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Radio<DuplicateAction>(
              value: action,
              groupValue: _selectedAction,
              onChanged: (value) {
                setState(() {
                  _selectedAction = value!;
                });
              },
              activeColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
