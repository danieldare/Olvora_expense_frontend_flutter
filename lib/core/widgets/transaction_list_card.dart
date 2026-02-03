import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/currency.dart';
import '../responsive/responsive_extensions.dart';
import '../../features/expenses/domain/entities/expense_entity.dart';
import 'transaction_item.dart';

/// Shared card component for transaction list and recent transactions.
/// Uses compact transaction list style (same decoration, spacing, and item layout).
class TransactionListCard extends ConsumerWidget {
  final List<ExpenseEntity> transactions;
  final Currency currency;
  final bool isDark;
  final bool showActions;
  final DateFormatStyle dateFormatStyle;

  const TransactionListCard({
    super.key,
    required this.transactions,
    required this.currency,
    required this.isDark,
    this.showActions = true,
    this.dateFormatStyle = DateFormatStyle.time,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardRadius = 14.scaled(context);
    final dividerIndent = 14.scaled(context);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : AppTheme.borderColor.withValues(alpha: 0.6);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: borderColor, width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppTheme.darkCardBackground,
                  AppTheme.darkCardBackground.withValues(alpha: 0.95),
                ]
              : [
                  Colors.white,
                  Color.lerp(Colors.white, AppTheme.borderColor, 0.04)!,
                ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: transactions.asMap().entries.map((entry) {
          final index = entry.key;
          final transaction = entry.value;
          final isLast = index == transactions.length - 1;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TransactionItem(
                transaction: transaction,
                currency: currency,
                isDark: isDark,
                dateFormatStyle: dateFormatStyle,
                showActions: showActions,
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.16)
                      : AppTheme.borderColor.withValues(alpha: 0.55),
                  indent: dividerIndent,
                  endIndent: dividerIndent,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
