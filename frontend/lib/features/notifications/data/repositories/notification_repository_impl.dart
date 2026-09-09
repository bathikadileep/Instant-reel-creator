import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:instant_reel/features/notifications/domain/models/notification_model.dart';
import 'package:instant_reel/features/notifications/domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final remoteDataSource = ref.watch(notificationRemoteDataSourceProvider);
  return NotificationRepositoryImpl(remoteDataSource: remoteDataSource);
});

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;

  NotificationRepositoryImpl({
    required NotificationRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<bool> registerDeviceToken({
    required String fcmToken,
    required String deviceType,
    String? deviceName,
  }) {
    return _remoteDataSource.registerDeviceToken(
      fcmToken: fcmToken,
      deviceType: deviceType,
      deviceName: deviceName,
    );
  }

  @override
  Future<bool> unregisterDeviceToken(String fcmToken) {
    return _remoteDataSource.unregisterDeviceToken(fcmToken);
  }

  @override
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
  }) {
    return _remoteDataSource.getNotifications(page: page, limit: limit);
  }

  @override
  Future<int> getUnreadCount() {
    return _remoteDataSource.getUnreadCount();
  }

  @override
  Future<NotificationModel> markAsRead(String notificationId) {
    return _remoteDataSource.markAsRead(notificationId);
  }

  @override
  Future<bool> markAllAsRead() {
    return _remoteDataSource.markAllAsRead();
  }

  @override
  Future<NotificationModel> sendTestNotification({
    required String title,
    required String body,
    String type = 'booking_confirmed',
    Map<String, dynamic>? data,
  }) {
    return _remoteDataSource.sendTestNotification(
      title: title,
      body: body,
      type: type,
      data: data,
    );
  }
}
