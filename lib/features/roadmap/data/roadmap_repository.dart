import 'dart:async';

import '../../../core/cache/cache_store.dart';
import '../../../core/models/roadmap_step.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/cached_result.dart';

class RoadmapRepository {
  final ApiClient _api = ApiClient.instance;

  /// GET /api/v1/users/{userId}/roadmap — topologically-sorted, ordered
  /// by stepOrder.
  Future<CachedResult<List<RoadmapStep>>> getRoadmap(int userId) async {
    final cacheKey = 'roadmap:$userId';
    try {
      final data = await _api.unwrap(
        (dio) => dio.get('/api/v1/users/$userId/roadmap'),
        (data) {
          unawaited(CacheStore.instance.write(cacheKey, data));
          return (data as List<dynamic>)
              .map((e) => RoadmapStep.fromJson(e as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.stepOrder.compareTo(b.stepOrder));
        },
      );
      return CachedResult.live(data);
    } on ApiException catch (e) {
      if (!e.isTransient) rethrow;
      final cached = await CacheStore.instance.read(cacheKey);
      if (cached == null) rethrow;
      return CachedResult.cached(
        (cached.value as List<dynamic>)
            .map((e) => RoadmapStep.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.stepOrder.compareTo(b.stepOrder)),
        cachedAt: cached.cachedAt,
      );
    }
  }

  /// PATCH /api/v1/users/{userId}/roadmap/{stepId} — marks a step done and
  /// returns the updated step. Not currently called from any screen.
  Future<RoadmapStep> markDone(int userId, int stepId) {
    return _api.unwrap(
      (dio) => dio.patch('/api/v1/users/$userId/roadmap/$stepId'),
      (data) => RoadmapStep.fromJson(data as Map<String, dynamic>),
    );
  }
}
