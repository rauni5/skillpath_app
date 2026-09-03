import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart' show XFile;

import '../../../core/models/user.dart';
import '../../../core/network/api_exception.dart';
import '../../career/data/career_repository.dart';
import '../../notifications/data/notification_preferences.dart';
import '../../notifications/data/notification_service.dart';
import '../data/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Single source of truth for auth state. Also passed to go_router as a
/// `refreshListenable` so the router automatically re-evaluates redirects
/// (e.g. login <-> dashboard <-> onboarding) whenever auth state changes.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository, CareerRepository? careerRepository})
    : _repo = repository ?? AuthRepository(),
      _careerRepo = careerRepository ?? CareerRepository() {
    _sub = _repo.firebaseUserChanges.listen(_onFirebaseUserChanged);
  }

  final AuthRepository _repo;
  final CareerRepository _careerRepo;
  late final StreamSubscription _sub;

  AuthStatus status = AuthStatus.unknown;
  AppUser? currentUser;
  bool isLoading = false;
  String? errorMessage;

  /// null = not yet determined (still checking with the backend).
  /// true = user hasn't set a career goal yet, onboarding should be shown.
  /// false = onboarding is done, the main app is unlocked.
  bool? needsOnboarding;

  /// True if the signed-in user registered with email/password and hasn't
  /// clicked the verification link yet. Always false for Google sign-in.
  bool needsEmailVerification = false;

  /// True if the current [currentUser]/[needsOnboarding] came from the
  /// on-device cache rather than a confirmed backend sync — the backend
  /// couldn't be reached (offline, or a cold-starting server) but Firebase
  /// still had a valid local session. Screens can use this to show a
  /// "you're offline, showing cached data" indicator.
  bool isOffline = false;

  /// True while signIn()/signInWithGoogle()/register() is actively driving its own sync.
  bool _explicitAuthInFlight = false;

  Future<void> _onFirebaseUserChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      status = AuthStatus.unauthenticated;
      currentUser = null;
      needsOnboarding = null;
      needsEmailVerification = false;
      isOffline = false;
      notifyListeners();
      return;
    }
    if (_explicitAuthInFlight) {
      // signIn()/signInWithGoogle()/register() is already handling this
      return;
    }
    needsEmailVerification = !_repo.isEmailVerified;
    try {
      final user = await _repo.sync();
      await _onSyncSuccess(user);
    } catch (e) {
      // Firebase still has a valid local session, but the backend sync
      // failed. Only treat this as a real logout if the backend actually
      // rejected the session (account deleted/banned/invalid token) — a
      // network hiccup, an offline device, or the Azure container just
      // cold-starting are not reasons to sign anyone out. In those cases,
      // fall back to the last known-good session on disk, if there is one.
      if (_isGenuineAuthRejection(e)) {
        await _onSyncFailure(e);
        return;
      }
      final cached = await _repo.getCachedSession();
      if (cached != null) {
        currentUser = cached.user;
        needsOnboarding = cached.needsOnboarding;
        status = AuthStatus.authenticated;
        isOffline = true;
        errorMessage = null;
        notifyListeners();
      } else {
        // Nothing safe to show offline (e.g. very first sync of this
        // device never completed) — fall back to the old behavior.
        await _onSyncFailure(e);
      }
    }
  }

  /// True only for failures where the backend explicitly rejected the
  /// session, as opposed to simply being unreachable.
  bool _isGenuineAuthRejection(Object e) {
    return e is ApiException && (e.statusCode == 401 || e.statusCode == 403);
  }

  //backend sync succeeded
  Future<void> _onSyncSuccess(AppUser user) async {
    currentUser = user;
    status = AuthStatus.authenticated;
    isOffline = false;
    notifyListeners();
    unawaited(_registerForPushIfEnabled(user.id));
    await refreshOnboardingStatus();
  }

  //backend sync failed
  Future<void> _onSyncFailure(
    Object e, {
    bool deleteFirebaseAccount = false,
  }) async {
    status = AuthStatus.unauthenticated;
    currentUser = null;
    needsOnboarding = null;
    errorMessage = e is ApiException
        ? e.message
        : 'Could not reach SkillPath servers.';
    try {
      if (deleteFirebaseAccount) {
        await _repo.deleteCurrentFirebaseUser();
      } else {
        await _repo.signOut();
      }
    } catch (_) {
      // Best-effort; if cleanup also fails there's nothing more we can
      // do here, but local state stays unauthenticated regardless.
    }
    notifyListeners();
  }

  Future<void> _registerForPushIfEnabled(int userId) async {
    final enabled = await NotificationPreferences.isEnabled();
    if (enabled) {
      await NotificationService.instance.registerForUser(userId);
    }
  }

  /// Derives onboarding status straight from the backend (whether a
  /// career goal is set) rather than any local flag, so it's correct even
  /// after a reinstall or a fresh device.
  Future<void> refreshOnboardingStatus() async {
    final userId = currentUser?.id;
    if (userId == null) return;
    try {
      final result = await _careerRepo.getGapAnalysis(userId);
      needsOnboarding = !result.data.hasGoalSet;
      isOffline = false;
      unawaited(_persistSessionCache());
    } catch (_) {
      // Keep whatever we already knew (e.g. from a previous successful
      // check, or a cached session) rather than forcing this to true —
      // that would incorrectly bounce an already-onboarded user back into
      // onboarding just because this one call failed to reach the server.
      needsOnboarding ??= true;
    }
    notifyListeners();
  }

  /// Best-effort write of the current session to disk, so a future cold
  /// start without connectivity has something to fall back to. Never
  /// throws — caching is a nice-to-have, not something that should ever
  /// break the auth flow it's piggybacking on.
  Future<void> _persistSessionCache() async {
    final user = currentUser;
    if (user == null) return;
    try {
      await _repo.cacheSession(user, needsOnboarding: needsOnboarding ?? true);
    } catch (_) {}
  }

  /// Called by the onboarding flow once it has just set the career goal
  /// itself — avoids one extra round trip before the router unlocks the
  /// main app.
  void markOnboardingComplete() {
    needsOnboarding = false;
    notifyListeners();
    unawaited(_persistSessionCache());
  }

  // Drives the Firebase sign-in *and* the backend sync itself
  Future<bool> signIn(String email, String password) => _run(() async {
    _explicitAuthInFlight = true;
    try {
      await _repo.signInWithEmail(email, password);
      needsEmailVerification = !_repo.isEmailVerified;
      try {
        final user = await _repo.sync();
        await _onSyncSuccess(user);
      } catch (e) {
        await _onSyncFailure(e);
        rethrow; // let _run() record the error and report failure
      }
    } finally {
      _explicitAuthInFlight = false;
    }
  });

  Future<bool> signInWithGoogle() => _run(() async {
    _explicitAuthInFlight = true;
    try {
      await _repo.signInWithGoogle();
      needsEmailVerification = !_repo.isEmailVerified;
      try {
        final user = await _repo.sync();
        await _onSyncSuccess(user);
      } catch (e) {
        await _onSyncFailure(e);
        rethrow; // let _run() record the error and report failure
      }
    } finally {
      _explicitAuthInFlight = false;
    }
  });

  Future<bool> register({
    required String email,
    required String password,
    required ExperienceLevel experienceLevel,
  }) => _run(() async {
    try {
      currentUser = await _repo.registerWithEmail(
        email: email,
        password: password,
        experienceLevel: experienceLevel,
      );
    } catch (e) {
      // If the Firebase account got created but the backend sync failed
      await _onSyncFailure(e, deleteFirebaseAccount: true);
      rethrow;
    }
    needsEmailVerification = !_repo.isEmailVerified;
    status = AuthStatus.authenticated;
    notifyListeners();
    unawaited(_registerForPushIfEnabled(currentUser!.id));
    await refreshOnboardingStatus();
  });

  /// Sends a password reset email. Always reports success to the caller
  /// (even for unknown emails) so the UI can't be used to enumerate
  /// registered accounts.
  Future<bool> sendPasswordResetEmail(String email) =>
      _run(() => _repo.sendPasswordReset(email));

  Future<bool> resendVerificationEmail() =>
      _run(() => _repo.sendEmailVerification());

  /// Re-checks verification status with Firebase. Called when the user taps
  /// "I've verified my email" on the verify-email screen.
  Future<bool> checkEmailVerified() async {
    final verified = await _repo.reloadAndCheckVerified();
    needsEmailVerification = !verified;
    notifyListeners();
    return verified;
  }

  /// True for accounts signed in with email/password — used to decide
  /// whether to show a "change password" action (Google accounts manage
  /// their password with Google, not us).
  bool get isPasswordAccount =>
      _repo.currentFirebaseUser?.providerData.any(
        (p) => p.providerId == 'password',
      ) ??
      false;

  /// Re-attempts the backend sync after a period of [isOffline]. Not wired
  /// to any UI yet — exposed as a hook for a future "retry" action (e.g.
  /// an offline banner) once connectivity-aware caching lands.
  Future<void> retrySync() async {
    if (!isOffline) return;
    await _onFirebaseUserChanged(_repo.currentFirebaseUser);
  }

  /// Used by the onboarding "About you" step and by the Settings/Portfolio
  /// screens to edit profile fields. Every param is optional so each
  /// caller only sends what it actually edits.
  Future<bool> updateProfile({
    required String name,
    String? phoneNumber,
    String? githubUrl,
    String? linkedinUrl,
    String? location,
    String? softSkills,
    String? bio,
    ExperienceLevel? experienceLevel,
    bool? availability,
  }) => _run(() async {
    currentUser = await _repo.updateProfile(
      name: name,
      phoneNumber: phoneNumber,
      githubUrl: githubUrl,
      linkedinUrl: linkedinUrl,
      location: location,
      softSkills: softSkills,
      bio: bio,
      experienceLevel: experienceLevel,
      availability: availability,
    );
    unawaited(_persistSessionCache());
  });

  Future<bool> uploadAvatar(XFile file) => _run(() async {
    currentUser = await _repo.uploadAvatar(file);
    unawaited(_persistSessionCache());
  });

  final List<VoidCallback> _signOutListeners = [];
  void registerSignOutListener(VoidCallback listener) {
    _signOutListeners.add(listener);
  }

  Future<void> signOut() async {
    await NotificationService.instance.handleSignOut();
    await _repo.signOut();
    for (final listener in _signOutListeners) {
      listener();
    }
  }

  Future<bool> _run(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      errorMessage = e is ApiException
          ? e.message
          : 'Something went wrong. Please try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
