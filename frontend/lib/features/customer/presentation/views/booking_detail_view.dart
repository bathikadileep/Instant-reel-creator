import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:instant_reel/core/theme/app_colors.dart';
import 'package:instant_reel/core/utils/responsive_layout.dart';
import 'package:instant_reel/features/customer/data/repositories/customer_booking_repository_impl.dart';
import 'package:instant_reel/features/customer/domain/models/booking_model.dart';
import 'package:instant_reel/features/customer/presentation/controllers/customer_dashboard_controller.dart';

final bookingDetailFutureProvider =
    FutureProvider.family<BookingModel, String>((ref, bookingId) async {
  final repo = ref.watch(customerBookingRepositoryProvider);
  return await repo.getBookingDetail(bookingId);
});

class BookingDetailView extends ConsumerWidget {
  final String bookingId;

  const BookingDetailView({Key? key, required this.bookingId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailFutureProvider(bookingId));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Booking Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: bookingAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 12),
                Text('Error loading booking: $err', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(bookingDetailFutureProvider(bookingId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (booking) => ResponsiveLayout(
            mobile: _buildBody(context, ref, booking, isMobile: true),
            desktop: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: _buildBody(context, ref, booking, isMobile: false),
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
    BookingModel booking, {
    required bool isMobile,
  }) {
    final formattedDate =
        DateFormat('EEE, d MMM yyyy • h:mm a').format(booking.scheduledAt.toLocal());
    final isCancellable =
        booking.status == BookingStatus.pending || booking.status == BookingStatus.creatorAssigned;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20.0 : 32.0,
        vertical: 20.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card with Code & Current Status
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.bookingCode,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.city,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: booking.status.statusColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: booking.status.statusColor),
                  ),
                  child: Row(
                    children: [
                      Icon(booking.status.statusIcon, size: 14, color: booking.status.statusColor),
                      const SizedBox(width: 6),
                      Text(
                        booking.status.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: booking.status.statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // WhatsApp Delivery Alert Banner
          if (booking.isDelivered) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF25D366).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF25D366), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reel Delivered on WhatsApp!',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your 4K edited reel was sent to ${booking.customerWhatsapp}${booking.deliveredAt != null ? ' at ${booking.formattedDeliveredAt}' : ''}.',
                          style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Live 6-Stage Progress Tracker
          Text(
            'Live Shoot Progress',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 16),
          _buildStageTracker(booking),
          const SizedBox(height: 24),

          // Package & Delivery Details
          Text(
            'Booking Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Column(
              children: [
                _buildRow('Package', booking.package?.name ?? 'Standard Package'),
                const Divider(color: AppColors.borderDark, height: 20),
                _buildRow(
                    'Price', '₹${booking.package?.price.toStringAsFixed(2) ?? '0.00'}'),
                const Divider(color: AppColors.borderDark, height: 20),
                _buildRow('Scheduled At', formattedDate),
                const Divider(color: AppColors.borderDark, height: 20),
                _buildRow('Shoot Venue', booking.locationAddress),
                const Divider(color: AppColors.borderDark, height: 20),
                _buildRow('WhatsApp Delivery', booking.customerWhatsapp),
                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  const Divider(color: AppColors.borderDark, height: 20),
                  _buildRow('Occasion / Notes', booking.notes!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Assigned Creator Profile (if available)
          if (booking.creator != null) ...[
            Text(
              'Assigned Creator',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.videocam_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.creator?['name'] ?? 'Professional Creator',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          booking.creator?['mobile'] ?? '',
                          style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Cancel Booking Button (if still early stage)
          if (isCancellable) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surfaceDark,
                      title: const Text('Cancel Booking?'),
                      content: const Text('Are you sure you want to cancel this booking?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Yes, Cancel', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ref
                        .read(customerDashboardControllerProvider.notifier)
                        .cancelBooking(booking.id);
                    ref.refresh(bookingDetailFutureProvider(bookingId));
                  }
                },
                icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 18),
                label: const Text('Cancel Booking', style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildStageTracker(BookingModel booking) {
    final stages = [
      {'title': 'Finding Creator', 'sub': 'Matching local pro'},
      {'title': 'Creator Assigned', 'sub': 'Videographer on the way'},
      {'title': 'Arrived at Location', 'sub': 'Creator ready to shoot'},
      {'title': 'Shooting Reel', 'sub': 'Capturing hooks & B-roll'},
      {'title': '10-Minute Rapid Edit', 'sub': 'On-site color grading'},
      {'title': 'Delivered on WhatsApp', 'sub': 'Ready to post!'},
    ];

    final currentStage = booking.status.stageStep;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: List.generate(stages.length, (index) {
          final stageNum = index + 1;
          final isPast = stageNum < currentStage;
          final isCurrent = stageNum == currentStage;
          final isFuture = stageNum > currentStage;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPast
                          ? AppColors.success
                          : (isCurrent ? AppColors.secondary : AppColors.cardDark),
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.secondary
                            : (isPast ? AppColors.success : AppColors.borderDark),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isPast
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : Text(
                              '$stageNum',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCurrent ? Colors.black : Colors.white54,
                              ),
                            ),
                    ),
                  ),
                  if (index < stages.length - 1)
                    Container(
                      width: 2,
                      height: 32,
                      color: isPast ? AppColors.success : AppColors.borderDark,
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stages[index]['title']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isFuture ? AppColors.textSecondaryDark : Colors.white,
                        ),
                      ),
                      Text(
                        stages[index]['sub']!,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
