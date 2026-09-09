import 'package:instant_reel/features/customer/domain/models/booking_model.dart';
import 'package:instant_reel/features/customer/domain/models/event_type.dart';
import 'package:instant_reel/features/customer/domain/models/package_model.dart';

abstract class CustomerBookingRepository {
  Future<List<PackageModel>> getPackages();
  Future<BookingModel> createBooking({
    required EventType eventType,
    required String packageId,
    required String city,
    required String locationAddress,
    required DateTime scheduledAt,
    required String customerWhatsapp,
    String? notes,
  });
  Future<List<BookingModel>> getActiveBookings();
  Future<List<BookingModel>> getBookingHistory();
  Future<BookingModel> getBookingDetail(String bookingId);
  Future<BookingModel> cancelBooking(String bookingId);
}
