// lib/core/constants/app_constants.dart

class AppConstants {
  // App Info
  static const String appName = 'MediMate';
  static const String appVersion = '1.0.0';
  
  // Localization
  static const String defaultLocale = 'np'; // Nepali
  static const String defaultTimezone = 'Asia/Kathmandu';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String medicinesCollection = 'medicines';
  static const String userMedicinesCollection = 'userMedicines';
  static const String remindersCollection = 'reminders';
  static const String doseLogsCollection = 'doseLogs';
  static const String notificationsCollection = 'notifications';
  
  // Storage Paths
  static const String scansStoragePath = 'scans';
  static const String medicineImagesPath = 'medicines';
  
  // Notification Channels
  static const String reminderChannelId = 'medicine_reminders';
  static const String reminderChannelName = 'Medicine Reminders';
  static const String reminderChannelDescription = 'Notifications for medicine reminders';
  
  // OCR Settings
  static const double minOcrConfidence = 0.7;
  static const int maxImageSizeMB = 5;
  
  // Reminder Settings
  static const int defaultSnoozeMinutes = 10;
  static const int maxRemindersPerDay = 10;
  
  // Error Messages
  static const String networkError = 'No internet connection';
  static const String genericError = 'Something went wrong. Please try again.';
  static const String authError = 'Authentication failed';
  static const String permissionError = 'Permission denied';
}

// Route Names
class Routes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String scan = '/scan';
  static const String scanPreview = '/scan/preview';
  static const String scanResult = '/scan/result';
  static const String reminders = '/reminders';
  static const String addReminder = '/reminders/add';
  static const String medicines = '/medicines';
  static const String medicineDetail = '/medicines/detail';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String onboarding = '/onboarding';
}