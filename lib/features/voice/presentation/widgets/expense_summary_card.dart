import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../domain/models/voice_expense_session.dart';

/// Beautiful expense summary card shown in confirmation state
class ExpenseSummaryCard extends StatelessWidget {
  final AccumulatedExpenseData data;
  final bool isDark;

  const ExpenseSummaryCard({
    super.key,
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.accentColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header - Compact
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: AppTheme.primaryColor,
                  size: 18,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Expense Summary',
                style: AppFonts.textStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          // Amount (highlighted)
          if (data.amount.value != null)
            _buildHighlightedAmount(data.amount.value!),
          SizedBox(height: 12),
          // Details grid
          _buildDetailsGrid(),
        ],
      ),
    );
  }

  Widget _buildHighlightedAmount(double amount) {
    final currency = data.currency.value ?? 'NGN';
    final symbol = currency == 'NGN' ? '₦' : '\$';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.15),
            AppTheme.accentColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            symbol,
            style: AppFonts.textStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(width: 4),
          Text(
            NumberFormat('#,###').format(amount),
            style: AppFonts.textStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryColor,
              letterSpacing: -0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid() {
    return Column(
      children: [
        if (data.merchant.value != null)
          _buildDetailRow(
            icon: Icons.store_rounded,
            label: 'Merchant',
            value: data.merchant.value!,
          ),
        if (data.date.value != null) ...[
          SizedBox(height: 10),
          _buildDetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: _formatDate(data.date.value!),
          ),
        ],
        if (data.category.value != null) ...[
          SizedBox(height: 10),
          _buildDetailRow(
            icon: Icons.category_rounded,
            label: 'Category',
            value: data.category.value!,
            isCategory: true,
          ),
        ],
        if (data.description.value != null && data.description.value!.isNotEmpty) ...[
          SizedBox(height: 10),
          _buildDetailRow(
            icon: Icons.description_rounded,
            label: 'Description',
            value: data.description.value!,
            isMultiline: true,
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isCategory = false,
    bool isMultiline = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            icon,
            size: 14,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppFonts.textStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary.withValues(alpha: 0.8),
                ),
              ),
              SizedBox(height: 2),
              if (isCategory)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    value,
                    style: AppFonts.textStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                )
              else
                Text(
                  value,
                  style: AppFonts.textStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                    height: isMultiline ? 1.4 : 1.2,
                  ),
                  maxLines: isMultiline ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
}
