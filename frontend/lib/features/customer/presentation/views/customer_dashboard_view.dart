import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:instant_reel/core/constants/app_constants.dart';
import 'package:instant_reel/core/router/route_names.dart';
import 'package:instant_reel/core/theme/app_colors.dart';
import 'package:instant_reel/core/utils/responsive_layout.dart';
import 'package:instant_reel/features/auth/presentation/controllers/auth_controller.dart';
import 'package:instant_reel/features/customer/presentation/controllers/customer_dashboard_controller.dart';
import 'package:instant_reel/features/customer/presentation/widgets/booking_card.dart';
import 'package:instant_reel/features/notifications/presentation/widgets/notification_bell_widget.dart';

class CustomerDashboardView extends ConsumerWidget {
  const CustomerDashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(customerDashboardControllerProvider);
    final dashboardNotifier =
        ref.read(customerDashboardControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _buildTabBody(context, ref, dashboardState, isMobile: true),
          desktop: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: _buildTabBody(context, ref, dashboardState, isMobile: false),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondaryDark,
        currentIndex: dashboardState.selectedTabIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => dashboardNotifier.setTab(index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library_rounded),
            label: 'My Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBody(
    BuildContext context,
    WidgetRef ref,
    CustomerDashboardState state, {
    required bool isMobile,
  }) {
    switch (state.selectedTabIndex) {
      case 1:
        return _buildActiveBookingsTab(context, ref, state, isMobile: isMobile);
      case 2:
        return _buildHistoryTab(context, ref, state, isMobile: isMobile);
      case 3:
        return _buildProfileTab(context, ref, isMobile: isMobile);
      case 0:
      default:
        return _buildHomeTab(context, ref, state, isMobile: isMobile);
    }
  }

  // ===========================================================================
  // TAB 0: HOME & HERO BOOKING
  // ===========================================================================
  Widget _buildHomeTab(
    BuildContext context,
    WidgetRef ref,
    CustomerDashboardState state, {
    required bool isMobile,
  }) {
    final user = ref.watch(authControllerProvider).user;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20.0 : 32.0,
        vertical: 20.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${user?.name ?? 'Creator'} 👋',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Need a reel in 10 minutes?',
                    style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const NotificationBellWidget(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                    onPressed: () =>
                        ref.read(customerDashboardControllerProvider.notifier).refreshData(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Hero Banner (Obsidian Black & Royal Blue)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF141620), Color(0xFF1E202E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.flash_on_rounded, size: 14, color: AppColors.secondary),
                      SizedBox(width: 4),
                      Text(
                        '10-MINUTE RAPID ON-SITE EDIT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Book a Pro Reel Creator\nto Your Location',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Creators in Maripeda, Mahabubabad, Khammam, and Warangal arrive with cameras, shoot, edit in 10 minutes, and WhatsApp the finished reel.',
                  style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(RoutePaths.bookingFlow),
                    icon: const Icon(Icons.videocam_rounded, size: 20),
                    label: const Text(
                      'Book a Reel Creator Now',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Active Bookings Quick Section
          if (state.activeBookings.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Shoot in Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(customerDashboardControllerProvider.notifier)
                      .setTab(1),
                  child: const Text('View All', style: TextStyle(color: AppColors.primaryLight)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BookingCard(
              booking: state.activeBookings.first,
              onTap: () => context.push('${RoutePaths.bookingDetail}/${state.activeBookings.first.id}'),
            ),
            const SizedBox(height: 16),
          ],

          // Operational Hubs
          const Text(
            'Active Service Hubs',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.supportedRegions.map((region) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 6),
                    Text(
                      region,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: MY ACTIVE BOOKINGS
  // ===========================================================================
  Widget _buildActiveBookingsTab(
    BuildContext context,
    WidgetRef ref,
    CustomerDashboardState state, {
    required bool isMobile,
  }) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(customerDashboardControllerProvider.notifier).refreshData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20.0 : 32.0,
          vertical: 20.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Bookings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'Live status of your upcoming and on-location reel shoots.',
              style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
            ),
            const SizedBox(height: 20),

            if (state.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (state.activeBookings.isEmpty)
              _buildEmptyState(
                context,
                title: 'No Active Bookings',
                subtitle: 'You do not have any pending or ongoing shoots. Book a creator to start!',
                ctaText: 'Book a Creator Now',
                onCta: () => context.push(RoutePaths.bookingFlow),
              )
            else
              ...state.activeBookings.map(
                (b) => BookingCard(
                  booking: b,
                  onTap: () => context.push('${RoutePaths.bookingDetail}/${b.id}'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 2: BOOKING HISTORY
  // ===========================================================================
  Widget _buildHistoryTab(
    BuildContext context,
    WidgetRef ref,
    CustomerDashboardState state, {
    required bool isMobile,
  }) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(customerDashboardControllerProvider.notifier).refreshData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20.0 : 32.0,
          vertical: 20.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking History',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'Completed shoots delivered to WhatsApp and archived bookings.',
              style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
            ),
            const SizedBox(height: 20),

            if (state.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (state.bookingHistory.isEmpty)
              _buildEmptyState(
                context,
                title: 'No Past Bookings',
                subtitle: 'Delivered and completed shoots will appear here.',
                ctaText: 'Book a Creator',
                onCta: () => context.push(RoutePaths.bookingFlow),
              )
            else
              ...state.bookingHistory.map(
                (b) => BookingCard(
                  booking: b,
                  onTap: () => context.push('${RoutePaths.bookingDetail}/${b.id}'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 3: PROFILE
  // ===========================================================================
  Widget _buildProfileTab(
    BuildContext context,
    WidgetRef ref, {
    required bool isMobile,
  }) {
    final user = ref.watch(authControllerProvider).user;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20.0 : 32.0,
        vertical: 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile & Account',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),

          // User Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (user?.name != null && user!.name!.isNotEmpty)
                        ? user.name![0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Instant Reel Customer',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.mobile ?? '',
                        style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Role Switcher
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Current Role', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                    SizedBox(height: 2),
                    Text('Customer (Booker)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                OutlinedButton(
                  onPressed: () => context.push(RoutePaths.roleSelection),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderDark),
                  ),
                  child: const Text('Switch Role', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) {
                  context.go(RoutePaths.login);
                }
              },
              icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
              label: const Text('Log Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String ctaText,
    required VoidCallback onCta,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          const Icon(Icons.videocam_outlined, size: 48, color: AppColors.textSecondaryDark),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onCta,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(ctaText),
          ),
        ],
      ),
    );
  }
}
