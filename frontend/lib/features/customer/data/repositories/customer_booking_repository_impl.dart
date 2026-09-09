import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/features/customer/data/datasources/customer_booking_remote_datasource.dart';
import 'package:instant_reel/features/customer/domain/models/booking_model.dart';
import 'package:instant_reel/features/customer/domain/models/event_type.dart';
import 'package:instant_reel/features/customer/domain/models/package_model.dart';
import 'package:instant_reel/features/customer/domain/repositories/customer_booking_repository.dart';

final customerBookingRepositoryProvider =
    Provider<CustomerBookingRepository>((ref) {
  final remoteDataSource =
      ref.watch(customerBookingRemoteDataSourceProvider);
  return CustomerBookingRepositoryImpl(remoteDataSource: remoteDataSource);
});

class CustomerBookingRepositoryImpl implements CustomerBookingRepository {
  final CustomerBookingRemoteDataSource _remoteDataSource;

  CustomerBookingRepositoryImpl({
    required CustomerBookingRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<List<PackageModel>> getPackages() async {
    final list = await _remoteDataSource.fetchPackages();
    return list
        .map((item) => PackageModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BookingModel> createBooking({
    required EventType eventType,
    required String packageId,
    required String city,
    required String locationAddress,
    required DateTime scheduledAt,
    required String customerWhatsapp,
    String? notes,
  }) async {
    final payload = {
      'event_type': eventType.toApiKey(),
      'package_id': packageId,
      'city': city,
      'location_address': locationAddress,
      'scheduled_at': scheduledAt.toIso8601String(),
      'customer_whatsapp': customerWhatsapp,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final json = await _remoteDataSource.createBooking(payload);
    return BookingModel.fromJson(json);
  }

  @override
  Future<List<BookingModel>> getActiveBookings() async {
    final list = await _remoteDataSource.fetchActiveBookings();
    return list
        .map((item) => BookingModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<BookingModel>> getBookingHistory() async {
    final list = await _remoteDataSource.fetchBookingHistory();
    return list
        .map((item) => BookingModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BookingModel> getBookingDetail(String bookingId) async {
    final json = await _remoteDataSource.fetchBookingDetail(bookingId);
    return BookingModel.fromJson(json);
  }

  @override
  Future<BookingModel> cancelBooking(String bookingId) async {
    final json = await _remoteDataSource.cancelBooking(bookingId);
    return BookingModel.fromJson(json);
  }
}
