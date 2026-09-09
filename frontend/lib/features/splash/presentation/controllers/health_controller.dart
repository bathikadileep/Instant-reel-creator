import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/core/utils/logger.dart';
import 'package:instant_reel/features/splash/data/repositories/health_repository_impl.dart';
import 'package:instant_reel/features/splash/domain/repositories/health_repository.dart';

enum HealthStatus { initial, loading, connected, disconnected }

class HealthState extends Equatable {
  final HealthStatus status;
  final String? apiVersion;
  final String? dbStatus;
  final String? errorMessage;

  const HealthState({
    this.status = HealthStatus.initial,
    this.apiVersion,
    this.dbStatus,
    this.errorMessage,
  });

  HealthState copyWith({
    HealthStatus? status,
    String? apiVersion,
    String? dbStatus,
    String? errorMessage,
  }) {
    return HealthState(
      status: status ?? this.status,
      apiVersion: apiVersion ?? this.apiVersion,
      dbStatus: dbStatus ?? this.dbStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, apiVersion, dbStatus, errorMessage];
}

final healthControllerProvider =
    StateNotifierProvider<HealthController, HealthState>((ref) {
  final repository = ref.watch(healthRepositoryProvider);
  return HealthController(repository: repository);
});

class HealthController extends StateNotifier<HealthState> {
  final HealthRepository _repository;

  HealthController({required HealthRepository repository})
      : _repository = repository,
        super(const HealthState()) {
    checkSystemStatus();
  }

  Future<void> checkSystemStatus() async {
    state = state.copyWith(status: HealthStatus.loading);
    try {
      final apiHealth = await _repository.checkApiHealth();
      final dbHealth = await _repository.checkDbHealth();

      final isHealthy = apiHealth['status'] == 'healthy' &&
          dbHealth['status'] == 'connected';

      state = state.copyWith(
        status: isHealthy ? HealthStatus.connected : HealthStatus.disconnected,
        apiVersion: apiHealth['version'] as String?,
        dbStatus: dbHealth['database'] != null
            ? '${dbHealth['database']} (${dbHealth['status']})'
            : 'Disconnected',
      );
    } catch (e) {
      AppLogger.w('Backend not yet reachable on current network: $e');
      state = state.copyWith(
        status: HealthStatus.disconnected,
        errorMessage: 'Backend offline or waiting for connection',
        dbStatus: 'Pending Neon DB configuration',
      );
    }
  }
}
