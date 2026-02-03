import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/pre_app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import 'welcome_screen.dart';

/// Notification Permission Screen for onboarding
///
/// Requests notification permissions during onboarding with a friendly explanation.
class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _navigateToWelcome() {
    HapticFeedback.mediumImpact();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const WelcomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Future<void> _requestPermission() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isRequesting = true;
    });

    try {
      final status = await Permission.notification.request();

      if (!mounted) return;

      // Navigate regardless of permission result
      // User can always enable later in settings
      _navigateToWelcome();
    } catch (e) {
      if (!mounted) return;
      _navigateToWelcome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Block back navigation - users should complete or skip notification permission
      },
      child: Semantics(
        label: 'Notification Permission - Enable reminders and alerts',
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(gradient: PreAppColors.authGradient),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Column(
              children: [
                // Skip button
                Padding(
                  padding: EdgeInsets.only(top: 16.scaledVertical(context)),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedBuilder(
                      animation: _fadeController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: TextButton(
                            onPressed: _isRequesting ? null : _navigateToWelcome,
                            child: Text(
                              'Skip',
                              style: AppFonts.textStyle(
                                fontSize: 15.scaledText(context),
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Main content
                Expanded(
                  child: AnimatedBuilder(
                    animation: _fadeController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Illustration
                            Container(
                              width: 160.scaled(context),
                              height: 160.scaled(context),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Decorative elements
                                  Positioned(
                                    top: 20.scaled(context),
                                    right: 20.scaled(context),
                                    child: Container(
                                      width: 24.scaled(context),
                                      height: 24.scaled(context),
                                      decoration: BoxDecoration(
                                        color: PreAppColors.warningColor
                                            .withValues(alpha: 0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.star_rounded,
                                        size: 14.scaled(context),
                                        color: PreAppColors.warningColor,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 25.scaled(context),
                                    left: 18.scaled(context),
                                    child: Container(
                                      width: 20.scaled(context),
                                      height: 20.scaled(context),
                                      decoration: BoxDecoration(
                                        color: PreAppColors.primaryColor
                                            .withValues(alpha: 0.3),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  // Main icon
                                  Container(
                                    width: 88.scaled(context),
                                    height: 88.scaled(context),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          PreAppColors.primaryColor,
                                          PreAppColors.primaryColor
                                              .withValues(alpha: 0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        28.scaled(context),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: PreAppColors.primaryColor
                                              .withValues(alpha: 0.4),
                                          blurRadius: 24.scaled(context),
                                          offset: Offset(0, 10.scaled(context)),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.notifications_rounded,
                                      size: 44.scaled(context),
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 48.scaledVertical(context)),

                            // Title
                            Text(
                              'Stay on Track',
                              textAlign: TextAlign.center,
                              style: AppFonts.textStyle(
                                fontSize: 28.scaledText(context),
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'With Reminders',
                              textAlign: TextAlign.center,
                              style: AppFonts.textStyle(
                                fontSize: 28.scaledText(context),
                                fontWeight: FontWeight.w700,
                                color: PreAppColors.primaryColor,
                                letterSpacing: -0.5,
                              ),
                            ),

                            SizedBox(height: 20.scaledVertical(context)),

                            // Description
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.scaled(context),
                              ),
                              child: Text(
                                'Get gentle reminders to log your expenses and weekly insights to help you stay on budget.',
                                textAlign: TextAlign.center,
                                style: AppFonts.textStyle(
                                  fontSize: 16.scaledText(context),
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  height: 1.5,
                                ),
                              ),
                            ),

                            SizedBox(height: 40.scaledVertical(context)),

                            // Benefits
                            _BenefitItem(
                              icon: Icons.access_time_rounded,
                              text: 'Daily expense reminders',
                            ),
                            SizedBox(height: 12.scaledVertical(context)),
                            _BenefitItem(
                              icon: Icons.insights_rounded,
                              text: 'Weekly spending summaries',
                            ),
                            SizedBox(height: 12.scaledVertical(context)),
                            _BenefitItem(
                              icon: Icons.savings_rounded,
                              text: 'Budget alerts when needed',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Buttons
                Padding(
                  padding: EdgeInsets.only(bottom: 32.scaledVertical(context)),
                  child: AnimatedBuilder(
                    animation: _fadeController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Column(
                          children: [
                            // Enable button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isRequesting ? null : _requestPermission,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: PreAppColors.warningColor,
                                  foregroundColor: Colors.black,
                                  padding: EdgeInsets.symmetric(
                                    vertical: 18.scaledVertical(context),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      14.scaled(context),
                                    ),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isRequesting
                                    ? SizedBox(
                                        width: 24.scaled(context),
                                        height: 24.scaled(context),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : Text(
                                        'Enable Notifications',
                                        style: AppFonts.textStyle(
                                          fontSize: 17.scaledText(context),
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(height: 12.scaledVertical(context)),

                            // Maybe later text
                            Text(
                              'You can always change this in settings',
                              style: AppFonts.textStyle(
                                fontSize: 13.scaledText(context),
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
        ),
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28.scaled(context),
          height: 28.scaled(context),
          decoration: BoxDecoration(
            color: PreAppColors.successColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16.scaled(context),
            color: PreAppColors.successColor,
          ),
        ),
        SizedBox(width: 12.scaled(context)),
        Text(
          text,
          style: AppFonts.textStyle(
            fontSize: 15.scaledText(context),
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
