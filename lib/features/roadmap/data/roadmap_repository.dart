import '../../../core/models/roadmap_step.dart';
import '../../../core/network/api_client.dart';

class RoadmapRepository {
  final ApiClient _api = ApiClient.instance;

  /// GET /api/v1/users/{userId}/roadmap — topologically-sorted, ordered
  /// by stepOrder.
  Future<List<RoadmapStep>> getRoadmap(int userId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/users/$userId/roadmap'),
      (data) => (data as List<dynamic>)
          .map((e) => RoadmapStep.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.stepOrder.compareTo(b.stepOrder)),
    );
  }

  /// PATCH /api/v1/users/{userId}/roadmap/{stepId} — marks a step done and
  /// returns the updated step.
  Future<RoadmapStep> markDone(int userId, int stepId) {
    return _api.unwrap(
      (dio) => dio.patch('/api/v1/users/$userId/roadmap/$stepId'),
      (data) => RoadmapStep.fromJson(data as Map<String, dynamic>),
    );
  }
}
