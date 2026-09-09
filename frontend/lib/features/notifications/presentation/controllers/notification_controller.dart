import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:instant_reel/features/notifications/domain/models/notification_model.dart';
import 'package:instant_reel/features/notifications/domain/repositories/notification_repository.dart';

class NotificationState {
  final bool isLoading;
  final List<NotificationModel> notifications;
  final int unreadCount;
  final String? errorMessage;
  final bool filterUnreadOnly;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.unreadCount = 0,
    this.errorMessage,
    this.filterUnreadOnly = false,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<NotificationModel>? notifications,
    int? unreadCount,
    String? errorMessage,
    bool? filterUnreadOnly,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: errorMessage,
      filterUnreadOnly: filterUnreadOnly ?? this.filterUnreadOnly,
    );
  }

  List<NotificationModel> get displayedNotifications {
    if (filterUnreadOnly) {
      return notifications.where((n) => !n.isRead).toList();
    }
    return notifications;
  }
}

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, NotificationState>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationController(repository: repository);
});

// Stream/Provider for just unread count so badges update without rebuilding full lists
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationControllerProvider).unreadCount;
});

class NotificationController extends StateNotifier<NotificationState> {
  final NotificationRepository _repository;

  NotificationController({required NotificationRepository repository})
      : _repository = repository,
        super(const NotificationState()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final unreadCount = await _repository.getUnreadCount();
      final items = await _repository.getNotifications(page: 1, limit: 50);

      state = state.copyWith(
        isLoading: false,
        notifications: items,
        unreadCount: unreadCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load notifications: $e',
      );
    }
  }

  Future<void> refresh() async {
    await loadNotifications();
  }

  void toggleFilterUnreadOnly() {
    state = state.copyWith(filterUnreadOnly: !state.filterUnreadOnly);
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      // Optimistic update
      final updatedList = state.notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true, readAt: DateTime.now());
        }
        return n;
      }).toList();

      final newUnreadCount = (state.unreadCount > 0) ? state.unreadCount - 1 : 0;
      state = state.copyWith(
        notifications: updatedList,
        unreadCount: newUnreadCount,
      );

      await _repository.markAsRead(notificationId);
    } catch (e) {
      // Revert if needed or refresh
      await refresh();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      // Optimistic update
      final updatedList = state.notifications
          .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
          .toList();

      state = state.copyWith(
        notifications: updatedList,
        unreadCount: 0,
      );

      await _repository.markAllAsRead();
    } catch (e) {
      await refresh();
    }
  }

  Future<void> sendTestNotification({
    required String title,
    required String body,
    String type = 'booking_confirmed',
    Map<String, dynamic>? data,
  }) async {
    try {
      final newNotification = await _repository.sendTestNotification(
        title: title,
        body: body,
        type: type,
        data: data,
      );

      state = state.copyWith(
        notifications: [newNotification, ...state.notifications],
        unreadCount: state.unreadCount + 1,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Could not send test push: $e');
    }
  }
}
