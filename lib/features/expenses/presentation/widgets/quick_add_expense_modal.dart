import 'package:flutter/material.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_option_row.dart';
import '../../../../core/widgets/bottom_sheet_modal.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/expense_entity.dart';
import '../screens/add_expense_screen.dart';
import '../screens/add_recurring_expense_screen.dart';
import '../screens/add_future_expense_screen.dart';
import '../../../receipts/presentation/screens/scan_receipt_screen.dart';
import '../../../ora/presentation/screens/ora_chat_screen.dart';
import '../../../ora/presentation/widgets/ora_avatar_widget.dart';
import '../../../import/presentation/screens/import_file_screen.dart';
import '../../../voice/presentation/screens/voice_input_screen.dart';

/// Quick Add Expense Modal
///
/// Main bottom modal that provides quick access to expense entry methods.
/// Supports navigation between main menu and expense type selection within the same modal.
/// Uses the reusable [BottomSheetModal] for consistent styling and theme [modalBackground].
class QuickAddExpenseModal {
  /// Show the quick add expense modal
  static Future<void> show({
    required BuildContext context,
    String? tripId,
  }) {
    // Smaller modal for trip expenses (3 options vs 4+ for regular)
    final maxHeight = tripId != null ? 0.38 : 0.45;

    return BottomSheetModal.show<void>(
      context: context,
      title: null,
      showCloseButton: false,
      maxHeightFraction: maxHeight,
      isScrollable: false,
      child: _QuickAddExpenseModalContent(tripId: tripId),
    );
  }
}

class _QuickAddExpenseModalContent extends StatefulWidget {
  final String? tripId;

  const _QuickAddExpenseModalContent({this.tripId});

  @override
  State<_QuickAddExpenseModalContent> createState() =>
      _QuickAddExpenseModalContentState();
}

class _QuickAddExpenseModalContentState
    extends State<_QuickAddExpenseModalContent> {
  bool _showExpenseTypes = false;

  bool get _isForTrip => widget.tripId != null;

  void _navigateToExpenseTypes() {
    setState(() {
      _showExpenseTypes = true;
    });
  }

  void _navigateBack() {
    setState(() {
      _showExpenseTypes = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Simplified subtitle for trips
    final subtitle = _isForTrip
        ? 'Add an expense to this trip'
        : _showExpenseTypes
            ? 'Select the type of expense you want to add'
            : 'Choose how you want to add an expense';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Compact header
        Row(
          children: [
            if (_showExpenseTypes && !_isForTrip) AppBackButton(onPressed: _navigateBack),
            if (_showExpenseTypes && !_isForTrip) const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isForTrip ? 'Add Trip Expense' : 'Add Expense',
                    style: AppFonts.textStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppFonts.textStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 22,
                color: AppTheme.textSecondary,
              ),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Content
        Flexible(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isForTrip
                  ? _buildTripExpenseView(context, isDark)
                  : _showExpenseTypes
                      ? _buildExpenseTypesView(context, isDark, widget.tripId)
                      : _buildMainMenuView(context, isDark),
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
      ],
    );
  }

  /// Simplified view for trip expenses - one-off, scan receipt, and voice input
  Widget _buildTripExpenseView(BuildContext context, bool isDark) {
    return Column(
      key: const ValueKey('trip_expense'),
      mainAxisSize: MainAxisSize.min,
      children: [
        AppOptionRow(
          title: 'One-off Expense',
          subtitle: 'Manually enter expense details',
          icon: Icons.edit_rounded,
          color: AppTheme.primaryColor,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddExpenseScreen(
                  entryMode: EntryMode.manual,
                  tripId: widget.tripId,
                ),
              ),
            );
          },
          dense: true,
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.borderColor.withValues(alpha: 0.3),
        ),
        AppOptionRow(
          title: 'Scan Receipt',
          subtitle: 'Capture expense details from a receipt',
          icon: Icons.camera_alt_rounded,
          color: AppTheme.accentColor,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScanReceiptScreen(tripId: widget.tripId),
              ),
            );
          },
          dense: true,
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.borderColor.withValues(alpha: 0.3),
        ),
        AppOptionRow(
          title: 'Voice Input',
          subtitle: 'Speak to add an expense',
          icon: Icons.mic_rounded,
          color: AppTheme.warningColor,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VoiceInputScreen(tripId: widget.tripId),
              ),
            );
          },
          dense: true,
        ),
      ],
    );
  }

  Widget _buildMainMenuView(BuildContext context, bool isDark) {
    return Column(
      key: const ValueKey('main_menu'),
      mainAxisSize: MainAxisSize.min,
      children: [
        AppOptionRow(
          title: 'Add Expense',
          subtitle: 'Manually add one-time, recurring, or future expenses',
          icon: Icons.add_circle_outline_rounded,
          color: AppTheme.primaryColor,
          onTap: _navigateToExpenseTypes,
          dense: true,
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.borderColor.withValues(alpha: 0.3),
        ),
        AppOptionRow(
          title: 'Scan Receipt',
          subtitle: 'Capture and extract expense details from a receipt',
          icon: Icons.camera_alt_rounded,
          color: AppTheme.accentColor,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ScanReceiptScreen(),
              ),
            );
          },
          dense: true,
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.borderColor.withValues(alpha: 0.3),
        ),
        AppOptionRow(
          title: 'Ora AI',
          subtitle: 'Chat with Ora to add expenses naturally',
          icon: Icons.chat_rounded,
          color: AppTheme.warningColor,
          leading: const OraAvatarWidget(size: 32, fontSize: 16),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OraChatScreen(),
              ),
            );
          },
          dense: true,
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.borderColor.withValues(alpha: 0.3),
        ),
        AppOptionRow(
          title: 'Import from File',
          subtitle: 'Import expenses from CSV or Excel file',
          icon: Icons.upload_file_rounded,
          color: AppTheme.secondaryColor,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ImportFileScreen(),
              ),
            );
          },
          dense: true,
        ),
      ],
    );
  }

  Widget _buildExpenseTypesView(BuildContext context, bool isDark, String? tripId) {
    return Column(
      key: const ValueKey('expense_types'),
      mainAxisSize: MainAxisSize.min,
      children: [
        AppOptionRow(
          title: 'One-time Expense',
          subtitle: 'A transaction that already occurred',
          icon: Icons.receipt_long_rounded,
          color: AppTheme.primaryColor,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddExpenseScreen(
                  entryMode: EntryMode.manual,
                  tripId: tripId,
                ),
              ),
            );
          },
          dense: true,
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.borderColor.withValues(alpha: 0.3),
        ),
        AppOptionRow(
          title: 'Recurring Expense',
          subtitle: 'A repeating expense (subscription, rent, etc.)',
          icon: Icons.repeat_rounded,
          color: AppTheme.accentColor,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddRecurringExpenseScreen(),
              ),
            );
          },
          dense: true,
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.borderColor.withValues(alpha: 0.3),
        ),
        AppOptionRow(
          title: 'Future Expense',
          subtitle: 'A planned expense (not yet occurred)',
          icon: Icons.calendar_today_rounded,
          color: AppTheme.warningColor,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddFutureExpenseScreen(),
              ),
            );
          },
          dense: true,
        ),
      ],
    );
  }

}
