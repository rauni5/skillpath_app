import '../../../core/models/portfolio.dart';
import '../../../core/network/api_client.dart';

/// GET /api/v1/users/{userId}/portfolio
class ProfileRepository {
  final ApiClient _api = ApiClient.instance;

  Future<PortfolioData> getPortfolio(int userId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/users/$userId/portfolio'),
      (data) => PortfolioData.fromJson(data as Map<String, dynamic>),
    );
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
}
