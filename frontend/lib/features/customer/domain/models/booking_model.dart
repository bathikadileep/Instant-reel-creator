import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:instant_reel/core/theme/app_colors.dart';
import 'package:instant_reel/features/customer/domain/models/package_model.dart';

enum BookingStatus {
  pending,
  creatorAssigned,
  arrivedAtLocation,
  shootingInProgress,
  editing,
  deliveredOnWhatsapp,
  completed,
  cancelled;

  static BookingStatus fromString(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'creator_assigned':
        return BookingStatus.creatorAssigned;
      case 'arrived_at_location':
        return BookingStatus.arrivedAtLocation;
      case 'shooting_in_progress':
        return BookingStatus.shootingInProgress;
      case 'editing':
        return BookingStatus.editing;
      case 'delivered_on_whatsapp':
        return BookingStatus.deliveredOnWhatsapp;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'pending':
      default:
        return BookingStatus.pending;
    }
  }

  String toApiString() {
    switch (this) {
      case BookingStatus.creatorAssigned:
        return 'creator_assigned';
      case BookingStatus.arrivedAtLocation:
        return 'arrived_at_location';
      case BookingStatus.shootingInProgress:
        return 'shooting_in_progress';
      case BookingStatus.editing:
        return 'editing';
      case BookingStatus.deliveredOnWhatsapp:
        return 'delivered_on_whatsapp';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.pending:
        return 'pending';
    }
  }

  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Finding Creator';
      case BookingStatus.creatorAssigned:
        return 'Creator Assigned';
      case BookingStatus.arrivedAtLocation:
        return 'Creator Arrived';
      case BookingStatus.shootingInProgress:
        return 'Shooting Reel';
      case BookingStatus.editing:
        return '10-Min Editing';
      case BookingStatus.deliveredOnWhatsapp:
        return 'Delivered on WhatsApp';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get statusColor {
    switch (this) {
      case BookingStatus.pending:
        return AppColors.warning;
      case BookingStatus.creatorAssigned:
      case BookingStatus.arrivedAtLocation:
        return AppColors.primary;
      case BookingStatus.shootingInProgress:
      case BookingStatus.editing:
        return AppColors.secondary;
      case BookingStatus.deliveredOnWhatsapp:
      case BookingStatus.completed:
        return AppColors.success;
      case BookingStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData get statusIcon {
    switch (this) {
      case BookingStatus.pending:
        return Icons.hourglass_top_rounded;
      case BookingStatus.creatorAssigned:
        return Icons.person_pin_circle_rounded;
      case BookingStatus.arrivedAtLocation:
        return Icons.location_on_rounded;
      case BookingStatus.shootingInProgress:
        return Icons.videocam_rounded;
      case BookingStatus.editing:
        return Icons.movie_edit;
      case BookingStatus.deliveredOnWhatsapp:
        return Icons.mark_chat_read_rounded;
      case BookingStatus.completed:
        return Icons.check_circle_rounded;
      case BookingStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  int get stageStep {
    switch (this) {
      case BookingStatus.pending:
        return 1;
      case BookingStatus.creatorAssigned:
        return 2;
      case BookingStatus.arrivedAtLocation:
        return 3;
      case BookingStatus.shootingInProgress:
        return 4;
      case BookingStatus.editing:
        return 5;
      case BookingStatus.deliveredOnWhatsapp:
      case BookingStatus.completed:
        return 6;
      case BookingStatus.cancelled:
        return 0;
    }
  }
}

class BookingStatusHistoryModel extends Equatable {
  final String id;
  final BookingStatus status;
  final String? note;
  final DateTime createdAt;

  const BookingStatusHistoryModel({
    required this.id,
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory BookingStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return BookingStatusHistoryModel(
      id: json['id'] as String,
      status: BookingStatus.fromString(json['status'] as String? ?? 'pending'),
      note: json['note'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, status, note, createdAt];

  String get formattedTime => DateFormat('hh:mm a, dd MMM').format(createdAt);
}

class BookingModel extends Equatable {
  final String id;
  final String bookingCode;
  final String customerId;
  final String? creatorId;
  final String packageId;
  final BookingStatus status;
  final String city;
  final String locationAddress;
  final DateTime scheduledAt;
  final String customerWhatsapp;
  final String? notes;
  final String? reelUrl;
  final DateTime? deliveredAt;
  final String deliveryStatus;
  final DateTime createdAt;
  final PackageModel? package;
  final Map<String, dynamic>? creator;
  final List<BookingStatusHistoryModel> statusHistory;

  // Payment and COD fields
  final String? paymentMethod;
  final double? totalAmount;
  final double advanceAmount;
  final double remainingAmount;
  final String paymentStatus;
  final bool cashCollected;
  final DateTime? cashCollectedAt;

  const BookingModel({
    required this.id,
    required this.bookingCode,
    required this.customerId,
    this.creatorId,
    required this.packageId,
    required this.status,
    required this.city,
    required this.locationAddress,
    required this.scheduledAt,
    required this.customerWhatsapp,
    this.notes,
    this.reelUrl,
    this.deliveredAt,
    this.deliveryStatus = 'pending',
    required this.createdAt,
    this.package,
    this.creator,
    this.statusHistory = const [],
    this.paymentMethod,
    this.totalAmount,
    this.advanceAmount = 0.0,
    this.remainingAmount = 0.0,
    this.paymentStatus = 'pending',
    this.cashCollected = false,
    this.cashCollectedAt,
  });

  // Getters for display
  String get packageName => package?.name ?? '10-Minute Rapid Reel';
  double get price => totalAmount ?? package?.price ?? 499.0;
  String get formattedSchedule => DateFormat('EEE, d MMM yyyy • h:mm a').format(scheduledAt);

  // Delivery status helpers
  bool get isDelivered =>
      status == BookingStatus.deliveredOnWhatsapp ||
      status == BookingStatus.completed ||
      deliveryStatus == 'delivered';
  bool get isSharedOnWhatsapp => deliveryStatus == 'shared_on_whatsapp';
  bool get isPendingDelivery => deliveryStatus == 'pending';
  String get formattedDeliveredAt =>
      deliveredAt != null ? DateFormat('EEE, d MMM yyyy • h:mm a').format(deliveredAt!.toLocal()) : '';

  // Helpers for creator and customer
  String? get creatorName => creator?['name'] as String?;
  String? get creatorWhatsapp => creator?['mobile'] as String?;
  String? get creatorCameraGear => creator?['profile']?['camera_gear'] as String?;
  String? get customerName => customerWhatsapp.isNotEmpty ? 'Customer ($customerWhatsapp)' : 'Customer';

  // Payment status helpers
  bool get isCod => paymentMethod == 'cod_with_advance';
  bool get isAdvancePaid => paymentStatus.toLowerCase() == 'advance_paid';
  bool get isPaidInFull =>
      paymentStatus.toLowerCase() == 'paid' ||
      (remainingAmount <= 0.0 && paymentStatus.toLowerCase() != 'pending' && paymentStatus.toLowerCase() != 'failed');
  bool get hasOutstandingCash => isCod && !cashCollected && remainingAmount > 0.0;

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      bookingCode: json['booking_code'] as String,
      customerId: json['customer_id'] as String,
      creatorId: json['creator_id'] as String?,
      packageId: json['package_id'] as String,
      status: BookingStatus.fromString(json['status'] as String? ?? 'pending'),
      city: json['city'] as String,
      locationAddress: json['location_address'] as String,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'] as String)
          : DateTime.now(),
      customerWhatsapp: json['customer_whatsapp'] as String,
      notes: json['notes'] as String?,
      reelUrl: json['reel_url'] as String?,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      deliveryStatus: json['delivery_status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      package: json['package'] != null
          ? PackageModel.fromJson(json['package'] as Map<String, dynamic>)
          : null,
      creator: json['creator'] as Map<String, dynamic>?,
      statusHistory: (json['status_history'] as List<dynamic>?)
              ?.map((e) =>
                  BookingStatusHistoryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      paymentMethod: json['payment_method'] as String?,
      totalAmount: json['total_amount'] != null
          ? (json['total_amount'] as num).toDouble()
          : null,
      advanceAmount: json['advance_amount'] != null
          ? (json['advance_amount'] as num).toDouble()
          : 0.0,
      remainingAmount: json['remaining_amount'] != null
          ? (json['remaining_amount'] as num).toDouble()
          : 0.0,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      cashCollected: json['cash_collected'] as bool? ?? false,
      cashCollectedAt: json['cash_collected_at'] != null
          ? DateTime.parse(json['cash_collected_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookingCode,
        customerId,
        creatorId,
        packageId,
        status,
        city,
        locationAddress,
        scheduledAt,
        customerWhatsapp,
        notes,
        reelUrl,
        deliveredAt,
        deliveryStatus,
        createdAt,
        package,
        creator,
        statusHistory,
        paymentMethod,
        totalAmount,
        advanceAmount,
        remainingAmount,
        paymentStatus,
        cashCollected,
        cashCollectedAt,
      ];
}
