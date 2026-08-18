import '../../../core/models/page_projects.dart';
import '../../../core/models/user_search_result.dart';
import '../../../core/network/api_client.dart';

/// Used by project owners searching for someone to invite by name/email.
class UserSearchRepository {
  final ApiClient _api = ApiClient.instance;

  /// GET /api/v1/users/search?q=...
  Future<Page<UserSearchResult>> search(
    String query, {
    int page = 0,
    int size = 20,
  }) {
    return _api.unwrap(
      (dio) => dio.get(
        '/api/v1/users/search',
        queryParameters: {'q': query, 'page': page, 'size': size},
      ),
      (data) => Page<UserSearchResult>.fromJson(
        data as Map<String, dynamic>,
        UserSearchResult.fromJson,
      ),
    );
  }
}
