import 'package:instant_reel/features/customer/domain/models/booking_model.dart';

class CreatorDashboardModel {
  final int todayBookingsCount;
  final int completedBookingsCount;
  final double todayEarnings;
  final double totalEarnings;
  final double ratingAvg;
  final int totalReviews;
  final bool isAvailable;
  final String? primaryCity;
  final List<BookingModel> todayBookings;

  const CreatorDashboardModel({
    required this.todayBookingsCount,
    required this.completedBookingsCount,
    required this.todayEarnings,
    required this.totalEarnings,
    required this.ratingAvg,
    required this.totalReviews,
    required this.isAvailable,
    this.primaryCity,
    required this.todayBookings,
  });

  factory CreatorDashboardModel.fromJson(Map<String, dynamic> json) {
    return CreatorDashboardModel(
      todayBookingsCount: json['today_bookings_count'] as int? ?? 0,
      completedBookingsCount: json['completed_bookings_count'] as int? ?? 0,
      todayEarnings: (json['today_earnings'] as num?)?.toDouble() ?? 0.0,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 5.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      isAvailable: json['is_available'] as bool? ?? true,
      primaryCity: json['primary_city'] as String?,
      todayBookings: (json['today_bookings'] as List<dynamic>?)
              ?.map((b) => BookingModel.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  CreatorDashboardModel copyWith({
    int? todayBookingsCount,
    int? completedBookingsCount,
    double? todayEarnings,
    double? totalEarnings,
    double? ratingAvg,
    int? totalReviews,
    bool? isAvailable,
    String? primaryCity,
    List<BookingModel>? todayBookings,
  }) {
    return CreatorDashboardModel(
      todayBookingsCount: todayBookingsCount ?? this.todayBookingsCount,
      completedBookingsCount: completedBookingsCount ?? this.completedBookingsCount,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      totalReviews: totalReviews ?? this.totalReviews,
      isAvailable: isAvailable ?? this.isAvailable,
      primaryCity: primaryCity ?? this.primaryCity,
      todayBookings: todayBookings ?? this.todayBookings,
    );
  }
}
