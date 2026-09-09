import 'package:flutter/material.dart';
import 'package:instant_reel/core/theme/app_colors.dart';
import 'package:instant_reel/features/creator/presentation/controllers/creator_workflow_controller.dart';
import 'package:instant_reel/features/customer/domain/models/booking_model.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppDeliveryCard extends StatefulWidget {
  final BookingModel booking;
  final CreatorWorkflowController controller;
  final bool isActionLoading;

  const WhatsAppDeliveryCard({
    super.key,
    required this.booking,
    required this.controller,
    required this.isActionLoading,
  });

  @override
  State<WhatsAppDeliveryCard> createState() => _WhatsAppDeliveryCardState();
}

class _WhatsAppDeliveryCardState extends State<WhatsAppDeliveryCard> {
  bool _whatsappOpened = false;

  Future<void> _handleSendReel() async {
    final res = await widget.controller.sendReelOnWhatsApp();
    if (res != null && res['whatsapp_url'] != null) {
      final urlStr = res['whatsapp_url'] as String;
      final uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (mounted) {
        setState(() {
          _whatsappOpened = true;
        });
      }
    }
  }

  Future<void> _handleConfirmDelivery() async {
    final noteController = TextEditingController(
      text: 'Vertical 4K reel delivered directly to customer via WhatsApp.',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
            SizedBox(width: 10),
            Text('Confirm Delivery', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Did you attach and send the 4K reel from your gallery to the customer in WhatsApp?',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Delivery Note (Optional):',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: noteController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.cardDark,
                hintText: 'e.g. 4K edited reel sent to client WhatsApp',
                hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Yet', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Delivered!'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.controller.markDelivered(note: noteController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final isDelivered = booking.isDelivered;
    final isShared = booking.isSharedOnWhatsapp || _whatsappOpened;

    if (isDelivered) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF25D366).withOpacity(0.18),
              AppColors.surfaceDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF25D366).withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_rounded, color: Color(0xFF25D366), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reel Delivered on WhatsApp',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (booking.deliveredAt != null)
                        Text(
                          'Delivered at ${booking.formattedDeliveredAt}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF25D366),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'DELIVERED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF25D366),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, color: Colors.white70, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Shared directly to ${booking.customerWhatsapp}. No video is saved on cloud servers (Privacy First).',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isShared ? const Color(0xFF25D366).withOpacity(0.6) : AppColors.cardDark,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_to_mobile_rounded, color: Color(0xFF25D366), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WhatsApp Reel Delivery',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'Direct peer-to-peer delivery to customer',
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isShared ? const Color(0xFF25D366).withOpacity(0.2) : AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isShared ? 'Shared in Chat' : 'Pending Delivery',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isShared ? const Color(0xFF25D366) : AppColors.textSecondaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Target Customer Info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Target Customer WhatsApp',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                      ),
                      Text(
                        booking.customerWhatsapp,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Delivery Flow Steps
          // Step 1: Send Reel Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: widget.isActionLoading ? null : _handleSendReel,
              icon: const Icon(Icons.chat_rounded, size: 20),
              label: Text(
                isShared ? '1. Re-open Customer WhatsApp' : '1. Send Reel via WhatsApp',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Step 1 instructions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Opens WhatsApp with customer. In chat: Tap 📎 > Gallery > Select 4K video > Send.',
              style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.65), height: 1.3),
            ),
          ),
          const SizedBox(height: 16),

          // Step 2: Mark Delivered Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: widget.isActionLoading ? null : _handleConfirmDelivery,
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: const Text(
                '2. Mark Booking Delivered',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isShared ? AppColors.success : AppColors.cardDark,
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: isShared ? AppColors.success : Colors.white24,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Step 2 instructions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Click after reel is sent in WhatsApp. Records delivery timestamp and completes the SLA.',
              style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.65), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
