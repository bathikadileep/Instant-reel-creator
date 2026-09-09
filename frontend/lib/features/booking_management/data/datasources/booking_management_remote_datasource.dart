import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/core/network/api_client.dart';
import 'package:instant_reel/features/booking_management/domain/models/booking_filter_params.dart';
import 'package:instant_reel/features/booking_management/domain/models/booking_timeline_model.dart';
import 'package:instant_reel/features/customer/domain/models/booking_model.dart';

final bookingManagementRemoteDataSourceProvider = Provider<BookingManagementRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return BookingManagementRemoteDataSourceImpl(dio: dio);
});

abstract class BookingManagementRemoteDataSource {
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

class BookingManagementRemoteDataSourceImpl implements BookingManagementRemoteDataSource {
  final Dio _dio;

  BookingManagementRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<BookingTimelineModel> getTimeline(String bookingId) async {
    final response = await _dio.get('/api/v1/bookings/$bookingId/timeline');
    return BookingTimelineModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<BookingModel> getBookingDetail(String bookingId) async {
    final response = await _dio.get('/api/v1/bookings/$bookingId');
    return BookingModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<BookingModel> cancelBooking(
    String bookingId, {
    required String reason,
    String? note,
  }) async {
    final response = await _dio.post(
      '/api/v1/bookings/$bookingId/cancel',
      data: {
        'reason': reason,
        if (note != null) 'note': note,
      },
    );
    return BookingModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<BookingModel> assignCreator(
    String bookingId, {
    required String creatorId,
    String? note,
  }) async {
    final response = await _dio.post(
      '/api/v1/bookings/$bookingId/assign',
      data: {
        'creator_id': creatorId,
        if (note != null) 'note': note,
      },
    );
    return BookingModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<BookingModel>> listBookings({BookingFilterParams? params}) async {
    final response = await _dio.get(
      '/api/v1/bookings',
      queryParameters: params?.toQueryParameters(),
    );
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items.map((i) => BookingModel.fromJson(i as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<BookingModel>> getActiveBookings() async {
    final response = await _dio.get('/api/v1/bookings/my-bookings');
    final list = response.data as List<dynamic>;
    return list.map((json) => BookingModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<BookingModel>> getBookingHistory() async {
    final response = await _dio.get('/api/v1/bookings/history');
    final list = response.data as List<dynamic>;
    return list.map((json) => BookingModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}
