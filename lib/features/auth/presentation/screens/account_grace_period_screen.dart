import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/utils/app_logger.dart';
import '../../data/mappers/auth_failure_mapper.dart';
import '../mappers/auth_failure_message_mapper.dart';
import '../providers/auth_providers.dart';
import 'auth_screen.dart';
import 'welcome_screen.dart';

// Temporary stub - TODO: Re-implement proper AccountDeletionStatus
class AccountDeletionStatus {
  final DateTime? deletedAt;
  final DateTime? recoveryDeadline;
  final int daysRemaining;
  final bool canRestore;
  final bool canStartAfresh;
  final String status; // Temporary: using String instead of enum

  const AccountDeletionStatus({
    this.deletedAt,
    this.recoveryDeadline,
    required this.daysRemaining,
    this.canRestore = true,
    this.canStartAfresh = true,
    this.status = 'pendingDeletion',
  });

  // Computed property for backward compatibility
  DateTime get scheduledDeletionDate =>
      recoveryDeadline ?? deletedAt ?? DateTime.now();
}

/// Account Grace Period Screen
///
/// Compact, smart UI for account scheduled for deletion.
/// Allows user to restore account or start afresh.
class AccountGracePeriodScreen extends ConsumerStatefulWidget {
  final AccountDeletionStatus deletionStatus;

  const AccountGracePeriodScreen({super.key, required this.deletionStatus});

  @override
  ConsumerState<AccountGracePeriodScreen> createState() =>
      _AccountGracePeriodScreenState();
}

class _AccountGracePeriodScreenState
    extends ConsumerState<AccountGracePeriodScreen> {
  bool _isRestoring = false;
  bool _isStartingAfresh = false;
  bool _isLoggingOut = false;
  String? _error;

  Future<void> _showRestoreConfirmation() async {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Restore account',
                  style: AppFonts.textStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.spacingMedium),
                Text(
                  'Your account will return to active status and you\'ll regain full access.',
                  style: AppFonts.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.sectionMedium),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.outlined(
                        label: 'Cancel',
                        onPressed: () => Navigator.pop(context, false),
                        textColor: onSurfaceVariant,
                        isFullWidth: true,
                      ),
                    ),
                    SizedBox(width: AppSpacing.spacingMedium),
                    Expanded(
                      child: AppButton(
                        label: 'Restore',
                        onPressed: () => Navigator.pop(context, true),
                        variant: AppButtonVariant.secondary,
                        backgroundColor: AppTheme.successColor,
                        textColor: Colors.white,
                        isFullWidth: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await _handleRestore();
    }
  }

  Future<void> _handleRestore() async {
    if (_isRestoring) return;

    setState(() {
      _isRestoring = true;
      _error = null;
    });

    final restoreUseCase = ref.read(restoreAccountUseCaseProvider);
    final result = await restoreUseCase();

    if (!mounted) return;

    result.fold(
      (failure) {
        final message = AuthFailureMapper.getLastExceptionMessage() ??
            AuthFailureMessageMapper.mapToMessage(failure);
        setState(() {
          _error = message;
          _isRestoring = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      },
      (_) {
        setState(() => _isRestoring = false);
        ref.read(authNotifierProvider.notifier).setAuthenticatedAfterRestore();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account restored. Welcome back.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  Future<void> _showStartAfreshConfirmation() async {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Start afresh',
                  style: AppFonts.textStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.errorColor,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.spacingMedium),
                Text(
                  'All your data will be permanently deleted. You can sign up again from the next screen when you\'re ready. This can\'t be undone.',
                  style: AppFonts.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.sectionMedium),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.outlined(
                        label: 'Cancel',
                        onPressed: () => Navigator.pop(context, false),
                        textColor: onSurfaceVariant,
                        isFullWidth: true,
                      ),
                    ),
                    SizedBox(width: AppSpacing.spacingMedium),
                    Expanded(
                      child: AppButton(
                        label: 'Continue',
                        onPressed: () => Navigator.pop(context, true),
                        variant: AppButtonVariant.secondary,
                        backgroundColor: AppTheme.errorColor,
                        textColor: Colors.white,
                        isFullWidth: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      _handleStartAfresh();
    }
  }

  Future<void> _handleStartAfresh() async {
    if (_isStartingAfresh) return;

    setState(() {
      _isStartingAfresh = true;
      _error = null;
    });

    final hardDeleteUseCase = ref.read(hardDeleteAccountUseCaseProvider);
    final deleteResult = await hardDeleteUseCase();

    if (!mounted) return;

    await deleteResult.fold(
      (failure) async {
        final message = AuthFailureMapper.getLastExceptionMessage() ??
            AuthFailureMessageMapper.mapToMessage(failure);
        setState(() {
          _error = message;
          _isStartingAfresh = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      },
      (_) async {
        final authNotifier = ref.read(authNotifierProvider.notifier);
        await authNotifier.logout();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account deleted. You can sign up again when you\'re ready.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 400));

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (context) => const AuthScreen(isSignIn: false),
          ),
          (route) => false,
        );
      },
    );
  }

  /// Show logout confirmation dialog
  Future<void> _showLogoutConfirmation() async {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Log out',
                  style: AppFonts.textStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.spacingMedium),
                Text(
                  'You can sign in again later to restore your account or start afresh.',
                  style: AppFonts.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.sectionMedium),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.outlined(
                        label: 'Cancel',
                        onPressed: () => Navigator.pop(context, false),
                        textColor: onSurfaceVariant,
                        isFullWidth: true,
                      ),
                    ),
                    SizedBox(width: AppSpacing.spacingMedium),
                    Expanded(
                      child: AppButton(
                        label: 'Log out',
                        onPressed: () => Navigator.pop(context, true),
                        variant: AppButtonVariant.secondary,
                        backgroundColor: AppTheme.primaryColor,
                        textColor: Colors.white,
                        isFullWidth: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await _handleLogout();
    }
  }

  /// Handle logout
  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
      _error = null;
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.logout();

      if (mounted) {
        // Navigate to welcome screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      AppLogger.e('Error during logout: $e', tag: 'GracePeriod');
      if (mounted) {
        setState(() {
          _error = 'Failed to logout. Please try again.';
          _isLoggingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final daysRemaining = widget.deletionStatus.daysRemaining;
    final canRestore = widget.deletionStatus.canRestore;
    final cardColor = AppTheme.cardBackground;
    final textColor = AppTheme.textPrimary;
    final subtitleColor = AppTheme.textSecondary;
    final borderColor = isDark
        ? AppTheme.borderColor.withValues(alpha: 0.2)
        : AppTheme.borderColor.withValues(alpha: 0.5);
    final mutedColor = isDark
        ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
        : AppTheme.textSecondary;

    // Grace period: use warning/amber tone for "time left" feel (like Budget Health Card)
    final accentColor = daysRemaining <= 7
        ? AppTheme.warningColor
        : AppTheme.primaryColor;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sectionLarge),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Main card (Budget Health Card–style)
                        Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: EdgeInsets.all(AppSpacing.cardPadding),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                              border: Border.all(color: borderColor, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.15 : 0.04,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header row: icon + title + days-left badge
                                Row(
                                  children: [
                                    Container(
                                      width: AppSpacing.iconContainerMedium,
                                      height: AppSpacing.iconContainerMedium,
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.schedule_rounded,
                                        color: accentColor,
                                        size: AppSpacing.iconSize,
                                      ),
                                    ),
                                    SizedBox(width: AppSpacing.spacingMedium),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Account scheduled for deletion',
                                            style: AppFonts.textStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: textColor,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Grace period · Restore or start afresh',
                                            style: AppFonts.textStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: subtitleColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$daysRemaining ${daysRemaining == 1 ? 'day' : 'days'}',
                                        style: AppFonts.textStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                // Subtitle
                                Text(
                                  'Your account is in the grace period. Restore it to keep your data, or start afresh to permanently delete and sign up again.',
                                  style: AppFonts.textStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: subtitleColor,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.sectionMedium),
                                // Restore (primary CTA)
                                if (canRestore) ...[
                                  AppButton(
                                    label: 'Restore account',
                                    onPressed: _isRestoring
                                        ? null
                                        : _showRestoreConfirmation,
                                    isLoading: _isRestoring,
                                    variant: AppButtonVariant.secondary,
                                    backgroundColor: AppTheme.successColor,
                                    textColor: Colors.white,
                                    isFullWidth: true,
                                  ),
                                  SizedBox(height: AppSpacing.spacingMedium),
                                ],
                                // Start afresh (outlined)
                                AppButton.outlined(
                                  label: 'Start afresh',
                                  onPressed: _isStartingAfresh
                                      ? null
                                      : _showStartAfreshConfirmation,
                                  isLoading: _isStartingAfresh,
                                  textColor: AppTheme.errorColor,
                                  borderColor:
                                      AppTheme.errorColor.withValues(alpha: 0.6),
                                  isFullWidth: true,
                                ),
                                if (_error != null) ...[
                                  SizedBox(height: AppSpacing.spacingMedium),
                                  Text(
                                    _error!,
                                    style: AppFonts.textStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.errorColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: AppSpacing.sectionLarge),

                        // Log out (text link, below card)
                        Center(
                          child: TextButton(
                            onPressed: _isLoggingOut
                                ? null
                                : _showLogoutConfirmation,
                            style: TextButton.styleFrom(
                              foregroundColor: mutedColor,
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.spacingSmall,
                                horizontal: AppSpacing.spacingMedium,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: _isLoggingOut
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        mutedColor,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Log out',
                                    style: AppFonts.textStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: mutedColor,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
