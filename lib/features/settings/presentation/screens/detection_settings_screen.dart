import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_toggle.dart';
import '../../../../core/services/expense_modal_service.dart';
import '../../../../core/services/clipboard_monitor_service.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import '../widgets/notification_detection_tile.dart';

/// Simplified expense detection settings
///
/// Only shows essential options that users actually need.
/// Technical settings use sensible defaults behind the scenes.
class DetectionSettingsScreen extends ConsumerStatefulWidget {
  const DetectionSettingsScreen({super.key});

  @override
  ConsumerState<DetectionSettingsScreen> createState() =>
      _DetectionSettingsScreenState();
}

class _DetectionSettingsScreenState
    extends ConsumerState<DetectionSettingsScreen> {
  bool _clipboardEnabled = false;
  bool _smartSuggestionsEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _clipboardEnabled = prefs.getBool('clipboard_monitoring_enabled') ?? false;
        _smartSuggestionsEnabled = prefs.getBool('ml_learning_enabled') ?? true;
      });
    } catch (e) {
      // Use defaults on error
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('clipboard_monitoring_enabled', _clipboardEnabled);
      await prefs.setBool('ml_learning_enabled', _smartSuggestionsEnabled);

      // Use sensible defaults for technical settings
      await prefs.setBool('auto_create_enabled', false); // Always require confirmation
      await prefs.setDouble('auto_create_threshold', 0.95);
      await prefs.setDouble('preview_threshold', 0.50);
      await prefs.setBool('show_auto_create_toast', true);

      _updateServices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _updateServices() {
    ExpenseModalService().updateConfig(
      ExpenseModalConfig(
        autoCreateThreshold: 0.95,
        previewThreshold: 0.50,
        autoCreateEnabled: false,
        showAutoCreateToast: true,
      ),
    );

    ClipboardMonitorService().updateConfig(
      ClipboardMonitorConfig(
        minConfidenceToShow: 0.50,
        autoShowModal: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.screenBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 6, 16, 0),
                      child: Row(
                        children: [
                          AppBackButton(),
                          Text(
                            'Expense Detection',
                            style: AppFonts.textStyle(
                              fontSize: 18.scaledText(context),
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.screenHorizontal,
                        20,
                        AppSpacing.screenHorizontal,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Description
                          Text(
                            'Automatically detect expenses from your device',
                            style: AppFonts.textStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          SizedBox(height: 24),

                          // Settings card
                          _buildSettingsCard(isDark),
                          SizedBox(height: 24),

                          // Info
                          _buildInfoSection(isDark),
                        ],
                      ),
                    ),
                  ),

                  // Bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.bottomNavPadding),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSettingsCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppTheme.borderColor.withValues(alpha: 0.3)
              : AppTheme.borderColor,
        ),
      ),
      child: Column(
        children: [
          // Notification Detection (uses existing tile)
          const NotificationDetectionTile(),

          _buildDivider(isDark),

          // Clipboard Detection
          _buildToggleTile(
            icon: Icons.content_paste_rounded,
            title: 'Clipboard',
            subtitle: 'Detect expenses from copied text',
            value: _clipboardEnabled,
            onChanged: (val) {
              setState(() => _clipboardEnabled = val);
              _saveSettings();
            },
            isDark: isDark,
          ),

          _buildDivider(isDark),

          // Smart Suggestions
          _buildToggleTile(
            icon: Icons.auto_awesome_rounded,
            title: 'Smart suggestions',
            subtitle: 'Learn from your habits to improve accuracy',
            value: _smartSuggestionsEnabled,
            onChanged: (val) {
              setState(() => _smartSuggestionsEnabled = val);
              _saveSettings();
            },
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark
          ? AppTheme.borderColor.withValues(alpha: 0.2)
          : AppTheme.borderColor.withValues(alpha: 0.5),
      indent: 54,
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
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
                size: 18,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.textStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppFonts.textStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            AppToggle(
              value: value,
              useCupertinoStyle: true,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.primaryColor.withValues(alpha: 0.08)
            : AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppTheme.primaryColor,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'When we detect a potential expense, you\'ll see a preview to confirm before it\'s added.',
              style: AppFonts.textStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
