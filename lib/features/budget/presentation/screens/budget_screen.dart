import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/models/currency.dart';
import '../widgets/budget_card.dart';
import '../widgets/budget_form_modal.dart';
import '../../../../core/widgets/bottom_sheet_modal.dart';
import '../../../../core/widgets/bottom_sheet_option_tile.dart';
import '../../domain/entities/budget_entity.dart';
import '../providers/budget_providers.dart';
import '../../data/dto/create_budget_dto.dart';
import '../../data/dto/update_budget_dto.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  /// When true, uses smaller padding, fonts, and spacing for a denser layout.
  final bool compact;

  const BudgetScreen({super.key, this.compact = true});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  String? _selectedGeneralBudgetId;
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Listen to scroll position to auto-select the center card
    _horizontalScrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _horizontalScrollController.removeListener(_onScroll);
    _horizontalScrollController.dispose();
    super.dispose();
  }

  /// Cleans up error messages to be more user-friendly
  String _cleanErrorMessage(String error) {
    final errorLower = error.toLowerCase();

    // Connection timeout errors
    if (errorLower.contains('timeout') ||
        errorLower.contains('connection took longer')) {
      return 'The request took too long. Please check your internet connection and try again.';
    }

    // Network errors
    if (errorLower.contains('network') ||
        errorLower.contains('connection') ||
        errorLower.contains('socket')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    // Server errors
    if (errorLower.contains('500') ||
        errorLower.contains('internal server error')) {
      return 'Server error. Please try again later.';
    }

    // Authentication errors
    if (errorLower.contains('401') ||
        errorLower.contains('unauthorized') ||
        errorLower.contains('authentication')) {
      return 'Authentication required. Please sign in again.';
    }

    // Parse errors
    if (errorLower.contains('parse') ||
        errorLower.contains('failed to parse')) {
      return 'Unable to process the response. Please try again.';
    }

    // Generic error - extract meaningful part if possible
    if (errorLower.contains('exception:')) {
      final parts = error.split(':');
      if (parts.length > 1) {
        final message = parts.sublist(1).join(':').trim();
        if (message.isNotEmpty && message.length < 100) {
          return message;
        }
      }
    }

    // If error is too long, provide generic message
    if (error.length > 150) {
      return 'Unable to load budgets. Please check your connection and try again.';
    }

    // Return cleaned error (remove technical prefixes)
    return error
        .replaceAll(RegExp(r'Exception:\s*'), '')
        .replaceAll(RegExp(r'Error:\s*'), '')
        .replaceAll(RegExp(r'Failed to fetch general budgets:\s*'), '')
        .replaceAll(RegExp(r'Failed to fetch category budgets:\s*'), '')
        .trim();
  }

  void _onScroll() {
    if (!_horizontalScrollController.hasClients || !mounted) return;

    // Use a debounce to avoid too many updates
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted || !_horizontalScrollController.hasClients) return;

      final generalBudgetsAsync = ref.read(generalBudgetsProvider);
      generalBudgetsAsync.whenData((generalBudgets) {
        if (!mounted) return;

        final activeGeneralBudgets =
            generalBudgets.where((b) => b.amount > 0).toList()..sort((a, b) {
              int getSortOrder(BudgetType type) {
                switch (type) {
                  case BudgetType.daily:
                    return 0;
                  case BudgetType.weekly:
                    return 1;
                  case BudgetType.monthly:
                    return 2;
                  case BudgetType.quarterly:
                    return 3;
                  case BudgetType.semiAnnual:
                    return 4;
                  case BudgetType.annual:
                    return 5;
                }
              }

              return getSortOrder(a.type).compareTo(getSortOrder(b.type));
            });

        if (activeGeneralBudgets.isEmpty) return;

        // Calculate which card is closest to center based on scroll position
        final scrollOffset = _horizontalScrollController.offset;
        final screenWidth = MediaQuery.of(context).size.width;
        final centerX = screenWidth / 2;
        final cardWidth = widget.compact ? 260.0 : 280.0;
        final cardSpacing = widget.compact ? 8.0 : 12.0;
        final padding = widget.compact ? 16.0 : 20.0;

        // Find the index of the card closest to center
        int closestIndex = 0;
        double minDistance = double.infinity;

        for (int i = 0; i < activeGeneralBudgets.length; i++) {
          // Left edge of each card
          final cardLeft = padding + (i * (cardWidth + cardSpacing));
          // Calculate the center of the card
          final cardCenter = cardLeft + (cardWidth / 2);
          // Account for scroll offset
          final visibleCardCenter = cardCenter - scrollOffset;
          // Calculate distance from screen center
          final distance = (visibleCardCenter - centerX).abs();

          if (distance < minDistance) {
            minDistance = distance;
            closestIndex = i;
          }
        }

        final newSelectedId = activeGeneralBudgets[closestIndex].id;
        if (newSelectedId != _selectedGeneralBudgetId && mounted) {
          setState(() {
            _selectedGeneralBudgetId = newSelectedId;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.screenBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          ScreenHeader(
            title: 'Budgets',
            subtitle: 'Track and manage your spending',
            trailing: _buildAddButton(),
          ),
          SizedBox(height: widget.compact ? 14 : 20),
          Expanded(child: _buildAllBudgets()),
        ],
      ),
    );
  }

  Widget _buildAllBudgets() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final generalBudgetsAsync = ref.watch(generalBudgetsProvider);
    final categoryBudgetsAsync = ref.watch(categoryBudgetsProvider);

    return generalBudgetsAsync.when(
      data: (generalBudgets) {
        return categoryBudgetsAsync.when(
          data: (categoryBudgets) {
            // Filter out budgets with 0 amount and sort by period type
            final activeGeneralBudgets =
                generalBudgets.where((b) => b.amount > 0).toList()..sort((
                  a,
                  b,
                ) {
                  // Sort order: daily (0), weekly (1), monthly (2), quarterly (3), semi-annual (4), annual (5)
                  int getSortOrder(BudgetType type) {
                    switch (type) {
                      case BudgetType.daily:
                        return 0;
                      case BudgetType.weekly:
                        return 1;
                      case BudgetType.monthly:
                        return 2;
                      case BudgetType.quarterly:
                        return 3;
                      case BudgetType.semiAnnual:
                        return 4;
                      case BudgetType.annual:
                        return 5;
                    }
                  }

                  return getSortOrder(a.type).compareTo(getSortOrder(b.type));
                });
            final activeCategoryBudgets = categoryBudgets
                .where((b) => b.amount > 0)
                .toList();

            if (activeGeneralBudgets.isEmpty && activeCategoryBudgets.isEmpty) {
              return _buildEmptyBudgets();
            }

            // Auto-select first general budget if none selected
            if (_selectedGeneralBudgetId == null &&
                activeGeneralBudgets.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _selectedGeneralBudgetId = activeGeneralBudgets.first.id;
                  });
                  // Scroll to center the first item
                  if (_horizontalScrollController.hasClients) {
                    _horizontalScrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  }
                }
              });
            }

            // Get selected general budget
            final selectedGeneral = activeGeneralBudgets
                .where((b) => b.id == _selectedGeneralBudgetId)
                .firstOrNull;

            // Get category budgets for selected general budget
            // Show all category budgets of the same period type as the selected general budget
            // Only exclude if explicitly marked as independent
            final selectedCategoryBudgets = selectedGeneral != null
                ? activeCategoryBudgets.where((b) {
                    // Must match the period type
                    if (b.type != selectedGeneral.type) return false;

                    // Exclude only if explicitly marked as independent
                    if (b.isIndependent == true) return false;

                    // Include all others (they belong to this base budget's period)
                    return true;
                  }).toList()
                : <BudgetEntity>[];

            // Independent category budgets (explicitly independent or no general budget for their period)
            final independentCategories = activeCategoryBudgets.where((b) {
              // Exclude category budgets that are shown under the selected base budget
              if (selectedGeneral != null &&
                  b.type == selectedGeneral.type &&
                  b.isIndependent != true) {
                return false; // These are shown under the base budget
              }

              // Show as independent if:
              // 1. Explicitly marked as independent, OR
              // 2. No general budget exists for this period type
              if (b.isIndependent == true) return true;

              final hasGeneralForPeriod = activeGeneralBudgets.any(
                (gb) => gb.type == b.type,
              );

              return !hasGeneralForPeriod;
            }).toList();

            return Column(
              children: [
                // Horizontal scrollable base budgets
                if (activeGeneralBudgets.isNotEmpty) ...[
                  SizedBox(
                    height: widget.compact ? 155 : 180,
                    child: ListView.builder(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.compact ? 16 : 20,
                      ),
                      itemCount: activeGeneralBudgets.length,
                      itemBuilder: (context, index) {
                        final budget = activeGeneralBudgets[index];
                        final isSelected =
                            budget.id == _selectedGeneralBudgetId;
                        final cardWidth = widget.compact ? 260.0 : 280.0;
                        final cardSpacing = widget.compact ? 8.0 : 12.0;
                        final horizontalPadding = widget.compact ? 16.0 : 20.0;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedGeneralBudgetId = budget.id;
                            });
                            // Smooth scroll to center the selected item
                            if (_horizontalScrollController.hasClients) {
                              final screenWidth = MediaQuery.of(
                                context,
                              ).size.width;
                              final targetOffset =
                                  (index * (cardWidth + cardSpacing)) -
                                  (screenWidth / 2) +
                                  (cardWidth / 2) +
                                  horizontalPadding;
                              _horizontalScrollController.animateTo(
                                targetOffset.clamp(
                                  0.0,
                                  _horizontalScrollController
                                      .position
                                      .maxScrollExtent,
                                ),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          },
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0.0,
                              end: isSelected ? 1.0 : 0.0,
                            ),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: 0.95 + (value * 0.05),
                                child: Container(
                                  width: cardWidth,
                                  margin: EdgeInsets.only(
                                    right:
                                        index == activeGeneralBudgets.length - 1
                                        ? 0
                                        : cardSpacing,
                                  ),
                                  child: _buildHorizontalBudgetCard(
                                    budget,
                                    isSelected,
                                    widget.compact,
                                    () => _showEditModal(context, budget),
                                    () {
                                      // General budgets ALWAYS show enhanced dialog with checkbox
                                      if (budget.category ==
                                          BudgetCategory.general) {
                                        final associatedBudgets =
                                            activeCategoryBudgets
                                                .where(
                                                  (b) =>
                                                      b.type == budget.type &&
                                                      b.isIndependent != true,
                                                )
                                                .toList();
                                        // Always show enhanced dialog for general budgets
                                        _showDeleteGeneralBudgetDialog(
                                          context,
                                          budget,
                                          associatedBudgets,
                                        );
                                      } else {
                                        // Category budgets show simple dialog
                                        _showDeleteConfirmationForHorizontalCard(
                                          context,
                                          budget,
                                          Theme.of(context).brightness ==
                                              Brightness.dark,
                                          () => _deleteBudget(budget.id),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  // Page indicator
                  SizedBox(height: widget.compact ? 12 : 16),
                  _buildPageIndicator(activeGeneralBudgets),
                  SizedBox(height: widget.compact ? 8 : 12),
                ],

                // Category budgets for selected general budget
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      if (selectedGeneral != null &&
                          selectedCategoryBudgets.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              widget.compact ? 16 : 20,
                              0,
                              widget.compact ? 16 : 20,
                              widget.compact ? 6 : 8,
                            ),
                            child: Text(
                              'Category Budgets',
                              style: AppFonts.textStyle(
                                fontSize: widget.compact ? 14 : 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : AppTheme.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: widget.compact ? 8 : 12),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: EdgeInsets.only(
                                left: widget.compact ? 16 : 20,
                                right: widget.compact ? 16 : 20,
                                bottom:
                                    index == selectedCategoryBudgets.length - 1
                                    ? (widget.compact ? 16 : 20)
                                    : (widget.compact ? 8 : 12),
                              ),
                              child: BudgetCard(
                                budget: selectedCategoryBudgets[index],
                                compact: widget.compact,
                                onEdit: () => _showEditModal(
                                  context,
                                  selectedCategoryBudgets[index],
                                ),
                                onAdd: null,
                                // Category budgets ALWAYS show simple dialog
                                onDelete: () {
                                  _showDeleteConfirmationForCategoryBudget(
                                    context,
                                    selectedCategoryBudgets[index],
                                  );
                                },
                                // For general budgets, show enhanced dialog
                                onDeleteWithCheck: (budget) {
                                  if (budget.category ==
                                      BudgetCategory.general) {
                                    final associatedBudgets =
                                        activeCategoryBudgets
                                            .where(
                                              (b) =>
                                                  b.type == budget.type &&
                                                  b.isIndependent != true,
                                            )
                                            .toList();
                                    // Always show enhanced dialog for general budgets
                                    _showDeleteGeneralBudgetDialog(
                                      context,
                                      budget,
                                      associatedBudgets,
                                    );
                                  } else {
                                    // Category budgets show simple dialog
                                    _showDeleteConfirmationForCategoryBudget(
                                      context,
                                      budget,
                                    );
                                  }
                                },
                              ),
                            ),
                            childCount: selectedCategoryBudgets.length,
                          ),
                        ),
                      ] else if (selectedGeneral != null &&
                          selectedCategoryBudgets.isEmpty) ...[
                        // Only show empty state if no category budgets exist for this base budget
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyStateWidget(
                            icon: Icons.layers_rounded,
                            title: 'No Category Budgets',
                            subtitle:
                                'Set spending limits for specific categories',
                            iconSize: 40,
                            size: EmptyStateSize.compact,
                            showIconContainer: true,
                            iconColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 24,
                            ),
                            action: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _showNewCategoryBudgetModal(context),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text(
                                  'Create Category Budget',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                  shadowColor: AppTheme.primaryColor.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Independent category budgets section
                      if (independentCategories.isNotEmpty) ...[
                        if (selectedGeneral != null)
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: widget.compact ? 24 : 32,
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: widget.compact ? 16 : 20,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: widget.compact ? 12 : 14,
                                    vertical: widget.compact ? 6 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : AppTheme.borderColor.withValues(
                                            alpha: 0.3,
                                          ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.15)
                                          : AppTheme.borderColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.1,
                                                )
                                              : AppTheme.primaryColor
                                                    .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.account_balance_wallet_outlined,
                                          size: 16,
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.8,
                                                )
                                              : AppTheme.primaryColor,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Independent Budgets',
                                        style: AppFonts.textStyle(
                                          fontSize: widget.compact ? 13 : 14,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.9,
                                                )
                                              : AppTheme.textPrimary,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.2,
                                                )
                                              : AppTheme.primaryColor
                                                    .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          '${independentCategories.length}',
                                          style: AppFonts.textStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: widget.compact ? 12 : 16),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: EdgeInsets.only(
                                left: widget.compact ? 16 : 20,
                                right: widget.compact ? 16 : 20,
                                bottom:
                                    index == independentCategories.length - 1
                                    ? (widget.compact ? 16 : 20)
                                    : (widget.compact ? 8 : 12),
                              ),
                              child: BudgetCard(
                                budget: independentCategories[index],
                                compact: widget.compact,
                                onEdit: () => _showEditModal(
                                  context,
                                  independentCategories[index],
                                ),
                                onAdd: null,
                                // Category budgets ALWAYS show simple dialog
                                onDelete: () {
                                  _showDeleteConfirmationForCategoryBudget(
                                    context,
                                    independentCategories[index],
                                  );
                                },
                                // For general budgets, show enhanced dialog
                                onDeleteWithCheck: (budget) {
                                  if (budget.category ==
                                      BudgetCategory.general) {
                                    final associatedBudgets =
                                        activeCategoryBudgets
                                            .where(
                                              (b) =>
                                                  b.type == budget.type &&
                                                  b.isIndependent != true,
                                            )
                                            .toList();
                                    // Always show enhanced dialog for general budgets
                                    _showDeleteGeneralBudgetDialog(
                                      context,
                                      budget,
                                      associatedBudgets,
                                    );
                                  } else {
                                    // Category budgets show simple dialog
                                    _showDeleteConfirmationForCategoryBudget(
                                      context,
                                      budget,
                                    );
                                  }
                                },
                              ),
                            ),
                            childCount: independentCategories.length,
                          ),
                        ),
                      ],
                      // Add bottom padding so content can scroll behind navigation bar
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.bottomNavPadding),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LoadingSpinner.large(color: AppTheme.primaryColor),
                SizedBox(height: 24),
                Text(
                  'Loading your budgets',
                  style: AppFonts.textStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Just a moment...',
                  style: AppFonts.textStyle(
                    fontSize: 14,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Colors.red.withValues(alpha: 0.8),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Oops! Something went wrong',
                    style: AppFonts.textStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'We couldn\'t load your budgets.\nPlease try again.',
                    style: AppFonts.textStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        ref.invalidate(generalBudgetsProvider);
                        ref.invalidate(categoryBudgetsProvider);
                      });
                    },
                    icon: Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingSpinner.large(),
            SizedBox(height: 16),
            Text(
              'Loading budgets...',
              style: AppFonts.textStyle(
                fontSize: 14,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 32,
                    color: AppTheme.errorColor,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Failed to load budgets',
                  style: AppFonts.textStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _cleanErrorMessage(error.toString()),
                    style: AppFonts.textStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppTheme.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      ref.invalidate(generalBudgetsProvider);
                      ref.invalidate(categoryBudgetsProvider);
                    });
                  },
                  icon: Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalBudgetCard(
    BudgetEntity budget,
    bool isSelected,
    bool compact,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = compact ? 12.0 : 16.0;
    final titleFontSize = compact ? 16.0 : 18.0;
    final spentFontSize = compact ? 12.0 : 13.0;
    final footerFontSize = compact ? 11.0 : 12.0;
    final statusFontSize = compact ? 10.0 : 11.0;
    final barHeight = compact ? 5.0 : 6.0;
    final borderRadius = compact ? 18.0 : 24.0;
    return Consumer(
      builder: (context, ref, child) {
        final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
        final currency =
            selectedCurrencyAsync.valueOrNull ?? Currency.defaultCurrency;

        // Use dynamic theme colors for elegant blend
        final gradientColors = AppTheme.walletGradient;
        final primaryColor = AppTheme.primaryColor;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors.length >= 2
                        ? [gradientColors[0], gradientColors[1]]
                        : [primaryColor, primaryColor],
                  )
                : (isDark
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF111827),
                            const Color(0xFF0F172A),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Colors.white],
                        )),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.6)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppTheme.borderColor),
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () =>
                  _showHorizontalCardMenu(context, budget, onEdit, onDelete),
              borderRadius: BorderRadius.circular(borderRadius),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                budget.typeLabel,
                                style: AppFonts.textStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected || isDark
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: compact ? 2 : 4),
                              Text(
                                '${CurrencyFormatter.format(budget.spent, currency)} / ${CurrencyFormatter.format(budget.amount, currency)}',
                                style: AppFonts.textStyle(
                                  fontSize: spentFontSize,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      (isSelected || isDark
                                              ? Colors.white
                                              : AppTheme.textSecondary)
                                          .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onEdit != null)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color:
                                  (isSelected || isDark
                                          ? Colors.white
                                          : AppTheme.borderColor)
                                      .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.more_vert_rounded,
                              size: 14,
                              color:
                                  (isSelected || isDark
                                          ? Colors.white
                                          : AppTheme.textSecondary)
                                      .withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),

                    const Spacer(),

                    // Progress bar
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: budget.progress),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedProgress, child) {
                        return Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            color:
                                (isSelected || isDark
                                        ? Colors.white
                                        : AppTheme.borderColor)
                                    .withValues(alpha: isDark ? 0.2 : 0.4),
                            borderRadius: BorderRadius.circular(barHeight / 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(barHeight / 2),
                            child: LinearProgressIndicator(
                              value: animatedProgress.clamp(0.0, 1.0),
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                budget.isOnTrack
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: compact ? 8 : 10),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (budget.isOnTrack
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFFEF4444))
                                    .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: budget.isOnTrack
                                      ? const Color(0xFF22C55E)
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                budget.statusText,
                                style: AppFonts.textStyle(
                                  fontSize: statusFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: budget.isOnTrack
                                      ? const Color(0xFF22C55E)
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          budget.isOnTrack
                              ? '${CurrencyFormatter.format(budget.remaining, currency)} left'
                              : '${CurrencyFormatter.format(budget.spent - budget.amount, currency)} over',
                          style: AppFonts.textStyle(
                            fontSize: footerFontSize,
                            fontWeight: FontWeight.w600,
                            color:
                                (isSelected || isDark
                                        ? Colors.white
                                        : AppTheme.textSecondary)
                                    .withValues(alpha: 0.8),
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
      },
    );
  }

  Widget _buildPageIndicator(List<BudgetEntity> budgets) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(budgets.length, (index) {
        final isActive = budgets[index].id == _selectedGeneralBudgetId;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primaryColor
                : (isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : AppTheme.borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyBudgets() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppTheme.textSecondary;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 20),
            // Hero illustration
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.15),
                    AppTheme.accentColor.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.savings_rounded,
                size: 48,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Take Control of Your Spending',
              style: AppFonts.textStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Set spending limits and get alerts when you\'re close to going over budget.',
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: subtitleColor,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 28),

            // Budget type explanation cards
            _buildBudgetTypeExplanation(isDark),
            SizedBox(height: 28),

            // Recommended first step
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recommended: Start with Monthly',
                          style: AppFonts.textStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Most users start with a monthly budget to track overall spending.',
                          style: AppFonts.textStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // CTA Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showNewGeneralBudgetModal(context),
                icon: Icon(Icons.add_rounded, size: 20),
                label: Text(
                  'Create Monthly Budget',
                  style: AppFonts.textStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            SizedBox(height: 12),

            // Secondary option
            TextButton(
              onPressed: () => _showBudgetTypeMenu(context),
              child: Text(
                'Or choose a different budget type',
                style: AppFonts.textStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Visual explanation of budget types for new users
  Widget _buildBudgetTypeExplanation(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppTheme.borderColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.borderColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Two ways to budget',
            style: AppFonts.textStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 14),
          // Duration budget
          _buildBudgetTypeRow(
            icon: Icons.calendar_today_rounded,
            title: 'Duration Budget',
            description: 'Set a total limit for a time period',
            example: 'e.g., \$2,000/month total',
            color: AppTheme.primaryColor,
            isDark: isDark,
          ),
          SizedBox(height: 12),
          // Category budget
          _buildBudgetTypeRow(
            icon: Icons.category_rounded,
            title: 'Category Budget',
            description: 'Set limits for specific categories',
            example: 'e.g., \$500/month on Food',
            color: AppTheme.secondaryColor,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetTypeRow({
    required IconData icon,
    required String title,
    required String description,
    required String example,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppFonts.textStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                description,
                style: AppFonts.textStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                example,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color.withValues(alpha: 0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showBudgetTypeMenu(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            Icons.add_rounded,
            size: 28,
            color: isDark ? Colors.white : AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  void _showBudgetTypeMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (context) => BottomSheetModal(
        title: 'Create Budget',
        subtitle: 'Choose how you want to track your spending',
        borderRadius: 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            // Duration-based budget option
            _BudgetTypeOption(
              icon: Icons.calendar_today_rounded,
              title: 'Duration Budget',
              subtitle: 'Track total spending over a time period',
              helpText: 'Best for overall spending control',
              color: AppTheme.primaryColor,
              recommended: true,
              onTap: () {
                Navigator.pop(context);
                _showNewGeneralBudgetModal(context);
              },
              isDark: isDark,
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppTheme.borderColor.withValues(alpha: 0.3),
            ),
            // Category budget option
            _BudgetTypeOption(
              icon: Icons.category_rounded,
              title: 'Category Budget',
              subtitle: 'Limit spending on specific categories',
              helpText: 'Great for controlling specific areas like Food or Shopping',
              color: AppTheme.secondaryColor,
              recommended: false,
              onTap: () {
                Navigator.pop(context);
                _showNewCategoryBudgetModal(context);
              },
              isDark: isDark,
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showNewGeneralBudgetModal(BuildContext context) {
    final generalBudgetsAsync = ref.read(generalBudgetsProvider);
    // Only consider enabled general budgets with amount > 0 when checking for duplicates
    // Budgets with amount 0 are placeholder/default budgets and shouldn't block creation
    // generalBudgetsProvider already returns only general budgets, so we just filter by enabled and amount > 0
    final existingBudgets = (generalBudgetsAsync.valueOrNull ?? [])
        .where((b) => b.enabled && b.amount > 0)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BudgetFormModal(
        budgetCategory: BudgetCategory
            .general, // Explicitly indicate we want a general budget
        existingBudgets: existingBudgets,
        title: 'Create General Budget',
        subtitle: 'Set spending limits by time period',
        onSave: (period, categoryId, amount, enabled) async {
          final notifier = ref.read(budgetNotifierProvider.notifier);
          try {
            await notifier.createBudget(
              CreateBudgetDto(
                type: period ?? BudgetType.monthly,
                amount: amount,
                enabled: enabled,
                categoryId: null, // General budgets have no category
              ),
            );
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Budget created successfully'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to create budget: $e'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showNewCategoryBudgetModal(BuildContext context) {
    // Get the active period from the selected general budget
    BudgetType? activePeriod;
    final generalBudgetsAsync = ref.read(generalBudgetsProvider);
    generalBudgetsAsync.maybeWhen(
      data: (generalBudgets) {
        if (_selectedGeneralBudgetId != null) {
          final selectedGeneral = generalBudgets
              .where((b) => b.id == _selectedGeneralBudgetId)
              .firstOrNull;
          if (selectedGeneral != null) {
            activePeriod = selectedGeneral.type;
          }
        }
      },
      orElse: () {},
    );

    // For category budgets, we should check against existing category budgets, not general budgets
    // Only consider enabled category budgets with amount > 0 when checking for duplicates
    // Budgets with amount 0 are placeholder/default budgets and shouldn't block creation
    // categoryBudgetsProvider already returns only category budgets, so we just filter by enabled and amount > 0
    final categoryBudgetsAsync = ref.read(categoryBudgetsProvider);
    final existingBudgets = (categoryBudgetsAsync.valueOrNull ?? [])
        .where((b) => b.enabled && b.amount > 0)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BudgetFormModal(
        initialPeriod: activePeriod,
        budgetCategory: BudgetCategory
            .category, // Explicitly indicate we want a category budget
        existingBudgets: existingBudgets,
        title: 'Create Category Budget',
        subtitle: 'Set spending limits for specific categories',
        onSave: (period, categoryId, amount, enabled) async {
          final notifier = ref.read(budgetNotifierProvider.notifier);
          try {
            await notifier.createBudget(
              CreateBudgetDto(
                type: period ?? BudgetType.monthly,
                amount: amount,
                enabled: enabled,
                categoryId: categoryId, // Can be null for general budgets
              ),
            );
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Budget created successfully'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to create budget: $e'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _deleteBudget(
    String budgetId, {
    bool deleteAssociatedCategories = false,
  }) async {
    final notifier = ref.read(budgetNotifierProvider.notifier);
    try {
      await notifier.deleteBudget(
        budgetId,
        deleteAssociatedCategories: deleteAssociatedCategories,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deleteAssociatedCategories
                  ? 'Budget and associated category budgets deleted successfully'
                  : 'Budget deleted successfully',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete budget: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showDeleteGeneralBudgetDialog(
    BuildContext context,
    BudgetEntity generalBudget,
    List<BudgetEntity> associatedCategoryBudgets,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = associatedCategoryBudgets.length;
    bool deleteAssociatedCategories = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(
        alpha: 0.5,
      ), // Ensure backdrop is visible
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDark
              ? const Color(0xFF1E293B)
              : Colors.white, // Use fully opaque color
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete ${generalBudget.typeLabel}?',
            style: AppFonts.textStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (count > 0) ...[
                  Text(
                    'This budget has $count category budget${count != 1 ? 's' : ''} associated with it.',
                    style: AppFonts.textStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: 16),
                  // Show list of affected budgets (up to 5)
                  if (count <= 5) ...[
                    ...associatedCategoryBudgets
                        .take(5)
                        .map(
                          (budget) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.category_rounded,
                                  size: 16,
                                  color: AppTheme.accentColor,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    budget.categoryName ?? 'Unknown',
                                    style: AppFonts.textStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.8)
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ] else ...[
                    ...associatedCategoryBudgets
                        .take(5)
                        .map(
                          (budget) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.category_rounded,
                                  size: 16,
                                  color: AppTheme.accentColor,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    budget.categoryName ?? 'Unknown',
                                    style: AppFonts.textStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.8)
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    SizedBox(height: 4),
                    Text(
                      '...and ${count - 5} more',
                      style: AppFonts.textStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                  SizedBox(height: 16),
                ] else ...[
                  // No associated categories
                  Text(
                    'No category budgets are currently associated with this budget.',
                    style: AppFonts.textStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                // Checkbox to delete associated categories (only show if there are categories)
                if (count > 0) ...[
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          deleteAssociatedCategories =
                              !deleteAssociatedCategories;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: deleteAssociatedCategories,
                              onChanged: (value) {
                                setState(() {
                                  deleteAssociatedCategories = value ?? false;
                                });
                              },
                              activeColor: AppTheme.errorColor,
                              checkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Also delete associated category budgets',
                                    style: AppFonts.textStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'If unchecked, category budgets will become independent',
                                    style: AppFonts.textStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.6)
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppFonts.textStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteBudget(
                  generalBudget.id,
                  deleteAssociatedCategories: deleteAssociatedCategories,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Delete',
                style: AppFonts.textStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditModal(BuildContext context, BudgetEntity budget) {
    final generalBudgetsAsync = ref.read(generalBudgetsProvider);
    final existingBudgets = generalBudgetsAsync.valueOrNull ?? [];

    // Determine title and subtitle based on budget type
    final String title;
    final String subtitle;

    if (budget.category == BudgetCategory.general) {
      title = 'Edit General Budget';
      subtitle = 'Update your spending limit by time period';
    } else {
      title = 'Edit Category Budget';
      subtitle = budget.categoryName != null
          ? 'Update spending limit for ${budget.categoryName}'
          : 'Update spending limit for this category';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BudgetFormModal(
        existingBudget: budget,
        existingBudgets: existingBudgets,
        title: title,
        subtitle: subtitle,
        onSave: (period, categoryId, amount, enabled) async {
          final notifier = ref.read(budgetNotifierProvider.notifier);
          try {
            // Update existing budget
            await notifier.updateBudget(
              budget.id,
              UpdateBudgetDto(amount: amount, enabled: enabled),
            );
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Budget updated successfully'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update budget: $e'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showHorizontalCardMenu(
    BuildContext context,
    BudgetEntity budget,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    BottomSheetModal.show(
      context: context,
      title: budget.typeLabel,
      subtitle: 'Manage your budget',
      borderRadius: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onEdit != null) ...[
            BottomSheetOptionTile(
              icon: Icons.edit_rounded,
              label: 'Edit Budget',
              color: AppTheme.primaryColor,
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            if (onDelete != null) const BottomSheetOptionDivider(),
          ],
          if (onDelete != null) ...[
            BottomSheetOptionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete Budget',
              color: AppTheme.errorColor,
              useColorForText: true,
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmationForHorizontalCard(
                  context,
                  budget,
                  isDark,
                  onDelete,
                );
              },
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showDeleteConfirmationForHorizontalCard(
    BuildContext context,
    BudgetEntity budget,
    bool isDark,
    VoidCallback onDelete,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Budget',
          style: AppFonts.textStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete the ${budget.typeLabel}?',
          style: AppFonts.textStyle(
            fontSize: 14,
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppFonts.textStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close confirmation dialog
              onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Delete',
              style: AppFonts.textStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationForCategoryBudget(
    BuildContext context,
    BudgetEntity budget,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Budget',
          style: AppFonts.textStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete the budget for ${budget.categoryName ?? 'this category'}?',
          style: AppFonts.textStyle(
            fontSize: 14,
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppFonts.textStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBudget(budget.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Delete',
              style: AppFonts.textStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetTypeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? helpText;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;
  final bool recommended;

  const _BudgetTypeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.helpText,
    required this.color,
    required this.onTap,
    required this.isDark,
    this.recommended = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppFonts.textStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Recommended',
                            style: AppFonts.textStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppFonts.textStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppTheme.textSecondary,
                    ),
                  ),
                  if (helpText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      helpText!,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: color.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
