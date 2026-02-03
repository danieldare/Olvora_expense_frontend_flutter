import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/models/color_theme.dart';
import '../../../../core/providers/theme_providers.dart';

/// Theme Selection Modal
class ThemeSelectionModal extends ConsumerWidget {
  const ThemeSelectionModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedTheme = ref.watch(colorThemeProvider);
    final themeNotifier = ref.read(colorThemeProvider.notifier);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ColorTheme.allThemes.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppTheme.borderColor.withValues(alpha: 0.3),
      ),
      itemBuilder: (context, index) {
        final theme = ColorTheme.allThemes[index];
        final isSelected = theme.id == selectedTheme.id;

        return InkWell(
          onTap: () async {
            await themeNotifier.setColorTheme(theme);
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
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
                // Theme color preview circle with emoji
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: theme.walletGradient,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      theme.emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // Theme names
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            theme.name,
                            style: AppFonts.textStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                          if (theme.isDark) ...[
                            SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                'DARK',
                                style: AppFonts.textStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : AppTheme.textSecondary,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 0),
                      Text(
                        theme.description,
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
                    color: theme.primaryColor,
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
