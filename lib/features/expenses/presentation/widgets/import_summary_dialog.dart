import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/currency.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/providers/currency_providers.dart';
import '../providers/import_providers.dart';

/// Dialog to show import summary after completion
class ImportSummaryDialog extends ConsumerWidget {
  final BatchImportResult result;

  const ImportSummaryDialog({
    super.key,
    required this.result,
  });

  static Future<void> show(
    BuildContext context,
    BatchImportResult result,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ImportSummaryDialog(result: result),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final currency = currencyAsync.valueOrNull ?? Currency.defaultCurrency;

    final hasErrors = result.errors.isNotEmpty;
    final isSuccess = result.successfulExpenses > 0;

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
                      color: (isSuccess
                              ? AppTheme.successColor
                              : hasErrors
                                  ? AppTheme.warningColor
                                  : AppTheme.errorColor)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isSuccess
                          ? Icons.check_circle_rounded
                          : hasErrors
                              ? Icons.warning_amber_rounded
                              : Icons.error_rounded,
                      color: isSuccess
                          ? AppTheme.successColor
                          : hasErrors
                              ? AppTheme.warningColor
                              : AppTheme.errorColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSuccess ? 'Import Completed' : 'Import Finished',
                          style: AppFonts.textStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.fileName,
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
              const SizedBox(height: 24),
              // Summary stats
              _buildStatRow(
                context,
                'Total Expenses',
                '${result.totalExpenses}',
                Icons.receipt_long_rounded,
                isDark,
              ),
              const SizedBox(height: 12),
              _buildStatRow(
                context,
                'Successfully Imported',
                '${result.successfulExpenses}',
                Icons.check_circle_outline_rounded,
                isDark,
                color: AppTheme.successColor,
              ),
              if (result.failedExpenses > 0) ...[
                const SizedBox(height: 12),
                _buildStatRow(
                  context,
                  'Failed',
                  '${result.failedExpenses}',
                  Icons.error_outline_rounded,
                  isDark,
                  color: AppTheme.errorColor,
                ),
              ],
              const SizedBox(height: 12),
              _buildStatRow(
                context,
                'Total Amount',
                CurrencyFormatter.format(result.totalAmount, currency),
                Icons.attach_money_rounded,
                isDark,
                color: AppTheme.primaryColor,
              ),
              // Errors list
              if (hasErrors && result.errors.length <= 5) ...[
                const SizedBox(height: 20),
                Divider(color: isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.borderColor),
                const SizedBox(height: 12),
                Text(
                  'Errors:',
                  style: AppFonts.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: result.errors.length,
                    itemBuilder: (context, index) {
                      final error = result.errors[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 6,
                              color: AppTheme.errorColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (error.expenseTitle != null)
                                    Text(
                                      error.expenseTitle!,
                                      style: AppFonts.textStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white.withValues(alpha: 0.9) : AppTheme.textPrimary,
                                      ),
                                    ),
                                  Text(
                                    'Row ${error.rowIndex + 1}: ${error.errorMessage}',
                                    style: AppFonts.textStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white.withValues(alpha: 0.7) : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
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
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Done',
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

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    bool isDark, {
    Color? color,
  }) {
    final displayColor = color ?? (isDark ? Colors.white.withValues(alpha: 0.8) : AppTheme.textSecondary);

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: displayColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppFonts.textStyle(
              fontSize: 14,
              color: isDark ? Colors.white.withValues(alpha: 0.8) : AppTheme.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppFonts.textStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: displayColor,
          ),
        ),
      ],
    );
  }
}
