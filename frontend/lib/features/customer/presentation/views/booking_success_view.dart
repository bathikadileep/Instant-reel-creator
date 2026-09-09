import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:instant_reel/core/router/route_names.dart';
import 'package:instant_reel/core/theme/app_colors.dart';
import 'package:instant_reel/core/utils/responsive_layout.dart';
import 'package:instant_reel/features/customer/domain/models/booking_model.dart';

class BookingSuccessView extends StatelessWidget {
  final BookingModel? booking;

  const BookingSuccessView({Key? key, this.booking}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _buildContent(context, isMobile: true),
          desktop: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Card(
                elevation: 0,
                color: AppColors.surfaceDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: AppColors.borderDark),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(36.0),
                  child: _buildContent(context, isMobile: false),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, {required bool isMobile}) {
    final bookingCode = booking?.bookingCode ?? 'IR-2026';
    final city = booking?.city ?? 'Telangana';
    final whatsapp = booking?.customerWhatsapp ?? '';

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24.0 : 0,
        vertical: 36.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Success Animated Icon
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.success, width: 2),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 56,
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'Booking Confirmed!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'We are matching you with an available pro reel creator in your city.',
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Booking Details Pill
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Booking ID', style: TextStyle(color: AppColors.textSecondaryDark)),
                    Text(
                      bookingCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppColors.borderDark, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('City', style: TextStyle(color: AppColors.textSecondaryDark)),
                    Text(city, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(color: AppColors.borderDark, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Delivery Channel', style: TextStyle(color: AppColors.textSecondaryDark)),
                    Row(
                      children: [
                        const Icon(Icons.chat_rounded, color: AppColors.success, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          whatsapp.isNotEmpty ? whatsapp : 'WhatsApp',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 10-Minute SLA Callout
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
            ),
            child: Row(
              children: const [
                Icon(Icons.timer_outlined, color: AppColors.secondary, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Rapid 10-minute on-site editing promise active. Your creator edits and delivers directly to WhatsApp after the shoot.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // CTAs
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => context.go(RoutePaths.customerDashboard),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('View in My Bookings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go(RoutePaths.customerDashboard),
            child: const Text('Return to Dashboard', style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
        ],
      ),
    );
  }
}
