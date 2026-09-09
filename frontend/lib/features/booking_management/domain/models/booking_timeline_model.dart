class BookingTimelineEventModel {
  final String status;
  final String title;
  final String? note;
  final String? changedById;
  final String? changedByName;
  final String? changedByRole;
  final DateTime timestamp;
  final bool isCurrent;
  final bool isCompleted;

  const BookingTimelineEventModel({
    required this.status,
    required this.title,
    this.note,
    this.changedById,
    this.changedByName,
    this.changedByRole,
    required this.timestamp,
    this.isCurrent = false,
    this.isCompleted = true,
  });

  factory BookingTimelineEventModel.fromJson(Map<String, dynamic> json) {
    return BookingTimelineEventModel(
      status: json['status'] as String? ?? '',
      title: json['title'] as String? ?? '',
      note: json['note'] as String?,
      changedById: json['changed_by_id'] as String?,
      changedByName: json['changed_by_name'] as String?,
      changedByRole: json['changed_by_role'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isCurrent: json['is_current'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? true,
    );
  }

  String get formattedTime {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    final min = timestamp.minute.toString().padLeft(2, '0');
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${monthNames[timestamp.month - 1]} ${timestamp.day}';
    return '$dateStr, $hour:$min $period';
  }
}

class BookingTimelineModel {
  final String bookingId;
  final String bookingCode;
  final String currentStatus;
  final String city;
  final String locationAddress;
  final String? customerName;
  final String? creatorName;
  final DateTime scheduledAt;
  final DateTime? deliveredAt;
  final String? reelUrl;
  final List<BookingTimelineEventModel> events;

  const BookingTimelineModel({
    required this.bookingId,
    required this.bookingCode,
    required this.currentStatus,
    required this.city,
    required this.locationAddress,
    this.customerName,
    this.creatorName,
    required this.scheduledAt,
    this.deliveredAt,
    this.reelUrl,
    required this.events,
  });

  factory BookingTimelineModel.fromJson(Map<String, dynamic> json) {
    return BookingTimelineModel(
      bookingId: json['booking_id'] as String? ?? '',
      bookingCode: json['booking_code'] as String? ?? '',
      currentStatus: json['current_status'] as String? ?? '',
      city: json['city'] as String? ?? '',
      locationAddress: json['location_address'] as String? ?? '',
      customerName: json['customer_name'] as String?,
      creatorName: json['creator_name'] as String?,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at'] as String) : null,
      reelUrl: json['reel_url'] as String?,
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => BookingTimelineEventModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
