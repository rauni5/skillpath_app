import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/models/user_search_result.dart';
import '../../../core/network/api_exception.dart';
import '../data/user_search_repository.dart';

enum UserSearchLoadState { idle, loading, loaded, error }

class UserSearchProvider extends ChangeNotifier {
  UserSearchProvider({UserSearchRepository? repository})
    : _repo = repository ?? UserSearchRepository();

  final UserSearchRepository _repo;
  Timer? _debounce;

  UserSearchLoadState state = UserSearchLoadState.idle;
  String? error;
  List<UserSearchResult> results = [];

  void onQueryChanged(String query) {
    _debounce?.cancel();
    final q = query.trim();
    if (q.length < 2) {
      state = UserSearchLoadState.idle;
      results = [];
      notifyListeners();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => search(q));
  }

  Future<void> search(String query) async {
    final q = query.trim();
    if (q.length < 2) {
      state = UserSearchLoadState.idle;
      results = [];
      notifyListeners();
      return;
    }
    state = UserSearchLoadState.loading;
    notifyListeners();
    try {
      final page = await _repo.search(q);
      results = page.content;
      state = UserSearchLoadState.loaded;
    } catch (e) {
      error = e is ApiException ? e.message : 'Could not search users.';
      state = UserSearchLoadState.error;
    }
    notifyListeners();
  }

  void clear() {
    _debounce?.cancel();
    state = UserSearchLoadState.idle;
    results = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
