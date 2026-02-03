import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/category_modal.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../data/repositories/category_repository.dart';
import '../providers/category_providers.dart';

class ManageCategoriesScreen extends ConsumerStatefulWidget {
  /// When true, uses smaller padding, fonts, and icons for a denser list.
  final bool compact;

  const ManageCategoriesScreen({super.key, this.compact = true});

  @override
  ConsumerState<ManageCategoriesScreen> createState() =>
      _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState
    extends ConsumerState<ManageCategoriesScreen> {
  IconData _getCategoryIconFromName(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'food':
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'transport':
      case 'car':
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'entertainment':
      case 'movie':
        return Icons.movie_rounded;
      case 'shopping':
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'bills':
      case 'receipt':
        return Icons.receipt_rounded;
      case 'health':
      case 'medical':
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'local_hospital':
        return Icons.local_hospital_rounded;
      case 'education':
      case 'school':
        return Icons.school_rounded;
      case 'bolt':
      case 'electricity':
        return Icons.bolt_rounded;
      case 'home':
      case 'rent':
        return Icons.home_rounded;
      case 'wifi':
      case 'internet':
        return Icons.wifi_rounded;
      case 'security':
      case 'insurance':
        return Icons.security_rounded;
      case 'spa':
      case 'personal_care':
        return Icons.spa_rounded;
      case 'card_giftcard':
      case 'gifts':
        return Icons.card_giftcard_rounded;
      case 'flight':
      case 'travel':
        return Icons.flight_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  void _showCreateCategoryModal() {
    showCategoryModal(context: context);
  }

  void _showEditCategoryModal(CategoryModel category) {
    showCategoryModal(
      context: context,
      category: category,
    );
  }

  void _showDeleteConfirmation(CategoryModel category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.errorColor,
                size: 22,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Delete Category',
                style: AppFonts.textStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${category.name}"? This action cannot be undone.',
          style: AppFonts.textStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark
                ? Colors.white.withValues(alpha: 0.8)
                : AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.textSecondary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.errorColor, AppTheme.errorColor],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog

                try {
                  final repository = ref.read(categoryRepositoryProvider);
                  await repository.deleteCategory(category.id);

                  // Invalidate categories provider to refresh list
                  ref.invalidate(categoriesProvider);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Category "${category.name}" deleted'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete category: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Delete',
                  style: AppFonts.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
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
    final bgColor = AppTheme.screenBackgroundColor;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(),
        title: Text(
          'Manage Categories',
          style: AppFonts.textStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_rounded,
              color: isDark ? Colors.white : AppTheme.textPrimary,
              size: 24,
            ),
            onPressed: _showCreateCategoryModal,
          ),
          SizedBox(width: 8),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return EmptyStateWidget.large(
              icon: Icons.category_outlined,
              title: 'No Categories',
              subtitle: 'Tap the + button to create your first category',
              showIconContainer: true,
              iconColor: AppTheme.primaryColor,
            );
          }

          // Separate default and user categories
          final defaultCategories = categories
              .where((c) => c.isDefault)
              .toList();
          final userCategories = categories.where((c) => !c.isDefault).toList();

          // Combine all categories for a single list with separators
          final allCategories = [...userCategories, ...defaultCategories];

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              widget.compact ? 12 : 16,
              AppSpacing.screenHorizontal,
              AppSpacing.bottomNavPadding,
            ),
            itemCount: allCategories.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.16)
                  : AppTheme.borderColor.withValues(alpha: 0.55),
            ),
            itemBuilder: (context, index) {
              final category = allCategories[index];
              final isUserCategory = !category.isDefault;
              return _buildCategoryItem(
                category,
                isDark,
                compact: widget.compact,
                canEdit: isUserCategory,
                canDelete: isUserCategory,
              );
            },
          );
        },
        loading: () => Center(
          child: SizedBox(
            child: LoadingSpinner.medium(
              color: AppTheme.primaryColor,
              strokeWidth: 2.5,
            ),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: AppTheme.errorColor,
              ),
              SizedBox(height: 14),
              Text(
                'Failed to load categories',
                style: AppFonts.textStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.errorColor,
                ),
              ),
              SizedBox(height: 6),
              Text(
                error.toString(),
                style: AppFonts.textStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(categoriesProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: AppFonts.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
    CategoryModel category,
    bool isDark, {
    bool compact = true,
    required bool canEdit,
    required bool canDelete,
  }) {
    final categoryColor = Color(
      int.parse(category.color.replaceFirst('#', '0xFF')),
    );
    final itemPadding = compact ? 12.0 : 16.0;
    final iconSize = compact ? 20.0 : 24.0;
    final iconBoxWidth = compact ? 28.0 : 32.0;
    final titleFontSize = compact ? 14.0 : 15.0;
    final subtitleFontSize = compact ? 11.0 : 12.0;
    final gapHeight = compact ? 1.0 : 2.0;
    final horizontalGap = compact ? 10.0 : 12.0;
    final actionIconSize = compact ? 16.0 : 18.0;
    final actionMinSize = compact ? 32.0 : 36.0;
    final borderRadius = compact ? 10.0 : 12.0;

    return InkWell(
      onTap: canEdit ? () => _showEditCategoryModal(category) : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: itemPadding),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Row(
          children: [
            // Category Icon
            SizedBox(
              width: iconBoxWidth,
              child: Icon(
                _getCategoryIconFromName(category.icon),
                color: categoryColor,
                size: iconSize,
              ),
            ),
            SizedBox(width: horizontalGap),
            // Category Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.name,
                    style: AppFonts.textStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: gapHeight),
                  Text(
                    category.isDefault
                        ? 'System category'
                        : 'Created ${_formatDate(category.createdAt)}',
                    style: AppFonts.textStyle(
                      fontSize: subtitleFontSize,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Action Buttons
            if (canEdit || canDelete) ...[
              if (canEdit)
                IconButton(
                  icon: Icon(
                    Icons.edit_rounded,
                    size: actionIconSize,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : AppTheme.textSecondary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: actionMinSize,
                    minHeight: actionMinSize,
                  ),
                  onPressed: () => _showEditCategoryModal(category),
                ),
              if (canDelete)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: actionIconSize,
                    color: AppTheme.errorColor.withValues(alpha: 0.8),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: actionMinSize,
                    minHeight: actionMinSize,
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _showDeleteConfirmation(category);
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }
}
