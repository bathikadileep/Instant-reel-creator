import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:instant_reel/core/constants/app_constants.dart';
import 'package:instant_reel/core/router/route_names.dart';
import 'package:instant_reel/core/theme/app_colors.dart';
import 'package:instant_reel/core/utils/responsive_layout.dart';
import 'package:instant_reel/features/booking_management/presentation/controllers/booking_history_controller.dart';
import 'package:instant_reel/features/customer/presentation/widgets/booking_card.dart';

class BookingHistoryScreen extends ConsumerWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingHistoryControllerProvider);
    final controller = ref.read(bookingHistoryControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: const Text(
          'Booking History & Records',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () => controller.refresh(),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _buildContent(context, state, controller, isMobile: true),
          desktop: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: _buildContent(context, state, controller, isMobile: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    BookingHistoryState state,
    BookingHistoryController controller, {
    required bool isMobile,
  }) {
    return Column(
      children: [
        // Search & Filter Header
        Container(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
          color: AppColors.surfaceDark,
          child: Column(
            children: [
              // Search Input
              TextField(
                onChanged: (val) => controller.setSearch(val),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by booking code, location, or notes...',
                  hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                  filled: true,
                  fillColor: AppColors.cardDark,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),

              // Status Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabChip('all', 'All Bookings', state.activeTab, controller),
                    const SizedBox(width: 8),
                    _buildTabChip('active', 'Active Shoots', state.activeTab, controller),
                    const SizedBox(width: 8),
                    _buildTabChip('completed', 'Delivered', state.activeTab, controller),
                    const SizedBox(width: 8),
                    _buildTabChip('cancelled', 'Cancelled', state.activeTab, controller),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // City Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => controller.setCity(null),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: state.selectedCity == null ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: state.selectedCity == null ? AppColors.primary : AppColors.cardDark,
                          ),
                        ),
                        child: Text(
                          'All Hubs',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: state.selectedCity == null ? AppColors.primary : AppColors.textSecondaryDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ...AppConstants.supportedRegions.map((c) {
                      final isSelected = state.selectedCity?.toLowerCase() == c.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: InkWell(
                          onTap: () => controller.setCity(c),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.cardDark,
                              ),
                            ),
                            child: Text(
                              c,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppColors.primary : AppColors.textSecondaryDark,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bookings List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => controller.refresh(),
            color: AppColors.secondary,
            backgroundColor: AppColors.surfaceDark,
            child: state.bookings.when(
              data: (list) {
                if (list.isEmpty) {
                  return ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                        child: Column(
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              size: 48,
                              color: AppColors.textSecondaryDark.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Bookings Found',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Try adjusting your search query or city filters.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final booking = list[index];
                    return BookingCard(
                      booking: booking,
                      onTap: () {
                        context.push('${RoutePaths.bookingDetail}/${booking.id}');
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.secondary),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
                      const SizedBox(height: 12),
                      Text('Error: $err', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => controller.refresh(),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.black),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabChip(
    String tabKey,
    String label,
    String activeTab,
    BookingHistoryController controller,
  ) {
    final isSelected = activeTab == tabKey;
    return InkWell(
      onTap: () => controller.setTab(tabKey),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
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
