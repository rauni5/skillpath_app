import 'package:flutter/foundation.dart';

import '../../../core/models/dashboard.dart';
import '../../../core/network/api_exception.dart';
import '../data/dashboard_repository.dart';

enum DashboardLoadState { initial, loading, loaded, error }

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({DashboardRepository? repository})
    : _repo = repository ?? DashboardRepository();

  final DashboardRepository _repo;

  DashboardLoadState state = DashboardLoadState.initial;
  DashboardData? data;
  String? errorMessage;

  /// True if [data] came from the on-device cache rather than a live
  /// request — the backend couldn't be reached. [cachedAt] is when that
  /// snapshot was taken.
  bool isShowingCachedData = false;
  DateTime? cachedAt;

  Future<void> load(int userId) async {
    state = DashboardLoadState.loading;
    notifyListeners();
    try {
      final result = await _repo.getDashboard(userId);
      data = result.data;
      isShowingCachedData = result.fromCache;
      cachedAt = result.cachedAt;
      state = DashboardLoadState.loaded;
    } catch (e) {
      errorMessage = e is ApiException
          ? e.message
          : 'Could not load your dashboard.';
      state = DashboardLoadState.error;
    }
    notifyListeners();
  }

  void reset() {
    state = DashboardLoadState.initial;
    data = null;
    errorMessage = null;
    isShowingCachedData = false;
    cachedAt = null;
    notifyListeners();
  }
}
