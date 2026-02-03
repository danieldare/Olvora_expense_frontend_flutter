import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_fonts.dart';
import '../theme/app_theme.dart';
import '../constants/app_spacing.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

/// Confirmation modal shown when user shares a receipt/image with the app
class ReceiptShareConfirmationModal {
  /// Show the confirmation modal
  static Future<bool?> show({
    required BuildContext context,
    required String imagePath,
  }) {
    try {
      return showDialog<bool>(
        context: context,
        barrierDismissible: true,
        useRootNavigator: true, // Use root navigator to ensure it shows on top
        builder: (context) =>
            _ReceiptShareConfirmationDialog(imagePath: imagePath),
      );
    } catch (e) {
      debugPrint('❌ Error in ReceiptShareConfirmationModal.show: $e');
      return Future.value(false);
    }
  }
}

/// Dialog wrapper for the confirmation modal
class _ReceiptShareConfirmationDialog extends ConsumerWidget {
  final String imagePath;

  const _ReceiptShareConfirmationDialog({required this.imagePath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        padding: const EdgeInsets.all(AppSpacing.spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                color: AppTheme.primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.spacingLarge),

            // Title
            Text(
              'Process Receipt?',
              style: AppFonts.textStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spacingSmall),

            // Message
            Text(
              isAuthenticated
                  ? 'Do you want to scan this receipt and create an expense?'
                  : 'Please sign in to process receipts. Do you want to continue?',
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppTheme.textPrimary.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spacingLarge),

            // Buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.spacingMedium,
                      ),
                      side: BorderSide(color: AppTheme.borderColor, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMedium,
                        ),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppFonts.textStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.spacingMedium),

                // Proceed button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.spacingMedium,
                      ),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMedium,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Proceed',
                      style: AppFonts.textStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
