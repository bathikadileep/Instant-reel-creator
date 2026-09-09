import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:instant_reel/core/theme/app_colors.dart';
import 'package:instant_reel/core/utils/responsive_layout.dart';
import 'package:instant_reel/features/auth/domain/models/user_model.dart';
import 'package:instant_reel/features/auth/presentation/controllers/auth_controller.dart';
import 'package:instant_reel/features/booking_management/presentation/controllers/booking_detail_controller.dart';
import 'package:instant_reel/features/booking_management/presentation/widgets/assign_creator_dialog.dart';
import 'package:instant_reel/features/booking_management/presentation/widgets/booking_status_timeline_widget.dart';
import 'package:instant_reel/features/booking_management/presentation/widgets/cancel_booking_dialog.dart';
import 'package:instant_reel/features/customer/domain/models/booking_model.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingDetailsScreen extends ConsumerWidget {
  final String bookingId;

  const BookingDetailsScreen({super.key, required this.bookingId});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWhatsApp(String phone, String bookingCode) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = Uri.encodeComponent('Hi! Regarding Instant Reel booking $bookingCode:');
    final uri = Uri.parse('https://wa.me/$clean?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingDetailControllerProvider(bookingId));
    final controller = ref.read(bookingDetailControllerProvider(bookingId).notifier);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Booking Inspection',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () => controller.loadAll(),
          ),
        ],
      ),
      body: SafeArea(
        child: state.booking.when(
          data: (booking) => state.timeline.when(
            data: (timeline) => ResponsiveLayout(
              mobile: _buildBody(context, booking, timeline, state, controller, currentUser, isMobile: true),
              desktop: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: _buildBody(context, booking, timeline, state, controller, currentUser, isMobile: false),
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.secondary)),
            error: (err, _) => _buildError(err.toString(), controller),
          ),
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.secondary)),
          error: (err, _) => _buildError(err.toString(), controller),
        ),
      ),
    );
  }

  Widget _buildError(String message, BookingDetailController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text('Error: $message', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.loadAll(),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.black),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    BookingModel booking,
    dynamic timeline,
    BookingDetailState state,
    BookingDetailController controller,
    UserModel? currentUser, {
    required bool isMobile,
  }) {
    final isCancelled = booking.status.toLowerCase() == 'cancelled';
    final isDelivered = booking.status.toLowerCase() == 'delivered' ||
        booking.status.toLowerCase() == 'completed' ||
        booking.status.toLowerCase() == 'delivered_on_whatsapp';

    final canCancel = !isCancelled &&
        !isDelivered &&
        (booking.status.toLowerCase() == 'pending' ||
            booking.status.toLowerCase() == 'assigned' ||
            booking.status.toLowerCase() == 'creator_assigned' ||
            currentUser?.role == UserRole.admin);

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 20),
      children: [
        // Feedback banners
        if (state.successMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(state.successMessage!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
        if (state.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(state.errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],

        // Header Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking.bookingCode,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? AppColors.error.withOpacity(0.15)
                          : (isDelivered ? AppColors.success.withOpacity(0.15) : AppColors.primary.withOpacity(0.15)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isCancelled
                            ? AppColors.error
                            : (isDelivered ? AppColors.success : AppColors.primary),
                      ),
                    ),
                    child: Text(
                      booking.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCancelled
                            ? AppColors.error
                            : (isDelivered ? AppColors.success : AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                booking.packageName,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking.formattedSchedule,
                    style: const TextStyle(fontSize: 13, color: AppColors.secondary, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '₹${booking.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Payment Details & COD Breakdown Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.payment_rounded, color: AppColors.secondary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Payment & Settlement',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (booking.isPaidInFull
                              ? AppColors.success
                              : (booking.isAdvancePaid ? AppColors.warning : AppColors.error))
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (booking.isPaidInFull
                                ? AppColors.success
                                : (booking.isAdvancePaid ? AppColors.warning : AppColors.error))
                            .withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      booking.paymentStatus.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: booking.isPaidInFull
                            ? AppColors.success
                            : (booking.isAdvancePaid ? AppColors.warning : AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Method', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                  Text(
                    booking.isCod ? 'Cash on Delivery (Advance)' : 'Razorpay Full Payment',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Package Price', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                  Text(
                    '₹${booking.price.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
              if (booking.isCod) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Online Advance Paid', style: TextStyle(color: AppColors.warning, fontSize: 13)),
                    Text(
                      '₹${booking.advanceAmount.toStringAsFixed(2)}',
                      style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cash on Delivery Balance', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                    Text(
                      booking.cashCollected
                          ? '₹0.00 (Collected On-Site)'
                          : '₹${booking.remainingAmount.toStringAsFixed(2)} (Pending On-Site)',
                      style: TextStyle(
                        color: booking.cashCollected ? AppColors.success : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Videographer Assignment Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Assigned Videographer',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  if (booking.creatorName == null && currentUser?.role == UserRole.admin)
                    ElevatedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => AssignCreatorDialog(
                            bookingCode: booking.bookingCode,
                            city: booking.city,
                            onAssign: (cid, note) => controller.assignCreator(creatorId: cid, note: note),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add, size: 14),
                      label: const Text('Assign'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (booking.creatorName != null) ...[
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.secondary.withOpacity(0.2),
                      child: const Icon(Icons.camera_alt_rounded, color: AppColors.secondary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.creatorName!,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          if (booking.creatorCameraGear != null)
                            Text(
                              booking.creatorCameraGear!,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (booking.creatorWhatsapp != null) ...[
                      IconButton(
                        icon: const Icon(Icons.phone_rounded, color: AppColors.primary),
                        onPressed: () => _callPhone(booking.creatorWhatsapp!),
                        tooltip: 'Call Creator',
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366)),
                        onPressed: () => _openWhatsApp(booking.creatorWhatsapp!, booking.bookingCode),
                        tooltip: 'WhatsApp Creator',
                      ),
                    ],
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Matching with the best local videographer in your city...',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Delivered Reel Link (if completed)
        if (isDelivered && booking.reelUrl != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.success.withOpacity(0.18), AppColors.surfaceDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_rounded, color: AppColors.success, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Reel Delivered to WhatsApp',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your 4K edited reel has been shared with you directly on WhatsApp. You can also view or download it below.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, height: 1.4),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchUrl(booking.reelUrl!),
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                    label: const Text('Open / Download Reel Video', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Venue & Client Info
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shoot Venue & Location Details',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${booking.city} Hub',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          booking.locationAddress,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes_rounded, size: 16, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.notes!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Live Status Timeline
        BookingStatusTimelineWidget(timeline: timeline),
        const SizedBox(height: 24),

        // Cancellation Button
        if (canCancel) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => CancelBookingDialog(
                    bookingCode: booking.bookingCode,
                    onConfirm: (reason, note) => controller.cancelBooking(reason: reason, note: note),
                  ),
                );
              },
              icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.error),
              label: const Text('Cancel Booking', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}
