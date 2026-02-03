import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/trip_entity.dart';
import '../providers/trip_providers.dart';
import '../../../expenses/domain/entities/expense_entity.dart';

/// Expense Split Modal
///
/// Allows users to view and manage expense splits for shared trips
class ExpenseSplitModal extends ConsumerStatefulWidget {
  final String tripId;
  final ExpenseEntity expense;
  final TripEntity trip;

  const ExpenseSplitModal({
    super.key,
    required this.tripId,
    required this.expense,
    required this.trip,
  });

  @override
  ConsumerState<ExpenseSplitModal> createState() => _ExpenseSplitModalState();
}

class _ExpenseSplitModalState extends ConsumerState<ExpenseSplitModal> {
  ExpenseSplitEntity? _split;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadSplit();
  }

  Future<void> _loadSplit() async {
    setState(() => _isLoading = true);

    try {
      final tripService = ref.read(tripServiceProvider);
      final split = await tripService.getExpenseSplit(
        tripId: widget.tripId,
        expenseId: widget.expense.id,
      );

      setState(() {
        _split = split;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load split: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _createEqualSplit() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final tripService = ref.read(tripServiceProvider);
      await tripService.createExpenseSplit(
        tripId: widget.tripId,
        expenseId: widget.expense.id,
        splitType: SplitType.equal,
      );

      await _loadSplit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Expense split created successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create split: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _deleteSplit() async {
    if (_isSubmitting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Split?'),
        content: const Text('Are you sure you want to delete this expense split?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final tripService = ref.read(tripServiceProvider);
      await tripService.deleteExpenseSplit(
        tripId: widget.tripId,
        expenseId: widget.expense.id,
      );

      setState(() => _split = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Expense split deleted'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete split: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.expense.title,
                      style: AppFonts.textStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Total: ${widget.expense.amount.toStringAsFixed(2)}',
                      style: AppFonts.textStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_split != null)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.errorColor,
                  ),
                  onPressed: _isSubmitting ? null : _deleteSplit,
                ),
            ],
          ),
          SizedBox(height: 24),

          // Content
          if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.screenHorizontal),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
            )
          else if (_split == null)
            _buildNoSplitView(isDark)
          else
            _buildSplitView(_split!, isDark),
        ],
      ),
    );
  }

  Widget _buildNoSplitView(bool isDark) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.screenHorizontal),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardBackground : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppTheme.borderColor,
            ),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 48,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : AppTheme.textSecondary.withValues(alpha: 0.5),
                ),
                SizedBox(height: 12),
                Text(
                  'No split configured',
                  style: AppFonts.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Split this expense equally among all participants',
                  style: AppFonts.textStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
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
        SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _createEqualSplit,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Split Equally',
                    style: AppFonts.textStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSplitView(ExpenseSplitEntity split, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Split type badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _getSplitTypeLabel(split.splitType),
            style: AppFonts.textStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        SizedBox(height: 16),

        // Split items list
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardBackground : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppTheme.borderColor,
            ),
          ),
          child: Column(
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: split.items.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppTheme.borderColor,
                ),
                itemBuilder: (context, index) {
                  final item = split.items[index];
                  return Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                          child: Text(
                            item.userName[0].toUpperCase(),
                            style: AppFonts.textStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.userName,
                                style: AppFonts.textStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppTheme.textPrimary,
                                ),
                              ),
                              if (item.percentage != null)
                                Text(
                                  '${item.percentage!.toStringAsFixed(1)}%',
                                  style: AppFonts.textStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.6)
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          item.amount.toStringAsFixed(2),
                          style: AppFonts.textStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Total
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppTheme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: AppFonts.textStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      split.totalAmount.toStringAsFixed(2),
                      style: AppFonts.textStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getSplitTypeLabel(SplitType type) {
    switch (type) {
      case SplitType.equal:
        return 'Equal Split';
      case SplitType.exact:
        return 'Exact Amounts';
      case SplitType.percentage:
        return 'Percentage Split';
    }
  }
}
