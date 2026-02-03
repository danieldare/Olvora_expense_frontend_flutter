import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_fonts.dart';
import '../theme/app_theme.dart';

/// Reusable option row for bottom sheets and modals (export, share, add expense, etc.).
/// Leading: 40×40 icon container or custom [leading] widget.
/// Trailing: arrow by default, or custom [trailing] (e.g. selection indicator).
class AppOptionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  /// Custom leading widget (e.g. avatar). If null, uses [icon] in a 40×40 colored container.
  final Widget? leading;

  /// Custom trailing widget (e.g. radio/check). If null, shows arrow.
  final Widget? trailing;

  /// When true, uses smaller padding, icon, and fonts for a compact layout.
  final bool dense;

  const AppOptionRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.leading,
    this.trailing,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppTheme.textSecondary;
    final arrowColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : AppTheme.textSecondary.withValues(alpha: 0.5);

    final verticalPadding = dense ? 10.0 : 16.0;
    final iconSize = dense ? 32.0 : 40.0;
    final iconInnerSize = dense ? 18.0 : 20.0;
    final iconRadius = dense ? 8.0 : 10.0;
    final gapAfterIcon = dense ? 12.0 : 16.0;
    final titleFontSize = dense ? 15.0 : 16.0;
    final subtitleFontSize = dense ? 12.0 : 13.0;
    final titleSubtitleGap = dense ? 2.0 : 4.0;
    final arrowSize = dense ? 14.0 : 16.0;

    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: verticalPadding),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            leading ??
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(iconRadius),
                  ),
                  child: Icon(icon, color: color, size: iconInnerSize),
                ),
            SizedBox(width: gapAfterIcon),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.textStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  SizedBox(height: titleSubtitleGap),
                  Text(
                    subtitle,
                    style: AppFonts.textStyle(
                      fontSize: subtitleFontSize,
                      fontWeight: FontWeight.w400,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: arrowSize,
                  color: arrowColor,
                ),
          ],
        ),
      ),
    );
  }
}
