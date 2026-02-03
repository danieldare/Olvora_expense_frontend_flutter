import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/models/currency.dart';
import '../../domain/entities/reallocation_suggestion_entity.dart';
import '../providers/budget_optimization_providers.dart';
import '../providers/budget_providers.dart';

class ReallocationCard extends ConsumerWidget {
  final ReallocationSuggestionEntity reallocation;

  const ReallocationCard({
    super.key,
    required this.reallocation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final currency = currencyAsync.value ?? Currency.defaultCurrency;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppTheme.textPrimary.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  size: 22,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Reallocation',
                  style: AppFonts.textStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
              if (reallocation.confidence >= 0.7)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'High confidence',
                    style: AppFonts.textStyle(
                      color: AppTheme.successColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

            // From Budget
            _buildBudgetInfo(
              context,
              'From',
              reallocation.fromBudget,
              currency,
              Icons.arrow_downward,
              AppTheme.successColor,
            ),
            const SizedBox(height: 12),

            // Arrow
            Center(
              child: Icon(
                Icons.arrow_downward,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),

            // To Budget
            _buildBudgetInfo(
              context,
              'To',
              reallocation.toBudget,
              currency,
              Icons.arrow_upward,
              AppTheme.warningColor,
            ),

            // Transfer Amount
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Transfer: ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    CurrencyFormatter.format(reallocation.suggestedAmount, currency),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                  ),
                ],
              ),
            ),

            // Reasoning
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkCardBackground
                    : AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                reallocation.reasoning,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _dismissReallocation(ref, context),
                  child: Text(
                    'Dismiss',
                    style: AppFonts.textStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: reallocation.canApply && !reallocation.isExpired
                      ? () => _applyReallocation(ref, context)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      );
  }

  Widget _buildBudgetInfo(
    BuildContext context,
    String label,
    BudgetInfo budget,
    Currency currency,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppFonts.textStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            budget.name,
            style: AppFonts.textStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Budget ${CurrencyFormatter.format(budget.amount, currency)}',
            style: AppFonts.textStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : AppTheme.textSecondary,
            ),
          ),
          Text(
            'Spent ${CurrencyFormatter.format(budget.spent, currency)}',
            style: AppFonts.textStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : AppTheme.textSecondary,
            ),
          ),
          if (label == 'From' && budget.projectedUnused > 0)
            Text(
              'Unused ${CurrencyFormatter.format(budget.projectedUnused, currency)}',
              style: AppFonts.textStyle(
                fontSize: 13,
                color: AppTheme.successColor,
              ),
            ),
          if (label == 'To' && budget.projectedOverage > 0)
            Text(
              'Overage ${CurrencyFormatter.format(budget.projectedOverage, currency)}',
              style: AppFonts.textStyle(
                fontSize: 13,
                color: AppTheme.errorColor,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _applyReallocation(WidgetRef ref, BuildContext context) async {
    try {
      await ref.read(applyReallocationProvider(reallocation.id).future);

      // Refresh budgets
      ref.invalidate(generalBudgetsProvider);
      ref.invalidate(categoryBudgetsProvider);
      ref.invalidate(reallocationSuggestionsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reallocation applied successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply reallocation: $e')),
        );
      }
    }
  }

  Future<void> _dismissReallocation(WidgetRef ref, BuildContext context) async {
    try {
      await ref.read(dismissReallocationProvider(reallocation.id).future);
      ref.invalidate(reallocationSuggestionsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reallocation dismissed')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to dismiss: $e')),
        );
      }
    }
  }
}
