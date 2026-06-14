import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

/// User-facing exception raised by [AuthService]. [code] is the raw Firebase
/// code (e.g. `email-already-in-use`).
class AuthException implements Exception {
  final String code;
  final String message;
  const AuthException(this.code, this.message);

  @override
  String toString() => 'AuthException($code): $message';
}

/// Handles advocate sign-up: creates a Firebase email/password account and
/// stores the rest of the profile at `users/{uid}` in Firestore.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Registers a new advocate. Creates the auth account, then writes the
  /// profile document. Throws [AuthException] on failure.
  Future<void> registerAdvocate({
    required String name,
    required String email,
    required String mobile,
    required String chamberNumber,
    required String barNumber,
    required String organization,
    required String city,
    required String pincode,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = AppUser(
        uid: cred.user!.uid,
        name: name,
        email: email,
        mobile: mobile,
        chamberNumber: chamberNumber,
        barNumber: barNumber,
        organization: organization,
        city: city,
        pincode: pincode,
      );
      await _db.collection('users').doc(user.uid).set(user.toMap());
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, _messageFor(e.code));
    } on FirebaseException catch (e) {
      throw AuthException(e.code, _messageFor(e.code));
    }
  }

  String _messageFor(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak (use at least 6 characters).';
      case 'operation-not-allowed':
        return 'Email sign-up is not enabled. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'permission-denied':
        return 'Unable to save your details. Please try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
