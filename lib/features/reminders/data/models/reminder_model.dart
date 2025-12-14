// ============================================
// FILE: lib/features/reminders/data/models/reminder_model.dart
// FIXED: Complete conversion functions
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/reminder.dart';

/// Firebase model for Reminder
/// Handles conversion between Firestore and domain entities
class ReminderModel extends Reminder {
  ReminderModel({
    required super.id,
    required super.userId,
    required super.medicineName,
    required super.dosage,
    super.instructions,
    required super.reminderTimes,
    required super.frequency,
    super.weekdays,
    super.isActive,
    required super.createdAt,
    super.nextReminderAt,
    super.scanId,
  });

  /// Convert from Firestore document to ReminderModel
  factory ReminderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ReminderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      medicineName: data['medicineName'] ?? '',
      dosage: data['dosage'] ?? '',
      instructions: data['instructions'],
      reminderTimes: List<String>.from(data['reminderTimes'] ?? []),
      frequency: ReminderFrequency.values.firstWhere(
        (e) => e.toString() == 'ReminderFrequency.${data['frequency']}',
        orElse: () => ReminderFrequency.daily,
      ),
      weekdays: data['weekdays'] != null 
          ? List<int>.from(data['weekdays']) 
          : null,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nextReminderAt: (data['nextReminderAt'] as Timestamp?)?.toDate(),
      scanId: data['scanId'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'medicineName': medicineName,
      'dosage': dosage,
      'instructions': instructions,
      'reminderTimes': reminderTimes,
      'frequency': frequency.toString().split('.').last,
      'weekdays': weekdays,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'nextReminderAt': nextReminderAt != null 
          ? Timestamp.fromDate(nextReminderAt!) 
          : null,
      'scanId': scanId,
    };
  }

  /// Create ReminderModel from domain entity (Reminder)
  /// CRITICAL: This is what fixes the type casting error
  factory ReminderModel.fromEntity(Reminder reminder) {
    return ReminderModel(
      id: reminder.id,
      userId: reminder.userId,
      medicineName: reminder.medicineName,
      dosage: reminder.dosage,
      instructions: reminder.instructions,
      reminderTimes: reminder.reminderTimes,
      frequency: reminder.frequency,
      weekdays: reminder.weekdays,
      isActive: reminder.isActive,
      createdAt: reminder.createdAt,
      nextReminderAt: reminder.nextReminderAt,
      scanId: reminder.scanId,
    );
  }

  /// Convert ReminderModel to domain entity (Reminder)
  Reminder toEntity() {
    return Reminder(
      id: id,
      userId: userId,
      medicineName: medicineName,
      dosage: dosage,
      instructions: instructions,
      reminderTimes: reminderTimes,
      frequency: frequency,
      weekdays: weekdays,
      isActive: isActive,
      createdAt: createdAt,
      nextReminderAt: nextReminderAt,
      scanId: scanId,
    );
  }

  /// Create a copy with modified fields
  @override
  ReminderModel copyWith({
    String? id,
    String? userId,
    String? medicineName,
    String? dosage,
    String? instructions,
    List<String>? reminderTimes,
    ReminderFrequency? frequency,
    List<int>? weekdays,
    bool? isActive,
    DateTime? createdAt,
    DateTime? nextReminderAt,
    String? scanId,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      instructions: instructions ?? this.instructions,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      frequency: frequency ?? this.frequency,
      weekdays: weekdays ?? this.weekdays,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      nextReminderAt: nextReminderAt ?? this.nextReminderAt,
      scanId: scanId ?? this.scanId,
    );
  }
}