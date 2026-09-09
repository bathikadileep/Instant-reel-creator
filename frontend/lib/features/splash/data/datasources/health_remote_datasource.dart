import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_reel/core/constants/api_endpoints.dart';
import 'package:instant_reel/core/network/api_client.dart';

final healthRemoteDataSourceProvider = Provider<HealthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HealthRemoteDataSourceImpl(apiClient: apiClient);
});

abstract class HealthRemoteDataSource {
  Future<Map<String, dynamic>> fetchApiHealth();
  Future<Map<String, dynamic>> fetchDbHealth();
}

class HealthRemoteDataSourceImpl implements HealthRemoteDataSource {
  final ApiClient _apiClient;

  HealthRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Map<String, dynamic>> fetchApiHealth() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.health,
    );
    return response.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> fetchDbHealth() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.dbHealth,
    );
    return response.data ?? {};
  }
}
