import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';
import '../theme/app_theme.dart';
import '../constants/app_spacing.dart';

/// A reusable dialog widget that provides consistent styling across the app
/// for dialogs like hints, confirmations, info messages, etc.
class AppDialog {
  /// Show an info/hint dialog with title and message
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    IconData? icon,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.8)
        : AppTheme.textSecondary;

    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: dialogBgColor,
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
            padding: EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: AppFonts.textStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppTheme.textSecondary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Message
                Text(
                  message,
                  style: AppFonts.textStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: subtitleColor,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 24),
                // Button - inline and small
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onButtonPressed ?? () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      buttonText ?? 'Got it',
                      style: AppFonts.textStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show a confirmation dialog
  static Future<bool> showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    IconData? icon,
    String? confirmText,
    String? cancelText,
    Color? confirmColor,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.8)
        : AppTheme.textSecondary;

    return await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.5),
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
                color: dialogBgColor,
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
                padding: EdgeInsets.all(AppSpacing.screenHorizontal),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with icon
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            color: confirmColor ?? AppTheme.primaryColor,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            style: AppFonts.textStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : AppTheme.textSecondary,
                          ),
                          onPressed: () => Navigator.of(context).pop(false),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Message
                    Text(
                      message,
                      style: AppFonts.textStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: subtitleColor,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 24),
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : AppTheme.borderColor,
                              ),
                            ),
                            child: Text(
                              cancelText ?? 'Cancel',
                              style: AppFonts.textStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: confirmColor ?? AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              confirmText ?? 'Confirm',
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
            ),
          ),
        ) ??
        false;
  }

  /// Show an error dialog
  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
  }) {
    return showInfo(
      context: context,
      title: title,
      message: message,
      icon: Icons.error_outline_rounded,
      buttonText: buttonText,
    );
  }

  /// Show a success dialog
  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
  }) {
    return showInfo(
      context: context,
      title: title,
      message: message,
      icon: Icons.check_circle_outline_rounded,
      buttonText: buttonText,
    );
  }
}

