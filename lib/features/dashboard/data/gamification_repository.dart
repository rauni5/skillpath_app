import '../../../core/models/achievement.dart';
import '../../../core/models/streak.dart';
import '../../../core/network/api_client.dart';

class GamificationRepository {
  final ApiClient _api = ApiClient.instance;

  /// GET /api/v1/users/{userId}/gamification/achievements
  Future<List<Achievement>> getAchievements(int userId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/users/$userId/gamification/achievements'),
      (data) => (data as List<dynamic>)
          .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// GET /api/v1/users/{userId}/gamification/streak
  Future<Streak> getStreak(int userId) {
    return _api.unwrap(
      (dio) => dio.get('/api/v1/users/$userId/gamification/streak'),
      (data) => Streak.fromJson(data as Map<String, dynamic>),
    );
  }
}
