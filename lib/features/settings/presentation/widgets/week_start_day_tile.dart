import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/widgets/bottom_sheet_modal.dart';
import '../../../user_preferences/presentation/providers/user_preferences_providers.dart';
import '../../../user_preferences/domain/entities/user_preferences_entity.dart';

/// Provider for week start day (backward compatibility)
/// Returns 0 for Sunday, 1 for Monday
final weekStartDayProvider = FutureProvider<int>((ref) async {
  final preferences = await ref.watch(userPreferencesProvider.future);
  return preferences.weekStartDay.toNumber();
});

/// StateNotifier for managing week start day (backward compatibility)
final weekStartDayNotifierProvider =
    StateNotifierProvider<WeekStartDayNotifier, AsyncValue<int>>((ref) {
      return WeekStartDayNotifier(ref);
    });

class WeekStartDayNotifier extends StateNotifier<AsyncValue<int>> {
  final Ref _ref;

  WeekStartDayNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadWeekStartDay();
  }

  Future<void> _loadWeekStartDay() async {
    try {
      final preferences = await _ref.read(userPreferencesProvider.future);
      state = AsyncValue.data(preferences.weekStartDay.toNumber());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> setWeekStartDay(int day) async {
    state = const AsyncValue.loading();
    try {
      final weekStartDay = WeekStartDay.fromNumber(day);
      await _ref
          .read(userPreferencesNotifierProvider.notifier)
          .updatePreferences(weekStartDay: weekStartDay);

      // Invalidate userPreferencesProvider to refresh all dependent providers
      _ref.invalidate(userPreferencesProvider);

      // Reload to get the updated value
      await _loadWeekStartDay();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

class WeekStartDayTile extends ConsumerWidget {
  const WeekStartDayTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStartDayAsync = ref.watch(weekStartDayNotifierProvider);

    return weekStartDayAsync.when(
      data: (day) => _WeekStartDayTileContent(weekStartDay: day),
      loading: () => _WeekStartDayTileContent(
        weekStartDay: 0,
      ), // Show default (Sunday) while loading
      error: (error, stack) {
        // Show default (Sunday) on error, but still allow user to change it
        return _WeekStartDayTileContent(weekStartDay: 0);
      },
    );
  }
}

class _WeekStartDayTileContent extends ConsumerStatefulWidget {
  final int weekStartDay;

  const _WeekStartDayTileContent({required this.weekStartDay});

  @override
  ConsumerState<_WeekStartDayTileContent> createState() =>
      _WeekStartDayTileContentState();
}

class _WeekStartDayTileContentState
    extends ConsumerState<_WeekStartDayTileContent> {
  bool _isLoading = false;

  Future<void> _openWeekStartDaySettings() async {
    final currentDay = widget.weekStartDay;

    await BottomSheetModal.show(
      context: context,
      title: 'Week Start Day',
      subtitle: 'Choose which day your week starts on',
      maxHeightFraction: 0.45,
      child: _WeekStartDaySelectionModal(
        currentDay: currentDay,
        onDaySelected: (day) async {
          if (_isLoading) return;

          // Close modal immediately for instant feedback (optimistic UI)
          if (mounted) {
            Navigator.pop(context);
          }

          // Update preference in background
          setState(() => _isLoading = true);
          try {
            await ref
                .read(weekStartDayNotifierProvider.notifier)
                .setWeekStartDay(day);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update preference: $e'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          } finally {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : AppTheme.textSecondary;

    // Theme-aware colors matching SettingsScreen style
    final iconColor = isDark ? Colors.white : AppTheme.primaryColor;
    final iconBgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : AppTheme.primaryColor.withValues(alpha: 0.05);

    return InkWell(
      onTap: _isLoading ? null : _openWeekStartDaySettings,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.calendar_view_week_rounded,
                  color: iconColor,
                  size: 16,
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Week Start Day',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    widget.weekStartDay == 0 ? 'Sunday' : 'Monday',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),
            if (_isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : AppTheme.textSecondary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

/// Week Start Day Selection Modal - matches language selection style
class _WeekStartDaySelectionModal extends StatelessWidget {
  final int currentDay;
  final Function(int) onDaySelected;

  const _WeekStartDaySelectionModal({
    required this.currentDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final weekDays = [
      {
        'value': 0,
        'emoji': '☀️',
        'name': 'Sunday',
        'description': 'Start week on Sunday',
      },
      {
        'value': 1,
        'emoji': '📅',
        'name': 'Monday',
        'description': 'Start week on Monday',
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: weekDays.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppTheme.borderColor.withValues(alpha: 0.3),
      ),
      itemBuilder: (context, index) {
        final day = weekDays[index];
        final dayValue = day['value'] as int;
        final isSelected = dayValue == currentDay;

        return InkWell(
          onTap: () => onDaySelected(dayValue),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                        ? AppTheme.primaryColor.withValues(alpha: 0.15)
                        : AppTheme.primaryColor.withValues(alpha: 0.08))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Emoji icon
                SizedBox(
                  width: 24,
                  child: Text(
                    day['emoji'] as String,
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 8),
                // Day name and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        day['name'] as String,
                        style: AppFonts.textStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 0),
                      Text(
                        day['description'] as String,
                        style: AppFonts.textStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.6)
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Selected indicator
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
