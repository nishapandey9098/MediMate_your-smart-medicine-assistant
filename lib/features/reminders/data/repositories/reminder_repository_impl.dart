// lib/features/reminders/data/repositories/reminder_repository_impl.dart
// ============================================
// FIXED: Removed redundant userId filters from dose log queries
// ============================================
// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/dose_log.dart';
import '../models/reminder_model.dart';
import '../models/dose_log_model.dart';
import '../../../../core/utils/notification_service.dart';

class ReminderRepository {
  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  ReminderRepository({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationService = notificationService ?? NotificationService();

  /// Create a new reminder
  Future<Reminder> createReminder({
    required String userId,
    required String medicineName,
    required String dosage,
    String? instructions,
    required List<String> reminderTimes,
    required ReminderFrequency frequency,
    List<int>? weekdays,
    String? scanId,
  }) async {
    print('📝 Creating reminder for $medicineName');
    
    try {
      final reminderId = const Uuid().v4();
      
      final nextReminder = _calculateNextReminderTime(
        reminderTimes,
        frequency,
        weekdays,
      );

      final reminder = ReminderModel(
        id: reminderId,
        userId: userId,
        medicineName: medicineName,
        dosage: dosage,
        instructions: instructions,
        reminderTimes: reminderTimes,
        frequency: frequency,
        weekdays: weekdays,
        isActive: true,
        createdAt: DateTime.now(),
        nextReminderAt: nextReminder,
        scanId: scanId,
      );

      await _firestore
          .collection('reminders')
          .doc(userId)
          .collection('userReminders')
          .doc(reminderId)
          .set(reminder.toFirestore());
      
      print('✅ Reminder saved to Firestore');
      await _scheduleNotificationsForReminder(reminder);
      
      final pending = await _notificationService.getPendingNotifications();
      print('✅ Total pending notifications: ${pending.length}');
      return reminder;
      
    } catch (e) {
      print('❌ Error creating reminder: $e');
      rethrow;
    }
  }

  /// Update a reminder - FIXED: Recalculates nextReminderAt
  Future<void> updateReminder({
    required String userId,
    required Reminder reminder,
  }) async {
    try {
      print('📝 Updating reminder: ${reminder.medicineName}');
      
      // STEP 1: Cancel ALL old notifications
      await _cancelAllNotificationsForReminder(reminder);
      print('✅ Old notifications canceled');
      
      // STEP 2: Convert domain entity to data model
      final reminderModel = ReminderModel.fromEntity(reminder);
      
      // ✅ FIX: Recalculate next reminder time BEFORE saving
      final nextTime = _calculateNextReminderTime(
        reminder.reminderTimes,
        reminder.frequency,
        reminder.weekdays,
      );
      
      // Create updated model with new nextReminderAt
      final updatedModel = reminderModel.copyWith(
        nextReminderAt: nextTime,
      );
      
      // STEP 3: Update in Firestore using the SAME document ID
      await _firestore
          .collection('reminders')
          .doc(userId)
          .collection('userReminders')
          .doc(reminder.id)
          .update(updatedModel.toFirestore());
      
      print('✅ Reminder updated in Firestore with next time: $nextTime');
      
      // STEP 4: Reschedule notifications if active
      if (reminder.isActive) {
        await _scheduleNotificationsForReminder(updatedModel);
        print('✅ New notifications scheduled');
        
        final pending = await _notificationService.getPendingNotifications();
        print('✅ Total pending: ${pending.length}');
      }
      
    } catch (e) {
      print('❌ Error updating reminder: $e');
      rethrow;
    }
  }

  /// Get all reminders for a user
  Stream<List<Reminder>> getUserReminders(String userId) {
    return _firestore
        .collection('reminders')
        .doc(userId)
        .collection('userReminders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ReminderModel.fromFirestore(doc);
          }).toList();
        });
  }

  /// Get a single reminder
  Future<Reminder?> getReminder({
    required String userId,
    required String reminderId,
  }) async {
    try {
      final doc = await _firestore
          .collection('reminders')
          .doc(userId)
          .collection('userReminders')
          .doc(reminderId)
          .get();
      
      if (doc.exists) {
        return ReminderModel.fromFirestore(doc);
      }
      return null;
      
    } catch (e) {
      print('❌ Error getting reminder: $e');
      return null;
    }
  }

  /// Toggle reminder active status
  Future<void> toggleReminderStatus({
    required String userId,
    required String reminderId,
    required bool isActive,
  }) async {
    try {
      await _firestore
          .collection('reminders')
          .doc(userId)
          .collection('userReminders')
          .doc(reminderId)
          .update({'isActive': isActive});
      
      final reminder = await getReminder(userId: userId, reminderId: reminderId);
      
      if (reminder != null) {
        final reminderModel = ReminderModel.fromEntity(reminder);
        
        if (!isActive) {
          await _cancelAllNotificationsForReminder(reminderModel);
          print('✅ Reminder deactivated - notifications canceled');
        } else {
          await _scheduleNotificationsForReminder(reminderModel);
          print('✅ Reminder activated - notifications scheduled');
        }
      }
      
    } catch (e) {
      print('❌ Error toggling reminder: $e');
      rethrow;
    }
  }

  /// Delete a reminder
  Future<void> deleteReminder({
    required String userId,
    required String reminderId,
  }) async {
    try {
      print('🗑️ Deleting reminder: $reminderId');
      
      final reminder = await getReminder(userId: userId, reminderId: reminderId);
      
      if (reminder != null) {
        await _cancelAllNotificationsForReminder(reminder);
        print('✅ Notifications canceled');
      }
      
      await _firestore
          .collection('reminders')
          .doc(userId)
          .collection('userReminders')
          .doc(reminderId)
          .delete();
      
      print('✅ Reminder deleted');
      
    } catch (e) {
      print('❌ Error deleting reminder: $e');
      rethrow;
    }
  }

  /// Record a dose log
  Future<void> recordDoseLog({
    required String userId,
    required String reminderId,
    required String medicineName,
    required DateTime scheduledTime,
    required DoseStatus status,
    String? notes,
  }) async {
    try {
      final logId = const Uuid().v4();
      
      final doseLog = DoseLogModel(
        id: logId,
        userId: userId,
        reminderId: reminderId,
        medicineName: medicineName,
        scheduledTime: scheduledTime,
        takenAt: status == DoseStatus.taken ? DateTime.now() : null,
        status: status,
        notes: notes,
      );

      await _firestore
          .collection('doseLogs')
          .doc(userId)
          .collection('logs')
          .doc(logId)
          .set(doseLog.toFirestore());
      
      print('✅ Dose log recorded: $status');
      
    } catch (e) {
      print('❌ Error recording dose log: $e');
      rethrow;
    }
  }

  /// Get dose logs for a reminder - FIXED: Removed redundant userId filter
  Stream<List<DoseLog>> getDoseLogsForReminder({
    required String userId,
    required String reminderId,
  }) {
    return _firestore
        .collection('doseLogs')
        .doc(userId)
        .collection('logs')
        .where('reminderId', isEqualTo: reminderId)
        // ✅ REMOVED: .where('userId', isEqualTo: userId) - redundant since we're under doseLogs/{userId}/logs
        .orderBy('scheduledTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return DoseLogModel.fromFirestore(doc);
          }).toList();
        });
  }

  /// Get recent dose logs - FIXED: Removed redundant userId filter
  Stream<List<DoseLog>> getRecentDoseLogs(String userId) {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    
    return _firestore
        .collection('doseLogs')
        .doc(userId)
        .collection('logs')
        // ✅ REMOVED: .where('userId', isEqualTo: userId) - redundant
        .where('scheduledTime', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
        .orderBy('scheduledTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return DoseLogModel.fromFirestore(doc);
          }).toList();
        });
  }

  /// Calculate adherence rate - FIXED: Removed redundant userId filter
  Future<double> calculateAdherenceRate(String userId) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      final logs = await _firestore
          .collection('doseLogs')
          .doc(userId)
          .collection('logs')
          // ✅ REMOVED: .where('userId', isEqualTo: userId) - redundant
          .where('scheduledTime', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      if (logs.docs.isEmpty) return 0.0;

      final takenCount = logs.docs.where((doc) {
        final status = doc.data()['status'] as String?;
        return status == 'taken';
      }).length;

      final totalCount = logs.docs.length;
      return (takenCount / totalCount) * 100;
      
    } catch (e) {
      print('❌ Error calculating adherence: $e');
      return 0.0;
    }
  }

  // ==========================================
  // PRIVATE HELPER METHODS
  // ==========================================

  /// Schedule notifications for a reminder
  Future<void> _scheduleNotificationsForReminder(Reminder reminder) async {
    print('🔔 Scheduling notifications for ${reminder.medicineName}');
    
    try {
      final baseId = _generateStableBaseId(reminder.id);
      print('   Base ID: $baseId');

      if (reminder.frequency == ReminderFrequency.daily) {
        await _notificationService.scheduleDailyReminders(
          baseId: baseId,
          medicineName: reminder.medicineName,
          dosage: reminder.dosage,
          times: reminder.reminderTimes,
          instructions: reminder.instructions,
        );
        
      } else if (reminder.frequency == ReminderFrequency.weekly) {
        int notificationIndex = 0;
        
        for (final timeStr in reminder.reminderTimes) {
          final timeParts = timeStr.split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          
          for (final weekday in (reminder.weekdays ?? [])) {
            final now = DateTime.now();
            var scheduledDate = _getNextWeekday(weekday, hour, minute);
            
            if (scheduledDate.isBefore(now)) {
              scheduledDate = scheduledDate.add(const Duration(days: 7));
            }
            
            await _notificationService.scheduleReminder(
              id: baseId + notificationIndex,
              medicineName: reminder.medicineName,
              dosage: reminder.dosage,
              scheduledTime: scheduledDate,
              instructions: reminder.instructions,
            );
            
            notificationIndex++;
            print('   ✅ Scheduled for ${_getDayName(weekday)} at $timeStr');
          }
        }
        
      } else {
        for (int i = 0; i < reminder.reminderTimes.length; i++) {
          final timeParts = reminder.reminderTimes[i].split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          
          final now = DateTime.now();
          var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
          
          if (scheduledDate.isBefore(now)) {
            scheduledDate = scheduledDate.add(const Duration(days: 1));
          }
          
          await _notificationService.scheduleReminder(
            id: baseId + i,
            medicineName: reminder.medicineName,
            dosage: reminder.dosage,
            scheduledTime: scheduledDate,
            instructions: reminder.instructions,
          );
        }
      }

      print('✅ All notifications scheduled');
      
    } catch (e) {
      print('❌ Error scheduling notifications: $e');
      rethrow;
    }
  }

  /// Cancel ALL notifications for a reminder
  Future<void> _cancelAllNotificationsForReminder(Reminder reminder) async {
    try {
      final baseId = _generateStableBaseId(reminder.id);
      print('🗑️ Canceling notifications for ${reminder.medicineName} (Base ID: $baseId)');
      
      final List<int> idsToCancel = [];
      for (int i = 0; i < 100; i++) {
        idsToCancel.add(baseId + i);
      }
      
      await Future.wait(idsToCancel.map((id) => _notificationService.cancelReminder(id)));
      print('✅ Canceled ${idsToCancel.length} potential notification IDs');
      
    } catch (e) {
      print('❌ Error canceling notifications: $e');
    }
  }

  /// Generate stable base ID from reminder UUID
  int _generateStableBaseId(String reminderId) {
    final shortId = reminderId.substring(0, 8);
    return shortId.hashCode.abs() % 100000;
  }

  /// Get next occurrence of a weekday at specific time
  DateTime _getNextWeekday(int weekday, int hour, int minute) {
    final now = DateTime.now();
    final currentWeekday = now.weekday;
    
    int daysToAdd;
    if (weekday >= currentWeekday) {
      daysToAdd = weekday - currentWeekday;
    } else {
      daysToAdd = 7 - (currentWeekday - weekday);
    }
    
    final targetDate = now.add(Duration(days: daysToAdd));
    return DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
  }

  /// Get day name from weekday number
  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  /// Calculate next reminder time - FIXED: Handles multiple times correctly
  DateTime? _calculateNextReminderTime(
    List<String> times,
    ReminderFrequency frequency,
    List<int>? weekdays,
  ) {
    if (times.isEmpty) return null;
    
    final now = DateTime.now();
    print('🕐 Calculating next reminder time...');
    print('   Current time: $now');
    print('   Reminder times: $times');
    
    // ✅ FIX: Sort times chronologically
    final sortedTimes = List<String>.from(times)..sort();
    
    // ✅ FIX: Find the NEXT upcoming time (not just first time)
    for (final timeStr in sortedTimes) {
      try {
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        
        var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
        
        // If this time hasn't passed yet TODAY, return it
        if (scheduledTime.isAfter(now)) {
          print('   ✅ Next reminder: $scheduledTime (today)');
          return scheduledTime;
        }
      } catch (e) {
        print('   ⚠️ Error parsing time $timeStr: $e');
      }
    }
    
    // ✅ FIX: All times passed today, return FIRST time tomorrow
    try {
      final firstTime = sortedTimes.first.split(':');
      final hour = int.parse(firstTime[0]);
      final minute = int.parse(firstTime[1]);
      final tomorrow = DateTime(now.year, now.month, now.day + 1, hour, minute);
      
      print('   ✅ Next reminder: $tomorrow (tomorrow)');
      return tomorrow;
    } catch (e) {
      print('   ❌ Error calculating next time: $e');
      return null;
    }
  }

  void dispose() {
    // Cleanup if needed
  }

 
// Add this to lib/features/reminders/data/repositories/reminder_repository_impl.dart
// Replace the existing updateNextReminderTime method with this:

/// Update next reminder time after an alarm fires
/// ✅ NEW: Also records missed dose if user didn't take it
Future<void> updateNextReminderTime({
  required String userId,
  required String reminderId,
}) async {
  try {
    print('📅 Updating next reminder time for: $reminderId');
    
    final reminder = await getReminder(userId: userId, reminderId: reminderId);
    if (reminder == null) {
      print('⚠️ Reminder not found');
      return;
    }

    // ✅ FIX 1: Check if this dose was already recorded
  
    final scheduledTime = reminder.nextReminderAt;
    
    if (scheduledTime != null) {
      // Check if user marked this dose as taken
      final recentLogs = await _firestore
          .collection('doseLogs')
          .doc(userId)
          .collection('logs')
          .where('reminderId', isEqualTo: reminderId)
          .where('scheduledTime', isGreaterThanOrEqualTo: 
              Timestamp.fromDate(scheduledTime.subtract(const Duration(minutes: 30))))
          .where('scheduledTime', isLessThanOrEqualTo: 
              Timestamp.fromDate(scheduledTime.add(const Duration(minutes: 30))))
          .get();

      // ✅ FIX 2: If no log exists, mark as MISSED
      if (recentLogs.docs.isEmpty) {
        print('⚠️ Dose was MISSED - recording automatically');
        await recordDoseLog(
          userId: userId,
          reminderId: reminderId,
          medicineName: reminder.medicineName,
          scheduledTime: scheduledTime,
          status: DoseStatus.missed, // ← Automatically mark as missed
        );
      } else {
        print('✅ Dose already recorded by user');
      }
    }

    // Calculate next reminder time
    final nextTime = _calculateNextReminderTime(
      reminder.reminderTimes,
      reminder.frequency,
      reminder.weekdays,
    );

    if (nextTime == null) {
      print('⚠️ Could not calculate next reminder time');
      return;
    }

    print('   Old next time: ${reminder.nextReminderAt}');
    print('   New next time: $nextTime');
    
    await _firestore
        .collection('reminders')
        .doc(userId)
        .collection('userReminders')
        .doc(reminderId)
        .update({
          'nextReminderAt': Timestamp.fromDate(nextTime),
        });
    
    print('✅ Next reminder time updated to: $nextTime');
    
  } catch (e) {
    print('❌ Error updating next reminder time: $e');
  }
}

// ✅ FIX 3: Add method to check for overdue reminders on app start
Future<void> checkOverdueReminders(String userId) async {
  try {
    print('🔍 Checking for overdue reminders...');
    
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection('reminders')
        .doc(userId)
        .collection('userReminders')
        .where('isActive', isEqualTo: true)
        .get();

    int missedCount = 0;

    for (final doc in snapshot.docs) {
      try {
        final reminder = ReminderModel.fromFirestore(doc);
        
        // Check if next reminder time has passed
        if (reminder.nextReminderAt != null && 
            reminder.nextReminderAt!.isBefore(now.subtract(const Duration(minutes: 30)))) {
          
          // Check if this dose was logged
          final logs = await _firestore
              .collection('doseLogs')
              .doc(userId)
              .collection('logs')
              .where('reminderId', isEqualTo: reminder.id)
              .where('scheduledTime', isEqualTo: Timestamp.fromDate(reminder.nextReminderAt!))
              .get();

          // If not logged, mark as missed
          if (logs.docs.isEmpty) {
            await recordDoseLog(
              userId: userId,
              reminderId: reminder.id,
              medicineName: reminder.medicineName,
              scheduledTime: reminder.nextReminderAt!,
              status: DoseStatus.missed,
            );
            
            missedCount++;
            print('   📝 Marked ${reminder.medicineName} as missed (${reminder.nextReminderAt})');
          }
        }
      } catch (e) {
        print('   ⚠️ Error processing reminder: $e');
      }
    }

    print('✅ Checked overdue reminders: $missedCount missed doses recorded');
    
  } catch (e) {
    print('❌ Error checking overdue reminders: $e');
  }
}
  /// Recalculate and update next reminder times for all user reminders
  Future<void> refreshAllNextReminderTimes(String userId) async {
    try {
      print('🔄 Refreshing next reminder times for all reminders...');
      
      final snapshot = await _firestore
          .collection('reminders')
          .doc(userId)
          .collection('userReminders')
          .where('isActive', isEqualTo: true)
          .get();
      
      int updatedCount = 0;
      
      for (final doc in snapshot.docs) {
        try {
          final reminder = ReminderModel.fromFirestore(doc);
          
          final nextTime = _calculateNextReminderTime(
            reminder.reminderTimes,
            reminder.frequency,
            reminder.weekdays,
          );
          
          if (nextTime != null) {
            await _firestore
                .collection('reminders')
                .doc(userId)
                .collection('userReminders')
                .doc(reminder.id)
                .update({
                  'nextReminderAt': Timestamp.fromDate(nextTime),
                });
            
            updatedCount++;
            print('   ✅ Updated ${reminder.medicineName}: $nextTime');
          }
        } catch (e) {
          print('   ⚠️ Error processing reminder: $e');
        }
      }
      
      print('✅ Refreshed $updatedCount reminder(s)');
      
    } catch (e) {
      print('❌ Error refreshing next reminder times: $e');
    }
  }
}