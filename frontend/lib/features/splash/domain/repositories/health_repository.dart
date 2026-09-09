abstract class HealthRepository {
  Future<Map<String, dynamic>> checkApiHealth();
  Future<Map<String, dynamic>> checkDbHealth();
}
