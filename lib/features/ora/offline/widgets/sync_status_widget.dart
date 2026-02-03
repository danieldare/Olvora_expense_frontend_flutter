import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../providers/offline_providers.dart';

/// Beautiful sync status banner
class SyncStatusBanner extends ConsumerWidget {
  final bool showWhenSynced;
  final bool compact;

  const SyncStatusBanner({
    super.key,
    this.showWhenSynced = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);

    // Hide if all synced and we don't want to show
    if (!showWhenSynced && status.isAllSynced && status.isOnline) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: compact ? 32 : 44,
      decoration: BoxDecoration(
        gradient: _getGradient(status),
        boxShadow: [
          BoxShadow(
            color: _getColor(status).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSyncDetails(context, ref, status),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: compact ? 6 : 12,
            ),
            child: Row(
              children: [
                _buildIcon(status),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildText(context, status),
                ),
                if (status.hasPending && status.isOnline)
                  _buildSyncButton(context, ref),
                if (status.hasConflicts)
                  _buildConflictBadge(context, status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(SyncStatusState status) {
    if (!status.isOnline) {
      return const Icon(
        Icons.cloud_off_rounded,
        color: Colors.white,
        size: 20,
      );
    }

    if (status.isSyncing) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(Colors.white),
        ),
      );
    }

    if (status.hasConflicts) {
      return const Icon(
        Icons.warning_amber_rounded,
        color: Colors.white,
        size: 20,
      );
    }

    if (status.hasPending) {
      return const Icon(
        Icons.cloud_upload_rounded,
        color: Colors.white,
        size: 20,
      );
    }

    return const Icon(
      Icons.cloud_done_rounded,
      color: Colors.white,
      size: 20,
    );
  }

  Widget _buildText(BuildContext context, SyncStatusState status) {
    return Text(
      status.statusText,
      style: TextStyle(
        color: Colors.white,
        fontSize: compact ? 12 : 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSyncButton(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () => ref.read(syncStatusProvider.notifier).syncNow(),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text(
        'Sync Now',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildConflictBadge(BuildContext context, SyncStatusState status) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${status.conflictCount} conflicts',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  LinearGradient _getGradient(SyncStatusState status) {
    final color = _getColor(status);
    return LinearGradient(
      colors: [
        color,
        color.withValues(alpha: 0.85),
      ],
    );
  }

  Color _getColor(SyncStatusState status) {
    if (!status.isOnline) return Colors.grey.shade600;
    if (status.hasConflicts) return Colors.orange.shade600;
    if (status.isSyncing) return Colors.blue.shade600;
    if (status.hasPending) return Colors.blue.shade500;
    return Colors.green.shade600;
  }

  void _showSyncDetails(
    BuildContext context,
    WidgetRef ref,
    SyncStatusState status,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SyncDetailsSheet(status: status),
    );
  }
}

/// Detailed sync status sheet
class SyncDetailsSheet extends ConsumerWidget {
  final SyncStatusState status;

  const SyncDetailsSheet({super.key, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status.isOnline ? Icons.wifi : Icons.wifi_off,
                color: status.isOnline ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 12),
              Text(
                status.isOnline ? 'Online' : 'Offline',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildStatRow(
            'Pending items',
            status.pendingCount.toString(),
            Icons.cloud_upload_outlined,
          ),
          _buildStatRow(
            'Conflicts',
            status.conflictCount.toString(),
            Icons.warning_amber_outlined,
            isWarning: status.hasConflicts,
          ),
          if (status.lastSyncTime != null)
            _buildStatRow(
              'Last sync',
              _formatTime(status.lastSyncTime!),
              Icons.schedule_outlined,
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: status.isOnline
                      ? () {
                          ref.read(syncStatusProvider.notifier).syncNow();
                          Navigator.pop(context);
                        }
                      : null,
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync Now'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: status.hasConflicts
                      ? () => _showConflicts(context, ref)
                      : null,
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('Resolve'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon, {
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isWarning ? Colors.orange : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isWarning ? Colors.orange : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showConflicts(BuildContext context, WidgetRef ref) {
    // Would navigate to conflict resolution screen
    Navigator.pop(context);
  }
}

/// Compact sync indicator for app bar
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);

    if (status.isAllSynced && status.isOnline) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _showSyncDetails(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            if (status.isSyncing)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            else
              Icon(
                _getIcon(status),
                size: 20,
                color: _getColor(status),
              ),
            if (status.pendingCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: _getColor(status),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    status.pendingCount > 9 ? '9+' : '${status.pendingCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(SyncStatusState status) {
    if (!status.isOnline) return Icons.cloud_off;
    if (status.hasConflicts) return Icons.warning_amber;
    if (status.hasPending) return Icons.cloud_upload;
    return Icons.cloud_done;
  }

  Color _getColor(SyncStatusState status) {
    if (!status.isOnline) return Colors.grey;
    if (status.hasConflicts) return Colors.orange;
    return Colors.blue;
  }

  void _showSyncDetails(BuildContext context) {
    // Show sync details bottom sheet
  }
}
