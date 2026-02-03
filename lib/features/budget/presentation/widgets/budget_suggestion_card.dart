import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/models/currency.dart';
import '../../domain/entities/budget_suggestion_entity.dart';
import '../providers/budget_optimization_providers.dart';
import '../providers/budget_providers.dart';

class BudgetSuggestionCard extends ConsumerWidget {
  final BudgetSuggestionEntity suggestion;

  const BudgetSuggestionCard({
    super.key,
    required this.suggestion,
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
                  color: (suggestion.isHighConfidence
                          ? AppTheme.successColor
                          : AppTheme.warningColor)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  suggestion.type == SuggestionType.newBudget
                      ? Icons.add_circle_outline_rounded
                      : Icons.tune_rounded,
                  size: 22,
                  color: suggestion.isHighConfidence
                      ? AppTheme.successColor
                      : AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  suggestion.type == SuggestionType.newBudget
                      ? 'New budget'
                      : 'Adjustment',
                  style: AppFonts.textStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
              if (suggestion.isHighConfidence)
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
          if (suggestion.categoryName != null) ...[
            const SizedBox(height: 10),
            Text(
              suggestion.categoryName!,
              style: AppFonts.textStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppTheme.textSecondary,
              ),
            ),
          ],
          if (suggestion.suggestedAmount != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Suggested ',
                  style: AppFonts.textStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : AppTheme.textSecondary,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(
                    suggestion.suggestedAmount!,
                    currency,
                  ),
                  style: AppFonts.textStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
          if (suggestion.currentAmount != null) ...[
            const SizedBox(height: 4),
            Text(
              'Current ${CurrencyFormatter.format(suggestion.currentAmount!, currency)}',
              style: AppFonts.textStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : AppTheme.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppTheme.borderColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              suggestion.reasonText,
              style: AppFonts.textStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _dismissSuggestion(ref, context),
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
                onPressed: suggestion.canApply
                    ? () => _applySuggestion(ref, context)
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

  Future<void> _applySuggestion(WidgetRef ref, BuildContext context) async {
    try {
      final budgetType = suggestion.budgetType;
      await ref.read(
        applySuggestionProvider(
          {
            'id': suggestion.id,
            if (budgetType != null) 'budgetType': budgetType,
          },
        ).future,
      );

      // Refresh budgets
      ref.invalidate(generalBudgetsProvider);
      ref.invalidate(categoryBudgetsProvider);
      ref.invalidate(budgetSuggestionsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suggestion applied successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply suggestion: $e')),
        );
      }
    }
  }

  Future<void> _dismissSuggestion(WidgetRef ref, BuildContext context) async {
    try {
      await ref.read(dismissSuggestionProvider(suggestion.id).future);
      ref.invalidate(budgetSuggestionsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suggestion dismissed')),
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
