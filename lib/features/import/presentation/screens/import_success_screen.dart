import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/import_result.dart';
import '../providers/import_providers.dart';
import '../../../expenses/presentation/providers/expenses_providers.dart';

/// Success screen shown after successful import
class ImportSuccessScreen extends ConsumerWidget {
  final ImportResult result;

  const ImportSuccessScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppTheme.screenBackgroundColor;
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 60,
                  color: AppTheme.successColor,
                ),
              ),
              SizedBox(height: 32),

              // Title
              Text(
                'Import Complete!',
                style: AppFonts.textStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),

              // Summary
              Text(
                '${result.successfulExpenses} expenses added to your account',
                style: AppFonts.textStyle(
                  fontSize: 16,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                currencyFormat.format(result.totalAmount),
                style: AppFonts.textStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48),

              // Actions
              AppButton(
                label: 'View Expenses',
                onPressed: () {
                  // Invalidate expenses provider to refresh
                  ref.invalidate(expensesProvider);
                  // Navigate back to home/expenses
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                variant: AppButtonVariant.primary,
                isFullWidth: true,
                icon: Icons.receipt_long_rounded,
              ),
              SizedBox(height: 12),

              if (result.canUndo)
                TextButton(
                  onPressed: () => _showUndoDialog(context, ref),
                  child: Text(
                    'Undo Import',
                    style: AppFonts.textStyle(
                      fontSize: 16,
                      color: AppTheme.errorColor,
                    ),
                  ),
                ),

              SizedBox(height: 16),
              Text(
                'You can undo this import within 24 hours from Settings → Import History',
                style: AppFonts.textStyle(
                  fontSize: 12,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : AppTheme.textSecondary.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUndoDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCardBackground : Colors.white,
        title: Text(
          'Undo Import?',
          style: AppFonts.textStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'This will remove all ${result.successfulExpenses} expenses from this import. This action cannot be undone.',
          style: AppFonts.textStyle(
            fontSize: 16,
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppFonts.textStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _undoImport(context, ref);
            },
            child: Text(
              'Undo',
              style: AppFonts.textStyle(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _undoImport(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(importRepositoryProvider);
      await repository.undoImport(result.importId);

      // Invalidate expenses to refresh
      ref.invalidate(expensesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import undone successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to undo import: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
