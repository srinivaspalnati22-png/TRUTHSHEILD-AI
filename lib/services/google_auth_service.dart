import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

class GoogleAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );
  
  final logger = Logger();

  // Stream to listen to auth changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      logger.i('Starting Google Sign-In...');
      
      // Check if user is already signed in
      final currentUser = _googleSignIn.currentUser;
      
      // Sign out if already signed in to force account selection
      if (currentUser != null) {
        await _googleSignIn.signOut();
      }
      
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        logger.w('Google Sign-In cancelled by user');
        return null;
      }
      
      logger.i('Google user signed in: ${googleUser.email}');
      
      // Get Google authentication tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create credential for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      logger.i('Firebase sign-in successful: ${userCredential.user?.email}');
      return userCredential;
      
    } on FirebaseAuthException catch (e) {
      logger.e('Firebase Auth Error: ${e.code} - ${e.message}');
      throw Exception(_getErrorMessage(e.code));
    } catch (e) {
      logger.e('Google Sign-In Error: $e');
      throw Exception('An error occurred during sign-in. Please try again.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      logger.i('User signed out successfully');
    } catch (e) {
      logger.e('Sign out error: $e');
      throw Exception('Failed to sign out');
    }
  }

  // Get error message
  String _getErrorMessage(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'Account exists with different credentials';
      case 'invalid-credential':
        return 'Invalid credentials provided';
      case 'operation-not-allowed':
        return 'Google Sign-In is not enabled';
      case 'user-disabled':
        return 'User account has been disabled';
      case 'user-not-found':
        return 'User not found';
      case 'wrong-password':
        return 'Wrong password provided';
      default:
        return 'An authentication error occurred';
    }
  }
}
