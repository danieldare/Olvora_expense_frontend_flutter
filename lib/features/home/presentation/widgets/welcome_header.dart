import 'package:flutter/material.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';

class WelcomeHeader extends StatelessWidget {
  final String? userName;
  final String? userPhotoUrl;
  final int? notificationCount;

  const WelcomeHeader({
    super.key,
    this.userName,
    this.userPhotoUrl,
    this.notificationCount,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final displayName = userName ?? 'User';
    final textColor = context.textPrimary;
    final subtitleColor = context.textSecondary;

    // Compact layout: smaller avatar, tighter spacing, smaller fonts
    const double avatarSize = 32;
    const double avatarTextGap = 8;
    const double greetingNameGap = 2;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5D5C7),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: userPhotoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          userPhotoUrl!,
                          fit: BoxFit.cover,
                          cacheWidth: 72,
                          cacheHeight: 72,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDefaultAvatar(isDark, avatarSize),
                        ),
                      )
                    : _buildDefaultAvatar(isDark, avatarSize),
              ),
            ),
            SizedBox(width: avatarTextGap),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: AppFonts.textStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: greetingNameGap),
                Text(
                  displayName,
                  style: AppFonts.textStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
              // Refresh notification count when returning from notifications screen
              // Note: This requires the widget to be a ConsumerWidget or have access to ref
              // For now, the count will refresh automatically via the provider watch
            },
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCardBackground : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppTheme.borderColor.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.1 : 0.04,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppTheme.textPrimary,
                    size: AppSpacing.iconSizeSmall,
                  ),
                ),
                if (notificationCount != null && notificationCount! > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          width: 2.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          notificationCount! > 9
                              ? '9+'
                              : '$notificationCount',
                          style: AppFonts.textStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar(bool isDark, [double avatarSize = 36]) {
    final iconSize = avatarSize * 0.55;
    return Center(
      child: Icon(
        Icons.person_rounded,
        color: isDark
            ? Colors.white.withValues(alpha: 0.6)
            : AppTheme.textSecondary,
        size: iconSize,
      ),
    );
  }
}
