import 'package:flutter/foundation.dart';

import '../../../core/models/user.dart';
import '../../../core/network/api_exception.dart';
import '../data/admin_repository.dart';

enum AdminUsersLoadState { initial, loading, loaded, error }

class AdminUsersProvider extends ChangeNotifier {
  AdminUsersProvider({AdminRepository? repository})
    : _repo = repository ?? AdminRepository();

  final AdminRepository _repo;

  AdminUsersLoadState state = AdminUsersLoadState.initial;
  String? error;
  List<AppUser> users = [];
  final Set<int> pendingUserIds = {};

  Future<void> loadUsers() async {
    state = AdminUsersLoadState.loading;
    notifyListeners();
    try {
      users = await _repo.getUsers();
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
      users = users.map((u) => u.id == userId ? updated : u).toList();
      return true;
    } catch (e) {
      error = e is ApiException ? e.message : 'Could not update that user.';
      return false;
    } finally {
      pendingUserIds.remove(userId);
      notifyListeners();
    }
  }
}
