import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bottom_sheet_modal.dart';

class DebitAlertExplanationModal {
  static const String _dontShowAgainKey = 'debit_alert_explanation_shown';

  /// Check if the explanation should be shown
  static Future<bool> shouldShow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(_dontShowAgainKey) ?? false);
    } catch (e) {
      return true; // Show by default if error
    }
  }

  /// Mark explanation as shown
  static Future<void> markAsShown({bool dontShowAgain = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dontShowAgainKey, dontShowAgain);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Show the explanation modal
  static Future<void> show(BuildContext context) async {
    final shouldShowModal = await shouldShow();

    if (!shouldShowModal) {
      return; // Don't show if user chose not to see it again
    }

    if (!context.mounted) return;

    await BottomSheetModal.show(
      context: context,
      title: 'How Debit Alert Detection Works',
      subtitle: 'Automatically track your expenses',
      child: _DebitAlertExplanationContent(),
    );
  }
}

class _DebitAlertExplanationContent extends StatefulWidget {
  const _DebitAlertExplanationContent();

  @override
  State<_DebitAlertExplanationContent> createState() =>
      _DebitAlertExplanationContentState();
}

class _DebitAlertExplanationContentState
    extends State<_DebitAlertExplanationContent> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.textPrimary;
    final subtitleColor = AppTheme.textSecondary;
    final borderColor = AppTheme.borderColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header icon (compact)
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: AppTheme.warningColor,
                size: 20,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Explanation content
        _buildFeatureItem(
          icon: Icons.content_copy_rounded,
          title: 'Copy-Paste Method',
          description:
              'Copy your SMS debit alert, then open Olvora. The app will automatically detect and extract expense details.',
          textColor: textColor,
          subtitleColor: subtitleColor,
        ),
        SizedBox(height: 12),
        _buildFeatureItem(
          icon: Icons.verified_rounded,
          title: 'Verification Modal',
          description:
              'Review and confirm detected expenses before saving. Edit amount, category, or merchant if needed.',
          textColor: textColor,
          subtitleColor: subtitleColor,
        ),
        SizedBox(height: 16),

        // Don't show again checkbox (compact)
        InkWell(
          onTap: () {
            setState(() {
              _dontShowAgain = !_dontShowAgain;
            });
          },
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _dontShowAgain
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  border: Border.all(
                    color: _dontShowAgain
                        ? AppTheme.primaryColor
                        : borderColor,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: _dontShowAgain
                    ? Icon(
                        Icons.check,
                        size: 14,
                        color: AppTheme.textPrimary,
                      )
                    : null,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Don't show this message again",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),

        // Got it button (compact)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              await DebitAlertExplanationModal.markAsShown(
                dontShowAgain: _dontShowAgain,
              );
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Got it',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 16,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: subtitleColor,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

