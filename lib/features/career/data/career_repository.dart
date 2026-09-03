import 'dart:async';

import '../../../core/cache/cache_store.dart';
import '../../../core/models/branch_recommendation.dart';
import '../../../core/models/career_role.dart';
import '../../../core/models/gap_analysis.dart';
import '../../../core/models/role_branch.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/cached_result.dart';

class CareerRepository {
  final ApiClient _api = ApiClient.instance;

  /// GET /api/v1/career-roles
  Future<CachedResult<List<CareerRole>>> getCareerRoles() async {
    const cacheKey = 'career_roles';
    try {
      final data = await _api.unwrap((dio) => dio.get('/api/v1/career-roles'), (
        data,
      ) {
        unawaited(CacheStore.instance.write(cacheKey, data));
        return (data as List<dynamic>)
            .map((e) => CareerRole.fromJson(e as Map<String, dynamic>))
            .toList();
      });
      return CachedResult.live(data);
    } on ApiException catch (e) {
      if (!e.isTransient) rethrow;
      final cached = await CacheStore.instance.read(cacheKey);
      if (cached == null) rethrow;
      return CachedResult.cached(
        (cached.value as List<dynamic>)
            .map((e) => CareerRole.fromJson(e as Map<String, dynamic>))
            .toList(),
        cachedAt: cached.cachedAt,
      );
    }
  }

  /// GET /api/v1/career-roles/{roleId}/branches
  Future<List<RoleBranch>> getBranches(int roleId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/career-roles/$roleId/branches'),
      (data) => (data as List<dynamic>)
          .map((e) => RoleBranch.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// GET /api/v1/users/{userId}/career-goal/branch-recommendations?roleId=
  Future<List<BranchRecommendation>> getBranchRecommendations(
    int userId,
    int roleId,
  ) {
    return _api.unwrap(
      (dio) => dio.get(
        '/api/v1/users/$userId/career-goal/branch-recommendations',
        queryParameters: {'roleId': roleId},
      ),
      (data) => (data as List<dynamic>)
          .map((e) => BranchRecommendation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// POST /api/v1/users/{userId}/career-goal
  Future<void> setCareerGoal(int userId, int roleId, {int? branchId}) {
    return _api.unwrap(
      (dio) => dio.post(
        '/api/v1/users/$userId/career-goal',
        data: {'roleId': roleId, 'branchId': ?branchId},
      ),
      (_) {},
    );
  }

  /// PUT /api/v1/users/{userId}/career-goal/branch
  Future<void> switchBranch(int userId, int branchId) {
    return _api.unwrap(
      (dio) => dio.put(
        '/api/v1/users/$userId/career-goal/branch',
        data: {'branchId': branchId},
      ),
      (_) {},
    );
  }

  /// GET /api/v1/users/{userId}/career-goal/gap
  ///
  /// A 404 here is a legitimate, expected state — the user hasn't set a
  /// career goal yet — and is treated as success with [GapAnalysis.empty],
  /// not an error. Any *other* failure (network down, timeout, a
  /// cold-starting server) is a real connectivity problem and must not be
  /// silently swallowed into the same "no goal set" shape, which is what
  /// used to happen here: every [ApiException], regardless of cause, was
  /// caught and turned into an empty result, so an offline device looked
  /// identical to a user who'd simply never picked a career goal. Now only
  /// the genuine 404 short-circuits; anything transient falls back to the
  /// last cached gap analysis instead.
  Future<CachedResult<GapAnalysis>> getGapAnalysis(int userId) async {
    final cacheKey = 'career_gap:$userId';
    try {
      final data = await _api.unwrap(
        (dio) => dio.get('/api/v1/users/$userId/career-goal/gap'),
        (data) {
          unawaited(CacheStore.instance.write(cacheKey, data));
          return GapAnalysis.fromJson(data as Map<String, dynamic>);
        },
      );
      return CachedResult.live(data);
    } on ApiException catch (e) {
      if (e.isNotFound) {
        // No career goal set — legitimate, not a connectivity problem.
        // Clear any stale cache too, in case a previously-set goal was
        // since removed.
        unawaited(CacheStore.instance.clear(cacheKey));
        return CachedResult.live(GapAnalysis.empty());
      }
      if (!e.isTransient) rethrow;
      final cached = await CacheStore.instance.read(cacheKey);
      if (cached == null) rethrow;
      return CachedResult.cached(
        GapAnalysis.fromJson(cached.value as Map<String, dynamic>),
        cachedAt: cached.cachedAt,
      );
    }
  }
}
