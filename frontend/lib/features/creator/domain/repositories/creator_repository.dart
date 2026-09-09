import 'package:instant_reel/features/creator/domain/models/creator_dashboard_model.dart';
import 'package:instant_reel/features/customer/domain/models/booking_model.dart';

abstract class CreatorRepository {
  Future<CreatorDashboardModel> getDashboardStats();

  Future<List<BookingModel>> getCreatorBookings({String tab = 'today'});

  Future<BookingModel> getBookingDetail(String bookingId);

  Future<BookingModel> acceptBooking(String bookingId);

  Future<BookingModel> rejectBooking(String bookingId, {String? reason});

  Future<BookingModel> updateStatus(
    String bookingId, {
    required String status,
    String? note,
    String? reelUrl,
  });

  Future<BookingModel> deliverReel(
    String bookingId, {
    required String reelUrl,
    String? note,
  });

  Future<bool> toggleAvailability(bool isAvailable);
}
