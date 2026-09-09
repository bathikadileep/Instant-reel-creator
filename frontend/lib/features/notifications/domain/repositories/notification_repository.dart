import 'package:instant_reel/features/notifications/domain/models/notification_model.dart';

abstract class NotificationRepository {
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
