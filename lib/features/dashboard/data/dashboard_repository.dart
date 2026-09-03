import 'dart:async';

import '../../../core/cache/cache_store.dart';
import '../../../core/models/dashboard.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/cached_result.dart';

/// GET /api/v1/users/{userId}/dashboard — one call feeds the whole screen:
/// career progress ring, roadmap completion %, next 3 skills, active projects.
class DashboardRepository {
  final ApiClient _api = ApiClient.instance;

  Future<CachedResult<DashboardData>> getDashboard(int userId) async {
    final cacheKey = 'dashboard:$userId';
    try {
      final data = await _api.unwrap(
        (dio) => dio.get('/api/v1/users/$userId/dashboard'),
        (data) {
          unawaited(CacheStore.instance.write(cacheKey, data));
          return DashboardData.fromJson(data as Map<String, dynamic>);
        },
      );
      return CachedResult.live(data);
    } on ApiException catch (e) {
      if (!e.isTransient) rethrow;
      final cached = await CacheStore.instance.read(cacheKey);
      if (cached == null) rethrow;
      return CachedResult.cached(
        DashboardData.fromJson(cached.value as Map<String, dynamic>),
        cachedAt: cached.cachedAt,
      );
    }
  }
}
