import '../../../core/models/dashboard.dart';
import '../../../core/network/api_client.dart';

/// GET /api/v1/users/{userId}/dashboard — one call feeds the whole screen:
/// career progress ring, roadmap completion %, next 3 skills, active projects.
class DashboardRepository {
  final ApiClient _api = ApiClient.instance;

  Future<DashboardData> getDashboard(int userId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/users/$userId/dashboard'),
      (data) => DashboardData.fromJson(data as Map<String, dynamic>),
    );
  }
}
