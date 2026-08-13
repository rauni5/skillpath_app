import '../../../core/models/dashboard_summary.dart';
import '../../../core/network/api_client.dart';

/// AI-generated "what's next" summary for the dashboard. Generation is
/// manual (triggered by a refresh button) — this repository just talks to
/// the two endpoints backing that.
class DashboardAiRepository {
  final ApiClient _api = ApiClient.instance;

  /// GET /api/v1/users/{userId}/dashboard/summary — returns null if the
  /// user has never generated a summary yet.
  Future<DashboardSummary?> getSummary(int userId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/users/$userId/dashboard/summary'),
      (data) => data == null
          ? null
          : DashboardSummary.fromJson(data as Map<String, dynamic>),
    );
  }

  /// POST /api/v1/users/{userId}/dashboard/summary/generate — calls Gemini
  /// fresh and overwrites the cached summary.
  Future<DashboardSummary> generateSummary(int userId) {
    return _api.unwrap(
      (dio) => dio.post('/api/v1/users/$userId/dashboard/summary/generate'),
      (data) => DashboardSummary.fromJson(data as Map<String, dynamic>),
    );
  }
}
