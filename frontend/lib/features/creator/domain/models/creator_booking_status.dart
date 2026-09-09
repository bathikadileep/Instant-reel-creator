import 'package:flutter/material.dart';
import 'package:instant_reel/core/theme/app_colors.dart';

enum CreatorWorkflowStatus {
  assigned('assigned', 'Assigned', 'Booking assigned to you', Icons.assignment_turned_in_rounded, AppColors.primary),
  onTheWay('on_the_way', 'On The Way', 'Traveling to client shoot location', Icons.directions_bike_rounded, AppColors.accent),
  reached('reached', 'Reached Venue', 'Arrived at client location', Icons.location_on_rounded, Colors.teal),
  shootingStarted('shooting_started', 'Shooting Started', 'Capturing 4K footage and hook shots', Icons.videocam_rounded, AppColors.secondary),
  shootingCompleted('shooting_completed', 'Shooting Completed', 'Raw clips recorded & verified', Icons.video_collection_rounded, Colors.purple),
  editingStarted('editing_started', '10-Min Editing', 'Rapid on-site edit & color grading', Icons.timer_rounded, AppColors.warning),
  editingCompleted('editing_completed', 'Editing Completed', 'Reel exported & ready for delivery', Icons.check_circle_outline_rounded, Colors.indigo),
  delivered('delivered', 'Delivered', 'Sent directly to customer WhatsApp', Icons.verified_rounded, AppColors.success),
  pending('pending', 'Pending', 'Waiting for videographer assignment', Icons.hourglass_top_rounded, AppColors.textSecondaryDark),
  rejected('rejected', 'Declined', 'Booking was declined', Icons.cancel_outlined, AppColors.error),
  completed('completed', 'Completed', 'Shoot & delivery finished', Icons.task_alt_rounded, AppColors.success),
  cancelled('cancelled', 'Cancelled', 'Booking was cancelled', Icons.block_rounded, AppColors.error);

  final String value;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const CreatorWorkflowStatus(this.value, this.title, this.description, this.icon, this.color);

  static CreatorWorkflowStatus fromString(dynamic val) {
    if (val == null) return CreatorWorkflowStatus.pending;
    if (val is CreatorWorkflowStatus) return val;
    String str;
    if (val is String) {
      str = val;
    } else {
      try {
        str = (val as dynamic).toApiString();
      } catch (_) {
        str = val.toString();
      }
    }
    final normalized = str.toLowerCase().trim();
    switch (normalized) {
      case 'assigned':
      case 'creator_assigned':
        return CreatorWorkflowStatus.assigned;
      case 'on_the_way':
        return CreatorWorkflowStatus.onTheWay;
      case 'reached':
      case 'arrived_at_location':
        return CreatorWorkflowStatus.reached;
      case 'shooting_started':
      case 'shooting_in_progress':
        return CreatorWorkflowStatus.shootingStarted;
      case 'shooting_completed':
        return CreatorWorkflowStatus.shootingCompleted;
      case 'editing_started':
      case 'editing':
        return CreatorWorkflowStatus.editingStarted;
      case 'editing_completed':
        return CreatorWorkflowStatus.editingCompleted;
      case 'delivered':
      case 'delivered_on_whatsapp':
        return CreatorWorkflowStatus.delivered;
      case 'completed':
        return CreatorWorkflowStatus.completed;
      case 'rejected':
        return CreatorWorkflowStatus.rejected;
      case 'cancelled':
        return CreatorWorkflowStatus.cancelled;
      default:
        return CreatorWorkflowStatus.pending;
    }
  }

  CreatorWorkflowStatus? get nextStatus {
    switch (this) {
      case CreatorWorkflowStatus.pending:
        return CreatorWorkflowStatus.assigned;
      case CreatorWorkflowStatus.assigned:
        return CreatorWorkflowStatus.onTheWay;
      case CreatorWorkflowStatus.onTheWay:
        return CreatorWorkflowStatus.reached;
      case CreatorWorkflowStatus.reached:
        return CreatorWorkflowStatus.shootingStarted;
      case CreatorWorkflowStatus.shootingStarted:
        return CreatorWorkflowStatus.shootingCompleted;
      case CreatorWorkflowStatus.shootingCompleted:
        return CreatorWorkflowStatus.editingStarted;
      case CreatorWorkflowStatus.editingStarted:
        return CreatorWorkflowStatus.editingCompleted;
      case CreatorWorkflowStatus.editingCompleted:
        return CreatorWorkflowStatus.delivered;
      default:
        return null;
    }
  }

  String? get nextActionLabel {
    switch (this) {
      case CreatorWorkflowStatus.pending:
        return 'Accept Booking';
      case CreatorWorkflowStatus.assigned:
        return "I'm On The Way";
      case CreatorWorkflowStatus.onTheWay:
        return "I've Reached Venue";
      case CreatorWorkflowStatus.reached:
        return 'Start Shoot';
      case CreatorWorkflowStatus.shootingStarted:
        return 'Finish Shoot';
      case CreatorWorkflowStatus.shootingCompleted:
        return 'Start 10-Min Edit';
      case CreatorWorkflowStatus.editingStarted:
        return 'Finish Editing';
      case CreatorWorkflowStatus.editingCompleted:
        return 'Deliver Reel to WhatsApp';
      default:
        return null;
    }
  }

  int get stepIndex {
    switch (this) {
      case CreatorWorkflowStatus.assigned:
        return 1;
      case CreatorWorkflowStatus.onTheWay:
        return 2;
      case CreatorWorkflowStatus.reached:
        return 3;
      case CreatorWorkflowStatus.shootingStarted:
        return 4;
      case CreatorWorkflowStatus.shootingCompleted:
        return 5;
      case CreatorWorkflowStatus.editingStarted:
        return 6;
      case CreatorWorkflowStatus.editingCompleted:
        return 7;
      case CreatorWorkflowStatus.delivered:
      case CreatorWorkflowStatus.completed:
        return 8;
      default:
        return 0;
    }
  }
}
