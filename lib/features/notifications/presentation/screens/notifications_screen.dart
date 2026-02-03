import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../providers/notification_providers.dart';
import '../../domain/entities/notification_entity.dart';
import '../../../expenses/presentation/screens/transaction_details_screen.dart';
import '../../../expenses/presentation/providers/expenses_providers.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../trips/presentation/screens/trip_details_screen.dart';
import '../../../budget/presentation/screens/budget_screen.dart';
import '../../../../core/providers/api_providers_v2.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh notifications and count when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationNotifierProvider.notifier).refresh();
      ref.invalidate(unreadNotificationCountProvider);
    });
  }

  @override
  void dispose() {
    // Invalidate count when leaving screen to ensure badge updates
    ref.invalidate(unreadNotificationCountProvider);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppTheme.screenBackgroundColor;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark ? Colors.grey[400] : AppTheme.textSecondary;
    final notificationsAsync = ref.watch(notificationNotifierProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(),
        title: Text(
          'Notifications',
          style: AppFonts.textStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        actions: [
          notificationsAsync.when(
            data: (notifications) {
              final unreadCount = notifications.where((n) => !n.isRead).length;
              if (unreadCount == 0) return const SizedBox.shrink();

              return TextButton(
                onPressed: () async {
                  final notifier = ref.read(
                    notificationNotifierProvider.notifier,
                  );
                  await notifier.markAllAsRead();
                },
                child: Text(
                  'Mark all read',
                  style: AppFonts.textStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications',
              subtitle: 'You\'re all caught up!',
            );
          }

          // Group notifications by date
          final grouped = _groupNotificationsByDate(notifications);

          return RefreshIndicator(
            onRefresh: () async {
              final notifier = ref.read(notificationNotifierProvider.notifier);
              await notifier.refresh();
            },
            color: AppTheme.primaryColor,
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                8,
                AppSpacing.screenHorizontal,
                AppSpacing.bottomNavPadding,
              ),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final dateGroup = grouped[index];
                final date = dateGroup['date'] as DateTime;
                final dateNotifications =
                    dateGroup['notifications'] as List<NotificationEntity>;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date header
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: 10,
                        top: index > 0 ? 20 : 0,
                      ),
                      child: Text(
                        _formatDateHeader(date),
                        style: AppFonts.textStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: subtitleColor,
                        ),
                      ),
                    ),
                    // Notifications for this date
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkCardBackground
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppTheme.borderColor,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.1 : 0.04,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: dateNotifications.asMap().entries.map((
                          entry,
                        ) {
                          final notificationIndex = entry.key;
                          final notification = entry.value;
                          final isLast =
                              notificationIndex == dateNotifications.length - 1;

                          return Column(
                            children: [
                              _NotificationItem(
                                notification: notification,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                                isDark: isDark,
                                onTap: () => _handleNotificationTap(
                                  context,
                                  notification,
                                ),
                                onMarkAsRead: () async {
                                  final notifier = ref.read(
                                    notificationNotifierProvider.notifier,
                                  );
                                  await notifier.markAsRead(notification.id);
                                },
                              ),
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : AppTheme.borderColor,
                                  indent: 62,
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
        loading: () =>
            Center(child: LoadingSpinner.medium(color: AppTheme.primaryColor)),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 14),
              Text(
                'Error loading notifications',
                style: AppFonts.textStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                error.toString(),
                style: AppFonts.textStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: subtitleColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final notifier = ref.read(
                    notificationNotifierProvider.notifier,
                  );
                  notifier.refresh();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    NotificationEntity notification,
  ) async {
    // Mark as read if not already read
    if (!notification.isRead) {
      final notifier = ref.read(notificationNotifierProvider.notifier);
      await notifier.markAsRead(notification.id);
    }

    // Handle navigation based on notification type and data
    final data = notification.data;
    if (data == null) return;

    switch (notification.type) {
      case NotificationType.expenseDetected:
        final expenseId = data['expenseId'] as String?;
        if (expenseId != null) {
          await _navigateToExpense(context, expenseId);
        }
        break;
      case NotificationType.tripUpdate:
        final tripId = data['tripId'] as String?;
        if (tripId != null) {
          await _navigateToTrip(context, tripId);
        }
        break;
      case NotificationType.budgetAlert:
        final budgetId = data['budgetId'] as String?;
        if (budgetId != null && context.mounted) {
          // Navigate to budget screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BudgetScreen(),
            ),
          );
        }
        break;
      case NotificationType.reminder:
      case NotificationType.system:
      case NotificationType.weeklySummary:
        // No specific navigation for these types
        break;
    }
  }

  Future<void> _navigateToExpense(
    BuildContext context,
    String expenseId,
  ) async {
    try {
      ExpenseEntity? expense;

      // Try to find expense in cached list first
      try {
        final expensesAsync = await ref.read(expensesProvider.future);
        expense = expensesAsync.firstWhere(
          (e) => e.id == expenseId,
          orElse: () => throw Exception('Not in cache'),
        );
      } catch (_) {
        // Not in cache, fetch from API
        final apiService = ref.read(apiServiceV2Provider);
        final response = await apiService.dio.get('/expenses/$expenseId');

        // Handle TransformInterceptor response wrapper
        dynamic actualData = response.data;
        if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;
          if (responseMap.containsKey('data') && responseMap['data'] != null) {
            actualData = responseMap['data'];
          }
        }

        expense = ExpenseEntity.fromJson(actualData as Map<String, dynamic>);
      }

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TransactionDetailsScreen(transaction: expense!),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not find expense details'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _navigateToTrip(BuildContext context, String tripId) async {
    try {
      // Navigate directly with tripId - TripDetailsScreen will fetch the trip
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TripDetailsScreen(tripId: tripId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not find trip details'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _groupNotificationsByDate(
    List<NotificationEntity> notifications,
  ) {
    final Map<String, List<NotificationEntity>> grouped = {};

    for (final notification in notifications) {
      final dateKey = DateFormat('yyyy-MM-dd').format(notification.timestamp);
      grouped.putIfAbsent(dateKey, () => []).add(notification);
    }

    return grouped.entries.map((entry) {
      return {
        'date': DateFormat('yyyy-MM-dd').parse(entry.key),
        'notifications': entry.value
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
      };
    }).toList()..sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationEntity notification;
  final Color textColor;
  final Color? subtitleColor;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onMarkAsRead;

  const _NotificationItem({
    required this.notification,
    required this.textColor,
    this.subtitleColor,
    required this.isDark,
    required this.onTap,
    required this.onMarkAsRead,
  });

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.expenseDetected:
        return Icons.receipt_long_rounded;
      case NotificationType.budgetAlert:
        return Icons.warning_rounded;
      case NotificationType.reminder:
        return Icons.notifications_active_rounded;
      case NotificationType.system:
        return Icons.info_rounded;
      case NotificationType.tripUpdate:
        return Icons.flight_rounded;
      case NotificationType.weeklySummary:
        return Icons.summarize_rounded;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.expenseDetected:
        return AppTheme.warningColor;
      case NotificationType.budgetAlert:
        return AppTheme.errorColor;
      case NotificationType.reminder:
        return AppTheme.primaryColor;
      case NotificationType.system:
        return AppTheme.accentColor;
      case NotificationType.tripUpdate:
        return AppTheme.secondaryColor;
      case NotificationType.weeklySummary:
        return AppTheme.primaryColor;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColor(notification.type);
    final iconBgColor = iconColor.withValues(alpha: 0.2);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getIcon(notification.type),
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppFonts.textStyle(
                            fontSize: 14,
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: AppFonts.textStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: subtitleColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(notification.timestamp),
                    style: AppFonts.textStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: subtitleColor?.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
