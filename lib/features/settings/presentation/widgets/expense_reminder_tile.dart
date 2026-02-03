import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/reminder_preferences_service.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/widgets/bottom_sheet_modal.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../../core/widgets/app_toggle.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/reminder_providers.dart';

class ExpenseReminderTile extends ConsumerWidget {
  const ExpenseReminderTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderState = ref.watch(reminderNotifierProvider);

    return reminderState.when(
      data: (isEnabled) => _ExpenseReminderTileContent(isEnabled: isEnabled),
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

class _ExpenseReminderTileContent extends ConsumerStatefulWidget {
  final bool isEnabled;

  const _ExpenseReminderTileContent({required this.isEnabled});

  @override
  ConsumerState<_ExpenseReminderTileContent> createState() =>
      _ExpenseReminderTileContentState();
}

class _ExpenseReminderTileContentState
    extends ConsumerState<_ExpenseReminderTileContent> {
  bool _isLoading = false;

  Future<void> _toggleReminder(bool enabled) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (enabled) {
        // When enabling, check permission first and request if needed
        final notificationService = ref.read(localNotificationServiceProvider);
        final permissionStatus = await notificationService.getPermissionStatus();

        if (permissionStatus != PermissionStatus.granted) {
          // Directly request permission (this will show the system dialog)
          final permissionGranted = await notificationService.requestNotificationPermission();
          
          if (!permissionGranted) {
            // Permission denied, show dialog to guide user to settings
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              _showPermissionDialog(notificationService);
            }
            return;
          }
        }
      }

      // Proceed with toggle (permission is granted or disabling)
      final notifier = ref.read(reminderNotifierProvider.notifier);
      final success = await notifier.toggleReminder(enabled);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                enabled
                    ? 'Daily expense reminders enabled'
                    : 'Daily expense reminders disabled',
              ),
              backgroundColor: enabled
                  ? AppTheme.successColor
                  : AppTheme.errorColor,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // Check permission status for error handling
          final notificationService = ref.read(
            localNotificationServiceProvider,
          );
          final permissionStatus = await notificationService
              .getPermissionStatus();

          if (permissionStatus == PermissionStatus.denied ||
              permissionStatus == PermissionStatus.permanentlyDenied) {
            _showPermissionDialog(notificationService);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Failed to enable reminders. Please try again.',
                ),
                backgroundColor: AppTheme.errorColor,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => _toggleReminder(enabled),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  void _showPermissionDialog(LocalNotificationService service) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark ? Colors.grey[400] : AppTheme.textSecondary;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => AlertDialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.notifications_active_rounded,
              color: AppTheme.primaryColor,
              size: 28,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Enable Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To send you daily expense reminders, we need permission to send notifications.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: subtitleColor,
                height: 1.5,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: AppTheme.warningColor,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please enable notifications in your device settings.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: subtitleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              service.openNotificationSettings();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openReminderSettings() async {
    final prefsService = ref.read(reminderPreferencesServiceProvider);
    final isEnabled = await prefsService.isEnabled();
    final currentTime = await prefsService.getReminderTime();
    final currentMessage = await prefsService.getReminderMessage();

    if (!mounted) return;

    await BottomSheetModal.show(
      context: context,
      title: 'Expense Reminder Settings',
      subtitle: 'Configure your daily expense tracking reminder',
      child: _ReminderSettingsContent(
        isEnabled: isEnabled,
        currentTime: currentTime,
        currentMessage: currentMessage,
      ),
      maxHeightFraction: 0.55,
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
      onTap: _isLoading ? null : _openReminderSettings,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  Icons.alarm_rounded,
                  color: iconColor,
                  size: 18,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expense Reminder',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    widget.isEnabled
                        ? 'Daily reminder to track expenses'
                        : 'Get reminded to track expenses daily',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),
            _isLoading
                ? LoadingSpinner.small()
                : AppToggle(
                    value: widget.isEnabled,
                    useCupertinoStyle: true,
                    onChanged: _isLoading ? null : _toggleReminder,
                  ),
          ],
        ),
      ),
    );
  }
}

class _ReminderSettingsContent extends ConsumerStatefulWidget {
  final bool isEnabled;
  final String currentTime;
  final String currentMessage;

  const _ReminderSettingsContent({
    required this.isEnabled,
    required this.currentTime,
    required this.currentMessage,
  });

  @override
  ConsumerState<_ReminderSettingsContent> createState() =>
      _ReminderSettingsContentState();
}

class _ReminderSettingsContentState
    extends ConsumerState<_ReminderSettingsContent> {
  late TextEditingController _messageController;
  late TimeOfDay _selectedTime;
  bool _isSaving = false;
  String? _messageError;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(text: widget.currentMessage);
    final timeParts = widget.currentTime.split(':');
    _selectedTime = TimeOfDay(
      hour: int.tryParse(timeParts[0]) ?? 18,
      minute: int.tryParse(timeParts[1]) ?? 0,
    );

    _messageController.addListener(_validateMessage);
  }

  void _validateMessage() {
    final message = _messageController.text.trim();
    setState(() {
      if (message.isEmpty) {
        _messageError = 'Message cannot be empty';
      } else if (message.length > ReminderPreferencesService.maxMessageLength) {
        _messageError =
            'Message too long (max ${ReminderPreferencesService.maxMessageLength} characters)';
      } else {
        _messageError = null;
      }
    });
  }

  @override
  void dispose() {
    _messageController.removeListener(_validateMessage);
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;

    // Validate message
    final message = _messageController.text.trim();
    if (message.isEmpty || _messageError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid reminder message'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final prefsService = ref.read(reminderPreferencesServiceProvider);
      final notificationService = ref.read(localNotificationServiceProvider);

      final timeString =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      // Always save preferences first, regardless of permission status
      final timeSaved = await prefsService.setReminderTime(timeString);
      final messageSaved = await prefsService.setReminderMessage(message);

      if (!timeSaved || !messageSaved) {
        throw Exception('Failed to save settings');
      }

      // Invalidate providers to refresh state
      ref.invalidate(reminderTimeProvider);
      ref.invalidate(reminderMessageProvider);

      // Try to update the schedule if reminders are enabled
      // But don't fail the save if scheduling fails - preferences are already saved
      bool scheduleSuccess = true;
      String? scheduleError;

      if (widget.isEnabled) {
        try {
          // Ensure service is initialized
          final initialized = await notificationService.initialize();
          if (!initialized) {
            scheduleSuccess = false;
            scheduleError = 'Failed to initialize notification service';
          } else {
            // Check permission before scheduling
            final permissionStatus = await notificationService.getPermissionStatus();
            if (permissionStatus != PermissionStatus.granted) {
              scheduleSuccess = false;
              scheduleError = 'Notification permission not granted';
            } else {
              // Update the schedule with new time and message
              final scheduled = await notificationService.updateReminderSchedule();
              if (!scheduled) {
                scheduleSuccess = false;
                scheduleError = 'Failed to schedule reminder';
              }
            }
          }
        } catch (e) {
          scheduleSuccess = false;
          scheduleError = e.toString();
        }
      } else {
        // If disabled, cancel any existing reminders
        try {
          await notificationService.cancelDailyReminder();
        } catch (e) {
          // Ignore cancellation errors
        }
      }

      if (mounted) {
        Navigator.pop(context);
        
        // Show appropriate message based on save and schedule results
        if (scheduleSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reminder settings saved successfully'),
              backgroundColor: AppTheme.successColor,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // Settings saved but scheduling failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                scheduleError?.contains('permission') == true
                    ? 'Settings saved, but notification permission is required to enable reminders.'
                    : 'Settings saved, but failed to schedule reminder.',
              ),
              backgroundColor: AppTheme.warningColor,
              duration: const Duration(seconds: 4),
              action: scheduleError?.contains('permission') == true
                  ? SnackBarAction(
                      label: 'Open Settings',
                      textColor: Colors.white,
                      onPressed: () {
                        notificationService.openNotificationSettings();
                      },
                    )
                  : null,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _saveSettings,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _testReminder() async {
    final notificationService = ref.read(localNotificationServiceProvider);
    final message = _messageController.text.trim().isEmpty
        ? ReminderPreferencesService.defaultMessage
        : _messageController.text.trim();

    if (message.length > ReminderPreferencesService.maxMessageLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Message too long (max ${ReminderPreferencesService.maxMessageLength} characters)',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Ensure service is initialized before showing test notification
    final initialized = await notificationService.initialize();
    if (!initialized) {
      // Check permission status
      final permissionStatus = await notificationService.getPermissionStatus();

      if (mounted) {
        if (permissionStatus == PermissionStatus.denied ||
            permissionStatus == PermissionStatus.permanentlyDenied) {
          _showPermissionDialogForTest(notificationService);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to initialize notification service. Please try again.',
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
      return;
    }

    final success = await notificationService.showTestNotification(message);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Test notification sent! Check your notification tray.'
                : 'Failed to send test notification. Please check permissions.',
          ),
          backgroundColor: success
              ? AppTheme.successColor
              : AppTheme.errorColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showPermissionDialogForTest(LocalNotificationService service) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark ? Colors.grey[400] : AppTheme.textSecondary;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => AlertDialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Notification Permission Required',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        content: Text(
          'To send test notifications, please enable notifications in your device settings.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: subtitleColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: subtitleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              service.openNotificationSettings();
            },
            child: Text(
              'Open Settings',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final gradientColors = AppTheme.walletGradient.isNotEmpty
        ? AppTheme.walletGradient
        : [AppTheme.primaryColor, AppTheme.secondaryColor];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero-style time card (inspired by Weekly Summary hero)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _selectTime,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors.length >= 2
                          ? gradientColors
                          : [gradientColors.first, gradientColors.first],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (gradientColors.isNotEmpty
                                ? gradientColors.first
                                : AppTheme.primaryColor)
                            .withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily reminder at',
                              style: AppFonts.textStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedTime.format(context),
                              style: AppFonts.textStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.sectionMedium),
            // Message card (inspired by Weekly Summary quick stat / insights cards)
            Text(
              'Reminder message',
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: AppSpacing.spacingSmall),
            AppTextField(
              controller: _messageController,
              hintText: ReminderPreferencesService.defaultMessage,
              maxLines: 3,
              maxLength: ReminderPreferencesService.maxMessageLength,
              useDarkStyle: isDark,
              errorText: _messageError,
              showCounter: true,
              onChanged: (_) => _validateMessage(),
            ),
            SizedBox(height: AppSpacing.sectionMedium),
            // Test notification (secondary / outline style)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _testReminder,
                icon: Icon(
                  Icons.notifications_active_rounded,
                  size: 20,
                  color: AppTheme.warningColor,
                ),
                label: Text(
                  'Send test notification',
                  style: AppFonts.textStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.warningColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.warningColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.spacingMedium),
            // Save (primary CTA, like Weekly Summary)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving || _messageError != null
                    ? null
                    : _saveSettings,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? LoadingSpinnerVariants.white(size: 20, strokeWidth: 2)
                    : Text(
                        'Save settings',
                        style: AppFonts.textStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
