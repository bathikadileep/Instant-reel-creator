import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/core/network/api_client.dart';
import 'package:instant_reel/features/creator/domain/models/creator_dashboard_model.dart';
import 'package:instant_reel/features/customer/domain/models/booking_model.dart';

final creatorRemoteDataSourceProvider = Provider<CreatorRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return CreatorRemoteDataSourceImpl(dio: dio);
});

abstract class CreatorRemoteDataSource {
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
  Future<Map<String, dynamic>> sendReel(String bookingId);
  Future<BookingModel> markDelivered(String bookingId, {String? note});
  Future<bool> toggleAvailability(bool isAvailable);
}

class CreatorRemoteDataSourceImpl implements CreatorRemoteDataSource {
  final Dio _dio;

  CreatorRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<CreatorDashboardModel> getDashboardStats() async {
    final response = await _dio.get('/api/v1/creator/dashboard');
    return CreatorDashboardModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<BookingModel>> getCreatorBookings({String tab = 'today'}) async {
    final response = await _dio.get(
      '/api/v1/creator/bookings',
      queryParameters: {'tab': tab},
    );
    final list = response.data as List<dynamic>;
    return list.map((json) => BookingModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<BookingModel> getBookingDetail(String bookingId) async {
    final response = await _dio.get('/api/v1/creator/bookings/$bookingId');
    return BookingModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<BookingModel> acceptBooking(String bookingId) async {
    final response = await _dio.post('/api/v1/creator/bookings/$bookingId/accept');
    return BookingModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<BookingModel> rejectBooking(String bookingId, {String? reason}) async {
    final response = await _dio.post(
      '/api/v1/creator/bookings/$bookingId/reject',
      data: {'reason': reason},
    );
    return BookingModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<BookingModel> updateStatus(
    String bookingId, {
    required String status,
    String? note,
    String? reelUrl,
  }) async {
    final response = await _dio.post(
      '/api/v1/creator/bookings/$bookingId/status',
      data: {
        'status': status,
        if (note != null) 'note': note,
        if (reelUrl != null) 'reel_url': reelUrl,
      },
    );
    return BookingModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<BookingModel> deliverReel(
    String bookingId, {
    required String reelUrl,
    String? note,
  }) async {
    final response = await _dio.post(
      '/api/v1/creator/bookings/$bookingId/deliver',
      data: {
        'reel_url': reelUrl,
        'note': note ?? 'Reel delivered directly to customer via WhatsApp',
      },
    );
    return BookingModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> sendReel(String bookingId) async {
    final response = await _dio.post('/api/v1/creator/bookings/$bookingId/send-reel');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<BookingModel> markDelivered(String bookingId, {String? note}) async {
    final response = await _dio.post(
      '/api/v1/creator/bookings/$bookingId/mark-delivered',
      data: note != null ? {'note': note} : {},
    );
    return BookingModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<bool> toggleAvailability(bool isAvailable) async {
    final response = await _dio.post(
      '/api/v1/creator/availability',
      data: {'is_available': isAvailable},
    );
    return response.data['is_available'] as bool? ?? isAvailable;
  }
}
