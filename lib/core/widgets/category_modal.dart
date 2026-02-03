import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_fonts.dart';
import '../theme/app_theme.dart';
import 'bottom_sheet_modal.dart';
import 'app_text_field.dart';
import '../../features/categories/data/repositories/category_repository.dart';
import '../../features/categories/presentation/providers/category_providers.dart';

/// A reusable modal for creating or editing categories
class CategoryModal extends ConsumerStatefulWidget {
  final CategoryModel?
  category; // If null, creates new category; if provided, edits
  final Function(CategoryModel)? onCategoryCreated;
  final Function(CategoryModel)? onCategoryUpdated;

  const CategoryModal({
    super.key,
    this.category,
    this.onCategoryCreated,
    this.onCategoryUpdated,
  });

  @override
  ConsumerState<CategoryModal> createState() => _CategoryModalState();
}

class _CategoryModalState extends ConsumerState<CategoryModal> {
  late TextEditingController _nameController;
  late String _selectedIcon;
  late String _selectedColor;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIcon = widget.category?.icon ?? 'category';
    _selectedColor = widget.category?.color ?? '#FF5722';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _availableIcons = [
    {'name': 'category', 'icon': Icons.category_rounded},
    {'name': 'restaurant', 'icon': Icons.restaurant_rounded},
    {'name': 'directions_car', 'icon': Icons.directions_car_rounded},
    {'name': 'shopping_bag', 'icon': Icons.shopping_bag_rounded},
    {'name': 'movie', 'icon': Icons.movie_rounded},
    {'name': 'receipt', 'icon': Icons.receipt_rounded},
    {'name': 'medical_services', 'icon': Icons.medical_services_rounded},
    {'name': 'school', 'icon': Icons.school_rounded},
    {'name': 'home', 'icon': Icons.home_rounded},
    {'name': 'flight', 'icon': Icons.flight_rounded},
    {'name': 'spa', 'icon': Icons.spa_rounded},
    {'name': 'card_giftcard', 'icon': Icons.card_giftcard_rounded},
    {'name': 'local_gas_station', 'icon': Icons.local_gas_station_rounded},
    {'name': 'fitness_center', 'icon': Icons.fitness_center_rounded},
    {'name': 'music_note', 'icon': Icons.music_note_rounded},
    {'name': 'sports_esports', 'icon': Icons.sports_esports_rounded},
    {'name': 'laptop', 'icon': Icons.laptop_rounded},
    {'name': 'phone', 'icon': Icons.phone_rounded},
    {'name': 'wifi', 'icon': Icons.wifi_rounded},
    {'name': 'bolt', 'icon': Icons.bolt_rounded},
    {'name': 'water_drop', 'icon': Icons.water_drop_rounded},
    {'name': 'local_parking', 'icon': Icons.local_parking_rounded},
    {'name': 'pets', 'icon': Icons.pets_rounded},
    {'name': 'child_care', 'icon': Icons.child_care_rounded},
    {'name': 'cake', 'icon': Icons.cake_rounded},
    {'name': 'coffee', 'icon': Icons.coffee_rounded},
    {'name': 'fastfood', 'icon': Icons.fastfood_rounded},
    {'name': 'local_bar', 'icon': Icons.local_bar_rounded},
    {'name': 'shopping_cart', 'icon': Icons.shopping_cart_rounded},
    {'name': 'store', 'icon': Icons.store_rounded},
    {'name': 'attach_money', 'icon': Icons.attach_money_rounded},
    {'name': 'account_balance', 'icon': Icons.account_balance_rounded},
    {'name': 'credit_card', 'icon': Icons.credit_card_rounded},
    {'name': 'savings', 'icon': Icons.savings_rounded},
    {'name': 'payments', 'icon': Icons.payments_rounded},
    {'name': 'work', 'icon': Icons.work_rounded},
    {'name': 'business', 'icon': Icons.business_rounded},
    {'name': 'apartment', 'icon': Icons.apartment_rounded},
    {'name': 'hotel', 'icon': Icons.hotel_rounded},
    {'name': 'beach_access', 'icon': Icons.beach_access_rounded},
    {'name': 'sports_soccer', 'icon': Icons.sports_soccer_rounded},
    {'name': 'sports_basketball', 'icon': Icons.sports_basketball_rounded},
    {'name': 'sports_tennis', 'icon': Icons.sports_tennis_rounded},
    {'name': 'directions_bike', 'icon': Icons.directions_bike_rounded},
    {'name': 'directions_bus', 'icon': Icons.directions_bus_rounded},
    {'name': 'train', 'icon': Icons.train_rounded},
    {'name': 'subway', 'icon': Icons.subway_rounded},
    {'name': 'book', 'icon': Icons.book_rounded},
    {'name': 'library_books', 'icon': Icons.library_books_rounded},
    {'name': 'theater_comedy', 'icon': Icons.theater_comedy_rounded},
    {'name': 'palette', 'icon': Icons.palette_rounded},
    {'name': 'camera_alt', 'icon': Icons.camera_alt_rounded},
    {'name': 'videocam', 'icon': Icons.videocam_rounded},
    {'name': 'headphones', 'icon': Icons.headphones_rounded},
    {'name': 'tv', 'icon': Icons.tv_rounded},
    {'name': 'gamepad', 'icon': Icons.gamepad_rounded},
    {'name': 'toys', 'icon': Icons.toys_rounded},
    {'name': 'local_pharmacy', 'icon': Icons.local_pharmacy_rounded},
    {'name': 'healing', 'icon': Icons.healing_rounded},
    {'name': 'favorite', 'icon': Icons.favorite_rounded},
    {'name': 'star', 'icon': Icons.star_rounded},
    {'name': 'celebration', 'icon': Icons.celebration_rounded},
    {'name': 'restaurant_menu', 'icon': Icons.restaurant_menu_rounded},
    {'name': 'room_service', 'icon': Icons.room_service_rounded},
    {'name': 'dining', 'icon': Icons.dining_rounded},
    {'name': 'local_cafe', 'icon': Icons.local_cafe_rounded},
    {'name': 'icecream', 'icon': Icons.icecream_rounded},
    {'name': 'local_drink', 'icon': Icons.local_drink_rounded},
    {'name': 'local_pizza', 'icon': Icons.local_pizza_rounded},
    {'name': 'nightlife', 'icon': Icons.nightlife_rounded},
    {'name': 'wine_bar', 'icon': Icons.wine_bar_rounded},
    {'name': 'local_movies', 'icon': Icons.local_movies_rounded},
    {'name': 'live_tv', 'icon': Icons.live_tv_rounded},
    {'name': 'radio', 'icon': Icons.radio_rounded},
    {'name': 'podcasts', 'icon': Icons.podcasts_rounded},
    {'name': 'audiotrack', 'icon': Icons.audiotrack_rounded},
    {'name': 'library_music', 'icon': Icons.library_music_rounded},
    {'name': 'play_circle', 'icon': Icons.play_circle_rounded},
    {'name': 'movie_creation', 'icon': Icons.movie_creation_rounded},
    {'name': 'photo_camera', 'icon': Icons.photo_camera_rounded},
    {'name': 'photo_library', 'icon': Icons.photo_library_rounded},
    {'name': 'brush', 'icon': Icons.brush_rounded},
    {'name': 'color_lens', 'icon': Icons.color_lens_rounded},
    {'name': 'auto_awesome', 'icon': Icons.auto_awesome_rounded},
    {'name': 'diamond', 'icon': Icons.diamond_rounded},
    {'name': 'watch', 'icon': Icons.watch_rounded},
    {'name': 'schedule', 'icon': Icons.schedule_rounded},
    {'name': 'event', 'icon': Icons.event_rounded},
    {'name': 'calendar_today', 'icon': Icons.calendar_today_rounded},
    {'name': 'confirmation_number', 'icon': Icons.confirmation_number_rounded},
    {'name': 'local_activity', 'icon': Icons.local_activity_rounded},
    {'name': 'sports_motorsports', 'icon': Icons.sports_motorsports_rounded},
    {'name': 'sports_volleyball', 'icon': Icons.sports_volleyball_rounded},
    {'name': 'sports_baseball', 'icon': Icons.sports_baseball_rounded},
    {'name': 'sports_football', 'icon': Icons.sports_football_rounded},
    {'name': 'sports_golf', 'icon': Icons.sports_golf_rounded},
    {'name': 'pool', 'icon': Icons.pool_rounded},
    {'name': 'golf_course', 'icon': Icons.golf_course_rounded},
    {'name': 'directions_walk', 'icon': Icons.directions_walk_rounded},
    {'name': 'directions_run', 'icon': Icons.directions_run_rounded},
    {'name': 'hiking', 'icon': Icons.hiking_rounded},
    {'name': 'luggage', 'icon': Icons.luggage_rounded},
  ];

  final List<String> _availableColors = [
    '#FF5722',
    '#2196F3',
    '#4CAF50',
    '#FF9800',
    '#9C27B0',
    '#F44336',
    '#00BCD4',
    '#8BC34A',
    '#FFC107',
    '#E91E63',
    '#3F51B5',
    '#009688',
    '#795548',
    '#607D8B',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Name
          AppTextField(
            controller: _nameController,
            label: 'Category name',
            hintText: 'Enter category name',
            useDarkStyle: isDark,
            autofocus: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a category name';
              }
              return null;
            },
          ),
        SizedBox(height: 16),
        // Icon Selection
        Text(
          'Select Icon',
          style: AppFonts.textStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _availableIcons.length,
            separatorBuilder: (context, index) => SizedBox(width: 10),
            itemBuilder: (context, index) {
              final iconData = _availableIcons[index];
              final isSelected = _selectedIcon == iconData['name'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIcon = iconData['name'] as String;
                  });
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.warningColor
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : AppTheme.borderColor.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.warningColor
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.2)
                                : AppTheme.borderColor),
                      width: isSelected ? 2 : 1.5,
                    ),
                  ),
                  child: Icon(
                    iconData['icon'] as IconData,
                    color: isSelected
                        ? Colors.black
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.8)
                              : AppTheme.textPrimary),
                    size: 22,
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 16),
        // Color Selection
        Text(
          'Select Color',
          style: AppFonts.textStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _availableColors.map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.white,
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 24),
        // Action Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) {
                return;
              }

              try {
                final repository = ref.read(categoryRepositoryProvider);

                if (widget.category == null) {
                  // Create new category
                  final newCategory = await repository.createCategory(
                    name: _nameController.text.trim(),
                    icon: _selectedIcon,
                    color: _selectedColor,
                  );

                  // Invalidate categories provider to refresh list
                  ref.invalidate(categoriesProvider);

                  if (!mounted) return;
                  Navigator.pop(context);
                  widget.onCategoryCreated?.call(newCategory);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Category "${newCategory.name}" created successfully',
                      ),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                } else {
                  // Update existing category
                  final updatedCategory = await repository.updateCategory(
                    id: widget.category!.id,
                    name: _nameController.text.trim(),
                    icon: _selectedIcon,
                    color: _selectedColor,
                  );

                  // Invalidate categories provider to refresh list
                  ref.invalidate(categoriesProvider);

                  if (!mounted) return;
                  Navigator.pop(context);
                  widget.onCategoryUpdated?.call(updatedCategory);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Category "${updatedCategory.name}" updated successfully',
                      ),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to ${widget.category == null ? 'create' : 'update'} category: $e',
                    ),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
            child: Text(
              widget.category == null ? 'Create' : 'Update',
              style: AppFonts.textStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Helper function to show the category modal
void showCategoryModal({
  required BuildContext context,
  CategoryModel? category,
  Function(CategoryModel)? onCategoryCreated,
  Function(CategoryModel)? onCategoryUpdated,
}) {
  BottomSheetModal.show(
    context: context,
    title: category == null ? 'Create Category' : 'Edit Category',
    subtitle: category == null
        ? 'Add a new category for your expenses'
        : 'Update category details',
    child: CategoryModal(
      category: category,
      onCategoryCreated: onCategoryCreated,
      onCategoryUpdated: onCategoryUpdated,
    ),
  );
}
