import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/models/language.dart';
import '../../../../core/providers/language_providers.dart';

/// Language Selection Modal
class LanguageSelectionModal extends ConsumerWidget {
  const LanguageSelectionModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedLanguageAsync = ref.watch(languageNotifierProvider);
    final languageNotifier = ref.read(languageNotifierProvider.notifier);

    return selectedLanguageAsync.when(
      data: (selectedLanguage) {
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: Language.supportedLanguages.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.borderColor.withValues(alpha: 0.3),
          ),
          itemBuilder: (context, index) {
            final language = Language.supportedLanguages[index];
            final isSelected = language.code == selectedLanguage.code;

            return InkWell(
              onTap: () async {
                await languageNotifier.setLanguage(language);
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
                    // Flag emoji
                    SizedBox(
                      width: 24,
                      child: Text(
                        language.flag,
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 8),
                    // Language names
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            language.nativeName,
                            style: AppFonts.textStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 0),
                          Text(
                            language.name,
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
      },
      loading: () => Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Failed to load languages',
          style: AppFonts.textStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.errorColor,
          ),
        ),
      ),
    );
  }
}
