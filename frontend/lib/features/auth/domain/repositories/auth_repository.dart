import 'package:instant_reel/features/auth/domain/models/auth_tokens.dart';
import 'package:instant_reel/features/auth/domain/models/user_model.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>> sendOtp(String mobile);
  Future<Map<String, dynamic>> verifyOtp(String mobile, String otp);
  Future<Map<String, dynamic>> login({
    required String mobile,
    required String otp,
    UserRole? role,
    String? name,
  });
  Future<AuthTokens> refreshToken(String refreshToken);
  Future<UserModel> getCurrentUser();
  Future<UserModel> selectRole(UserRole role);
  Future<void> logout();

  // Token cache helpers
  AuthTokens? getCachedTokens();
  UserModel? getCachedUser();
}
