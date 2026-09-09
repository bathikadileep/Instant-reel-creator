import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/core/utils/logger.dart';
import 'package:instant_reel/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:instant_reel/features/auth/domain/models/auth_tokens.dart';
import 'package:instant_reel/features/auth/domain/models/user_model.dart';
import 'package:instant_reel/features/auth/domain/repositories/auth_repository.dart';

enum AuthStatus {
  initial,
  loading,
  otpSent,
  needsRoleSelection,
  authenticated,
  unauthenticated,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final AuthTokens? tokens;
  final String? mobile;
  final String? devOtp;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.tokens,
    this.mobile,
    this.devOtp,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    AuthTokens? tokens,
    String? mobile,
    String? devOtp,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      tokens: tokens ?? this.tokens,
      mobile: mobile ?? this.mobile,
      devOtp: devOtp ?? this.devOtp,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        tokens,
        mobile,
        devOtp,
        errorMessage,
      ];
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository: repository);
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authControllerProvider).user;
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController({required AuthRepository repository})
      : _repository = repository,
        super(const AuthState()) {
    checkInitialAuth();
  }

  Future<void> checkInitialAuth() async {
    final cachedTokens = _repository.getCachedTokens();
    if (cachedTokens == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final user = await _repository.getCurrentUser();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        tokens: cachedTokens,
      );
    } catch (e) {
      AppLogger.w('Auto-auth check failed: $e');
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> sendOtp(String mobile) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _repository.sendOtp(mobile);
      final devOtp = response['dev_otp'] as String?;

      state = state.copyWith(
        status: AuthStatus.otpSent,
        mobile: mobile,
        devOtp: devOtp,
      );
      AppLogger.i('OTP successfully sent to $mobile. Dev OTP: $devOtp');
      return true;
    } catch (e) {
      AppLogger.e('Failed to send OTP: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Unable to send OTP. Please verify mobile number and connection.',
      );
      return false;
    }
  }

  Future<bool> loginWithOtp({
    required String otp,
    String? name,
    UserRole? role,
  }) async {
    if (state.mobile == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Mobile number not found. Please re-enter number.',
      );
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _repository.login(
        mobile: state.mobile!,
        otp: otp,
        name: name,
        role: role,
      );

      final tokens = AuthTokens.fromJson(response);
      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        tokens: tokens,
      );
      return true;
    } catch (e) {
      AppLogger.e('Login failed: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Invalid or expired OTP code. Please try again.',
      );
      return false;
    }
  }

  Future<bool> selectRole(UserRole role) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final updatedUser = await _repository.selectRole(role);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: updatedUser,
      );
      return true;
    } catch (e) {
      AppLogger.e('Failed to select role: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Failed to update role. Please retry.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
