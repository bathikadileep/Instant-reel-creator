import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/features/booking_management/data/datasources/booking_management_remote_datasource.dart';
import 'package:instant_reel/features/booking_management/domain/models/booking_filter_params.dart';
import 'package:instant_reel/features/booking_management/domain/models/booking_timeline_model.dart';
import 'package:instant_reel/features/booking_management/domain/repositories/booking_management_repository.dart';
import 'package:instant_reel/features/customer/domain/models/booking_model.dart';

final bookingManagementRepositoryProvider = Provider<BookingManagementRepository>((ref) {
  final remoteDataSource = ref.watch(bookingManagementRemoteDataSourceProvider);
  return BookingManagementRepositoryImpl(remoteDataSource: remoteDataSource);
});

class BookingManagementRepositoryImpl implements BookingManagementRepository {
  final BookingManagementRemoteDataSource _remoteDataSource;

  BookingManagementRepositoryImpl({required BookingManagementRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<BookingTimelineModel> getTimeline(String bookingId) {
    return _remoteDataSource.getTimeline(bookingId);
  }

  @override
  Future<BookingModel> getBookingDetail(String bookingId) {
    return _remoteDataSource.getBookingDetail(bookingId);
  }

  @override
  Future<BookingModel> cancelBooking(
    String bookingId, {
    required String reason,
    String? note,
  }) {
    return _remoteDataSource.cancelBooking(
      bookingId,
      reason: reason,
      note: note,
    );
  }

  @override
  Future<BookingModel> assignCreator(
    String bookingId, {
    required String creatorId,
    String? note,
  }) {
    return _remoteDataSource.assignCreator(
      bookingId,
      creatorId: creatorId,
      note: note,
    );
  }

  @override
  Future<List<BookingModel>> listBookings({BookingFilterParams? params}) {
    return _remoteDataSource.listBookings(params: params);
  }

  @override
  Future<List<BookingModel>> getActiveBookings() {
    return _remoteDataSource.getActiveBookings();
  }

  @override
  Future<List<BookingModel>> getBookingHistory() {
    return _remoteDataSource.getBookingHistory();
  }
}
