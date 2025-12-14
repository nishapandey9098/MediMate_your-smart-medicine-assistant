// ============================================
// FILE: lib/main.dart
// CHANGE: Added timezone initialization before runApp
// WHY: Notifications were using UTC instead of local time
// ============================================

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'core/config/firebase_options.dart';
import 'core/utils/notification_service.dart'; // ADDED
import 'shared/theme/app_theme.dart';
import 'routes/app_router.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }

  // ==========================================
  // CRITICAL FIX: Initialize timezone BEFORE notification service
  // ==========================================
  try {
    print('🌍 Initializing timezones...');
    tz.initializeTimeZones();
    
    // Set to Asia/Kathmandu (Nepal timezone)
    final kathmandu = tz.getLocation('Asia/Kathmandu');
    tz.setLocalLocation(kathmandu);
    
    print('✅ Timezone set to: ${kathmandu.name}');
    print('   Current time: ${tz.TZDateTime.now(kathmandu)}');
  } catch (e) {
    print('⚠️ Timezone initialization error: $e');
    print('   Falling back to system timezone');
  }

  // ==========================================
  // CRITICAL FIX: Initialize notification service on app start
  // ==========================================
  try {
    print('🔔 Initializing notification service...');
    final notificationService = NotificationService();
    await notificationService.initialize();
    print('✅ Notification service initialized');
  } catch (e) {
    print('❌ Notification service initialization error: $e');
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: MediMateApp(),
    ),
  );
}

class MediMateApp extends ConsumerWidget {
  const MediMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'MediMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}