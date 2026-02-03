import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/platform_notification_service.dart';
import '../../../../core/providers/notification_detection_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../../core/widgets/app_toggle.dart';
import 'debit_alert_explanation_modal.dart';

class NotificationDetectionTile extends ConsumerStatefulWidget {
  const NotificationDetectionTile({super.key});

  @override
  ConsumerState<NotificationDetectionTile> createState() =>
      _NotificationDetectionTileState();
}

class _NotificationDetectionTileState
    extends ConsumerState<NotificationDetectionTile> {
  bool _isLoading = false;

  Future<void> _toggleNotificationDetection() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final stateNotifier = ref.read(notificationDetectionStateProvider.notifier);
      final service = ref.read(platformNotificationServiceProvider);
      final isCurrentlyEnabled = ref.read(notificationDetectionStateProvider);

      if (isCurrentlyEnabled) {
        // Disable
        await stateNotifier.disable();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Debit alert detection disabled'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Enable - check permissions first
        final hasPermission = await service.checkPermission();
        if (!hasPermission) {
          final granted = await service.requestPermission();
          if (!granted && mounted) {
            _showPermissionDialog(service);
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }

        // Enable the service
        final enabled = await stateNotifier.enable();
        if (!mounted) return;
        
        if (enabled) {
          // Show explanation modal
          await DebitAlertExplanationModal.show(context);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Debit alert detection enabled'),
                backgroundColor: AppTheme.successColor,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Refresh state to ensure UI is in sync
          await stateNotifier.refresh();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to enable detection. Please check permissions.'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Refresh state on error to ensure UI is in sync
        ref.read(notificationDetectionStateProvider.notifier).refresh();
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

  void _showPermissionDialog(PlatformNotificationService service) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark ? Colors.grey[400] : AppTheme.textSecondary;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => AlertDialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Permission Required',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        content: Text(
          'To detect debit alerts from notifications/SMS, please grant access in your device settings.',
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
              service.openSettings();
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
    // Watch the state notifier for reactive updates
    final isEnabled = ref.watch(notificationDetectionStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Theme-aware colors matching SettingsScreen style
    final iconColor = isDark ? Colors.white : AppTheme.primaryColor;
    final iconBgColor = isDark 
        ? Colors.white.withValues(alpha: 0.05) 
        : AppTheme.primaryColor.withValues(alpha: 0.05);
    
    // Theme-aware text colors
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark 
        ? Colors.white.withValues(alpha: 0.7) 
        : AppTheme.textSecondary;

    return InkWell(
      onTap: _isLoading ? null : () => _toggleNotificationDetection(),
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
                  Icons.notifications_active,
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
                    'Debit Alert Detection',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    isEnabled
                        ? 'Automatically detect expenses from notifications'
                        : 'Enable to detect expenses from debit notifications',
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
                    value: isEnabled,
                    useCupertinoStyle: true,
                    onChanged: _isLoading ? null : (_) => _toggleNotificationDetection(),
                  ),
          ],
        ),
      ),
    );
  }
}

