import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';

import '../../../core/models/user.dart';
import '../../../core/network/api_exception.dart';
import '../../career/data/career_repository.dart';
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

  Future<void> _onFirebaseUserChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      status = AuthStatus.unauthenticated;
      currentUser = null;
      needsOnboarding = null;
      needsEmailVerification = false;
      notifyListeners();
      return;
    }
    needsEmailVerification = !_repo.isEmailVerified;
    try {
      currentUser = await _repo.sync();
      status = AuthStatus.authenticated;
      notifyListeners();
      await refreshOnboardingStatus();
    } catch (e) {
      // Firebase says signed in but backend sync failed (e.g. API down).
      status = AuthStatus.unauthenticated;
      errorMessage = e is ApiException
          ? e.message
          : 'Could not reach SkillPath servers.';
      notifyListeners();
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

  Future<bool> signIn(String email, String password) =>
      _run(() => _repo.signInWithEmail(email, password));

  Future<bool> signInWithGoogle() => _run(() => _repo.signInWithGoogle());

  Future<bool> register({
    required String email,
    required String password,
    required ExperienceLevel experienceLevel,
  }) => _run(() async {
    currentUser = await _repo.registerWithEmail(
      email: email,
      password: password,
      experienceLevel: experienceLevel,
    );
    needsEmailVerification = !_repo.isEmailVerified;
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

  /// Used by the onboarding "About you" step to confirm/edit the name,
  /// bio, and experience level (Google sign-in never collects these).
  Future<bool> updateProfile({
    required String name,
    String? bio,
    ExperienceLevel? experienceLevel,
  }) => _run(() async {
    currentUser = await _repo.updateProfile(
      name: name,
      bio: bio,
      experienceLevel: experienceLevel,
    );
  });

  Future<void> signOut() async {
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
