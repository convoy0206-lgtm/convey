import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart' show firebaseAvailable;
import '../models/user_model.dart';

/// Mock user used when Firebase is not available (demo/test mode).
const _mockUser = UserModel(
  uid: 'mock_uid_12345',
  email: 'trailblazer@convoy.com',
  displayName: 'Yosemite Trailblazer',
  photoUrl: '',
);

/// Provider definition for [AuthService] to integrate with Riverpod.
final authServiceProvider = Provider<AuthService>((ref) {
  if (!firebaseAvailable) {
    return AuthService(null);
  }
  try {
    return AuthService(FirebaseAuth.instance);
  } catch (e) {
    debugPrint("FirebaseAuth not available, using mock: $e");
    return AuthService(null);
  }
});

/// StreamProvider to track user authentication changes.
final authStateChangesProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

class AuthService {
  final FirebaseAuth? _firebaseAuth;

  AuthService(this._firebaseAuth);

  /// Map Firebase [User] to our custom [UserModel].
  UserModel? _userFromFirebase(User? user) {
    if (user == null) return null;
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL ?? '',
    );
  }

  /// Exposes a stream of authentication state changes mapped to our [UserModel].
  Stream<UserModel?> get authStateChanges {
    if (_firebaseAuth == null) {
      // Mock mode: immediately emit a logged-in mock user for local testing
      return Stream.value(_mockUser);
    }
    return _firebaseAuth!.authStateChanges().map(_userFromFirebase);
  }

  /// Retrieve current authenticated user directly.
  UserModel? get currentUser {
    if (_firebaseAuth == null) return _mockUser;
    return _userFromFirebase(_firebaseAuth!.currentUser);
  }

  /// User Registration using email and password.
  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (_firebaseAuth == null) return _mockUser;
    try {
      final UserCredential credential = await _firebaseAuth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = credential.user;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.reload();
        return _userFromFirebase(_firebaseAuth!.currentUser);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign In using email and password.
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (_firebaseAuth == null) return _mockUser;
    try {
      final UserCredential credential = await _firebaseAuth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebase(credential.user);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out the current user session.
  Future<void> signOut() async {
    if (_firebaseAuth == null) return;
    try {
      await _firebaseAuth!.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  /// Map firebase exception codes to developer-friendly errors.
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception('The password provided is too weak.');
      case 'email-already-in-use':
        return Exception('An account already exists for that email.');
      case 'invalid-email':
        return Exception('The email address format is invalid.');
      case 'user-disabled':
        return Exception('This user account has been disabled.');
      case 'user-not-found':
        return Exception('No user found for that email.');
      case 'wrong-password':
        return Exception('Incorrect password provided.');
      case 'invalid-credential':
        return Exception('Invalid email or password.');
      default:
        return Exception(e.message ?? 'An unknown authentication error occurred.');
    }
  }
}
