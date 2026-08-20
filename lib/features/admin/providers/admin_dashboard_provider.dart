import 'package:flutter/foundation.dart';

import '../../../core/models/admin_dashboard_stats.dart';
import '../../../core/network/api_exception.dart';
import '../data/admin_repository.dart';

enum AdminDashboardLoadState { initial, loading, loaded, error }

class AdminDashboardProvider extends ChangeNotifier {
  AdminDashboardProvider({AdminRepository? repository})
    : _repo = repository ?? AdminRepository();

  final AdminRepository _repo;

  AdminDashboardLoadState state = AdminDashboardLoadState.initial;
  AdminDashboardStats? stats;
  String? error;
  DateTime? lastUpdated;

  int trendDays = 30;
  static const List<int> trendDayOptions = [7, 30, 90];
  bool trendLoading = false;

  /// Refreshes only the signup-trend chart data — not the whole dashboard —
  /// so switching 7d/30d/90d doesn't flash every stat card back to a
  /// loading spinner.
  Future<void> setTrendDays(int days) async {
    if (days == trendDays) return;
    trendDays = days;
    if (stats == null) {
      // Nothing loaded yet to patch in place — fall back to a full load.
      await loadStats();
      return;
    }
    trendLoading = true;
    notifyListeners();
    try {
      final trend = await _repo.getSignupTrend(days: days);
      stats = stats!.copyWith(userSignupTrend: trend);
    } catch (_) {
      // Keep showing the previous trend rather than clearing the chart.
    } finally {
      trendLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStats() async {
    state = AdminDashboardLoadState.loading;
    notifyListeners();
    try {
      stats = await _repo.getDashboardStats(trendDays: trendDays);
      lastUpdated = DateTime.now();
      state = AdminDashboardLoadState.loaded;
    } catch (e) {
      error = e is ApiException ? e.message : 'Could not load dashboard stats.';
      state = AdminDashboardLoadState.error;
    }
    notifyListeners();
  }
}
