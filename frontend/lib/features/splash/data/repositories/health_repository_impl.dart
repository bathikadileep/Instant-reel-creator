import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/features/splash/data/datasources/health_remote_datasource.dart';
import 'package:instant_reel/features/splash/domain/repositories/health_repository.dart';

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  final remoteDataSource = ref.watch(healthRemoteDataSourceProvider);
  return HealthRepositoryImpl(remoteDataSource: remoteDataSource);
});

class HealthRepositoryImpl implements HealthRepository {
  final HealthRemoteDataSource _remoteDataSource;

  HealthRepositoryImpl({required HealthRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Map<String, dynamic>> checkApiHealth() async {
    return await _remoteDataSource.fetchApiHealth();
  }

  @override
  Future<Map<String, dynamic>> checkDbHealth() async {
    return await _remoteDataSource.fetchDbHealth();
  }
}
