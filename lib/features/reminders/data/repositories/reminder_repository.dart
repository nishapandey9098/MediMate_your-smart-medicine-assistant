// ============================================
// FILE: lib/features/reminders/data/repositories/reminder_repository.dart
// ============================================
/// Repository for managing reminders in Firestore and local notifications

// ignore_for_file: avoid_print, dangling_library_doc_comments

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
  /// 
  /// This function:
  /// 1. Saves reminder to Firestore
  /// 2. Schedules local notifications for each reminder time
  /// 3. Returns the created reminder
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
      // Generate unique ID
      final reminderId = const Uuid().v4();
      
      // Calculate next reminder time
      final nextReminder = _calculateNextReminderTime(
        reminderTimes,
        frequency,
        weekdays,
      );

      // Create reminder object
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

      // Save to Firestore
      await _firestore
          .collection('reminders')
          .doc(userId)
          .collection('userReminders')
          .doc(reminderId)
          .set(reminder.toFirestore());

      print('✅ Reminder saved to Firestore');

      // Schedule local notifications
      await _scheduleNotificationsForReminder(reminder);

      return reminder;
    } catch (e) {
      print('❌ Error creating reminder: $e');
      rethrow;
    }
  }

  /// Get all reminders for a user (real-time stream)
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

// ✅ FIXED: Update a reminder
Future<void> updateReminder({
  required String userId,
  required Reminder reminder,
}) async {
  try {
    print('📝 Updating reminder: ${reminder.medicineName}');
    
    // Step 1: Cancel old notifications
    final baseId = reminder.id.hashCode.abs() % 100000;
    print('🗑️ Cancelling old notifications with baseId: $baseId');
    await _notificationService.cancelRemindersByBaseId(baseId);
    
    // Step 2: Update in Firestore
    print('☁️ Updating Firestore document...');
    await _firestore
        .collection('reminders')
        .doc(userId)
        .collection('userReminders')
        .doc(reminder.id)
        .update((reminder as ReminderModel).toFirestore());
    print('✅ Firestore updated');
    
    // Step 3: Reschedule notifications if active
    if (reminder.isActive) {
      print('🔔 Rescheduling notifications...');
      await _scheduleNotificationsForReminder(reminder);
      print('✅ Notifications rescheduled');
    }
    
    print('✅ Reminder updated successfully');
  } catch (e) {
    print('❌ Error updating reminder: $e');
    rethrow;
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

      if (!isActive) {
        // Cancel notifications if deactivated
        final reminder = await getReminder(userId: userId, reminderId: reminderId);
        if (reminder != null) {
          await _cancelNotificationsForReminder(reminder);
        }
      } else {
        // Reschedule if reactivated
        final reminder = await getReminder(userId: userId, reminderId: reminderId);
        if (reminder != null) {
          await _scheduleNotificationsForReminder(reminder);
        }
      }

      print('✅ Reminder status toggled: $isActive');
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

      // Get reminder first to cancel notifications
      final reminder = await getReminder(userId: userId, reminderId: reminderId);
      if (reminder != null) {
        await _cancelNotificationsForReminder(reminder);
      }

      // Delete from Firestore
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

  /// Record a dose log (when user takes medicine)
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

  /// Get dose logs for a reminder
  Stream<List<DoseLog>> getDoseLogsForReminder({
    required String userId,
    required String reminderId,
  }) {
    return _firestore
        .collection('doseLogs')
        .doc(userId)
        .collection('logs')
        .where('reminderId', isEqualTo: reminderId)
        .orderBy('scheduledTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return DoseLogModel.fromFirestore(doc);
          }).toList();
        });
  }

  /// Get recent dose logs (last 7 days)
  Stream<List<DoseLog>> getRecentDoseLogs(String userId) {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    return _firestore
        .collection('doseLogs')
        .doc(userId)
        .collection('logs')
        .where('scheduledTime', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
        .orderBy('scheduledTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return DoseLogModel.fromFirestore(doc);
          }).toList();
        });
  }

  /// Calculate adherence rate (percentage of doses taken)
  Future<double> calculateAdherenceRate(String userId) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final logs = await _firestore
          .collection('doseLogs')
          .doc(userId)
          .collection('logs')
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


// ✅ FIXED: Schedule local notifications for a reminder
Future<void> _scheduleNotificationsForReminder(Reminder reminder) async {
  print('🔔 Scheduling notifications for ${reminder.medicineName}');
  try {
    // Generate base ID from reminder ID
    final baseId = reminder.id.hashCode.abs() % 100000;
    print('📍 Base ID: $baseId');
    
    if (reminder.frequency == ReminderFrequency.daily) {
      // Schedule daily notifications
      print('📅 Frequency: Daily');
      await _notificationService.scheduleDailyReminders(
        baseId: baseId,
        medicineName: reminder.medicineName,
        dosage: reminder.dosage,
        times: reminder.reminderTimes,
        instructions: reminder.instructions,
      );
    } else if (reminder.frequency == ReminderFrequency.weekly) {
      // For weekly: schedule for each day, but only if that day is selected
      print('📅 Frequency: Weekly - Days: ${reminder.weekdays}');
      
      final now = DateTime.now();
      
      for (int i = 0; i < reminder.reminderTimes.length; i++) {
        try {
          final timeParts = reminder.reminderTimes[i].split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          
          // Find next occurrence on a selected weekday
          DateTime scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
          
          // If time already passed today, start from tomorrow
          if (scheduledDate.isBefore(now)) {
            scheduledDate = scheduledDate.add(const Duration(days: 1));
          }
          
          // Find next occurrence on a selected weekday
          while (!reminder.weekdays!.contains(scheduledDate.weekday)) {
            scheduledDate = scheduledDate.add(const Duration(days: 1));
          }
          
          await _notificationService.scheduleReminder(
            id: baseId + i,
            medicineName: reminder.medicineName,
            dosage: reminder.dosage,
            scheduledTime: scheduledDate,
            instructions: reminder.instructions,
          );
          
          print(' ✅ Scheduled for ${scheduledDate.toString().split(' ')[0]} at ${reminder.reminderTimes[i]}');
        } catch (e) {
          print(' ❌ Failed to schedule time ${reminder.reminderTimes[i]}: $e');
        }
      }
    }
    
    print('✅ All notifications scheduled successfully');
  } catch (e) {
    print('❌ Error scheduling notifications: $e');
  }
}
// ✅ FIXED: Cancel notifications for a reminder
Future<void> _cancelNotificationsForReminder(Reminder reminder) async {
  try {
    final baseId = reminder.id.hashCode.abs() % 100000;
    print('🗑️ Cancelling notifications for ${reminder.medicineName}');
    
    // Use the new method from NotificationService
    await _notificationService.cancelRemindersByBaseId(baseId);
    
    print('✅ Notifications cancelled');
  } catch (e) {
    print('❌ Error cancelling notifications: $e');
  }
}

  /// Calculate next reminder time
  DateTime? _calculateNextReminderTime(
    List<String> times,
    ReminderFrequency frequency,
    List<int>? weekdays,
  ) {
    final now = DateTime.now();

    // Find the next upcoming time today
    for (final timeStr in times) {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

      // If this time hasn't passed yet today, return it
      if (scheduledTime.isAfter(now)) {
        return scheduledTime;
      }
    }

    // All times passed today, return first time tomorrow
    final firstTime = times.first.split(':');
    final hour = int.parse(firstTime[0]);
    final minute = int.parse(firstTime[1]);

    return DateTime(now.year, now.month, now.day + 1, hour, minute);
  }
}