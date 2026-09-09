import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/core/constants/api_endpoints.dart';
import 'package:instant_reel/core/network/api_client.dart';
import 'package:instant_reel/features/notifications/domain/models/notification_model.dart';

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationRemoteDataSourceImpl(apiClient: apiClient);
});

abstract class NotificationRemoteDataSource {
  Future<bool> registerDeviceToken({
    required String fcmToken,
    required String deviceType,
    String? deviceName,
  });

  Future<bool> unregisterDeviceToken(String fcmToken);

  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
  });

  Future<int> getUnreadCount();

  Future<NotificationModel> markAsRead(String notificationId);

  Future<bool> markAllAsRead();

  Future<NotificationModel> sendTestNotification({
    required String title,
    required String body,
    String type = 'booking_confirmed',
    Map<String, dynamic>? data,
  });
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient _apiClient;

  NotificationRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<bool> registerDeviceToken({
    required String fcmToken,
    required String deviceType,
    String? deviceName,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.notificationDevices,
      data: {
        'fcm_token': fcmToken,
        'device_type': deviceType,
        if (deviceName != null) 'device_name': deviceName,
      },
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  @override
  Future<bool> unregisterDeviceToken(String fcmToken) async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      ApiEndpoints.notificationDeleteDevice(fcmToken),
    );
    return response.statusCode == 200;
  }

  @override
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.notifications,
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final responseData = response.data;
    if (responseData == null) return [];

    final dynamic items = responseData['items'] ?? responseData['data'];
    if (items is List) {
      return items
          .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.notificationUnreadCount,
    );

    final data = response.data;
    if (data != null && data.containsKey('unread_count')) {
      return (data['unread_count'] as num).toInt();
    }
    return 0;
  }

  @override
  Future<NotificationModel> markAsRead(String notificationId) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      ApiEndpoints.notificationMarkRead(notificationId),
    );
    final data = response.data ?? {};
    return NotificationModel.fromJson(data);
  }

  @override
  Future<bool> markAllAsRead() async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      ApiEndpoints.notificationReadAll,
    );
    return response.statusCode == 200;
  }

  @override
  Future<NotificationModel> sendTestNotification({
    required String title,
    required String body,
    String type = 'booking_confirmed',
    Map<String, dynamic>? data,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.notificationTest,
      data: {
        'title': title,
        'body': body,
        'type': type,
        if (data != null) 'data': data,
      },
    );
    final responseData = response.data ?? {};
    return NotificationModel.fromJson(responseData);
  }
}
