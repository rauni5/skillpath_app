import 'dart:async';

import '../../../core/cache/cache_store.dart';
import '../../../core/models/portfolio.dart';
import '../../../core/models/public_profile.dart';
import '../../../core/models/user.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/cached_result.dart';

/// GET /api/v1/users/{userId}/portfolio
class ProfileRepository {
  final ApiClient _api = ApiClient.instance;

  /// GET /api/v1/users/{userId} — just the basics (name, avatarUrl,
  Future<AppUser> getUser(int userId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/users/$userId'),
      (data) => AppUser.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<CachedResult<PortfolioData>> getPortfolio(int userId) async {
    final cacheKey = 'portfolio:$userId';
    try {
      final data = await _api.unwrap(
        (dio) => dio.get('/api/v1/users/$userId/portfolio'),
        (data) {
          unawaited(CacheStore.instance.write(cacheKey, data));
          return PortfolioData.fromJson(data as Map<String, dynamic>);
        },
      );
      return CachedResult.live(data);
    } on ApiException catch (e) {
      if (!e.isTransient) rethrow;
      final cached = await CacheStore.instance.read(cacheKey);
      if (cached == null) rethrow;
      return CachedResult.cached(
        PortfolioData.fromJson(cached.value as Map<String, dynamic>),
        cachedAt: cached.cachedAt,
      );
    }
  }

  /// POST /api/v1/users/{userId}/portfolio
  Future<PortfolioItem> addPortfolioItem(
    int userId, {
    int? projectId,
    String? githubUrl,
    String? description,
    String? userRole,
  }) {
    final body = <String, dynamic>{};
    if (projectId != null) body['projectId'] = projectId;
    if (githubUrl != null) body['githubUrl'] = githubUrl;
    if (description != null) body['description'] = description;
    if (userRole != null) body['userRole'] = userRole;

    return _api.unwrap(
      (dio) => dio.post('/api/v1/users/$userId/portfolio', data: body),
      (data) => PortfolioItem.fromJson(data as Map<String, dynamic>),
    );
  }

  /// DELETE /api/v1/users/{userId}/portfolio/{itemId}
  Future<void> deletePortfolioItem(int userId, int itemId) {
    return _api.unwrap(
      (dio) => dio.delete('/api/v1/users/$userId/portfolio/$itemId'),
      (_) {},
    );
  }

  /// POST /api/v1/users/{userId}/certifications
  Future<Certification> addCertification(
    int userId, {
    required String name,
    String? issuer,
    String? credentialUrl,
    DateTime? earnedOn,
  }) {
    final body = <String, dynamic>{'name': name};
    if (issuer != null) body['issuer'] = issuer;
    if (credentialUrl != null) body['credentialUrl'] = credentialUrl;
    if (earnedOn != null) {
      body['earnedOn'] =
          '${earnedOn.year.toString().padLeft(4, '0')}-'
          '${earnedOn.month.toString().padLeft(2, '0')}-'
          '${earnedOn.day.toString().padLeft(2, '0')}';
    }

    return _api.unwrap(
      (dio) => dio.post('/api/v1/users/$userId/certifications', data: body),
      (data) => Certification.fromJson(data as Map<String, dynamic>),
    );
  }

  /// DELETE /api/v1/users/{userId}/certifications/{certId}
  Future<void> deleteCertification(int userId, int certId) {
    return _api.unwrap(
      (dio) => dio.delete('/api/v1/users/$userId/certifications/$certId'),
      (_) {},
    );
  }

  /// POST /api/v1/users/{userId}/education
  Future<Education> addEducation(
    int userId, {
    required String institution,
    String? degree,
    String? fieldOfStudy,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
  }) {
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    final body = <String, dynamic>{'institution': institution};
    if (degree != null) body['degree'] = degree;
    if (fieldOfStudy != null) body['fieldOfStudy'] = fieldOfStudy;
    if (startDate != null) body['startDate'] = fmt(startDate);
    if (endDate != null) body['endDate'] = fmt(endDate);
    if (description != null) body['description'] = description;

    return _api.unwrap(
      (dio) => dio.post('/api/v1/users/$userId/education', data: body),
      (data) => Education.fromJson(data as Map<String, dynamic>),
    );
  }

  /// DELETE /api/v1/users/{userId}/education/{eduId}
  Future<void> deleteEducation(int userId, int eduId) {
    return _api.unwrap(
      (dio) => dio.delete('/api/v1/users/$userId/education/$eduId'),
      (_) {},
    );
  }

  // --- Public profile sharing ---

  /// GET /api/v1/users/{userId}/public-profile
  Future<PublicProfileSettings> getPublicProfileSettings(int userId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/users/$userId/public-profile'),
      (data) => PublicProfileSettings.fromJson(data as Map<String, dynamic>),
    );
  }

  /// POST /api/v1/users/{userId}/public-profile/enable
  Future<PublicProfileSettings> enablePublicProfile(int userId) {
    return _api.unwrap(
      (dio) => dio.post('/api/v1/users/$userId/public-profile/enable'),
      (data) => PublicProfileSettings.fromJson(data as Map<String, dynamic>),
    );
  }

  /// POST /api/v1/users/{userId}/public-profile/disable
  Future<PublicProfileSettings> disablePublicProfile(int userId) {
    return _api.unwrap(
      (dio) => dio.post('/api/v1/users/$userId/public-profile/disable'),
      (data) => PublicProfileSettings.fromJson(data as Map<String, dynamic>),
    );
  }

  /// POST /api/v1/users/{userId}/public-profile/regenerate — invalidates
  /// whatever link was shared before.
  Future<PublicProfileSettings> regeneratePublicProfileLink(int userId) {
    return _api.unwrap(
      (dio) => dio.post('/api/v1/users/$userId/public-profile/regenerate'),
      (data) => PublicProfileSettings.fromJson(data as Map<String, dynamic>),
    );
  }

  /// GET /api/v1/public/profiles/{token} — deliberately does not require
  /// (or send anything special for) auth. The backend permits this path
  /// unauthenticated; ApiClient still attaches a Firebase token if the
  /// viewer happens to be signed in on this device, but the backend
  /// ignores it here either way, so this works identically for a visitor
  /// with no SkillPath account at all. Not cached — a public profile
  /// isn't something the viewer's own account owns, so there's no
  /// "my last known copy" to fall back to if it's offline.
  Future<PublicProfileData> getPublicProfile(String token) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/public/profiles/$token'),
      (data) => PublicProfileData.fromJson(data as Map<String, dynamic>),
    );
  }
}
