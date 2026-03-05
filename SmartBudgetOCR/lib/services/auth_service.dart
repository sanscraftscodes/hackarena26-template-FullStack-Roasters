import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Initialize GoogleSignIn with platform-specific configuration
GoogleSignIn _initializeGoogleSignIn() {
  if (kIsWeb) {
    // Web platform requires clientId to be set
    // The clientId is initialized via meta tag in web/index.html
    // Using null here will fall back to meta tag initialization
    return GoogleSignIn();
  }
  return GoogleSignIn();
}

/// Auth service. No business logic in UI - use this service.
/// Uses firebase_options.dart for config (do NOT hardcode).
class AuthService {
  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? _initializeGoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current Firebase ID token. Always use for API calls.
  /// Never send user_id manually - backend extracts from token.
  Future<String?> getIdToken() async {
    return _auth.currentUser?.getIdToken();
  }

  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return _auth.signInWithCredential(credential);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Google Sign-In error: $e');
      }
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }
}
