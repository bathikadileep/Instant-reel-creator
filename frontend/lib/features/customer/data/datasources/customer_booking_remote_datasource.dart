import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/core/network/api_client.dart';

final customerBookingRemoteDataSourceProvider =
    Provider<CustomerBookingRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CustomerBookingRemoteDataSourceImpl(apiClient: apiClient);
});

abstract class CustomerBookingRemoteDataSource {
  Future<List<dynamic>> fetchPackages();
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data);
  Future<List<dynamic>> fetchActiveBookings();
  Future<List<dynamic>> fetchBookingHistory();
  Future<Map<String, dynamic>> fetchBookingDetail(String bookingId);
  Future<Map<String, dynamic>> cancelBooking(String bookingId);
}

class CustomerBookingRemoteDataSourceImpl
    implements CustomerBookingRemoteDataSource {
  final ApiClient _apiClient;

  CustomerBookingRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<dynamic>> fetchPackages() async {
    final response = await _apiClient.get<List<dynamic>>('/packages/');
    return response.data ?? [];
  }

  @override
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/bookings/',
      data: data,
    );
    return response.data ?? {};
  }

  @override
  Future<List<dynamic>> fetchActiveBookings() async {
    final response = await _apiClient.get<List<dynamic>>('/bookings/my-bookings');
    return response.data ?? [];
  }

  @override
  Future<List<dynamic>> fetchBookingHistory() async {
    final response = await _apiClient.get<List<dynamic>>('/bookings/history');
    return response.data ?? [];
  }

  @override
  Future<Map<String, dynamic>> fetchBookingDetail(String bookingId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/bookings/$bookingId',
    );
    return response.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/bookings/$bookingId/cancel',
    );
    return response.data ?? {};
  }
}
