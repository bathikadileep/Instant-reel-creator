import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/core/network/api_client.dart';
import 'package:instant_reel/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:instant_reel/features/auth/domain/models/auth_tokens.dart';
import 'package:instant_reel/features/auth/domain/models/user_model.dart';
import 'package:instant_reel/features/auth/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    apiClient: apiClient,
  );
});

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final ApiClient _apiClient;

  AuthTokens? _cachedTokens;
  UserModel? _cachedUser;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required ApiClient apiClient,
  })  : _remoteDataSource = remoteDataSource,
        _apiClient = apiClient;

  @override
  AuthTokens? getCachedTokens() => _cachedTokens;

  @override
  UserModel? getCachedUser() => _cachedUser;

  @override
  Future<Map<String, dynamic>> sendOtp(String mobile) async {
    return await _remoteDataSource.sendOtp(mobile);
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(String mobile, String otp) async {
    return await _remoteDataSource.verifyOtp(mobile, otp);
  }

  @override
  Future<Map<String, dynamic>> login({
    required String mobile,
    required String otp,
    UserRole? role,
    String? name,
  }) async {
    final response = await _remoteDataSource.login(
      mobile: mobile,
      otp: otp,
      role: role?.toApiString(),
      name: name,
    );

    if (response.containsKey('access_token')) {
      _cachedTokens = AuthTokens.fromJson(response);
      _cachedUser = UserModel.fromJson(response['user'] as Map<String, dynamic>);
      _apiClient.setAuthToken(_cachedTokens!.accessToken);
    }

    return response;
  }

  @override
  Future<AuthTokens> refreshToken(String refreshToken) async {
    final response = await _remoteDataSource.refreshToken(refreshToken);
    _cachedTokens = AuthTokens.fromJson(response);
    _apiClient.setAuthToken(_cachedTokens!.accessToken);
    if (response.containsKey('user')) {
      _cachedUser = UserModel.fromJson(response['user'] as Map<String, dynamic>);
    }
    return _cachedTokens!;
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await _remoteDataSource.getCurrentUser();
    _cachedUser = UserModel.fromJson(response);
    return _cachedUser!;
  }

  @override
  Future<UserModel> selectRole(UserRole role) async {
    final response = await _remoteDataSource.selectRole(role.toApiString());
    _cachedUser = UserModel.fromJson(response);
    return _cachedUser!;
  }

  @override
  Future<void> logout() async {
    _cachedTokens = null;
    _cachedUser = null;
    _apiClient.setAuthToken(null);
  }
}
