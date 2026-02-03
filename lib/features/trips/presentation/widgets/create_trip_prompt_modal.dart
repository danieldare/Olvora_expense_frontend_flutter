import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/trip_providers.dart';

/// Create Trip Prompt Modal
///
/// Shown after first expense is saved when no Trip is active.
/// Suggests creating a Trip to group related expenses.
///
/// Design Principles:
/// - Discoverable (shows after first expense)
/// - Non-intrusive (can be skipped)
/// - Helpful suggestion (groups related expenses)
class CreateTripPromptModal extends ConsumerStatefulWidget {
  final String? suggestedName;
  final VoidCallback? onCreated;

  const CreateTripPromptModal({super.key, this.suggestedName, this.onCreated});

  @override
  ConsumerState<CreateTripPromptModal> createState() =>
      _CreateTripPromptModalState();
}

class _CreateTripPromptModalState extends ConsumerState<CreateTripPromptModal> {
  final TextEditingController _nameController = TextEditingController();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    if (widget.suggestedName != null) {
      _nameController.text = widget.suggestedName!;
    }
    // Listen to text changes to update button state
    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createTrip() async {
    if (_isCreating) return;

    final tripName = _nameController.text.trim();

    // Validate trip name is not empty
    if (tripName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Trip name is required'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final tripService = ref.read(tripServiceProvider);

      await tripService.createTrip(name: tripName);

      // Refresh active trip
      ref.invalidate(activeTripProvider);
      ref.read(tripNotifierProvider.notifier).refresh();

      if (mounted) {
        Navigator.pop(context);
        if (widget.onCreated != null) {
          widget.onCreated!();
        }
        // Show success with next steps hint
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trip started!',
                        style: AppFonts.textStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'New expenses will be linked automatically',
                        style: AppFonts.textStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create trip: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info tip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'All expenses added while this trip is active will be automatically linked to it.',
                    style: AppFonts.textStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Trip name input
          AppTextField(
            controller: _nameController,
            label: 'Trip Name',
            hintText: 'e.g., Paris Vacation, Work Trip',
            enabled: !_isCreating,
          ),
          const SizedBox(height: 12),

          // Quick suggestions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSuggestionChip('Weekend Getaway', isDark),
              _buildSuggestionChip('Business Trip', isDark),
              _buildSuggestionChip('Family Vacation', isDark),
            ],
          ),
          const SizedBox(height: 24),

          // Create Trip button (full width)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isCreating || _nameController.text.trim().isEmpty)
                  ? null
                  : _createTrip,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isCreating
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Start Trip',
                      style: AppFonts.textStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, bool isDark) {
    return GestureDetector(
      onTap: () {
        _nameController.text = text;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.borderColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : AppTheme.borderColor,
          ),
        ),
        child: Text(
          text,
          style: AppFonts.textStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
