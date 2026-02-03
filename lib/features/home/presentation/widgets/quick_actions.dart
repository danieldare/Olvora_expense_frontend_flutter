import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/action_card.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../trips/presentation/widgets/trip_context_indicator.dart';
import '../../../ora/presentation/widgets/ora_avatar_widget.dart';

class QuickActions extends ConsumerWidget {
  final VoidCallback? onAddEntry;
  final VoidCallback? onScanReceipt;
  final VoidCallback? onVoiceInput;

  const QuickActions({
    super.key,
    this.onAddEntry,
    this.onScanReceipt,
    this.onVoiceInput,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTripAsync = ref.watch(activeTripProvider);
    final activeTrip = activeTripAsync.valueOrNull;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ActionCard(
                icon: Icons.add_rounded,
                label: 'Add Expense',
                onTap: onAddEntry ?? () {},
                color: context.primaryColor,
                iconColor: AppTheme.accentColor,
              ),
            ),
            SizedBox(width: AppSpacing.spacingSmall),
            Expanded(
              child: ActionCard(
                icon: Icons.document_scanner_rounded,
                label: 'Scan Receipt',
                onTap: onScanReceipt ?? () {},
                color: context.warningColor,
                iconColor: AppTheme.successColor,
              ),
            ),
            SizedBox(width: AppSpacing.spacingSmall),
            Expanded(
              child: ActionCard(
                iconWidget: const OraAvatarWidget(size: 28, fontSize: 14),
                label: 'Ora AI',
                onTap: onVoiceInput ?? () {},
              ),
            ),
          ],
        ),
        // Trip Context Indicator (only shows when trip is active)
        TripContextIndicator(trip: activeTrip),
      ],
    );
  }
}
