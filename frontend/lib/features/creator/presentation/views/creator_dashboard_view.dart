import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:instant_reel/core/router/route_names.dart';
import 'package:instant_reel/core/theme/app_colors.dart';
import 'package:instant_reel/core/utils/responsive_layout.dart';
import 'package:instant_reel/features/auth/presentation/controllers/auth_controller.dart';
import 'package:instant_reel/features/creator/presentation/controllers/creator_dashboard_controller.dart';
import 'package:instant_reel/features/creator/presentation/widgets/creator_booking_card.dart';
import 'package:instant_reel/features/creator/presentation/widgets/creator_metric_card.dart';
import 'package:instant_reel/features/notifications/presentation/widgets/notification_bell_widget.dart';

class CreatorDashboardView extends ConsumerWidget {
  const CreatorDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dashboardState = ref.watch(creatorDashboardControllerProvider);
    final controller = ref.read(creatorDashboardControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.secondary, Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Creator Studio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  user?.name ?? 'Professional Videographer',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Availability Switch
          dashboardState.stats.when(
            data: (stats) => Row(
              children: [
                Text(
                  stats.isAvailable ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: stats.isAvailable ? AppColors.success : AppColors.textSecondaryDark,
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: stats.isAvailable,
                    activeColor: AppColors.success,
                    activeTrackColor: AppColors.success.withOpacity(0.3),
                    inactiveThumbColor: AppColors.textSecondaryDark,
                    inactiveTrackColor: AppColors.cardDark,
                    onChanged: (val) {
                      controller.toggleAvailability(val);
                    },
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const NotificationBellWidget(),

          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                context.go(RoutePaths.login);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => controller.refresh(),
          color: AppColors.secondary,
          backgroundColor: AppColors.surfaceDark,
          child: ResponsiveLayout(
            mobile: _buildBody(context, ref, dashboardState, controller, isMobile: true),
            desktop: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: _buildBody(context, ref, dashboardState, controller, isMobile: false),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    CreatorDashboardState state,
    CreatorDashboardController controller, {
    required bool isMobile,
  }) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 20,
      ),
      children: [
        // SLA Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withOpacity(0.15),
                AppColors.surfaceDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
          ),
          child: const Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppColors.secondary, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '10-Minute Rapid Edit SLA Guarantee',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Shoot footage on-site, edit in 10 minutes, and deliver via WhatsApp directly to client.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondaryDark,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Metrics Grid (2x2)
        state.stats.when(
          data: (stats) => GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isMobile ? 1.4 : 1.8,
            children: [
              CreatorMetricCard(
                title: "Today's Bookings",
                value: stats.todayBookingsCount.toString(),
                subtitle: 'Scheduled',
                icon: Icons.calendar_today_rounded,
                iconColor: AppColors.primary,
                onTap: () => controller.selectTab('today'),
              ),
              CreatorMetricCard(
                title: 'Completed Shoots',
                value: stats.completedBookingsCount.toString(),
                subtitle: 'Delivered',
                icon: Icons.task_alt_rounded,
                iconColor: AppColors.success,
                onTap: () => controller.selectTab('completed'),
              ),
              CreatorMetricCard(
                title: "Today's Earnings",
                value: '₹${stats.todayEarnings.toStringAsFixed(0)}',
                subtitle: 'Total ₹${stats.totalEarnings.toStringAsFixed(0)}',
                icon: Icons.currency_rupee_rounded,
                iconColor: AppColors.secondary,
              ),
              CreatorMetricCard(
                title: 'Rating & Reviews',
                value: '${stats.ratingAvg.toStringAsFixed(1)} ★',
                subtitle: '${stats.totalReviews} reviews',
                icon: Icons.star_rounded,
                iconColor: Colors.amber,
              ),
            ],
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: AppColors.secondary),
            ),
          ),
          error: (err, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Error loading dashboard: $err',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Tab Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Booking Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton.icon(
              onPressed: () => controller.refresh(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondary,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Tabs Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTabChip('today', "Today's Shoots", state.activeTab, controller),
              const SizedBox(width: 8),
              _buildTabChip('active', 'Active Workflow', state.activeTab, controller),
              const SizedBox(width: 8),
              _buildTabChip('completed', 'Completed', state.activeTab, controller),
              const SizedBox(width: 8),
              _buildTabChip('all', 'All Bookings', state.activeTab, controller),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Bookings List
        if (state.isLoadingTab)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(color: AppColors.secondary),
            ),
          )
        else if (state.tabBookings.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardDark),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.videocam_off_outlined,
                  size: 48,
                  color: AppColors.textSecondaryDark.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No Bookings in this Tab',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'New client booking requests in Maripeda, Mahabubabad, Khammam, and Warangal will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          )
        else
          ...state.tabBookings.map((b) {
            return CreatorBookingCard(
              booking: b,
              onTap: () {
                context.push('${RoutePaths.creatorBooking}/${b.id}');
              },
            );
          }),
      ],
    );
  }

  Widget _buildTabChip(
    String tabKey,
    String label,
    String activeTab,
    CreatorDashboardController controller,
  ) {
    final isSelected = activeTab == tabKey;
    return InkWell(
      onTap: () => controller.selectTab(tabKey),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.cardDark,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : AppColors.textSecondaryDark,
          ),
        ),
      ),
    );
  }
}
