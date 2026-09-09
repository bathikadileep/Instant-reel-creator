import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/core/constants/api_endpoints.dart';
import 'package:instant_reel/core/network/api_client.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(apiClient: apiClient);
});

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> sendOtp(String mobile);
  Future<Map<String, dynamic>> verifyOtp(String mobile, String otp);
  Future<Map<String, dynamic>> login({
    required String mobile,
    required String otp,
    String? role,
    String? name,
  });
  Future<Map<String, dynamic>> refreshToken(String refreshToken);
  Future<Map<String, dynamic>> getCurrentUser();
  Future<Map<String, dynamic>> selectRole(String role);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Map<String, dynamic>> sendOtp(String mobile) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.sendOtp,
      data: {'mobile': mobile},
    );
    return response.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(String mobile, String otp) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.verifyOtp,
      data: {'mobile': mobile, 'otp': otp},
    );
    return response.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> login({
    required String mobile,
    required String otp,
    String? role,
    String? name,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {
        'mobile': mobile,
        'otp': otp,
        if (role != null) 'role': role,
        if (name != null) 'name': name,
      },
    );
    return response.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.refreshToken,
      data: {'refresh_token': refreshToken},
    );
    return response.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.me,
    );
    return response.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> selectRole(String role) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.selectRole,
      data: {'role': role},
    );
    return response.data ?? {};
  }
}
