// ============================================
// FILE: lib/features/reminders/presentation/providers/reminder_provider.dart
// FIXED: updateReminder method passes Reminder (not ReminderModel)
// ============================================

// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/reminder_repository_impl.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/dose_log.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:flutter/services.dart';   // <-- REQUIRED for EventChannel

// Repository provider
final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository();
});

// Stream of user's reminders
final userRemindersProvider = StreamProvider<List<Reminder>>((ref) {
  final userId = ref.watch(authRepositoryProvider).currentUserId;
  
  if (userId == null) {
    return Stream.value([]);
  }
  
  return ref.watch(reminderRepositoryProvider).getUserReminders(userId);
});

// Recent dose logs
final recentDoseLogsProvider = StreamProvider<List<DoseLog>>((ref) {
  final userId = ref.watch(authRepositoryProvider).currentUserId;
  
  if (userId == null) {
    return Stream.value([]);
  }
  
  return ref.watch(reminderRepositoryProvider).getRecentDoseLogs(userId);
});

// Adherence rate
final adherenceRateProvider = FutureProvider<double>((ref) async {
  final userId = ref.watch(authRepositoryProvider).currentUserId;
  
  if (userId == null) {
    return 0.0;
  }
  
  return ref.watch(reminderRepositoryProvider).calculateAdherenceRate(userId);
});

// Dose logs for specific reminder
final reminderDoseLogsProvider = StreamProvider.family<List<DoseLog>, String>((ref, reminderId) {
  final userId = ref.watch(authRepositoryProvider).currentUserId;
  
  if (userId == null) {
    return Stream.value([]);
  }
  
  return ref.watch(reminderRepositoryProvider).getDoseLogsForReminder(
    userId: userId,
    reminderId: reminderId,
  );
});

// Reminder state
class ReminderState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;
  final Reminder? selectedReminder;

  ReminderState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
    this.selectedReminder,
  });

  ReminderState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    Reminder? selectedReminder,
  }) {
    return ReminderState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      successMessage: successMessage,
      selectedReminder: selectedReminder ?? this.selectedReminder,
    );
  }
}

// Reminder controller
class ReminderController extends StateNotifier<ReminderState> {
  final ReminderRepository _repository;
  final String _userId;

  ReminderController(this._repository, this._userId) : super(ReminderState());

  /// Create a new reminder
  Future<bool> createReminder({
    required String medicineName,
    required String dosage,
    String? instructions,
    required List<String> reminderTimes,
    required ReminderFrequency frequency,
    List<int>? weekdays,
    String? scanId,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    
    try {
      print('📝 Creating reminder...');
      
      await _repository.createReminder(
        userId: _userId,
        medicineName: medicineName,
        dosage: dosage,
        instructions: instructions,
        reminderTimes: reminderTimes,
        frequency: frequency,
        weekdays: weekdays,
        scanId: scanId,
      );
      
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Reminder created successfully!',
      );
      
      print('✅ Reminder created');
      return true;
      
    } catch (e) {
      print('❌ Error creating reminder: $e');
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to create reminder: $e',
      );
      return false;
    }
  }

  /// Update existing reminder - FIXED
  /// Receives domain entity (Reminder) and passes to repository
  Future<bool> updateReminder(Reminder reminder) async {
    state = state.copyWith(isSaving: true, error: null);
    
    try {
      print('📝 Updating reminder in provider...');
      
      // Pass domain entity directly - repository handles conversion
      await _repository.updateReminder(
        userId: _userId,
        reminder: reminder, // Domain entity - repository converts to ReminderModel
      );
      
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Reminder updated successfully!',
      );
      
      print('✅ Reminder updated in provider');
      return true;
      
    } catch (e) {
      print('❌ Error updating reminder in provider: $e');
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to update reminder: $e',
      );
      return false;
    }
  }

  /// Toggle reminder on/off
  Future<void> toggleReminder({
    required String reminderId,
    required bool isActive,
  }) async {
    try {
      await _repository.toggleReminderStatus(
        userId: _userId,
        reminderId: reminderId,
        isActive: isActive,
      );
      
      state = state.copyWith(
        successMessage: isActive ? 'Reminder enabled' : 'Reminder disabled',
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to toggle reminder: $e',
      );
    }
  }

  /// Delete a reminder
  Future<bool> deleteReminder(String reminderId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _repository.deleteReminder(
        userId: _userId,
        reminderId: reminderId,
      );
      
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Reminder deleted',
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete reminder: $e',
      );
      return false;
    }
  }

  /// Mark dose as taken
  Future<void> markDoseAsTaken({
    required String reminderId,
    required String medicineName,
    required DateTime scheduledTime,
    String? notes,
  }) async {
    try {
      await _repository.recordDoseLog(
        userId: _userId,
        reminderId: reminderId,
        medicineName: medicineName,
        scheduledTime: scheduledTime,
        status: DoseStatus.taken,
        notes: notes,
      );
      
      state = state.copyWith(
        successMessage: 'Dose marked as taken ✓',
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to record dose: $e',
      );
    }
  }

  /// Mark dose as missed
  Future<void> markDoseAsMissed({
    required String reminderId,
    required String medicineName,
    required DateTime scheduledTime,
  }) async {
    try {
      await _repository.recordDoseLog(
        userId: _userId,
        reminderId: reminderId,
        medicineName: medicineName,
        scheduledTime: scheduledTime,
        status: DoseStatus.missed,
      );
      
      state = state.copyWith(
        successMessage: 'Dose marked as missed',
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to record dose: $e',
      );
    }
  }

  /// Clear messages
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}


// Reminder controller provider
final reminderControllerProvider = StateNotifierProvider<ReminderController, ReminderState>((ref) {
  final repository = ref.watch(reminderRepositoryProvider);
  final userId = ref.watch(authRepositoryProvider).currentUserId ?? '';
  
  return ReminderController(repository, userId);
});

// ✅ NEW: Provider to handle alarm fired events
final alarmFiredProvider = StreamProvider<int>((ref) {
  const eventChannel = EventChannel('com.medimate.app/alarm_events');
  
  return eventChannel.receiveBroadcastStream().asyncMap((event) async {
    if (event is Map) {
      final eventType = event['event'] as String?;
      final id = event['id'] as int?;
      
      if (eventType == 'alarm_fired' && id != null) {
        print('🔔 Provider received alarm fired: $id');
        
        // Refresh the reminders list
        ref.invalidate(userRemindersProvider);
        
        return id;
      }
    }
    return -1;
  }).where((id) => id != -1);
});


