// lib/features/auth/data/repositories/auth_repository.dart
// ✅ COMPLETE FIX for email verification token refresh

// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../domain/entities/user.dart';

class AuthRepository {
  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    firebase_auth.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        // 🔑 Force token refresh on every auth state change
        await firebaseUser.getIdToken(true);
        
        if (!firebaseUser.emailVerified) {
          print('⚠️ User email not verified yet');
          return null;
        }

        final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (!doc.exists) {
          print('⚠️ User document does not exist');
          return null;
        }

        return UserModel.fromFirestore(doc);
      } catch (e) {
        print('❌ Error getting user data: $e');
        return null;
      }
    });
  }

  String? get currentUserId => _auth.currentUser?.uid;
  firebase_auth.User? get currentFirebaseUser => _auth.currentUser;

  // 🔑 FIXED: Properly refresh token and check verification
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      print('🔄 Checking email verification...');
      
      // Step 1: Reload user object
      await user.reload();
      print('✅ User reloaded');
      
      // Step 2: Force refresh ID token (THIS IS CRITICAL!)
      await user.getIdToken(true);
      print('✅ Token refreshed');
      
      // Step 3: Get fresh user instance
      final refreshedUser = _auth.currentUser;
      final isVerified = refreshedUser?.emailVerified ?? false;
      
      print('📧 Email verified status: $isVerified');
      return isVerified;
      
    } catch (e) {
      print('❌ Error checking verification: $e');
      return false;
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }
      if (user.emailVerified) {
        throw Exception('Email already verified');
      }
      await user.sendEmailVerification();
      print('✅ Verification email sent to ${user.email}');
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      print('📝 Starting registration for: $email');

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Registration failed - no user returned');
      }

      print('✅ Firebase Auth account created');

      await credential.user!.sendEmailVerification();
      print('✅ Verification email sent to $email');

      final user = UserModel(
        id: credential.user!.uid,
        email: email,
        name: name,
        createdAt: DateTime.now(),
        locale: 'np',
        timezone: 'Asia/Kathmandu',
      );

      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toFirestore());

      print('✅ User document created in Firestore');
      return user;

    } on firebase_auth.FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Registration error: $e');
      rethrow;
    }
  }

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Sign in failed');
      }

      // 🔑 Force token refresh on login
      await credential.user!.getIdToken(true);

      if (!credential.user!.emailVerified) {
        print('⚠️ Email not verified - user needs to verify');
      }

      final doc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      return UserModel.fromFirestore(doc);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }
      if (user.emailVerified) {
        throw Exception('Email already verified');
      }

      await user.sendEmailVerification();
      print('✅ Verification email resent to ${user.email}');
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        throw 'Too many requests. Please wait a few minutes before trying again.';
      }
      throw _handleAuthException(e);
    }
  }

  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      await user.getIdToken(true); // 🔑 Also refresh token
    }
  }

  String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}