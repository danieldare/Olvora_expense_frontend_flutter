import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';
import '../theme/app_theme.dart';
import '../responsive/responsive_extensions.dart';

class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : AppTheme.textSecondary;

    return Padding(
      padding: padding ?? EdgeInsets.fromLTRB(
        20.scaled(context),
        24.scaledVertical(context),
        20.scaled(context),
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.textStyle(
                    fontSize: 28.scaledText(context),
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    letterSpacing: -0.5,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 6.scaled(context)),
                  Text(
                    subtitle!,
                    style: AppFonts.textStyle(
                      fontSize: 14.scaledText(context),
                      fontWeight: FontWeight.w400,
                      color: subtitleColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[SizedBox(width: 16.scaled(context)), trailing!],
        ],
      ),
    );
  }
}
