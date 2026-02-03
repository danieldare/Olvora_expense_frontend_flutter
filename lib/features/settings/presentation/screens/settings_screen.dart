import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/bottom_sheet_modal.dart';
import '../../../../core/widgets/app_toggle.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/providers/theme_providers.dart';
import '../widgets/currency_selection_modal.dart';
import '../widgets/language_selection_modal.dart';
import '../widgets/theme_selection_modal.dart';
import '../widgets/expense_reminder_tile.dart';
import '../widgets/week_start_day_tile.dart';
import 'detection_settings_screen.dart';
import '../../../../core/providers/language_providers.dart';
import '../../../app_lock/presentation/providers/app_lock_providers.dart';
import '../../../app_lock/data/services/app_lock_storage_service.dart';
import '../../../app_lock/presentation/screens/change_pin_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppTheme.screenBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            0,
            AppSpacing.screenHorizontal,
            AppSpacing.bottomNavPadding,
          ),
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: 4.scaled(context),
                bottom: 2.scaled(context),
              ),
              child: Row(
                children: [
                  const AppBackButton(),
                  SizedBox(width: 6.scaled(context)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Settings',
                          style: AppFonts.textStyle(
                            fontSize: 18.scaledText(context),
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 1.scaled(context)),
                        Text(
                          'Customize your app experience',
                          style: AppFonts.textStyle(
                            fontSize: 11.scaledText(context),
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            _buildSectionHeader(context, 'PREFERENCES', isDark,
                icon: Icons.tune_rounded),
            SizedBox(height: 4),
            _buildGroupedTiles(context, [
              _SettingsTile(
                icon: Icons.notifications_rounded,
                title: 'Notifications',
                subtitle: 'Receive expense reminders',
                trailing: AppToggle(
                  value: _notificationsEnabled,
                  useCupertinoStyle: true,
                  onChanged: (val) =>
                      setState(() => _notificationsEnabled = val),
                ),
              ),
              _buildColorThemeTile(),
              _buildDetectionSettingsTile(),
              const ExpenseReminderTile(),
              const WeekStartDayTile(),
              _buildLanguageTile(),
              _buildCurrencyTile(),
            ]),
            SizedBox(height: 10),
            _buildSectionHeader(context, 'SECURITY', isDark,
                icon: Icons.security_rounded),
            SizedBox(height: 4),
            _buildSecuritySection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    bool isDark, {
    IconData? icon,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: EdgeInsets.all(4.scaled(context)),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(
                alpha: isDark ? 0.2 : 0.1,
              ),
              borderRadius: BorderRadius.circular(5.scaled(context)),
            ),
            child: Icon(
              icon,
              size: 11.scaled(context),
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(width: 4.scaled(context)),
        ],
        Text(
          title,
          style: AppFonts.textStyle(
            fontSize: 10.scaledText(context),
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.grey[300] : AppTheme.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  /// Build grouped tiles with dividers between items (card style aligned with More/Home).
  Widget _buildGroupedTiles(BuildContext context, List<Widget> tiles) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : AppTheme.borderColor;
    final radius = 12.scaled(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.borderColor,
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: AppShadows.cardAlphaLight,
                  ),
                  blurRadius: AppShadows.cardBlur.scaled(context),
                  offset: Offset(0, AppShadows.cardOffsetY.scaled(context)),
                  spreadRadius: AppShadows.cardSpread,
                ),
              ],
      ),
      child: Column(
        children: tiles.asMap().entries.map((entry) {
          final index = entry.key;
          final tile = entry.value;
          final isLast = index == tiles.length - 1;

          return Column(
            children: [
              _wrapTileForGroup(context, tile),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: dividerColor,
                  indent: 48,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Wrap tile to remove its container styling when in a group
  Widget _wrapTileForGroup(BuildContext context, Widget tile) {
    if (tile is _SettingsTile) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final textColor = isDark ? Colors.white : AppTheme.textPrimary;
      final subtitleColor = isDark
          ? Colors.white.withValues(alpha: 0.7)
          : AppTheme.textSecondary;
      final chevronColor = isDark
          ? Colors.white.withValues(alpha: 0.6)
          : AppTheme.textSecondary;
      final iconColor = isDark ? Colors.white : AppTheme.primaryColor;
      final iconBgColor = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : AppTheme.primaryColor.withValues(alpha: 0.05);

      return InkWell(
        onTap: tile.onTap,
        borderRadius: BorderRadius.circular(10.scaled(context)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12.scaled(context),
            vertical: 10.scaled(context),
          ),
          child: Row(
            children: [
              Container(
                width: 28.scaled(context),
                height: 28.scaled(context),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8.scaled(context)),
                ),
                child: Center(
                  child: Icon(
                    tile.icon,
                    color: iconColor,
                    size: 16.scaled(context),
                  ),
                ),
              ),
              SizedBox(width: 10.scaled(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tile.title,
                      style: AppFonts.textStyle(
                        fontSize: 14.scaledText(context),
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    if (tile.subtitle.isNotEmpty) ...[
                      SizedBox(height: 1.scaled(context)),
                      Text(
                        tile.subtitle,
                        style: AppFonts.textStyle(
                          fontSize: 11.scaledText(context),
                          fontWeight: FontWeight.normal,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.scaled(context)),
              tile.trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: chevronColor,
                    size: 18.scaled(context),
                  ),
            ],
          ),
        ),
      );
    }
    return tile;
  }

  Widget _buildColorThemeTile() {
    final selectedTheme = ref.watch(colorThemeProvider);

    return _SettingsTile(
      icon: Icons.palette_rounded,
      title: 'Color Theme',
      subtitle: '${selectedTheme.emoji} ${selectedTheme.name}',
      onTap: () {
        BottomSheetModal.show(
          context: context,
          title: 'Select Color Theme',
          subtitle: 'Choose your favorite color scheme',
          maxHeightFraction: 0.6,
          child: const ThemeSelectionModal(),
        );
      },
    );
  }

  Widget _buildLanguageTile() {
    final selectedLanguageAsync = ref.watch(languageNotifierProvider);

    return selectedLanguageAsync.when(
      data: (language) => _SettingsTile(
        icon: Icons.language_rounded,
        title: 'Language',
        subtitle: '${language.flag} ${language.nativeName}',
        onTap: () {
          BottomSheetModal.show(
            context: context,
            title: 'Select Language',
            subtitle: 'Choose your preferred language',
            maxHeightFraction: 0.6,
            child: const LanguageSelectionModal(),
          );
        },
      ),
      loading: () => _SettingsTile(
        icon: Icons.language_rounded,
        title: 'Language',
        subtitle: 'Loading...',
        onTap: () {},
      ),
      error: (_, _) => _SettingsTile(
        icon: Icons.language_rounded,
        title: 'Language',
        subtitle: '🇺🇸 English',
        onTap: () {
          BottomSheetModal.show(
            context: context,
            title: 'Select Language',
            subtitle: 'Choose your preferred language',
            maxHeightFraction: 0.6,
            child: const LanguageSelectionModal(),
          );
        },
      ),
    );
  }

  Widget _buildDetectionSettingsTile() {
    return _SettingsTile(
      icon: Icons.smart_toy_rounded,
      title: 'Expense Detection',
      subtitle: 'Configure SMS, clipboard, and AI detection',
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const DetectionSettingsScreen(),
          ),
        );
      },
    );
  }

  Widget _buildCurrencyTile() {
    final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);

    return selectedCurrencyAsync.when(
      data: (currency) => _SettingsTile(
        icon: Icons.attach_money_rounded,
        title: 'Currency',
        subtitle: '${currency.name} (${currency.symbol})',
        onTap: () {
          BottomSheetModal.show(
            context: context,
            title: 'Select Currency',
            subtitle: 'Choose your preferred currency',
            maxHeightFraction: 0.6,
            child: const CurrencySelectionModal(),
          );
        },
      ),
      loading: () => _SettingsTile(
        icon: Icons.attach_money_rounded,
        title: 'Currency',
        subtitle: 'Loading...',
        onTap: () {},
      ),
      error: (_, _) => _SettingsTile(
        icon: Icons.attach_money_rounded,
        title: 'Currency',
        subtitle: 'Nigerian Naira (₦)',
        onTap: () {
          BottomSheetModal.show(
            context: context,
            title: 'Select Currency',
            subtitle: 'Choose your preferred currency',
            maxHeightFraction: 0.6,
            child: const CurrencySelectionModal(),
          );
        },
      ),
    );
  }

  Widget _buildSecuritySection(BuildContext context) {
    final hasPinSetup = ref.watch(hasPinSetupProvider);
    final appLockEnabled = ref.watch(appLockEnabledProvider);
    final biometricEnabled = ref.watch(biometricEnabledProvider);
    final biometricAvailable = ref.watch(isBiometricUnlockAvailableProvider);
    final biometricType = ref.watch(biometricTypeProvider);
    final lockTimeout = ref.watch(lockTimeoutProvider);

    return hasPinSetup.when(
      data: (hasPin) {
        final tiles = <Widget>[];

        // App Lock toggle (only show if PIN is set up)
        if (hasPin) {
          tiles.add(
            appLockEnabled.when(
              data: (isEnabled) => _SettingsTile(
                icon: Icons.lock_rounded,
                title: 'App Lock',
                subtitle: isEnabled ? 'Enabled' : 'Disabled',
                trailing: AppToggle(
                  value: isEnabled,
                  useCupertinoStyle: true,
                  onChanged: (val) => _toggleAppLock(val),
                ),
              ),
              loading: () => _SettingsTile(
                icon: Icons.lock_rounded,
                title: 'App Lock',
                subtitle: 'Loading...',
              ),
              error: (_, _) => _SettingsTile(
                icon: Icons.lock_rounded,
                title: 'App Lock',
                subtitle: 'Error',
              ),
            ),
          );

          // Biometric toggle (only if PIN exists and device supports biometrics)
          tiles.add(
            biometricAvailable.when(
              data: (isAvailable) {
                if (!isAvailable) {
                  // Check if biometrics are supported but not enrolled
                  return biometricType.when(
                    data: (_) => const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  );
                }

                return biometricEnabled.when(
                  data: (isEnabled) => biometricType.when(
                    data: (type) {
                      final biometricService = ref.read(biometricServiceProvider);
                      final typeName = biometricService.getBiometricTypeName(type);
                      final icon = type == BiometricType.face
                          ? Icons.face_rounded
                          : Icons.fingerprint_rounded;

                      return _SettingsTile(
                        icon: icon,
                        title: typeName,
                        subtitle: isEnabled
                            ? 'Enabled for quick unlock'
                            : 'Use $typeName to unlock',
                        trailing: AppToggle(
                          value: isEnabled,
                          useCupertinoStyle: true,
                          onChanged: (val) => _toggleBiometric(val),
                        ),
                      );
                    },
                    loading: () => _SettingsTile(
                      icon: Icons.fingerprint_rounded,
                      title: 'Biometrics',
                      subtitle: 'Loading...',
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  loading: () => _SettingsTile(
                    icon: Icons.fingerprint_rounded,
                    title: 'Biometrics',
                    subtitle: 'Loading...',
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          );

          // Lock timeout selector
          tiles.add(
            lockTimeout.when(
              data: (timeout) => _SettingsTile(
                icon: Icons.timer_rounded,
                title: 'Lock After',
                subtitle: timeout.displayName,
                onTap: () => _showTimeoutSelector(context),
              ),
              loading: () => _SettingsTile(
                icon: Icons.timer_rounded,
                title: 'Lock After',
                subtitle: 'Loading...',
              ),
              error: (_, _) => _SettingsTile(
                icon: Icons.timer_rounded,
                title: 'Lock After',
                subtitle: 'Immediately',
                onTap: () => _showTimeoutSelector(context),
              ),
            ),
          );

          // Change PIN
          tiles.add(
            _SettingsTile(
              icon: Icons.pin_rounded,
              title: 'Change PIN',
              subtitle: 'Update your security PIN',
              onTap: () => _navigateToChangePIN(context),
            ),
          );
        } else {
          // No PIN set up - show setup option
          tiles.add(
            _SettingsTile(
              icon: Icons.lock_outline_rounded,
              title: 'Set Up PIN',
              subtitle: 'Protect your app with a PIN',
              onTap: () => _setupPIN(context),
            ),
          );
        }

        // Filter out empty widgets
        final validTiles = tiles.where((tile) => tile is! SizedBox).toList();

        return _buildGroupedTiles(context, validTiles);
      },
      loading: () => _buildGroupedTiles(context, [
        _SettingsTile(
          icon: Icons.lock_rounded,
          title: 'Security',
          subtitle: 'Loading...',
        ),
      ]),
      error: (_, _) => _buildGroupedTiles(context, [
        _SettingsTile(
          icon: Icons.lock_rounded,
          title: 'Security',
          subtitle: 'Error loading settings',
        ),
      ]),
    );
  }

  Future<void> _toggleAppLock(bool enabled) async {
    final storageService = ref.read(appLockStorageServiceProvider);
    await storageService.setAppLockEnabled(enabled);
    ref.invalidate(appLockEnabledProvider);
  }

  Future<void> _toggleBiometric(bool enabled) async {
    if (enabled) {
      // Verify biometric works before enabling
      final biometricService = ref.read(biometricServiceProvider);
      final success = await biometricService.authenticate(
        reason: 'Confirm biometric setup',
      );
      if (!success) return;
    }

    final storageService = ref.read(appLockStorageServiceProvider);
    await storageService.setBiometricEnabled(enabled);
    ref.invalidate(biometricEnabledProvider);
    ref.invalidate(isBiometricUnlockAvailableProvider);
  }

  void _showTimeoutSelector(BuildContext context) {
    BottomSheetModal.show(
      context: context,
      title: 'Lock After',
      subtitle: 'Choose when to lock the app',
      maxHeightFraction: 0.4,
      child: _LockTimeoutSelector(
        onSelected: (timeout) async {
          final storageService = ref.read(appLockStorageServiceProvider);
          await storageService.setLockTimeout(timeout);
          ref.invalidate(lockTimeoutProvider);
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  void _navigateToChangePIN(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChangePinScreen(),
      ),
    );
  }

  void _setupPIN(BuildContext context) {
    // Navigate to PIN setup - this will set the app lock state to PinSetupRequired
    ref.read(appLockNotifierProvider.notifier).initialize();
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCardBackground : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppTheme.borderColor;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : AppTheme.textSecondary;
    final chevronColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppTheme.textSecondary;
    
    // Use primary color for icons by default
    final iconColor = isDark ? Colors.white : AppTheme.primaryColor;
    final iconBgColor = isDark 
        ? Colors.white.withValues(alpha: 0.05) 
        : AppTheme.primaryColor.withValues(alpha: 0.05);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Icon(icon, color: iconColor, size: 16)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppFonts.textStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: AppFonts.textStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ??
                    Icon(Icons.chevron_right_rounded, color: chevronColor, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lock timeout selection modal
class _LockTimeoutSelector extends ConsumerWidget {
  final ValueChanged<LockTimeout> onSelected;

  const _LockTimeoutSelector({required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTimeout = ref.watch(lockTimeoutProvider);

    return currentTimeout.when(
      data: (selected) => Column(
        mainAxisSize: MainAxisSize.min,
        children: LockTimeout.values.map((timeout) {
          final isSelected = timeout == selected;
          return ListTile(
            leading: Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected
                  ? AppTheme.primaryColor
                  : (isDark ? Colors.white54 : Colors.grey),
            ),
            title: Text(
              timeout.displayName,
              style: AppFonts.textStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            onTap: () => onSelected(timeout),
          );
        }).toList(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Error loading settings')),
    );
  }
}
