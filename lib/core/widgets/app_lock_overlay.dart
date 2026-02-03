import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/app_lock/domain/entities/app_lock_state.dart';
import '../../features/app_lock/presentation/providers/app_lock_providers.dart';
import '../../features/app_lock/presentation/screens/lock_screen.dart';

/// App lock overlay widget
///
/// Displays the lock screen as an overlay on top of the app content
/// when the app is in locked state. This approach:
/// - Prevents screen content flash during lock/unlock
/// - Maintains app state while locked
/// - Provides smooth transitions
class AppLockOverlay extends ConsumerWidget {
  final Widget child;

  const AppLockOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLockState = ref.watch(appLockNotifierProvider);

    return Stack(
      children: [
        // App content
        child,

        // Lock screen overlay
        if (appLockState is AppLockStateLocked)
          const Positioned.fill(
            child: LockScreen(),
          ),
      ],
    );
  }
}
