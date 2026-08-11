import 'package:flutter/foundation.dart';

import '../../../core/models/portfolio.dart';
import '../../../core/network/api_exception.dart';
import '../data/profile_repository.dart';

enum PortfolioLoadState { initial, loading, loaded, error }

class PortfolioProvider extends ChangeNotifier {
  PortfolioProvider({ProfileRepository? repository})
    : _repo = repository ?? ProfileRepository();

  final ProfileRepository _repo;
  int? _userId;

  PortfolioLoadState state = PortfolioLoadState.initial;
  PortfolioData? data;
  String? errorMessage;
  bool mutating = false;
  String? mutationError;

  Future<void> load(int userId) async {
    _userId = userId;
    final isFirstLoad = data == null;
    if (isFirstLoad) {
      state = PortfolioLoadState.loading;
      notifyListeners();
    }
    try {
      data = await _repo.getPortfolio(userId);
      state = PortfolioLoadState.loaded;
      notifyListeners();
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : 'Could not load your portfolio.';
      if (isFirstLoad) {
        errorMessage = message;
        state = PortfolioLoadState.error;
        notifyListeners();
      }
    }
  }

  Future<bool> addItem({
    int? projectId,
    String? githubUrl,
    String? description,
    String? userRole,
  }) => _mutate(() async {
    final userId = _userId;
    if (userId == null) throw ApiException('Not signed in.');
    await _repo.addPortfolioItem(
      userId,
      projectId: projectId,
      githubUrl: githubUrl,
      description: description,
      userRole: userRole,
    );
    data = await _repo.getPortfolio(userId);
  });

  Future<bool> deleteItem(int itemId) => _mutate(() async {
    final userId = _userId;
    if (userId == null) throw ApiException('Not signed in.');
    await _repo.deletePortfolioItem(userId, itemId);
    data = await _repo.getPortfolio(userId);
  });

  Future<bool> addCertification({
    required String name,
    String? issuer,
    String? credentialUrl,
    DateTime? earnedOn,
  }) => _mutate(() async {
    final userId = _userId;
    if (userId == null) throw ApiException('Not signed in.');
    await _repo.addCertification(
      userId,
      name: name,
      issuer: issuer,
      credentialUrl: credentialUrl,
      earnedOn: earnedOn,
    );
    data = await _repo.getPortfolio(userId);
  });

  Future<bool> deleteCertification(int certId) => _mutate(() async {
    final userId = _userId;
    if (userId == null) throw ApiException('Not signed in.');
    await _repo.deleteCertification(userId, certId);
    data = await _repo.getPortfolio(userId);
  });

  /// Called after Settings/Portfolio-edit screens update the bio,
  /// experience level, or availability, so the Portfolio screen reflects
  /// it without a full page reload.
  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null) return;
    await load(userId);
  }

  Future<bool> _mutate(Future<void> Function() action) async {
    mutating = true;
    mutationError = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      mutationError = e is ApiException
          ? e.message
          : 'Something went wrong. Please try again.';
      return false;
    } finally {
      mutating = false;
      notifyListeners();
    }
  }
}
