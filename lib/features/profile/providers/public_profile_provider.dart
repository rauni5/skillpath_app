import 'package:flutter/foundation.dart';

import '../../../core/models/public_profile.dart';
import '../../../core/network/api_exception.dart';
import '../data/profile_repository.dart';

enum PublicProfileLoadState { initial, loading, loaded, error }

/// Two unrelated jobs share this provider since they're both thin wrappers
/// around the same repository and neither is complex enough to earn its
/// own class:
/// 1. Managing your own share settings (Settings screen toggle).
/// 2. Viewing someone else's public profile by token (PublicProfileScreen,
///    reachable while signed out — see settings-vs-viewing state below,
///    kept deliberately separate so viewing a stranger's profile can never
///    clobber your own settings state or vice versa).
class PublicProfileProvider extends ChangeNotifier {
  PublicProfileProvider({ProfileRepository? repository})
    : _repo = repository ?? ProfileRepository();

  final ProfileRepository _repo;

  // --- Settings (managing your own link) ---
  PublicProfileLoadState settingsState = PublicProfileLoadState.initial;
  PublicProfileSettings? settings;
  String? settingsError;
  bool isUpdatingSettings = false;

  Future<void> loadSettings(int userId) async {
    settingsState = PublicProfileLoadState.loading;
    notifyListeners();
    try {
      settings = await _repo.getPublicProfileSettings(userId);
      settingsState = PublicProfileLoadState.loaded;
    } catch (e) {
      settingsError = e is ApiException
          ? e.message
          : 'Could not load your sharing settings.';
      settingsState = PublicProfileLoadState.error;
    }
    notifyListeners();
  }

  Future<bool> enable(int userId) =>
      _updateSettings(() => _repo.enablePublicProfile(userId));

  Future<bool> disable(int userId) =>
      _updateSettings(() => _repo.disablePublicProfile(userId));

  Future<bool> regenerateLink(int userId) =>
      _updateSettings(() => _repo.regeneratePublicProfileLink(userId));

  Future<bool> _updateSettings(
    Future<PublicProfileSettings> Function() action,
  ) async {
    isUpdatingSettings = true;
    settingsError = null;
    notifyListeners();
    try {
      settings = await action();
      return true;
    } catch (e) {
      settingsError = e is ApiException
          ? e.message
          : 'Could not update your sharing settings.';
      return false;
    } finally {
      isUpdatingSettings = false;
      notifyListeners();
    }
  }

  // --- Viewing someone else's public profile by token ---
  PublicProfileLoadState viewState = PublicProfileLoadState.initial;
  PublicProfileData? viewedProfile;
  String? viewError;

  Future<void> loadPublicProfile(String token) async {
    viewState = PublicProfileLoadState.loading;
    notifyListeners();
    try {
      viewedProfile = await _repo.getPublicProfile(token);
      viewState = PublicProfileLoadState.loaded;
    } catch (e) {
      viewError = e is ApiException && e.isNotFound
          ? "This link doesn't lead anywhere — the profile may no longer be shared."
          : e is ApiException
          ? e.message
          : 'Could not load this profile.';
      viewState = PublicProfileLoadState.error;
    }
    notifyListeners();
  }

  void reset() {
    settingsState = PublicProfileLoadState.initial;
    settings = null;
    settingsError = null;
    isUpdatingSettings = false;
    viewState = PublicProfileLoadState.initial;
    viewedProfile = null;
    viewError = null;
    notifyListeners();
  }
}
