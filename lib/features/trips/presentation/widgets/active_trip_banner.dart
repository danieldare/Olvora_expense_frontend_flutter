import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/trip_entity.dart';

/// Message-row icon size used for visual alignment with "No weekly budget set" row.
const double _kMessageRowIconSize = AppSpacing.iconSizeSmall;

/// Active Trip Banner Widget
///
/// Displays a compact banner on the Home Screen when a Trip is active.
/// Styled identically to the "No weekly budget set" row: same padding, border,
/// background, icon size, and spacing. Icons sit in fixed-size boxes for alignment.
class ActiveTripBanner extends ConsumerWidget {
  final TripEntity trip;
  final VoidCallback onViewTrip;

  const ActiveTripBanner({
    super.key,
    required this.trip,
    required this.onViewTrip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.transparent : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppTheme.borderColor.withValues(alpha: 0.5);
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final trailingIconColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppTheme.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onViewTrip,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.messageRowPaddingHorizontal,
            vertical: AppSpacing.messageRowPaddingVertical,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              SizedBox(
                width: _kMessageRowIconSize,
                height: _kMessageRowIconSize,
                child: Center(
                  child: Icon(
                    Icons.luggage_rounded,
                    color: AppTheme.primaryColor,
                    size: _kMessageRowIconSize,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.spacingXSmall),
              Expanded(
                child: Text(
                  trip.name,
                  style: AppFonts.textStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: AppSpacing.spacingXXSmall),
              Text(
                'Active Trip',
                style: AppFonts.textStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(width: AppSpacing.spacingXXSmall),
              SizedBox(
                width: 22,
                height: 22,
                child: Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: trailingIconColor,
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
