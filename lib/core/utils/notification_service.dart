// lib/core/utils/notification_service.dart
// ═══════════════════════════════════════════════════════════════
// ANDROID 15 (API 35) COMPATIBLE NOTIFICATION SERVICE
// ═══════════════════════════════════════════════════════════════
// ignore_for_file: avoid_print

import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'text_to_speech_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'native_alarm_manager.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class NotificationService {
  
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final TextToSpeechService _tts = TextToSpeechService();
  bool _isInitialized = false;

  // ✅ ADD: EventChannel for receiving alarm fired events
  static const EventChannel _alarmEventChannel = 
      EventChannel('com.medimate.app/alarm_events');
  StreamSubscription? _alarmEventSubscription;
  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════
/// Handle background notification (when app is closed/background)
@pragma('vm:entry-point')
static void _onBackgroundNotificationTapped(NotificationResponse response) {
  print('🔔 BACKGROUND notification fired!');
  print('   ID: ${response.id}');
  print('   Payload: ${response.payload}');
  
  // Note: Can't update UI here, but the notification is automatically removed
  // from pending list by the system
}
  /// Initialize notification service with Android 15 requirements
  Future<void> initialize() async {
    if (_isInitialized) {
      print('ℹ️ NotificationService already initialized');
      return;
    }

    print('🔔 Initializing NotificationService for Android 15...');
    print('═══════════════════════════════════════════════════════════════');

    try {
      // Step 1: Initialize plugin
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
      );

      print('✅ Plugin initialized');

      // Step 2: Request ALL permissions (CRITICAL for Android 15)
      await _requestAllPermissions();

      // Step 3: Verify permissions
      await _verifyPermissions();

      _listenToAlarmEvents();
       /// Listen to alarm fired events from native Android

      _isInitialized = true;
      print('✅ NotificationService fully initialized');
      print('═══════════════════════════════════════════════════════════════\n');
      
    } catch (e) {
      print('❌ NotificationService initialization error: $e');
      print('═══════════════════════════════════════════════════════════════\n');
      rethrow;
    }
  }

// Update the _listenToAlarmEvents method in notification_service.dart

void _listenToAlarmEvents() {
  print('📡 Setting up alarm event listener...');
  _alarmEventSubscription = _alarmEventChannel
      .receiveBroadcastStream()
      .listen((dynamic event) async {
    try {
      print('📨 Received alarm event: $event');
      
      if (event is Map) {
        final eventType = event['event'] as String?;
        final id = event['id'] as int?;
        
        if (eventType == 'alarm_fired' && id != null) {
          print('🔔 Alarm fired event received: ID $id');
          
          // ✅ FIX: Cancel the Flutter notification IMMEDIATELY
          try {
            await _notifications.cancel(id);
            print('✅ Cancelled Flutter notification: ID $id');
            
            await Future.delayed(const Duration(milliseconds: 300));
            
            final pending = await _notifications.pendingNotificationRequests();
            final stillExists = pending.any((n) => n.id == id);
            
            if (stillExists) {
              print('⚠️ WARNING: Notification $id still in pending list!');
              await _notifications.cancel(id);
            } else {
              print('✅ VERIFIED: Notification $id removed from pending');
            }
            
            print('📊 Remaining pending notifications: ${pending.length}');
          } catch (e) {
            print('❌ Error cancelling notification: $e');
          }

          // ✅ NEW: Update next reminder time (which auto-records missed doses)
          await _updateNextReminderTimeForAlarm(id);
        }
      }
    } catch (e) {
      print('❌ Error handling alarm event: $e');
    }
  }, onError: (error) {
    print('❌ Alarm event stream error: $error');
  });
  
  print('✅ Alarm event listener active');
}

// ✅ ADD THIS NEW HELPER METHOD:
Future<void> _updateNextReminderTimeForAlarm(int notificationId) async {
  try {
    // We need to find which reminder this notification belongs to
    // For now, we'll trigger a refresh of all reminders
    // The ReminderRepository will handle the update
    print('📅 Triggering reminder time update for notification: $notificationId');
    
    // Note: We can't directly update here because we don't have access to ReminderRepository
    // The UI providers will handle this when they refresh
    
  } catch (e) {
    print('❌ Error updating reminder time: $e');
  }
}
  /// Request ALL required permissions (Android 15 compatible)
  Future<void> _requestAllPermissions() async {
    print('\n🔐 Requesting Android 15 Permissions...');
    
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      print('⚠️ Not running on Android - skipping Android permissions');
      return;
    }

    // ✅ PERMISSION 1: Notifications (Android 13+)
    print('📱 1. Requesting notification permission...');
    try {
      final notifGranted = await androidPlugin.requestNotificationsPermission();
      print('   Result: ${notifGranted == true ? "✅ GRANTED" : "❌ DENIED"}');
    } catch (e) {
      print('   ⚠️ Error: $e');
    }

    // ✅ PERMISSION 2: Exact Alarms (Android 12+ / CRITICAL for Android 15)
    print('⏰ 2. Requesting exact alarm permission...');
    try {
      final alarmGranted = await androidPlugin.requestExactAlarmsPermission();
      print('   Result: ${alarmGranted == true ? "✅ GRANTED" : "❌ DENIED"}');
    } catch (e) {
      print('   ⚠️ Error: $e');
    }

    // ✅ PERMISSION 3: Full Screen Intent (for locked screen notifications)
    print('🔓 3. Requesting full screen intent permission...');
    try {
      final fullScreenGranted = await androidPlugin.requestFullScreenIntentPermission();
      print('   Result: ${fullScreenGranted == true ? "✅ GRANTED" : "❌ DENIED"}');
    } catch (e) {
      print('   ⚠️ Error: $e');
    }

    // ✅ PERMISSION 4: Battery Optimization Exemption (OPPO specific)
    print('⚡ 4. Requesting battery optimization exemption...');
    try {
      final batteryStatus = await Permission.ignoreBatteryOptimizations.request();
      print('   Result: ${batteryStatus.isGranted ? "✅ GRANTED" : "❌ DENIED"}');
    } catch (e) {
      print('   ⚠️ Error: $e');
    }

    print('✅ Permission requests completed\n');
  }

  /// Verify all permissions are granted
  Future<void> _verifyPermissions() async {
    print('📊 Verifying Permissions Status...');
    
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      print('⚠️ Not running on Android\n');
      return;
    }

    // Check each permission
    final notifEnabled = await androidPlugin.areNotificationsEnabled();
    final canScheduleExact = await androidPlugin.canScheduleExactNotifications();
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;

    print('┌─────────────────────────────────────────────────────┐');
    print('│ PERMISSION STATUS                                    │');
    print('├─────────────────────────────────────────────────────┤');
    print('│ Notifications:      ${notifEnabled == true ? "✅ ENABLED " : "❌ DISABLED"}│');
    print('│ Exact Alarms:       ${canScheduleExact == true ? "✅ ENABLED " : "❌ DISABLED"}│');
    print('│ Battery Exemption:  ${batteryStatus.isGranted ? "✅ GRANTED " : "❌ DENIED  "}│');
    print('└─────────────────────────────────────────────────────┘');

    // Warn if any permission is missing
    if (notifEnabled != true || canScheduleExact != true) {
      print('\n⚠️ ⚠️ ⚠️ WARNING: MISSING CRITICAL PERMISSIONS ⚠️ ⚠️ ⚠️');
      print('Scheduled notifications will NOT work without these permissions!');
      print('Please grant all permissions in Settings.\n');
    } else {
      print('\n✅ All critical permissions granted!\n');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SCHEDULING - ANDROID 15 COMPATIBLE
  // ═══════════════════════════════════════════════════════════════

  /// Schedule a single reminder (Android 15 compatible)
  /// Schedule a single reminder using NATIVE AlarmManager
Future<void> scheduleReminder({
  required int id,
  required String medicineName,
  required String dosage,
  required DateTime scheduledTime,
  String? instructions,
  bool speakNow = false,
}) async {
  await initialize();
  
  print('\n🔔 SCHEDULING REMINDER');
  print('═══════════════════════════════════════════════════════════════');
  print('ID:        $id');
  print('Medicine:  $medicineName');
  print('Dosage:    $dosage');
  print('Scheduled: $scheduledTime');
  
  final now = DateTime.now();
  final difference = scheduledTime.difference(now);
  
  print('Now:       $now');
  print('Difference: ${difference.inSeconds} seconds');
  
  if (scheduledTime.isBefore(now)) {
    print('❌ ERROR: Time is in the past - SKIPPING');
    print('═══════════════════════════════════════════════════════════════\n');
    return;
  }

  try {
    // ✅ FIX: Schedule BOTH native alarm AND Flutter notification
    // This ensures the notification fires AND the counter updates
    
    // 1. Schedule native alarm (for reliability)
    final nativeSuccess = await NativeAlarmManager.scheduleAlarm(
      id: id,
      medicineName: medicineName,
      dosage: dosage,
      instructions: instructions ?? '',
      scheduledTime: scheduledTime,
    );

    if (nativeSuccess) {
      print('✅ Native alarm scheduled');
    }

    // 2. ALSO schedule via Flutter Local Notifications (for pending count)
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
    
    final androidDetails = AndroidNotificationDetails(
      'medicine_reminders',
      'Medicine Reminders',
      channelDescription: 'Time-sensitive medicine reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      styleInformation: BigTextStyleInformation(
        '$medicineName - $dosage${instructions != null ? '\n$instructions' : ''}',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _notifications.zonedSchedule(
      id,
      '💊 Medicine Reminder',
      '$medicineName - $dosage',
      tzScheduledTime,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'reminder:$id|$medicineName|$dosage|${instructions ?? ''}',
    );

    print('✅ Flutter notification scheduled');
    
    // ✅ FIX: Verify it was added to pending list
    final pending = await getPendingNotifications();
    final isScheduled = pending.any((n) => n.id == id);
    
    if (isScheduled) {
      print('✅ VERIFIED: Notification is in pending list');
      print('   Total pending: ${pending.length}');
    } else {
      print('⚠️ WARNING: Notification not found in pending list');
    }
    
    print('═══════════════════════════════════════════════════════════════\n');
  } catch (e) {
    print('❌ SCHEDULING ERROR: $e');
    print('═══════════════════════════════════════════════════════════════\n');
    rethrow;
  }

  if (speakNow) {
    await _tts.speakReminder(
      medicineName: medicineName,
      dosage: dosage,
      instructions: instructions,
    );
  }
}

  /// Schedule daily reminders (Android 15 compatible)
  Future<void> scheduleDailyReminders({
    required int baseId,
    required String medicineName,
    required String dosage,
    required List<String> times,
    String? instructions,
  }) async {
    await initialize();

    print('\n🔔 SCHEDULING ${times.length} DAILY REMINDERS');
    print('Medicine: $medicineName');
    print('Base ID:  $baseId');
    print('═══════════════════════════════════════════════════════════════');

    final now = tz.TZDateTime.now(tz.local);
    int successCount = 0;

    for (int i = 0; i < times.length; i++) {
      try {
        final timeParts = times[i].split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        var scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        // If time passed today, schedule for tomorrow
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
          print('⏰ Time ${times[i]} passed today - scheduling for tomorrow');
        }

        final notificationId = baseId + i;

        await scheduleReminder(
          id: notificationId,
          medicineName: medicineName,
          dosage: dosage,
          scheduledTime: scheduledDate.toLocal(),
          instructions: instructions,
        );

        successCount++;
        print('✅ [$successCount/${times.length}] Scheduled ${times[i]} (ID: $notificationId)');
      } catch (e) {
        print('❌ Failed to schedule ${times[i]}: $e');
      }
    }

    print('═══════════════════════════════════════════════════════════════');
    print('✅ Successfully scheduled $successCount/${times.length} reminders\n');

    // Verify all scheduled
    await _verifyScheduledCount(baseId, successCount);
  }

  // ═══════════════════════════════════════════════════════════════
  // CANCELLATION
  // ═══════════════════════════════════════════════════════════════

  /// Cancel a specific reminder
  Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
    print('🗑️ Cancelled notification ID: $id');
  }

  /// Cancel reminders by base ID
  Future<void> cancelRemindersByBaseId(int baseId) async {
    print('🗑️ Cancelling notifications for base ID: $baseId...');
    
    for (int i = 0; i < 100; i++) {
      await _notifications.cancel(baseId + i);
    }

    print('✅ Cancelled up to 100 notification IDs');
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    print('🗑️ Cancelled ALL notifications');
  }

  // ═══════════════════════════════════════════════════════════════
  // QUERIES & VERIFICATION
  // ═══════════════════════════════════════════════════════════════

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Verify scheduled count
  Future<void> _verifyScheduledCount(int baseId, int expectedCount) async {
    try {
      final pending = await getPendingNotifications();
      final relevantNotifications = pending.where((n) {
        return n.id >= baseId && n.id < baseId + 100;
      }).toList();

      print('\n📊 VERIFICATION:');
      print('Expected: $expectedCount');
      print('Found:    ${relevantNotifications.length}');

      if (relevantNotifications.length != expectedCount) {
        print('⚠️ WARNING: Mismatch in scheduled count!');
      }

      for (final notif in relevantNotifications) {
        print('  • ID ${notif.id}: ${notif.title}');
      }
    } catch (e) {
      print('⚠️ Verification error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // TESTING & DEBUGGING
  // ═══════════════════════════════════════════════════════════════

  /// Show immediate notification (for testing)
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    bool speak = true,
  }) async {
    await initialize();

    final androidDetails = AndroidNotificationDetails(
      'medicine_reminders',
      'Medicine Reminders',
      channelDescription: 'Immediate test notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    await _notifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: 'immediate:$id',
    );

    print('✅ Immediate notification shown (ID: $id)');

    if (speak) {
      await _tts.speak(body);
    }
  }

  /// Get comprehensive status
  Future<Map<String, dynamic>> getStatus() async {
    final pending = await getPendingNotifications();
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    bool? notificationPermission;
    bool? exactAlarmPermission;

    if (androidPlugin != null) {
      notificationPermission = await androidPlugin.areNotificationsEnabled();
      try {
        exactAlarmPermission = await androidPlugin.canScheduleExactNotifications();
      } catch (e) {
        print('Error checking exact alarm permission: $e');
      }
    }

    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;

    return {
      'isInitialized': _isInitialized,
      'notificationPermission': notificationPermission ?? 'unknown',
      'exactAlarmPermission': exactAlarmPermission ?? 'unknown',
      'batteryOptimization': batteryStatus.isGranted ? 'exempted' : 'not exempted',
      'pendingCount': pending.length,
      'pendingReminders': pending.map((n) => {
        'id': n.id,
        'title': n.title,
        'body': n.body,
      }).toList(),
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // HANDLERS
  // ═══════════════════════════════════════════════════════════════

/// Handle notification tap and fire events
void _onNotificationTapped(NotificationResponse response) {
  print('🔔 Notification event!');
  print('   Action ID: ${response.actionId}');
  print('   Payload: ${response.payload}');
  print('   Input: ${response.input}');
  print('   Notification ID: ${response.id}');
  
  // ✅ FIX: Refresh pending count after notification fires
  _refreshPendingCount();
  
  if (response.payload != null && response.payload!.contains('|')) {
    final parts = response.payload!.split('|');
    if (parts.length >= 3) {
      _tts.speakReminder(
        medicineName: parts[1],
        dosage: parts[2],
        instructions: parts.length > 3 ? parts[3] : null,
      );
    }
  }
}

/// Refresh pending notification count
Future<void> _refreshPendingCount() async {
  try {
    final pending = await getPendingNotifications();
    print('📊 Pending count refreshed: ${pending.length} notifications');
  } catch (e) {
    print('⚠️ Error refreshing count: $e');
  }
}

  /// Speak a reminder
  Future<void> speakReminder({
    required String medicineName,
    required String dosage,
    String? instructions,
  }) async {
    await _tts.speakReminder(
      medicineName: medicineName,
      dosage: dosage,
      instructions: instructions,
    );
  }

  /// Test notification
  Future<void> testNotification() async {
    await showImmediateNotification(
      id: 999999,
      title: '🧪 Test Medicine Reminder',
      body: 'Paracetamol - 500mg\nTake with food',
      speak: true,
    );
  }

  /// Clean up
  void dispose() {
     _alarmEventSubscription?.cancel();  
    _tts.dispose();
  }
}