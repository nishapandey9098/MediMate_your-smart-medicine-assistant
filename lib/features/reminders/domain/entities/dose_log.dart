// ============================================
// FILE 2: lib/features/reminders/domain/entities/dose_log.dart
// ============================================
/// Records when user takes medicine
class DoseLog {
  final String id;
  final String userId;
  final String reminderId;
  final String medicineName;
  final DateTime scheduledTime;      // When they should have taken it
  final DateTime? takenAt;           // When they actually took it
  final DoseStatus status;           // taken, missed, skipped
  final String? notes;               // Optional user notes

  DoseLog({
    required this.id,
    required this.userId,
    required this.reminderId,
    required this.medicineName,
    required this.scheduledTime,
    this.takenAt,
    required this.status,
    this.notes,
  });

  /// Check if dose was taken on time (within 30 min)
  bool get isTakenOnTime {
    if (takenAt == null) return false;
    final diff = takenAt!.difference(scheduledTime).abs();
    return diff.inMinutes <= 30;
  }

  /// Check if dose is overdue
  bool get isOverdue {
    if (status != DoseStatus.pending) return false;
    return DateTime.now().isAfter(scheduledTime.add(const Duration(hours: 1)));
  }
}

enum DoseStatus {
  pending,    // Not taken yet
  taken,      // User confirmed they took it
  missed,     // User missed it
  skipped,    // User intentionally skipped
}