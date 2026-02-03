import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/user_info_provider.dart';
import '../../../auth/presentation/screens/account_grace_period_screen.dart';
import '../../../auth/presentation/mappers/auth_failure_message_mapper.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppTheme.screenBackgroundColor;

    // Use centralized user info provider - eliminates duplicate logic
    final userInfo = ref.watch(currentUserInfoProvider);
    final userName = userInfo.displayName;
    final userEmail = userInfo.email;
    final userPhotoUrl = userInfo.photoUrl;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(),
        title: Text(
          'Profile',
          style: AppFonts.textStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          0,
          AppSpacing.screenHorizontal,
          AppSpacing.bottomNavPadding,
        ),
        children: [
          SizedBox(height: 16),
          // Profile Card
          _buildProfileCard(
            context: context,
            userName: userName,
            userEmail: userEmail,
            userPhotoUrl: userPhotoUrl,
            isDark: isDark,
          ),
          SizedBox(height: 8),
          _buildEditHint(isDark),
          SizedBox(height: 16),
          // Account (read-only)
          _buildSectionTitle('Account', isDark),
          SizedBox(height: 8),
          _buildGroupedTiles(
            context: context,
            isDark: isDark,
            tiles: [
              _ProfileTile(
                icon: Icons.person_outline_rounded,
                iconBg: AppTheme.primaryColor,
                title: 'Name',
                subtitle: userName,
                onTap: null, // read-only
              ),
              _ProfileTile(
                icon: Icons.email_outlined,
                iconBg: const Color(0xFF2563EB),
                title: 'Email',
                subtitle: userEmail,
                onTap: null, // read-only
              ),
            ],
          ),
          SizedBox(height: 16),
          // Account Management
          _buildSectionTitle('Account Management', isDark),
          SizedBox(height: 8),
          _buildGroupedTiles(
            context: context,
            isDark: isDark,
            tiles: [
              _ProfileTile(
                icon: Icons.delete_outline_rounded,
                iconBg: AppTheme.errorColor,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account',
                onTap: () {
                  _showDeleteAccountDialog(context, ref);
                },
              ),
            ],
          ),
          SizedBox(height: 16),
          // Logout Button
          _buildLogoutButton(context, ref, isDark),
        ],
      ),
    );
  }

  /// Single source of truth: "Tap to edit" hint so users know where to update profile.
  Widget _buildEditHint(bool isDark) {
    final subtitleColor = AppTheme.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'Tap the card above to edit your name and photo',
        style: AppFonts.textStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark
              ? Colors.white.withValues(alpha: 0.5)
              : subtitleColor.withValues(alpha: 0.8),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildProfileCard({
    required BuildContext context,
    required String userName,
    required String userEmail,
    required String? userPhotoUrl,
    required bool isDark,
  }) {
    final cardColor = AppTheme.cardBackground;
    final textColor = AppTheme.textPrimary;
    final subtitleColor = AppTheme.textSecondary;
    final borderColor = isDark
        ? AppTheme.borderColor.withValues(alpha: 0.2)
        : AppTheme.borderColor.withValues(alpha: 0.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showEditProfileModal(context, userName, userEmail),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
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
          child: Row(
            children: [
              // Avatar
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: userPhotoUrl != null
                          ? Image.network(
                              userPhotoUrl,
                              fit: BoxFit.cover,
                              cacheWidth: 160,
                              cacheHeight: 160,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildDefaultAvatar(),
                            )
                          : _buildDefaultAvatar(),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cardColor,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: AppSpacing.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: AppFonts.textStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      userEmail,
                      style: AppFonts.textStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: subtitleColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppTheme.primaryColor.withValues(alpha: 0.2),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: AppTheme.primaryColor,
          size: 44,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    final subtitleColor = AppTheme.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        title.toUpperCase(),
        style: AppFonts.textStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark
              ? Colors.white.withValues(alpha: 0.6)
              : subtitleColor.withValues(alpha: 0.9),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildGroupedTiles({
    required BuildContext context,
    required bool isDark,
    required List<_ProfileTile> tiles,
  }) {
    final cardColor = AppTheme.cardBackground;
    final textColor = AppTheme.textPrimary;
    final subtitleColor = AppTheme.textSecondary;
    final borderColor = isDark
        ? AppTheme.borderColor.withValues(alpha: 0.2)
        : AppTheme.borderColor.withValues(alpha: 0.5);
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppTheme.borderColor.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        children: tiles.asMap().entries.map((entry) {
          final index = entry.key;
          final tile = entry.value;
          final isLast = index == tiles.length - 1;

          final isReadOnly = tile.onTap == null;

          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: tile.onTap,
                  borderRadius: BorderRadius.vertical(
                    top: index == 0
                        ? Radius.circular(AppSpacing.radiusLarge)
                        : Radius.zero,
                    bottom: isLast
                        ? Radius.circular(AppSpacing.radiusLarge)
                        : Radius.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.cardPadding,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: AppSpacing.iconContainerMedium,
                          height: AppSpacing.iconContainerMedium,
                          decoration: BoxDecoration(
                            color: tile.iconBg.withValues(
                              alpha: isDark ? 0.2 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            tile.icon,
                            color: tile.iconBg,
                            size: AppSpacing.iconSize,
                          ),
                        ),
                        SizedBox(width: AppSpacing.spacingMedium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tile.title,
                                style: AppFonts.textStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                tile.subtitle,
                                style: AppFonts.textStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: subtitleColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (!isReadOnly)
                          Icon(
                            Icons.chevron_right_rounded,
                            color: subtitleColor,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: dividerColor,
                  indent: AppSpacing.cardPadding +
                      AppSpacing.iconContainerMedium +
                      AppSpacing.spacingMedium,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref, bool isDark) {
    final borderColor = AppTheme.errorColor.withValues(alpha: 0.3);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLogoutDialog(context, ref),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: AppSpacing.cardPadding,
          ),
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: AppTheme.errorColor,
                size: AppSpacing.iconSize,
              ),
              SizedBox(width: AppSpacing.spacingMedium),
              Text(
                'Logout',
                style: AppFonts.textStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.errorColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileModal(
    BuildContext context,
    String currentName,
    String currentEmail,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditProfileBottomSheet(
        currentName: currentName,
        currentEmail: currentEmail,
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DeleteAccountBottomSheet(ref: ref),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dialogBgColor = isDark ? AppTheme.darkCardBackground : Colors.white;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: dialogBgColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: dialogBgColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Logout',
                  style: AppFonts.textStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to logout?',
                  style: AppFonts.textStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: AppFonts.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () async {
                        // Close dialog first
                        Navigator.pop(context);
                        
                        // Trigger logout - navigation is handled by authNavigationProvider
                        await ref.read(authNotifierProvider.notifier).logout();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Logout',
                        style: AppFonts.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.red,
                        ),
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
  }
}

/// Edit Profile bottom modal — single place to update name and photo.
class _EditProfileBottomSheet extends StatefulWidget {
  final String currentName;
  final String currentEmail;

  const _EditProfileBottomSheet({
    required this.currentName,
    required this.currentEmail,
  });

  @override
  State<_EditProfileBottomSheet> createState() =>
      _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends State<_EditProfileBottomSheet> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSave() {
    // TODO: Implement profile update (name, photo)
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile update coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : AppTheme.textSecondary;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : AppTheme.borderColor;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: icon + title + close
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            size: 26,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Profile',
                                style: AppFonts.textStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Update your name and photo',
                                style: AppFonts.textStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: subtitleColor,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Name field
                    Text(
                      'Name',
                      style: AppFonts.textStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: AppFonts.textStyle(
                        fontSize: 16,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Your name',
                        hintStyle: AppFonts.textStyle(
                          fontSize: 16,
                          color: subtitleColor,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : AppTheme.borderColor.withValues(alpha: 0.3),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Email (read-only)
                    Text(
                      'Email',
                      style: AppFonts.textStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : AppTheme.borderColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        widget.currentEmail,
                        style: AppFonts.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Email cannot be changed',
                      style: AppFonts.textStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Save
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: AppFonts.textStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Cancel
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: textColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppFonts.textStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: subtitleColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// World-class Delete Account Bottom Sheet
///
/// Features:
/// - Clean bottom modal design
/// - Clear warning about data loss
/// - 30-day grace period notice
/// - Type "DELETE" to confirm (prevents accidents)
/// - Smooth loading states
/// - Proper error handling
class _DeleteAccountBottomSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _DeleteAccountBottomSheet({required this.ref});

  @override
  ConsumerState<_DeleteAccountBottomSheet> createState() =>
      _DeleteAccountBottomSheetState();
}

class _DeleteAccountBottomSheetState extends ConsumerState<_DeleteAccountBottomSheet> {
  final _confirmController = TextEditingController();
  bool _isDeleting = false;
  String? _error;

  bool get _canDelete => _confirmController.text.toUpperCase() == 'DELETE';

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    if (!_canDelete || _isDeleting) return;

    setState(() {
      _isDeleting = true;
      _error = null;
    });

    try {
      final deleteAccountUseCase = widget.ref.read(deleteAccountUseCaseProvider);
      final result = await deleteAccountUseCase();

      result.fold(
        (failure) {
          if (mounted) {
            setState(() {
              _isDeleting = false;
              _error = AuthFailureMessageMapper.mapToMessage(failure);
            });
          }
        },
        (deletionResult) {
          if (mounted) {
            // Close the bottom sheet
            Navigator.pop(context);

            // Navigate to grace period screen
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => AccountGracePeriodScreen(
                  deletionStatus: AccountDeletionStatus(
                    deletedAt: DateTime.now(),
                    recoveryDeadline: deletionResult.recoveryDeadline ??
                        DateTime.now().add(const Duration(days: 30)),
                    daysRemaining: deletionResult.daysRemaining ?? 30,
                    canRestore: true,
                    canStartAfresh: true,
                    status: deletionResult.status,
                  ),
                ),
              ),
              (route) => false, // Remove all previous routes
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _error = 'Failed to delete account. Please try again or contact support.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon and title
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.delete_forever_rounded,
                            size: 26,
                            color: AppTheme.errorColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delete Account',
                                style: AppFonts.textStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : AppTheme.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'This action cannot be undone',
                                style: AppFonts.textStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Close button
                        IconButton(
                          onPressed: _isDeleting ? null : () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : AppTheme.textSecondary,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Grace period notice
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.primaryColor.withValues(alpha: 0.1)
                            : AppTheme.primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.restore_rounded,
                            size: 20,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You have 30 days to restore your account before all data is permanently deleted.',
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
                    ),

                    const SizedBox(height: 16),

                    // What gets deleted
                    Text(
                      'What will be deleted:',
                      style: AppFonts.textStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDeleteItem('All expenses, transactions & receipts', isDark),
                    _buildDeleteItem('Budgets, categories & preferences', isDark),
                    _buildDeleteItem('Reports, summaries & insights', isDark),

                    const SizedBox(height: 20),

                    // Confirmation input
                    Text(
                      'Type DELETE to confirm:',
                      style: AppFonts.textStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: _confirmController,
                      onChanged: (_) => setState(() {}),
                      enabled: !_isDeleting,
                      style: AppFonts.textStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _canDelete
                            ? AppTheme.errorColor
                            : (isDark ? Colors.white : AppTheme.textPrimary),
                        letterSpacing: 4,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'DELETE',
                        hintStyle: AppFonts.textStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.2)
                              : AppTheme.textSecondary.withValues(alpha: 0.3),
                          letterSpacing: 4,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : AppTheme.borderColor.withValues(alpha: 0.3),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _canDelete
                                ? AppTheme.errorColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _canDelete
                                ? AppTheme.errorColor
                                : AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),

                    // Error message
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 16,
                              color: AppTheme.errorColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: AppFonts.textStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Delete button (full width, prominent)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _canDelete && !_isDeleting
                            ? _handleDelete
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppTheme.borderColor.withValues(alpha: 0.5),
                          disabledForegroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : AppTheme.textSecondary.withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: _canDelete ? 0 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isDeleting
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: LoadingSpinnerVariants.white(
                                  size: 20,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Delete My Account',
                                style: AppFonts.textStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Cancel button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _isDeleting
                            ? null
                            : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? Colors.white
                              : AppTheme.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppFonts.textStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom safe area padding
              SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.remove_circle_outline_rounded,
            size: 16,
            color: AppTheme.errorColor.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppFonts.textStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  /// Null = read-only row (no chevron, no tap).
  final VoidCallback? onTap;

  _ProfileTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
}
