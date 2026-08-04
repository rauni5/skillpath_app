import '../../../core/models/user.dart';
import '../../../core/network/api_client.dart';

class AdminRepository {
  final ApiClient _api = ApiClient.instance;

  /// GET /api/v1/admin/users
  Future<List<AppUser>> getUsers() {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/admin/users'),
      (data) => (data as List<dynamic>)
          .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// PATCH /api/v1/admin/users/{userId}/admin
  Future<AppUser> setAdmin(int userId, bool isAdmin) {
    return _api.unwrap(
      (dio) => dio.patch(
        '/api/v1/admin/users/$userId/admin',
        data: {'admin': isAdmin},
      ),
      (data) => AppUser.fromJson(data as Map<String, dynamic>),
    );
  }
}
