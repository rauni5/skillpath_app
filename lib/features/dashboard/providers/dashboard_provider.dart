import 'package:flutter/foundation.dart';

import '../../../core/models/dashboard.dart';
import '../../../core/network/api_exception.dart';
import '../data/dashboard_repository.dart';

enum DashboardLoadState { initial, loading, loaded, error }

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({DashboardRepository? repository}) : _repo = repository ?? DashboardRepository();

  final DashboardRepository _repo;

  DashboardLoadState state = DashboardLoadState.initial;
  DashboardData? data;
  String? errorMessage;

  Future<void> load(int userId) async {
    state = DashboardLoadState.loading;
    notifyListeners();
    try {
      data = await _repo.getDashboard(userId);
      state = DashboardLoadState.loaded;
    } catch (e) {
      errorMessage = e is ApiException ? e.message : 'Could not load your dashboard.';
      state = DashboardLoadState.error;
    }
    notifyListeners();
  }
}
