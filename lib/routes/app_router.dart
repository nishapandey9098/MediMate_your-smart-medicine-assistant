// lib/routes/app_router.dart
// ✅ FIXED: Proper email verification routing

// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/email_verification_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/scan/presentation/screens/home_screen.dart';

// In app_router.dart:

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final isLoggedIn = authState.value != null;
      final currentPath = state.matchedLocation;
      
      final isAuthRoute = currentPath == '/login' || currentPath == '/register';
      final isVerificationRoute = currentPath == '/verify-email';

      print('🔀 Router redirect check:');
      print('   Path: $currentPath');
      print('   Logged in: $isLoggedIn');

      if (!isLoggedIn) {
        final authRepo = ref.read(authRepositoryProvider);
        final currentUser = authRepo.currentFirebaseUser;
        
        if (currentUser != null && !currentUser.emailVerified) {
          print('   → User exists but not verified');
          if (!isVerificationRoute) return '/verify-email';
          return null;
        }
        
        if (isAuthRoute) return null;
        return '/login';
      }

      // User is logged in and verified
      print('   → User is verified, allowing access');
      
      if (isAuthRoute || isVerificationRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});