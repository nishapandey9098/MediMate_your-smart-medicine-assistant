// ignore_for_file: avoid_print

import 'package:flutter/services.dart';

class NativeAlarmManager {
  static const _platform = MethodChannel('com.medimate.app/native_alarm');
  
  /// Schedule alarm using native Android AlarmManager
  static Future<bool> scheduleAlarm({
    required int id,
    required String medicineName,
    required String dosage,
    required String instructions,
    required DateTime scheduledTime,
  }) async {
    try {
      print('📱 Scheduling NATIVE alarm...');
      print('   ID: $id');
      print('   Medicine: $medicineName');
      print('   Time: $scheduledTime');
      
      final result = await _platform.invokeMethod('scheduleAlarm', {
        'id': id,
        'medicineName': medicineName,
        'dosage': dosage,
        'instructions': instructions,
        'triggerTimeMillis': scheduledTime.millisecondsSinceEpoch,
      });
      
      print('✅ Native alarm scheduled: $result');
      return result == true;
    } catch (e) {
      print('❌ Failed to schedule native alarm: $e');
      return false;
    }
  }
  
  /// Cancel alarm
  static Future<bool> cancelAlarm(int id) async {
    try {
      final result = await _platform.invokeMethod('cancelAlarm', {'id': id});
      print('🗑️ Native alarm cancelled: ID $id');
      return result == true;
    } catch (e) {
      print('❌ Failed to cancel native alarm: $e');
      return false;
    }
  }
}