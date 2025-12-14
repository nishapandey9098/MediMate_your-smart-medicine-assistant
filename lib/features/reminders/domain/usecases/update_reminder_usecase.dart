// ============================================
// FILE: lib/features/reminders/domain/usecases/update_reminder_usecase.dart
// CREATE THIS FILE if you're using Clean Architecture with UseCases
// ============================================

import '../entities/reminder.dart';
import '../../data/repositories/reminder_repository_impl.dart';

class UpdateReminderUseCase {
  final ReminderRepository _repository;

  UpdateReminderUseCase(this._repository);

  /// Execute the update reminder use case
  /// 
  /// Takes a domain entity (Reminder) and passes it to repository
  /// Repository handles conversion to ReminderModel
  Future<void> execute({
    required String userId,
    required Reminder reminder,
  }) async {
    // Validate input
    if (reminder.id.isEmpty) {
      throw Exception('Reminder ID cannot be empty');
    }
    
    if (reminder.medicineName.isEmpty) {
      throw Exception('Medicine name cannot be empty');
    }
    
    if (reminder.dosage.isEmpty) {
      throw Exception('Dosage cannot be empty');
    }
    
    if (reminder.reminderTimes.isEmpty) {
      throw Exception('At least one reminder time is required');
    }

    // Call repository - it handles the type conversion
    await _repository.updateReminder(
      userId: userId,
      reminder: reminder, // Pass domain entity
    );
  }
}