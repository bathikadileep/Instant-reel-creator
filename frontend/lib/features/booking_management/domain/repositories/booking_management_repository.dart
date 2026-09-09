import 'package:instant_reel/features/booking_management/domain/models/booking_filter_params.dart';
import 'package:instant_reel/features/booking_management/domain/models/booking_timeline_model.dart';
import 'package:instant_reel/features/customer/domain/models/booking_model.dart';

abstract class BookingManagementRepository {
  Future<BookingTimelineModel> getTimeline(String bookingId);

  Future<BookingModel> getBookingDetail(String bookingId);

  Future<BookingModel> cancelBooking(
    String bookingId, {
    required String reason,
    String? note,
  });

  Future<BookingModel> assignCreator(
    String bookingId, {
    required String creatorId,
    String? note,
  });

  Future<List<BookingModel>> listBookings({BookingFilterParams? params});

  Future<List<BookingModel>> getActiveBookings();

  Future<List<BookingModel>> getBookingHistory();
}
