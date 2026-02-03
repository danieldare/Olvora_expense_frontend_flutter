import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/category_icon_utils.dart';
import 'loading_spinner.dart';
import '../../features/categories/presentation/providers/category_providers.dart';
import '../../features/categories/data/repositories/category_repository.dart';

/// A reusable horizontal scrollable category selection widget
///
/// Features:
/// - Horizontal scrollable list of categories
/// - Optional "Add Category" button
/// - Optional "None" option
/// - Selection state management
/// - Loading and error states
/// - Auto-scrolls to selected category
class CategorySelectionWidget extends ConsumerStatefulWidget {
  final CategoryModel? selectedCategory;
  final ValueChanged<CategoryModel?> onCategorySelected;
  final VoidCallback? onAddCategory;
  final bool showAddButton;
  final bool showNoneOption;
  final double height;
  final double itemWidth;
  final Color? selectedColor;
  final Color? textColor;

  const CategorySelectionWidget({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.onAddCategory,
    this.showAddButton = true,
    this.showNoneOption = false,
    this.height = 110,
    this.itemWidth = 90,
    this.selectedColor,
    this.textColor,
  });

  @override
  ConsumerState<CategorySelectionWidget> createState() =>
      _CategorySelectionWidgetState();
}

class _CategorySelectionWidgetState
    extends ConsumerState<CategorySelectionWidget> {
  final ScrollController _scrollController = ScrollController();
  CategoryModel? _previousSelectedCategory;
  List<CategoryModel>? _cachedCategories;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedCategory(List<CategoryModel> categories) {
    if (widget.selectedCategory == null) return;
    if (_previousSelectedCategory?.id == widget.selectedCategory?.id) return;

    _previousSelectedCategory = widget.selectedCategory;

    // Calculate the index of the selected category
    int selectedIndex = -1;
    for (int i = 0; i < categories.length; i++) {
      if (categories[i].id == widget.selectedCategory?.id) {
        selectedIndex = i;
        break;
      }
    }

    if (selectedIndex == -1) return;

    // Adjust index based on showAddButton and showNoneOption
    int displayIndex = selectedIndex;
    if (widget.showAddButton) displayIndex++;
    if (widget.showNoneOption) displayIndex++;

    // Calculate scroll position
    final itemWidth = widget.itemWidth;
    final separatorWidth = 2.0;
    final scrollPosition = (displayIndex * (itemWidth + separatorWidth)) -
        (MediaQuery.of(context).size.width / 2) +
        (itemWidth / 2);

    // Scroll to position after a short delay to ensure the list is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          scrollPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF111827) : Colors.white;
    final categoriesAsync = ref.watch(categoriesProvider);
    final defaultSelectedColor = widget.selectedColor ?? AppTheme.warningColor;
    final defaultTextColor =
        widget.textColor ??
        (isDark ? Colors.white.withValues(alpha: 0.9) : AppTheme.textPrimary);

    return categoriesAsync.when(
      data: (categories) {
        // Cache categories for smooth transitions
        if (categories.isNotEmpty) {
          _cachedCategories = categories;
        }

        // Use cached categories if available during transition
        final displayCategories = _cachedCategories ?? categories;

        if (categories.isEmpty && _cachedCategories == null) {
          return Container(
            height: widget.height,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppTheme.borderColor,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                'No categories available',
                style: AppFonts.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        }

        if (displayCategories.isEmpty) {
          // Show cached data or loading if we have cached data
          if (_cachedCategories != null && _cachedCategories!.isNotEmpty) {
            return _buildCategoryList(_cachedCategories!, isDark, defaultSelectedColor, defaultTextColor);
          }
          return Container(
            height: widget.height,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppTheme.borderColor,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                'No categories available',
                style: AppFonts.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        }

        // Scroll to selected category
        _scrollToSelectedCategory(displayCategories);

        // Build category list with fade transition
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: _buildCategoryList(
            displayCategories,
            isDark,
            defaultSelectedColor,
            defaultTextColor,
          ),
        );
      },
      loading: () {
        // Show cached categories if available, otherwise show loading spinner
        if (_cachedCategories != null && _cachedCategories!.isNotEmpty) {
          return AnimatedOpacity(
            opacity: 0.7,
            duration: const Duration(milliseconds: 200),
            child: _buildCategoryList(
              _cachedCategories!,
              isDark,
              defaultSelectedColor,
              defaultTextColor,
            ),
          );
        }

        // Loading state without background container
        return SizedBox(
          height: widget.height,
          child: Center(
            child: LoadingSpinner(
              size: 20,
              color: defaultSelectedColor,
              strokeWidth: 2.5,
            ),
          ),
        );
      },
      error: (error, stack) => Container(
        height: widget.height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to load categories',
                    style: AppFonts.textStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                // Retry by invalidating the provider
                ref.invalidate(categoriesProvider);
              },
              icon: Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                'Retry',
                style: AppFonts.textStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build category list widget
  Widget _buildCategoryList(
    List<CategoryModel> categories,
    bool isDark,
    Color defaultSelectedColor,
    Color defaultTextColor,
  ) {
    // Calculate item count
    int itemCount = categories.length;
    if (widget.showAddButton) itemCount++;
    if (widget.showNoneOption) itemCount++;

    return SizedBox(
      height: widget.height,
      key: ValueKey('categories_${categories.length}'),
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        physics: const BouncingScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (context, index) => SizedBox(width: 2),
        itemBuilder: (context, index) {
          int categoryIndex = index;

          // Add Category button
          if (widget.showAddButton) {
            if (index == 0) {
              return _buildAddCategoryButton(
                context,
                isDark,
                defaultTextColor,
              );
            }
            categoryIndex--;
          }

          // None option
          if (widget.showNoneOption) {
            if (categoryIndex == 0) {
              return _buildNoneOption(
                context,
                isDark,
                defaultSelectedColor,
                defaultTextColor,
              );
            }
            categoryIndex--;
          }

          // Category items
          final category = categories[categoryIndex];
          return _buildCategoryItem(
            context,
            category,
            isDark,
            defaultSelectedColor,
            defaultTextColor,
          );
        },
      ),
    );
  }

  Widget _buildAddCategoryButton(
    BuildContext context,
    bool isDark,
    Color textColor,
  ) {
    return GestureDetector(
      onTap: widget.onAddCategory,
      child: Container(
        width: widget.itemWidth,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.1),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Icon(Icons.add_rounded, color: textColor, size: 24),
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 32,
              width: double.infinity,
              child: Center(
                child: Text(
                  'Add',
                  style: AppFonts.textStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoneOption(
    BuildContext context,
    bool isDark,
    Color selectedColor,
    Color textColor,
  ) {
    final isSelected = widget.selectedCategory == null;
    return AnimatedScale(
      scale: isSelected ? 1.05 : 0.96,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: () => widget.onCategorySelected(null),
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: widget.itemWidth,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? selectedColor
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? null
                    : Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.1),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: selectedColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.block_rounded,
                color: isSelected
                    ? Colors.white
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : textColor),
                size: 22,
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: Center(
                child: Text(
                  'None',
                  style: AppFonts.textStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? selectedColor : textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
    BuildContext context,
    CategoryModel category,
    bool isDark,
    Color selectedColor,
    Color textColor,
  ) {
    final isSelected = widget.selectedCategory?.id == category.id;
    final categoryColor = Color(
      int.parse(category.color.replaceFirst('#', '0xFF')),
    );

    return AnimatedScale(
      scale: isSelected ? 1.05 : 0.96,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: () => widget.onCategorySelected(category),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: widget.itemWidth,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? selectedColor
                      : categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: selectedColor, width: 2)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: selectedColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  CategoryIconUtils.getCategoryIconFromName(category.icon),
                  color: isSelected ? Colors.white : categoryColor,
                  size: 22,
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                height: 32,
                width: double.infinity,
                child: Center(
                  child: Text(
                    category.name,
                  style: AppFonts.textStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? selectedColor : textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
