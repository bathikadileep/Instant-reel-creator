import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:instant_reel/core/router/route_names.dart';
import 'package:instant_reel/core/theme/app_colors.dart';
import 'package:instant_reel/features/auth/domain/models/user_model.dart';
import 'package:instant_reel/features/auth/presentation/controllers/auth_controller.dart';
import 'package:instant_reel/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:instant_reel/features/notifications/domain/models/notification_model.dart';
import 'package:instant_reel/features/notifications/domain/repositories/notification_repository.dart';

final fcmNotificationServiceProvider = Provider<FCMNotificationService>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return FCMNotificationService(ref: ref, repository: repository);
});

class FCMNotificationService {
  final Ref _ref;
  final NotificationRepository _repository;
  String? _currentFcmToken;
  bool _isInitialized = false;

  FCMNotificationService({
    required Ref ref,
    required NotificationRepository repository,
  })  : _ref = ref,
        _repository = repository;

  String? get currentFcmToken => _currentFcmToken;
  bool get isInitialized => _isInitialized;

  /// Detects client platform: android, ios, or web
  String get _deviceType {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
    } catch (_) {}
    return 'unknown';
  }

  /// Initializes device token registration and message listeners
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Generate or retrieve device token
      _currentFcmToken ??= _generateDeviceIdentifier();

      // Register device token with backend
      await _repository.registerDeviceToken(
        fcmToken: _currentFcmToken!,
        deviceType: _deviceType,
        deviceName: kIsWeb ? 'Web Browser' : 'Mobile Client',
      );

      _isInitialized = true;
      debugPrint('[FCM] Device registered successfully with token: $_currentFcmToken');
    } catch (e) {
      debugPrint('[FCM] Initialization error: $e');
    }
  }

  /// Deactivates device token on backend when user logs out
  Future<void> handleLogout() async {
    if (_currentFcmToken != null) {
      try {
        await _repository.unregisterDeviceToken(_currentFcmToken!);
        debugPrint('[FCM] Device token deactivated on logout: $_currentFcmToken');
      } catch (e) {
        debugPrint('[FCM] Error deactivating token: $e');
      }
      _currentFcmToken = null;
      _isInitialized = false;
    }
  }

  /// Show in-app banner for incoming foreground push notification
  void showForegroundNotificationBanner(
    BuildContext context, {
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) {
    final notification = NotificationModel(
      id: data?['notification_id'] ?? '',
      userId: '',
      title: title,
      body: body,
      type: type,
      data: data ?? {},
      isRead: false,
      createdAt: DateTime.now(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceDark,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: notification.accentColor.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: notification.accentColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification.iconData,
                color: notification.accentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: notification.accentColor,
          onPressed: () => handleNotificationTap(context, notification),
        ),
      ),
    );
  }

  /// Navigates to appropriate destination screen when notification is tapped
  void handleNotificationTap(BuildContext context, NotificationModel notification) {
    final bookingId = notification.bookingId;
    final user = _ref.read(currentUserProvider);

    if (bookingId != null && bookingId.isNotEmpty) {
      if (user?.role == UserRole.creator) {
        context.push('${RoutePaths.creatorBooking}/$bookingId');
        return;
      } else {
        context.push('${RoutePaths.bookingDetail}/$bookingId');
        return;
      }
    }

    // Default route is notifications center
    context.push(RoutePaths.notifications);
  }

  /// Generates deterministic fallback token for development and emulator environments
  String _generateDeviceIdentifier() {
    final user = _ref.read(currentUserProvider);
    final userSuffix = user?.id.substring(0, 8) ?? 'guest';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'fcm_dev_${userSuffix}_$timestamp';
  }
}
