import 'package:flutter/material.dart';
import 'package:instant_reel/core/theme/app_colors.dart';
import 'package:instant_reel/features/booking_management/domain/models/booking_timeline_model.dart';

class BookingStatusTimelineWidget extends StatelessWidget {
  final BookingTimelineModel timeline;

  const BookingStatusTimelineWidget({
    super.key,
    required this.timeline,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'assigned':
      case 'creator_assigned':
        return AppColors.primary;
      case 'on_the_way':
        return AppColors.accent;
      case 'reached':
      case 'arrived_at_location':
        return Colors.teal;
      case 'shooting_started':
      case 'shooting_in_progress':
        return AppColors.secondary;
      case 'shooting_completed':
        return Colors.purple;
      case 'editing_started':
      case 'editing':
        return Colors.amber;
      case 'editing_completed':
        return Colors.indigo;
      case 'delivered':
      case 'delivered_on_whatsapp':
      case 'completed':
        return AppColors.success;
      case 'cancelled':
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'assigned':
      case 'creator_assigned':
        return Icons.person_pin_rounded;
      case 'on_the_way':
        return Icons.directions_bike_rounded;
      case 'reached':
      case 'arrived_at_location':
        return Icons.pin_drop_rounded;
      case 'shooting_started':
      case 'shooting_in_progress':
        return Icons.videocam_rounded;
      case 'shooting_completed':
        return Icons.video_collection_rounded;
      case 'editing_started':
      case 'editing':
        return Icons.timer_rounded;
      case 'editing_completed':
        return Icons.check_circle_outline_rounded;
      case 'delivered':
      case 'delivered_on_whatsapp':
      case 'completed':
        return Icons.verified_rounded;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = timeline.events;

    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardDark),
        ),
        child: const Center(
          child: Text(
            'No status events recorded yet',
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
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
                  Icon(Icons.timeline_rounded, color: AppColors.secondary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Live Status Timeline & SLA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${events.length} Events',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Vertical Stepper
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isLast = index == events.length - 1;
              final color = _getStatusColor(event.status);
              final icon = _getStatusIcon(event.status);

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Node + Line
                    Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 2),
                            boxShadow: isLast
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.4),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Icon(icon, size: 16, color: color),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: AppColors.cardDark,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Event Details
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    event.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isLast ? FontWeight.bold : FontWeight.w600,
                                      color: isLast ? Colors.white : Colors.white70,
                                    ),
                                  ),
                                ),
                                Text(
                                  event.formattedTime,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondaryDark,
                                  ),
                                ),
                              ],
                            ),
                            if (event.changedByName != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'By ${event.changedByName} (${event.changedByRole ?? "user"})',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            if (event.note != null && event.note!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.cardDark,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  event.note!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondaryDark,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
