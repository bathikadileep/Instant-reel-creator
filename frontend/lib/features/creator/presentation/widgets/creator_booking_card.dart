import 'package:flutter/material.dart';
import 'package:instant_reel/core/theme/app_colors.dart';
import 'package:instant_reel/features/creator/domain/models/creator_booking_status.dart';
import 'package:instant_reel/features/customer/domain/models/booking_model.dart';
import 'package:url_launcher/url_launcher.dart';

class CreatorBookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const CreatorBookingCard({
    super.key,
    required this.booking,
    required this.onTap,
    this.onAccept,
    this.onReject,
  });

  Future<void> _openWhatsAppChat() async {
    final cleanPhone = booking.customerWhatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    final url = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workflow = CreatorWorkflowStatus.fromString(booking.status);
    final isPending = workflow == CreatorWorkflowStatus.pending;
    final isDelivered = workflow == CreatorWorkflowStatus.delivered || workflow == CreatorWorkflowStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending ? AppColors.warning.withOpacity(0.5) : AppColors.cardDark,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Code + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.videocam_rounded, color: AppColors.secondary, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          booking.bookingCode,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: workflow.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: workflow.color.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(workflow.icon, size: 12, color: workflow.color),
                          const SizedBox(width: 4),
                          Text(
                            workflow.title,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: workflow.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Package name & price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        booking.packageName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '₹${booking.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Location & City
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.textSecondaryDark, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${booking.city} • ${booking.locationAddress}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Scheduled Date & Time
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: AppColors.textSecondaryDark, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      booking.formattedSchedule,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),

                const Divider(color: AppColors.cardDark, height: 24),

                // Bottom row: Customer Contact & Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.cardDark,
                          child: const Icon(Icons.person, size: 14, color: Colors.white70),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          booking.customerName ?? 'Customer',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF25D366)),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _openWhatsAppChat,
                          tooltip: 'Chat on WhatsApp',
                        ),
                      ],
                    ),

                    // Actions
                    if (isPending)
                      Row(
                        children: [
                          if (onReject != null)
                            TextButton(
                              onPressed: onReject,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Decline'),
                            ),
                          const SizedBox(width: 8),
                          if (onAccept != null)
                            ElevatedButton(
                              onPressed: onAccept,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                        ],
                      )
                    else if (isDelivered)
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          const Text(
                            'Delivered',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                        label: Text(workflow.nextActionLabel ?? 'Update Status'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: workflow.color,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
