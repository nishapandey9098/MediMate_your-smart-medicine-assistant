// lib/core/utils/notification_helper.dart
// ============================================
// NOTIFICATION SYSTEM - COMPLETE FIX
// ✅ Fixed: Initialization, permissions, timezone, scheduling
// ============================================
// ignore_for_file: avoid_print

import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  // ============================================
  // INITIALIZATION
  // ============================================

  /// ✅ FIX: Complete initialization with permissions
  static Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ Notification helper already initialized');
      return;
    }

    print('🔔 Initializing NotificationHelper...');

    try {
      // Android settings
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );

      // ✅ FIX: Request permissions
      await _requestPermissions();

      _isInitialized = true;
      print('✅ NotificationHelper initialized successfully');

    } catch (e) {
      print('❌ Error initializing NotificationHelper: $e');
      rethrow;
    }
  }

  /// ✅ FIX: Request all required permissions
  static Future<void> _requestPermissions() async {
    print('🔐 Requesting notification permissions...');

    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // ✅ FIX: Request notification permission (Android 13+)
        final notificationGranted =
            await androidPlugin.requestNotificationsPermission();
        print('📱 Notification permission: ${notificationGranted == true ? '✅ GRANTED' : '❌ DENIED'}');

        // ✅ FIX: Request exact alarm permission (Android 12+)
        final alarmGranted =
            await androidPlugin.requestExactAlarmsPermission();
        print('⏰ Exact alarm permission: ${alarmGranted == true ? '✅ GRANTED' : '❌ DENIED'}');
      }
    } catch (e) {
      print('⚠️ Permission request error: $e');
    }
  }

  // ============================================
  // SCHEDULING
  // ============================================

  /// ✅ FIX: Schedule reminder with full debugging and error handling
  static Future<bool> scheduleReminder({
    required int id,
    required String medicineName,
    required String dosage,
    required DateTime scheduledTime,
    String? instructions,
  }) async {
    if (!_isInitialized) {
      print('⚠️ NotificationHelper not initialized, initializing now...');
      await initialize();
    }

    print('═══════════════════════════════════════════════════════════════');
    print('🔔 SCHEDULING REMINDER');
    print('═══════════════════════════════════════════════════════════════');
    print('📍 ID: $id');
    print('💊 Medicine: $medicineName');
    print('💉 Dosage: $dosage');
    print('⏰ Scheduled for: $scheduledTime');
    print('🕐 Current device time: ${DateTime.now()}');

    try {
      // ✅ FIX: Convert to TZDateTime with Asia/Kathmandu timezone
      final kathanduTZ = tz.getLocation('Asia/Kathmandu');
      final tzDateTime = tz.TZDateTime.from(scheduledTime, kathanduTZ);
      final nowTZ = tz.TZDateTime.now(kathanduTZ);

      print('🇳🇵 Scheduled (Kathmandu TZ): $tzDateTime');
      print('⏱️ Minutes from now: ${tzDateTime.difference(nowTZ).inMinutes}');

      // ✅ FIX: Validate time not in past
      if (tzDateTime.isBefore(nowTZ)) {
        print('❌ ERROR: Scheduled time is in the past!');
        return false;
      }

      // ✅ FIX: Cancel any existing notification with this ID
      await _plugin.cancel(id);
      print('🗑️ Cancelled existing notification with ID: $id');

      // Build notification details
      final title = '💊 Medicine Reminder';
      final body =
          '$medicineName - $dosage${instructions != null ? '\n$instructions' : ''}';
      final payload = 'reminder:$id|$medicineName|$dosage|${instructions ?? ''}';

      final androidDetails = AndroidNotificationDetails(
        'medicine_reminders',
        'Medicine Reminders',
        channelDescription: 'Reminders to take medicine on time',
        importance: Importance.max,
        priority: Priority.high,
        sound: const RawResourceAndroidNotificationSound('notification'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        playSound: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'Tap to mark as taken',
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification.aiff',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // ✅ FIX: Schedule with exactAllowWhileIdle for background execution
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      // ✅ FIX: Verify notification was scheduled
      final pending = await _plugin.pendingNotificationRequests();
      final scheduled = pending.any((n) => n.id == id);

      if (scheduled) {
        print('✅ NOTIFICATION SCHEDULED SUCCESSFULLY');
        print('   ID: $id at $tzDateTime');
      } else {
        print('⚠️ WARNING: Notification may not have been scheduled');
      }

      print('═══════════════════════════════════════════════════════════════');
      return true;

    } catch (e) {
      print('❌ ERROR SCHEDULING NOTIFICATION: $e');
      print('═══════════════════════════════════════════════════════════════');
      return false;
    }
  }

  // ============================================
  // CANCELLATION
  // ============================================

  /// ✅ FIX: Cancel a single notification
  static Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id);
      print('🗑️ Cancelled notification ID: $id');
    } catch (e) {
      print('❌ Error cancelling notification: $e');
    }
  }

  /// ✅ FIX: Cancel all notifications for a base ID (for daily reminders)
  static Future<void> cancelNotificationsByBaseId(int baseId) async {
    print('🗑️ Cancelling all notifications for baseId: $baseId');

    try {
      // Cancel up to 10 instances (usually enough for daily reminders)
      for (int i = 0; i < 10; i++) {
        await _plugin.cancel(baseId + i);
      }
      print('✅ Cancelled all notifications for baseId: $baseId');
    } catch (e) {
      print('❌ Error cancelling notifications: $e');
    }
  }

  /// ✅ FIX: Cancel all notifications
  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      print('🗑️ Cancelled all notifications');
    } catch (e) {
      print('❌ Error cancelling all: $e');
    }
  }

  // ============================================
  // QUERYING
  // ============================================

  /// ✅ FIX: Get pending notifications for debugging
  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (e) {
      print('❌ Error getting pending notifications: $e');
      return [];
    }
  }

  // ============================================
  // HANDLERS
  // ============================================

  static void _handleNotificationResponse(NotificationResponse response) {
    print('📲 Notification tapped: ${response.payload}');
    // Handle notification tap
  }

  // ============================================
  // UTILITIES
  // ============================================

  /// Generate unique but consistent ID for a reminder
  static int generateNotificationId(String reminderId) {
    // Use first 8 chars of UUID hash to generate ID
    final hash = reminderId.hashCode.abs();
    return hash % 1000000; // Keep ID reasonable size
  }

  /// Check if a specific notification is scheduled
  static Future<bool> isNotificationScheduled(int id) async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.any((n) => n.id == id);
    } catch (e) {
      print('❌ Error checking notification status: $e');
      return false;
    }
  }
}