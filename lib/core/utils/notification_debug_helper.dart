// ============================================
// FILE: lib/core/utils/notification_debug_helper.dart
// CREATE THIS NEW FILE
// ============================================
/// Helper to debug notification issues
// ignore_for_file: avoid_print

library;


import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';

class NotificationDebugHelper {
  static final NotificationService _notificationService = NotificationService();

  /// Check if notifications are working
  static Future<Map<String, dynamic>> checkNotificationStatus() async {
    final plugin = FlutterLocalNotificationsPlugin();
    
    // Check Android permissions
    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    bool? notificationPermission;
    bool? exactAlarmPermission;
    
    if (androidPlugin != null) {
      notificationPermission = await androidPlugin.areNotificationsEnabled();
      
      // Try to check exact alarm permission
      try {
        exactAlarmPermission = await androidPlugin.canScheduleExactNotifications();
      } catch (e) {
        print('Could not check exact alarm permission: $e');
      }
    }

    // Get pending notifications
    final pending = await _notificationService.getPendingNotifications();

    return {
      'notificationPermission': notificationPermission ?? 'unknown',
      'exactAlarmPermission': exactAlarmPermission ?? 'unknown',
      'pendingCount': pending.length,
      'pendingNotifications': pending.map((n) => {
        'id': n.id,
        'title': n.title,
        'body': n.body,
      }).toList(),
    };
  }

  /// Request all permissions
  static Future<void> requestAllPermissions() async {
    final plugin = FlutterLocalNotificationsPlugin();
    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      print('🔔 Requesting notification permission...');
      final granted = await androidPlugin.requestNotificationsPermission();
      print('   Result: $granted');
      
      print('⏰ Requesting exact alarm permission...');
      final alarmGranted = await androidPlugin.requestExactAlarmsPermission();
      print('   Result: $alarmGranted');
    }
  }

  /// Print debug info
  static Future<void> printDebugInfo() async {
    print('\n========================================');
    print('🔍 NOTIFICATION DEBUG INFO');
    print('========================================');
    
    final status = await checkNotificationStatus();
    
    print('📱 Notification Permission: ${status['notificationPermission']}');
    print('⏰ Exact Alarm Permission: ${status['exactAlarmPermission']}');
    print('📊 Pending Notifications: ${status['pendingCount']}');
    
    if (status['pendingCount'] > 0) {
      print('\n📋 Pending Notifications:');
      for (final notif in status['pendingNotifications']) {
        print('   • ID ${notif['id']}: ${notif['title']}');
      }
    } else {
      print('⚠️  No pending notifications scheduled!');
    }
    
    print('========================================\n');
  }
}