import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/models/user.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final ApiClient _api = ApiClient.instance;

  Stream<User?> get firebaseUserChanges => _firebaseAuth.authStateChanges();
  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  bool get isEmailVerified {
    final user = _firebaseAuth.currentUser;
    if (user == null) return true;
    final signedInWithPassword = user.providerData.any(
      (p) => p.providerId == 'password',
    );
    if (!signedInWithPassword) return true;
    return user.emailVerified;
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw ApiException(_mapFirebaseError(e));
    }
  }

  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required ExperienceLevel experienceLevel,
  }) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw ApiException(_mapFirebaseError(e));
    }

    try {
      await _firebaseAuth.currentUser?.sendEmailVerification();
    } catch (_) {
      // Non-fatal — the user can request another one from the
      // verify-email screen.
    }

    final synced = await sync();
    return updateProfile(name: synced.name, experienceLevel: experienceLevel);
  }

  /// Resends the verification link to the currently signed-in user.
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw ApiException('Not signed in.');
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw ApiException(_mapFirebaseError(e));
    }
  }

  Future<bool> reloadAndCheckVerified() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;
    try {
      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw ApiException(_mapFirebaseError(e));
    }
    return isEmailVerified;
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return;
      throw ApiException(_mapFirebaseError(e));
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        await _firebaseAuth.signInWithPopup(GoogleAuthProvider());
        return;
      }
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw ApiException('Google sign-in was cancelled.');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw ApiException(_mapFirebaseError(e));
    }
  }

  Future<AppUser> sync() {
    return _api.unwrap(
      (dio) => dio.post('/api/v1/auth/sync'),
      (data) => AppUser.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<AppUser> updateProfile({
    required String name,
    String? phoneNumber,
    String? githubUrl,
    String? linkedinUrl,
    String? location,
    String? softSkills,
    String? bio,
    ExperienceLevel? experienceLevel,
    bool? availability,
    String? avatarUrl,
  }) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) throw ApiException('Not signed in.');

    final current = await sync();

    final body = <String, dynamic>{'name': name};
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    if (githubUrl != null) body['githubUrl'] = githubUrl;
    if (linkedinUrl != null) body['linkedinUrl'] = linkedinUrl;
    if (location != null) body['location'] = location;
    if (softSkills != null) body['softSkills'] = softSkills;
    if (bio != null) body['bio'] = bio;
    if (experienceLevel != null) {
      body['experienceLevel'] = experienceLevelToApiString(experienceLevel);
    }
    if (availability != null) body['availability'] = availability;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;

    return _api.unwrap(
      (dio) => dio.put('/api/v1/users/${current.id}', data: body),
      (data) => AppUser.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _firebaseAuth.signOut();
  }

  /// Used when a registration's backend sync fails after the Firebase account was already created: signing out
  Future<void> deleteCurrentFirebaseUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') rethrow;
      try {
        await signOut();
      } catch (_) {}
    }
  }

  /// PUT /api/v1/users/{userId}/device-token — registers this device's FCM
  /// token so push notifications (invite received/accepted/rejected, join
  /// request received/accepted/rejected) can reach it.
  Future<void> registerDeviceToken(int userId, String token, String platform) {
    return _api.unwrap(
      (dio) => dio.put(
        '/api/v1/users/$userId/device-token',
        data: {'token': token, 'platform': platform},
      ),
      (_) {},
    );
  }

  /// DELETE /api/v1/users/{userId}/device-token?token=... — called on
  /// sign-out so a shared/reinstalled device stops receiving this user's
  /// notifications.
  Future<void> unregisterDeviceToken(int userId, String token) {
    return _api.unwrap(
      (dio) => dio.delete(
        '/api/v1/users/$userId/device-token',
        queryParameters: {'token': token},
      ),
      (_) {},
    );
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Please choose a stronger password (6+ characters).';
      case 'invalid-email':
        return 'That email address looks invalid.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
