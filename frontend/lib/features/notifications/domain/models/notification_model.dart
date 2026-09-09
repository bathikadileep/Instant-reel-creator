import 'package:flutter/material.dart';
import 'package:instant_reel/core/theme/app_colors.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      data: json['data'] != null ? Map<String, dynamic>.from(json['data'] as Map) : {},
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'] as String) : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String? get bookingId => data['booking_id'] as String?;
  String? get bookingCode => data['booking_code'] as String?;

  IconData get iconData {
    switch (type) {
      case 'booking_confirmed':
        return Icons.check_circle_outline_rounded;
      case 'creator_assigned':
        return Icons.videocam_rounded;
      case 'creator_reached':
        return Icons.location_on_rounded;
      case 'reel_delivered':
        return Icons.send_rounded;
      case 'new_booking':
        return Icons.bolt_rounded;
      case 'booking_cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color get accentColor {
    switch (type) {
      case 'booking_confirmed':
        return const Color(0xFF10B981); // Emerald Green
      case 'creator_assigned':
        return AppColors.primary; // Royal Blue
      case 'creator_reached':
        return const Color(0xFFF59E0B); // Amber
      case 'reel_delivered':
        return const Color(0xFF25D366); // WhatsApp Green
      case 'new_booking':
        return const Color(0xFF8B5CF6); // Purple
      case 'booking_cancelled':
        return const Color(0xFFEF4444); // Red
      default:
        return AppColors.primary;
    }
  }

  String get typeLabel {
    switch (type) {
      case 'booking_confirmed':
        return 'Confirmed';
      case 'creator_assigned':
        return 'Creator Assigned';
      case 'creator_reached':
        return 'Arrived';
      case 'reel_delivered':
        return 'Delivered';
      case 'new_booking':
        return 'New Booking';
      case 'booking_cancelled':
        return 'Cancelled';
      default:
        return 'Alert';
    }
  }

  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}
