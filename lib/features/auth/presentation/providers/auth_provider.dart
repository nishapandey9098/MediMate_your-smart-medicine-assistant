// lib/features/auth/presentation/providers/auth_provider.dart
// ============================================
// UPDATED: Added email verification support
// ============================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Auth state stream provider
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

// ✅ NEW: Email verification status provider
final emailVerificationProvider = StreamProvider<bool>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  
  return Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
    return await repository.isEmailVerified();
  });
});

// Auth controller state
class AuthState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  AuthState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

// Auth controller
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(AuthState());

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.signInWithEmail(
        email: email,
        password: password,
      );
      
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Signed in successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ✅ UPDATED: Register now sends verification email
  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.registerWithEmail(
        email: email,
        password: password,
        name: name,
      );
      
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Account created! Please check your email to verify.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = AuthState();
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.resetPassword(email);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password reset email sent',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ✅ NEW: Resend verification email
  Future<void> resendVerificationEmail() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.resendVerificationEmail();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Verification email sent!',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

// Auth controller provider
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});