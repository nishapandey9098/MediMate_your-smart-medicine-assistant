// lib/core/utils/oppo_settings_guide.dart
// ignore_for_file: avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class OppoSettingsGuide {
  /// Show dialog to guide user through OPPO settings
  static Future<void> showSettingsGuide(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings, color: Colors.orange),
            SizedBox(width: 12),
            Text('Setup Required'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'For reminders to work on OPPO devices, you need to:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              _buildStep(
                '1',
                'Enable Auto-start',
                'Settings → Apps → App Management → MediMate → Allow Auto-start',
              ),
              
              _buildStep(
                '2',
                'Disable Battery Optimization',
                'Settings → Battery → Battery Saver → MediMate → Don\'t optimize',
              ),
              
              _buildStep(
                '3',
                'Allow Background Activity',
                'Settings → Apps → App Management → MediMate → Background Activity → Allow',
              ),
              
              _buildStep(
                '4',
                'Allow Notifications',
                'Settings → Notifications → MediMate → Enable all',
              ),
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Without these settings, notifications won\'t work!',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I\'ll do it later'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  static Widget _buildStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Open app settings
  static Future<void> _openSettings() async {
    await openAppSettings();
  }

  /// Check if all permissions are granted
  static Future<bool> checkAllPermissions() async {
    final plugin = FlutterLocalNotificationsPlugin();
    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return true;

    final notifEnabled = await androidPlugin.areNotificationsEnabled();
    final canSchedule = await androidPlugin.canScheduleExactNotifications();
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;

    return (notifEnabled == true) && 
           (canSchedule == true) && 
           batteryStatus.isGranted;
  }

  /// Show warning if permissions not granted
  static Future<void> checkAndShowWarning(BuildContext context) async {
    final allGranted = await checkAllPermissions();
    
    if (!allGranted && context.mounted) {
      await showSettingsGuide(context);
    }
  }
}