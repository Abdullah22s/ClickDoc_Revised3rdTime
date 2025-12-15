import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleSignInService {
  // No persistent instance to ensure fresh account picker
  GoogleSignIn _createGoogleSignIn() {
    return GoogleSignIn(
      scopes: ['email', 'profile'],
      signInOption: SignInOption.standard, // forces account picker
    );
  }

  /// Signs in with Google and returns Firebase [User] or null if cancelled.
  Future<User?> signInWithGoogle() async {
    final googleSignIn = _createGoogleSignIn();
    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      debugPrint('GoogleSignInService.signInWithGoogle error: $e');
      return null;
    }
  }

  /// Sign out Firebase + Google
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      final googleSignIn = _createGoogleSignIn();
      await googleSignIn.signOut();
      // ✅ Do NOT call disconnect() — causes PlatformException
    } catch (e) {
      debugPrint('GoogleSignInService.signOut error: $e');
    }
  }
}
