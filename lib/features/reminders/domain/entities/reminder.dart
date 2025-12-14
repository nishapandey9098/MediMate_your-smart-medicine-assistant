// FILE 1: lib/features/reminders/domain/entities/reminder.dart
// ============================================
/// Represents a medicine reminder
class Reminder {
  final String id;                    // Unique reminder ID
  final String userId;                // Who this belongs to
  final String medicineName;          // Medicine name (from scan or manual)
  final String dosage;                // e.g., "500mg", "2 tablets"
  final String? instructions;         // e.g., "Take with food"
  final List<String> reminderTimes;   // e.g., ["08:00", "14:00", "20:00"]
  final ReminderFrequency frequency;  // daily, weekly, custom
  final List<int>? weekdays;          // For weekly: [1,3,5] = Mon, Wed, Fri
  final bool isActive;                // Is reminder enabled?
  final DateTime createdAt;
  final DateTime? nextReminderAt;     // Next time this fires
  final String? scanId;               // Link to scan (if created from scan)

  Reminder({
    required this.id,
    required this.userId,
    required this.medicineName,
    required this.dosage,
    this.instructions,
    required this.reminderTimes,
    required this.frequency,
    this.weekdays,
    this.isActive = true,
    required this.createdAt,
    this.nextReminderAt,
    this.scanId,
  });

  /// Create a copy with modifications
  Reminder copyWith({
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
    return Reminder(
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

/// How often the reminder repeats
enum ReminderFrequency {
  daily,      // Every day
  weekly,     // Specific days of week
  custom,     // Custom interval
}
