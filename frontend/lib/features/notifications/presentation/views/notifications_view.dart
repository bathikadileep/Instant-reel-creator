import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:instant_reel/core/router/route_names.dart';
import 'package:instant_reel/core/theme/app_colors.dart';
import 'package:instant_reel/core/utils/responsive_layout.dart';
import 'package:instant_reel/features/auth/domain/models/user_model.dart';
import 'package:instant_reel/features/auth/presentation/controllers/auth_controller.dart';
import 'package:instant_reel/features/notifications/domain/models/notification_model.dart';
import 'package:instant_reel/features/notifications/presentation/controllers/notification_controller.dart';
import 'package:instant_reel/features/notifications/services/fcm_notification_service.dart';

class NotificationsView extends ConsumerWidget {
  const NotificationsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationControllerProvider);
    final controller = ref.read(notificationControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.customerDashboard);
            }
          },
        ),
        actions: [
          // Filter toggle (All vs Unread)
          TextButton.icon(
            onPressed: () => controller.toggleFilterUnreadOnly(),
            icon: Icon(
              state.filterUnreadOnly
                  ? Icons.filter_alt_rounded
                  : Icons.filter_alt_outlined,
              size: 16,
              color: state.filterUnreadOnly ? AppColors.secondary : AppColors.textSecondaryDark,
            ),
            label: Text(
              state.filterUnreadOnly ? 'Unread' : 'All',
              style: TextStyle(
                fontSize: 12,
                color: state.filterUnreadOnly ? AppColors.secondary : AppColors.textSecondaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Mark all read button
          if (state.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all_rounded, color: AppColors.primary, size: 22),
              tooltip: 'Mark all as read',
              onPressed: () => controller.markAllAsRead(),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _buildContent(context, ref, state, controller),
          desktop: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: _buildContent(context, ref, state, controller),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    NotificationState state,
    NotificationController controller,
  ) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final displayed = state.displayedNotifications;

    if (displayed.isEmpty) {
      return _buildEmptyState(context, state.filterUnreadOnly, controller);
    }

    return RefreshIndicator(
      onRefresh: () => controller.refresh(),
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceDark,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: displayed.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notif = displayed[index];
          return _buildNotificationCard(context, ref, notif, controller);
        },
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isUnreadOnly,
    NotificationController controller,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12),
              ),
              child: Icon(
                isUnreadOnly
                    ? Icons.mark_chat_read_outlined
                    : Icons.notifications_off_outlined,
                size: 56,
                color: AppColors.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isUnreadOnly ? 'All Caught Up!' : 'No Notifications Yet',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUnreadOnly
                  ? 'You have read all incoming alerts and shoot updates.'
                  : 'Important status updates for your reels will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.refresh(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.white12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notif,
    NotificationController controller,
  ) {
    final hasBooking = notif.bookingId != null && notif.bookingId!.isNotEmpty;

    return InkWell(
      onTap: () {
        if (!notif.isRead) {
          controller.markAsRead(notif.id);
        }
        ref.read(fcmNotificationServiceProvider).handleNotificationTap(context, notif);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.isRead
              ? AppColors.surfaceDark.withOpacity(0.6)
              : const Color(0xFF1E2235),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notif.isRead
                ? Colors.white.withOpacity(0.06)
                : notif.accentColor.withOpacity(0.35),
            width: notif.isRead ? 1 : 1.5,
          ),
          boxShadow: notif.isRead
              ? []
              : [
                  BoxShadow(
                    color: notif.accentColor.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: notif.accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                notif.iconData,
                color: notif.accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge & timestamp row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: notif.accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          notif.typeLabel.toUpperCase(),
                          style: TextStyle(
                            color: notif.accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        notif.relativeTime,
                        style: TextStyle(
                          color: notif.isRead
                              ? AppColors.textSecondaryDark.withOpacity(0.7)
                              : AppColors.secondary,
                          fontSize: 11,
                          fontWeight: notif.isRead ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    notif.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Body
                  Text(
                    notif.body,
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),

                  // Footer action row if booking link exists
                  if (hasBooking) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'View Shoot Details',
                          style: TextStyle(
                            color: notif.accentColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: notif.accentColor,
                          size: 13,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Unread dot
            if (!notif.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: notif.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
