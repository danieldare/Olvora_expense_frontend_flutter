import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extensions.dart';
import '../responsive/responsive_extensions.dart';

/// Reusable action card used across the app:
/// - Home: Add Expense, Scan Receipt, Ora AI
/// - More: App tools (Settings, Export, Import, Help, etc.)
class ActionCard extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? iconColor;
  final List<Color>? gradient;

  const ActionCard({
    super.key,
    this.icon,
    this.iconWidget,
    required this.label,
    required this.onTap,
    this.color,
    this.iconColor,
    this.gradient,
  }) : assert(
         icon != null || iconWidget != null,
         'Either icon or iconWidget must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final baseCard = isDark ? AppTheme.darkCardBackground : Colors.white;
    final bgColor = baseCard;
    final textColor = context.textPrimary;
    final actionColor = color ?? context.primaryColor;
    final iconColorValue = iconColor ?? actionColor;

    final iconBgAlpha = isDark ? 0.4 : 0.25;

    const cardHeight = 75.0;
    const verticalPadding = 10.0;
    const horizontalPadding = 10.0;
    const iconSize = 26.0;
    const iconInnerSize = 14.0;
    const labelFontSize = 12.0;
    const gapAfterIcon = 4.0;
    const radius = 14.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius.scaled(context)),
        child: Container(
          height: cardHeight.scaledVertical(context),
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding.scaledVertical(context),
            horizontal: horizontalPadding.scaled(context),
          ),
          decoration: BoxDecoration(
            gradient: gradient != null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient!,
                  )
                : null,
            color: gradient == null ? bgColor : null,
            borderRadius: BorderRadius.circular(radius.scaled(context)),
            border: gradient == null && isDark
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: (gradient?.first ?? Colors.black).withValues(
                  alpha: isDark
                      ? AppShadows.cardAlphaDark
                      : AppShadows.cardAlphaLight,
                ),
                blurRadius: AppShadows.cardBlur.scaled(context),
                offset: Offset(0, AppShadows.cardOffsetY.scaled(context)),
                spreadRadius: AppShadows.cardSpread,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (iconWidget != null)
                Center(child: iconWidget!)
              else
                Center(
                  child: Container(
                    width: iconSize.scaledMin(context, iconSize + 6),
                    height: iconSize.scaledMin(context, iconSize + 6),
                    decoration: BoxDecoration(
                      color: gradient != null
                          ? Colors.white.withValues(alpha: 0.2)
                          : iconColorValue.withValues(alpha: iconBgAlpha),
                      borderRadius: BorderRadius.circular(8.scaled(context)),
                      boxShadow: gradient == null
                          ? [
                              BoxShadow(
                                color: iconColorValue.withValues(
                                  alpha: isDark ? 0.2 : 0.15,
                                ),
                                blurRadius: 4.scaled(context),
                                offset: Offset(0, 2.scaled(context)),
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      color: gradient != null ? Colors.white : iconColorValue,
                      size: iconInnerSize.scaled(context),
                    ),
                  ),
                ),
              SizedBox(height: gapAfterIcon.scaled(context)),
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      label,
                      style: AppFonts.textStyle(
                        fontSize: labelFontSize.scaledText(context),
                        fontWeight: FontWeight.w500,
                        color: gradient != null ? Colors.white : textColor,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Larger action card variant (e.g. More screen Quick Access: Transaction History, Trips, etc.)
class ActionFeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final List<Color>? gradient;

  const ActionFeatureCard({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bgColor = isDark ? AppTheme.darkCardBackground : Colors.white;
    final textColor = context.textPrimary;

    const cardHeight = 100.0;
    const padding = 12.0;
    const iconSize = 28.0;
    const iconInnerSize = 14.0;
    const gapAfterIcon = 8.0;
    const titleFontSize = 14.0;
    const subtitleFontSize = 11.0;
    const titleSubtitleGap = 2.0;
    const radius = 14.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius.scaled(context)),
        child: Container(
          height: cardHeight.scaledVertical(context),
          padding: EdgeInsets.all(padding.scaled(context)),
          decoration: BoxDecoration(
            gradient: gradient != null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient!,
                  )
                : null,
            color: gradient == null ? bgColor : null,
            borderRadius: BorderRadius.circular(radius.scaled(context)),
            border: gradient == null
                ? Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.01)
                        : AppTheme.borderColor,
                    width: 1,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: (gradient?.first ?? Colors.black).withValues(
                  alpha: isDark
                      ? AppShadows.cardAlphaDarkStrong
                      : AppShadows.cardAlphaLightStrong,
                ),
                blurRadius: AppShadows.cardBlur.scaled(context),
                offset: Offset(0, AppShadows.cardOffsetY.scaled(context)),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconSize.scaledMin(context, iconSize + 8),
                height: iconSize.scaledMin(context, iconSize + 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8.scaled(context)),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: iconInnerSize.scaled(context),
                ),
              ),
              SizedBox(height: gapAfterIcon.scaled(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppFonts.textStyle(
                        fontSize: titleFontSize.scaledText(context),
                        fontWeight: FontWeight.w700,
                        color: gradient != null ? Colors.white : textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: titleSubtitleGap.scaled(context)),
                      Expanded(
                        child: Text(
                          subtitle!,
                          style: AppFonts.textStyle(
                            fontSize: subtitleFontSize.scaledText(context),
                            fontWeight: FontWeight.normal,
                            color: gradient != null
                                ? Colors.white.withValues(alpha: 0.9)
                                : (isDark
                                      ? Colors.grey[400]
                                      : AppTheme.textSecondary),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
