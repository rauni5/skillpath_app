import '../../../core/models/career_role.dart';
import '../../../core/models/gap_analysis.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class CareerRepository {
  final ApiClient _api = ApiClient.instance;

  /// GET /api/v1/career-roles
  Future<List<CareerRole>> getCareerRoles() {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/career-roles'),
      (data) => (data as List<dynamic>).map((e) => CareerRole.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  /// POST /api/v1/users/{userId}/career-goal
  Future<void> setCareerGoal(int userId, int roleId) {
    return _api.unwrap(
      (dio) => dio.post('/api/v1/users/$userId/career-goal', data: {'roleId': roleId}),
      (_) {},
    );
  }

  /// GET /api/v1/users/{userId}/career-goal/gap
  ///
  /// Returns [GapAnalysis.empty] instead of throwing when the backend
  /// signals "no goal set yet" — whether that's an error response or a
  /// 200 with null fields varies by implementation, so both are treated
  /// the same way by the caller.
  Future<GapAnalysis> getGapAnalysis(int userId) async {
    try {
      return await _api.unwrap(
        (dio) => dio.get('/api/v1/users/$userId/career-goal/gap'),
        (data) => GapAnalysis.fromJson(data as Map<String, dynamic>),
      );
    } on ApiException {
      return GapAnalysis.empty();
    }
  }
}
