import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/models/currency.dart';
import '../../domain/entities/budget_alert_entity.dart';
import '../providers/budget_optimization_providers.dart';

class BudgetAlertCard extends ConsumerWidget {
  final BudgetAlertEntity alert;

  const BudgetAlertCard({
    super.key,
    required this.alert,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final currency = currencyAsync.value ?? Currency.defaultCurrency;

    Color getAlertColor() {
      switch (alert.alertType) {
        case AlertType.exceeded:
          return AppTheme.errorColor;
        case AlertType.critical:
          return AppTheme.errorColor;
        case AlertType.warning:
          return AppTheme.warningColor;
      }
    }

    IconData getAlertIcon() {
      switch (alert.alertType) {
        case AlertType.exceeded:
          return Icons.error_outline;
        case AlertType.critical:
          return Icons.warning_amber_rounded;
        case AlertType.warning:
          return Icons.info_outline;
      }
    }

    String getAlertTitle() {
      switch (alert.alertType) {
        case AlertType.exceeded:
          return 'Budget Exceeded';
        case AlertType.critical:
          return 'Critical Warning';
        case AlertType.warning:
          return 'Budget Warning';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: getAlertColor().withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: getAlertColor(), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  getAlertIcon(),
                  color: getAlertColor(),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    getAlertTitle(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: getAlertColor(),
                        ),
                  ),
                ),
                if (alert.budgetName != null)
                  Text(
                    alert.budgetName!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              alert.message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            // Projected overage
            if (alert.projectedOverage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: getAlertColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: getAlertColor(),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Projected overage: ${CurrencyFormatter.format(alert.projectedOverage!, currency)}',
                      style: TextStyle(
                        color: getAlertColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Safe daily spend
            if (alert.safeDailySpend != null && alert.safeDailySpend! > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.speed,
                      color: AppTheme.successColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Safe daily spend: ${CurrencyFormatter.format(alert.safeDailySpend!, currency)}',
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Suggested action
            if (alert.suggestedAction != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert.suggestedAction!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Dismiss button
            if (alert.canDismiss) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _dismissAlert(ref, context),
                  child: const Text('Dismiss'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _dismissAlert(WidgetRef ref, BuildContext context) async {
    try {
      await ref.read(dismissAlertProvider(alert.id).future);
      ref.invalidate(budgetAlertsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alert dismissed')),
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
