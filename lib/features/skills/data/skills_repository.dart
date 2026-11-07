import 'dart:async';

import '../../../core/cache/cache_store.dart';
import '../../../core/models/skill.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/cached_result.dart';

class SkillsRepository {
  final ApiClient _api = ApiClient.instance;

  /// GET /api/v1/skills — the full catalog, used for search/browse when
  /// adding skills.
  Future<CachedResult<List<Skill>>> getAllSkills() async {
    const cacheKey = 'skills_catalog';
    try {
      final data = await _api.unwrap((dio) => dio.get('/api/v1/skills'), (
        data,
      ) {
        unawaited(CacheStore.instance.write(cacheKey, data));
        return (data as List<dynamic>)
            .map((e) => Skill.fromJson(e as Map<String, dynamic>))
            .toList();
      });
      return CachedResult.live(data);
    } on ApiException catch (e) {
      if (!e.isTransient) rethrow;
      final cached = await CacheStore.instance.read(cacheKey);
      if (cached == null) rethrow;
      return CachedResult.cached(
        (cached.value as List<dynamic>)
            .map((e) => Skill.fromJson(e as Map<String, dynamic>))
            .toList(),
        cachedAt: cached.cachedAt,
      );
    }
  }

  /// GET /api/v1/users/{userId}/skills — the user's current skill
  /// inventory.
  Future<CachedResult<List<Skill>>> getUserSkills(int userId) async {
    final cacheKey = 'user_skills:$userId';
    try {
      final data = await _api.unwrap(
        (dio) => dio.get('/api/v1/users/$userId/skills'),
        (data) {
          unawaited(CacheStore.instance.write(cacheKey, data));
          return (data as List<dynamic>)
              .map((e) => Skill.fromJson(e as Map<String, dynamic>))
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
            .map((e) => Skill.fromJson(e as Map<String, dynamic>))
            .toList(),
        cachedAt: cached.cachedAt,
      );
    }
  }

  /// POST /api/v1/users/{userId}/skills
  Future<void> addSkill(int userId, int skillId, SkillProficiency proficiency) {
    return _api.unwrap(
      (dio) => dio.post(
        '/api/v1/users/$userId/skills',
        data: {
          'skillId': skillId,
          'proficiency': skillProficiencyToApiString(proficiency),
        },
      ),
      (_) {},
    );
  }

  /// DELETE /api/v1/users/{userId}/skills/{skillId}
  Future<void> removeSkill(int userId, int skillId) {
    return _api.unwrap(
      (dio) => dio.delete('/api/v1/users/$userId/skills/$skillId'),
      (_) {},
    );
  }
}
