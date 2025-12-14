// ============================================
// FILE 4: lib/features/reminders/data/models/dose_log_model.dart
// ============================================
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/dose_log.dart';

/// Firebase model for DoseLog
class DoseLogModel extends DoseLog {
  DoseLogModel({
    required super.id,
    required super.userId,
    required super.reminderId,
    required super.medicineName,
    required super.scheduledTime,
    super.takenAt,
    required super.status,
    super.notes,
  });

  /// Convert from Firestore
  factory DoseLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return DoseLogModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      reminderId: data['reminderId'] ?? '',
      medicineName: data['medicineName'] ?? '',
      scheduledTime: (data['scheduledTime'] as Timestamp).toDate(),
      takenAt: (data['takenAt'] as Timestamp?)?.toDate(),
      status: DoseStatus.values.firstWhere(
        (e) => e.toString() == 'DoseStatus.${data['status']}',
        orElse: () => DoseStatus.pending,
      ),
      notes: data['notes'],
    );
  }

  /// Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'reminderId': reminderId,
      'medicineName': medicineName,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'takenAt': takenAt != null ? Timestamp.fromDate(takenAt!) : null,
      'status': status.toString().split('.').last,
      'notes': notes,
    };
  }
}