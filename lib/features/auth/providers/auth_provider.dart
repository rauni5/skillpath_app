import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';

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

  /// True while signIn()/signInWithGoogle()/register() is actively driving its own sync.
  bool _explicitAuthInFlight = false;

  Future<void> _onFirebaseUserChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      status = AuthStatus.unauthenticated;
      currentUser = null;
      needsOnboarding = null;
      needsEmailVerification = false;
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
      // Firebase says signed in but backend sync faile
      await _onSyncFailure(e);
    }
  }

  //backend sync succeeded
  Future<void> _onSyncSuccess(AppUser user) async {
    currentUser = user;
    status = AuthStatus.authenticated;
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
      final gap = await _careerRepo.getGapAnalysis(userId);
      needsOnboarding = !gap.hasGoalSet;
    } catch (_) {
      needsOnboarding = true;
    }
    notifyListeners();
  }

  /// Called by the onboarding flow once it has just set the career goal
  /// itself — avoids one extra round trip before the router unlocks the
  /// main app.
  void markOnboardingComplete() {
    needsOnboarding = false;
    notifyListeners();
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
  });

  Future<void> signOut() async {
    await NotificationService.instance.handleSignOut();
    await _repo.signOut();
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
