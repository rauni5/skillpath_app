import 'dart:async';

import '../../../core/cache/cache_store.dart';
import '../../../core/models/achievement.dart';
import '../../../core/models/streak.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/cached_result.dart';

class GamificationRepository {
  final ApiClient _api = ApiClient.instance;

  /// GET /api/v1/users/{userId}/gamification/achievements
  Future<CachedResult<List<Achievement>>> getAchievements(int userId) async {
    final cacheKey = 'gamification_achievements:$userId';
    try {
      final data = await _api.unwrap(
        (dio) => dio.get('/api/v1/users/$userId/gamification/achievements'),
        (data) {
          unawaited(CacheStore.instance.write(cacheKey, data));
          return (data as List<dynamic>)
              .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
              .toList();
        },
      );
      return CachedResult.live(data);
    } on ApiException catch (e) {
      if (!e.isTransient) rethrow;
      final cached = await CacheStore.instance.read(cacheKey);
      if (cached == null) rethrow;
      return CachedResult.cached(
        (cached.value as List<dynamic>)
            .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
            .toList(),
        cachedAt: cached.cachedAt,
      );
    }
  }

  /// GET /api/v1/users/{userId}/gamification/streak
  Future<CachedResult<Streak>> getStreak(int userId) async {
    final cacheKey = 'gamification_streak:$userId';
    try {
      final data = await _api.unwrap(
        (dio) => dio.get('/api/v1/users/$userId/gamification/streak'),
        (data) {
          unawaited(CacheStore.instance.write(cacheKey, data));
          return Streak.fromJson(data as Map<String, dynamic>);
        },
      );
      return CachedResult.live(data);
    } on ApiException catch (e) {
      if (!e.isTransient) rethrow;
      final cached = await CacheStore.instance.read(cacheKey);
      if (cached == null) rethrow;
      return CachedResult.cached(
        Streak.fromJson(cached.value as Map<String, dynamic>),
        cachedAt: cached.cachedAt,
      );
    }
  }
}
