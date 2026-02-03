import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../domain/entities/trip_entity.dart';

/// Trip Context Indicator Widget
///
/// Displays a subtle indicator showing which Trip expenses will be added to.
/// Only visible when a Trip is active.
///
/// Design Principles:
/// - Subtle reminder without being pushy
/// - Confirms behavior (auto-attachment)
/// - Non-blocking (doesn't require action)
class TripContextIndicator extends StatelessWidget {
  final TripEntity? trip;

  const TripContextIndicator({
    super.key,
    this.trip,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show if no trip is active
    if (trip == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.luggage_rounded,
            size: 14,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : AppTheme.textSecondary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),
          Text(
            'Adding to: ${trip!.name}',
            style: AppFonts.textStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : AppTheme.textSecondary.withValues(alpha: 0.7),
            ).copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
