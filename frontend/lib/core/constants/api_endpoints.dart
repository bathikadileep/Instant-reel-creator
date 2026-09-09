class ApiEndpoints {
  // Base URLs (Switchable for Android Emulator, iOS Simulator, or Production)
  // For Android Emulator: http://10.0.2.2:8000/api/v1
  // For iOS/Web/Desktop: http://localhost:8000/api/v1
  static const String defaultBaseUrl = 'http://localhost:8000/api/v1';

  // System & Health
  static const String health = '/health';
  static const String dbHealth = '/health/db';

  // Authentication & RBAC Endpoints
  static const String sendOtp = '/auth/send_otp';
  static const String verifyOtp = '/auth/verify_otp';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh_token';
  static const String me = '/auth/me';
  static const String selectRole = '/auth/select_role';

  // Payment & COD Endpoints
  static const String paymentConfig = '/payments/config';
  static const String createPaymentOrder = '/payments/create-order';
  static const String verifyPayment = '/payments/verify';
  static const String collectCash = '/payments/collect-cash';
  static const String paymentSummary = '/payments/admin/summary';
  static const String allPayments = '/payments/admin/all';

  // Notifications & FCM Endpoints
  static const String notifications = '/notifications';
  static const String notificationDevices = '/notifications/devices';
  static const String notificationUnreadCount = '/notifications/unread-count';
  static const String notificationReadAll = '/notifications/read-all';
  static String notificationMarkRead(String id) => '/notifications/$id/read';
  static String notificationDeleteDevice(String token) => '/notifications/devices/$token';
  static const String notificationTest = '/notifications/test';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
