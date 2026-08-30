import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/models/admin_user_analytics.dart';
import '../../../core/models/admin_user_summary.dart';
import '../../../core/models/admin_users_query.dart';
import '../../../core/network/api_exception.dart';
import '../data/admin_repository.dart';

enum AdminUsersLoadState { initial, loading, loaded, error }

enum AdminAnalyticsLoadState { initial, loading, loaded, error }

class AdminUsersProvider extends ChangeNotifier {
  AdminUsersProvider({AdminRepository? repository})
    : _repo = repository ?? AdminRepository();

  final AdminRepository _repo;

  static const int pageSize = 20;

  // --- List (paginated) ---
  AdminUsersLoadState state = AdminUsersLoadState.initial;
  String? error;
  List<AdminUserSummary> users = [];
  int page = 0;
  int totalPages = 0;
  int totalElements = 0;
  bool hasMore = true;
  final Set<int> pendingUserIds = {};

  // --- Search ---
  String searchQuery = '';
  Timer? _searchDebounce;

  void setSearchQuery(String query) {
    searchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => loadUsers(),
    );
  }

  // --- Filter + sort ---
  UserStatusFilter statusFilter = UserStatusFilter.all;
  UserSortBy sortBy = UserSortBy.createdAt;
  SortDir sortDir = SortDir.desc;

  void setStatusFilter(UserStatusFilter filter) {
    if (filter == statusFilter) return;
    statusFilter = filter;
    loadUsers();
  }

  /// Tapping the same column again flips direction; a new column starts
  /// descending (newest/last first tends to be what admins want first).
  void setSort(UserSortBy column) {
    if (sortBy == column) {
      sortDir = sortDir == SortDir.asc ? SortDir.desc : SortDir.asc;
    } else {
      sortBy = column;
      sortDir = SortDir.desc;
    }
    loadUsers();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> loadUsers() async {
    state = AdminUsersLoadState.loading;
    page = 0;
    notifyListeners();
    try {
      final result = await _repo.getUsers(
        page: 0,
        size: pageSize,
        q: searchQuery,
        status: statusFilter,
        sortBy: sortBy,
        sortDir: sortDir,
      );
      users = result.content;
      hasMore = !result.last;
      totalPages = result.totalPages;
      totalElements = result.totalElements;
      state = AdminUsersLoadState.loaded;
    } catch (e) {
      error = e is ApiException ? e.message : 'Could not load users.';
      state = AdminUsersLoadState.error;
    }
    notifyListeners();
  }

  /// Jumps to a specific page (0-indexed) — used by the Prev/Next pager.
  Future<void> goToPage(int targetPage) async {
    if (targetPage < 0) return;
    state = AdminUsersLoadState.loading;
    notifyListeners();
    try {
      final result = await _repo.getUsers(
        page: targetPage,
        size: pageSize,
        q: searchQuery,
        status: statusFilter,
        sortBy: sortBy,
        sortDir: sortDir,
      );
      users = result.content;
      page = result.number;
      totalPages = result.totalPages;
      totalElements = result.totalElements;
      hasMore = !result.last;
      state = AdminUsersLoadState.loaded;
    } catch (e) {
      error = e is ApiException ? e.message : 'Could not load users.';
      state = AdminUsersLoadState.error;
    }
    notifyListeners();
  }

  Future<bool> setAdmin(int userId, bool isAdmin) async {
    pendingUserIds.add(userId);
    notifyListeners();
    try {
      final updated = await _repo.setAdmin(userId, isAdmin);
      users = users
          .map((s) => s.user.id == userId ? s.copyWith(user: updated) : s)
          .toList();
      // Admin counts shown in the analytics header can shift too.
      unawaited(loadAnalytics());
      return true;
    } catch (e) {
      error = e is ApiException ? e.message : 'Could not update that user.';
      return false;
    } finally {
      pendingUserIds.remove(userId);
      notifyListeners();
    }
  }

  /// Deactivate/reactivate a user. If they're currently filtered out by
  /// [statusFilter] after the change (e.g. filtering to "Active" and this
  /// user just got deactivated), drop them from the visible list instead
  /// of showing a stale row.
  Future<bool> setActive(int userId, bool active) async {
    pendingUserIds.add(userId);
    notifyListeners();
    try {
      final updated = await _repo.setActive(userId, active);
      final stillMatches = switch (statusFilter) {
        UserStatusFilter.active => updated.isActive,
        UserStatusFilter.inactive => !updated.isActive,
        UserStatusFilter.admin || UserStatusFilter.all => true,
      };
      if (stillMatches) {
        users = users
            .map((s) => s.user.id == userId ? s.copyWith(user: updated) : s)
            .toList();
      } else {
        users = users.where((s) => s.user.id != userId).toList();
        totalElements = totalElements > 0 ? totalElements - 1 : 0;
      }
      unawaited(loadAnalytics());
      return true;
    } catch (e) {
      error = e is ApiException ? e.message : 'Could not update that user.';
      return false;
    } finally {
      pendingUserIds.remove(userId);
      notifyListeners();
    }
  }

  // --- Analytics ---
  AdminAnalyticsLoadState analyticsState = AdminAnalyticsLoadState.initial;
  AdminUserAnalytics? analytics;
  String? analyticsError;

  Future<void> loadAnalytics() async {
    analyticsState = AdminAnalyticsLoadState.loading;
    notifyListeners();
    try {
      analytics = await _repo.getUserAnalytics();
      analyticsState = AdminAnalyticsLoadState.loaded;
    } catch (e) {
      analyticsError = e is ApiException
          ? e.message
          : 'Could not load user analytics.';
      analyticsState = AdminAnalyticsLoadState.error;
    }
    notifyListeners();
  }
}
