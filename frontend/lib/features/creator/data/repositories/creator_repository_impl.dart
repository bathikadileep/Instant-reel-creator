import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/features/creator/data/datasources/creator_remote_datasource.dart';
import 'package:instant_reel/features/creator/domain/models/creator_dashboard_model.dart';
import 'package:instant_reel/features/creator/domain/repositories/creator_repository.dart';
import 'package:instant_reel/features/customer/domain/models/booking_model.dart';

final creatorRepositoryProvider = Provider<CreatorRepository>((ref) {
  final remoteDataSource = ref.watch(creatorRemoteDataSourceProvider);
  return CreatorRepositoryImpl(remoteDataSource: remoteDataSource);
});

class CreatorRepositoryImpl implements CreatorRepository {
  final CreatorRemoteDataSource _remoteDataSource;

  CreatorRepositoryImpl({required CreatorRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<CreatorDashboardModel> getDashboardStats() {
    return _remoteDataSource.getDashboardStats();
  }

  @override
  Future<List<BookingModel>> getCreatorBookings({String tab = 'today'}) {
    return _remoteDataSource.getCreatorBookings(tab: tab);
  }

  @override
  Future<BookingModel> getBookingDetail(String bookingId) {
    return _remoteDataSource.getBookingDetail(bookingId);
  }

  @override
  Future<BookingModel> acceptBooking(String bookingId) {
    return _remoteDataSource.acceptBooking(bookingId);
  }

  @override
  Future<BookingModel> rejectBooking(String bookingId, {String? reason}) {
    return _remoteDataSource.rejectBooking(bookingId, reason: reason);
  }

  @override
  Future<BookingModel> updateStatus(
    String bookingId, {
    required String status,
    String? note,
    String? reelUrl,
  }) {
    return _remoteDataSource.updateStatus(
      bookingId,
      status: status,
      note: note,
      reelUrl: reelUrl,
    );
  }

  @override
  Future<BookingModel> deliverReel(
    String bookingId, {
    required String reelUrl,
    String? note,
  }) {
    return _remoteDataSource.deliverReel(
      bookingId,
      reelUrl: reelUrl,
      note: note,
    );
  }

  @override
  Future<bool> toggleAvailability(bool isAvailable) {
    return _remoteDataSource.toggleAvailability(isAvailable);
  }
}
