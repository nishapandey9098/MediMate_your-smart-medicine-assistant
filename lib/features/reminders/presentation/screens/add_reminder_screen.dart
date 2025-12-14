// ============================================
// FILE: lib/features/reminders/presentation/screens/add_reminder_screen.dart
// FIXED: Update uses Reminder.copyWith() - proper type handling
// ============================================

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/reminder.dart';
import '../providers/reminder_provider.dart';

class AddReminderScreen extends ConsumerStatefulWidget {
  final String? medicineName;
  final String? dosage;
  final String? scanId;
  final Reminder? existingReminder; // Domain entity for edit mode

  const AddReminderScreen({
    super.key,
    this.medicineName,
    this.dosage,
    this.scanId,
    this.existingReminder,
  });

  @override
  ConsumerState<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends ConsumerState<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicineController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();
  
  ReminderFrequency _frequency = ReminderFrequency.daily;
  List<TimeOfDay> _selectedTimes = [];
  List<int> _selectedWeekdays = [];
  
  bool get _isEditMode => widget.existingReminder != null;

  @override
  void initState() {
    super.initState();
    
    // Load existing reminder data if editing
    if (_isEditMode) {
      final reminder = widget.existingReminder!;
      _medicineController.text = reminder.medicineName;
      _dosageController.text = reminder.dosage;
      _instructionsController.text = reminder.instructions ?? '';
      _frequency = reminder.frequency;
      _selectedWeekdays = reminder.weekdays ?? [];
      
      // Convert time strings to TimeOfDay
      _selectedTimes = reminder.reminderTimes.map((timeStr) {
        final parts = timeStr.split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }).toList();
      
      print('📝 Edit mode: Loaded reminder ${reminder.medicineName}');
    }
    // Pre-fill if coming from scan
    else if (widget.medicineName != null) {
      _medicineController.text = widget.medicineName!;
    }
    if (widget.dosage != null) {
      _dosageController.text = widget.dosage!;
    }
  }

  @override
  void dispose() {
    _medicineController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() {
        _selectedTimes.add(time);
      });
    }
  }

  void _removeTime(int index) {
    setState(() {
      _selectedTimes.removeAt(index);
    });
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one reminder time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Convert TimeOfDay to String format
    final timeStrings = _selectedTimes
        .map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
        .toList();

    bool success;
    
    if (_isEditMode) {
      // UPDATE existing reminder using copyWith()
      // This maintains the Reminder type (domain entity)
      print('📝 Updating reminder: ${widget.existingReminder!.id}');
      
      final updatedReminder = widget.existingReminder!.copyWith(
        medicineName: _medicineController.text.trim(),
        dosage: _dosageController.text.trim(),
        instructions: _instructionsController.text.trim().isEmpty 
            ? null 
            : _instructionsController.text.trim(),
        reminderTimes: timeStrings,
        frequency: _frequency,
        weekdays: _frequency == ReminderFrequency.weekly ? _selectedWeekdays : null,
      );
      
      // Pass Reminder entity - provider/repository handles conversion
      success = await ref.read(reminderControllerProvider.notifier)
          .updateReminder(updatedReminder);
      
      if (success && mounted) {
        // Invalidate providers to refresh UI
        ref.invalidate(userRemindersProvider);
        ref.invalidate(reminderDoseLogsProvider(widget.existingReminder!.id));
        ref.invalidate(adherenceRateProvider);
        
        print('✅ Providers invalidated after update');
      }
      
    } else {
      // CREATE new reminder
      print('📝 Creating new reminder');
      
      success = await ref.read(reminderControllerProvider.notifier)
          .createReminder(
            medicineName: _medicineController.text.trim(),
            dosage: _dosageController.text.trim(),
            instructions: _instructionsController.text.trim().isEmpty 
                ? null 
                : _instructionsController.text.trim(),
            reminderTimes: timeStrings,
            frequency: _frequency,
            weekdays: _frequency == ReminderFrequency.weekly ? _selectedWeekdays : null,
            scanId: widget.scanId,
          );
      
      if (success && mounted) {
        ref.invalidate(userRemindersProvider);
        print('✅ Providers invalidated after create');
      }
    }

    if (success && mounted) {
      Navigator.pop(context, true); // Return true to indicate success
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminderState = ref.watch(reminderControllerProvider);
    
    // Listen for messages
    ref.listen(reminderControllerProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(reminderControllerProvider.notifier).clearMessages();
      }
      
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Reminder' : 'Add Reminder'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Medicine Name
              TextFormField(
                controller: _medicineController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name',
                  hintText: 'e.g., Paracetamol',
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter medicine name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Dosage
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  hintText: 'e.g., 500mg, 2 tablets',
                  prefixIcon: Icon(Icons.science),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter dosage';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Instructions (Optional)
              TextFormField(
                controller: _instructionsController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Instructions (Optional)',
                  hintText: 'e.g., Take with food',
                  prefixIcon: Icon(Icons.info_outline),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Frequency Selector
              Text(
                'Reminder Frequency',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              
              SegmentedButton<ReminderFrequency>(
                segments: const [
                  ButtonSegment(
                    value: ReminderFrequency.daily,
                    label: Text('Daily'),
                    icon: Icon(Icons.today, size: 18),
                  ),
                  ButtonSegment(
                    value: ReminderFrequency.weekly,
                    label: Text('Weekly'),
                    icon: Icon(Icons.calendar_month, size: 18),
                  ),
                ],
                selected: {_frequency},
                onSelectionChanged: (Set<ReminderFrequency> newSelection) {
                  setState(() {
                    _frequency = newSelection.first;
                  });
                },
              ),
              
              // Weekly Days Selector
              if (_frequency == ReminderFrequency.weekly) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    for (int i = 1; i <= 7; i++)
                      FilterChip(
                        label: Text(_getDayName(i)),
                        selected: _selectedWeekdays.contains(i),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedWeekdays.add(i);
                            } else {
                              _selectedWeekdays.remove(i);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Reminder Times Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reminder Times',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: _selectTime,
                    icon: const Icon(Icons.add_alarm, size: 18),
                    label: const Text('Add Time'),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Times List
              if (_selectedTimes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.alarm_add, size: 40, color: Colors.orange),
                      SizedBox(height: 8),
                      Text(
                        'No reminder times added',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tap "Add Time" to set when you want to be reminded',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: _selectedTimes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final time = entry.value;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Icon(
                            Icons.alarm,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        title: Text(
                          time.format(context),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _getTimeLabel(time),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _removeTime(index),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              
              const SizedBox(height: 32),
              
              // Save Button
              ElevatedButton.icon(
                onPressed: reminderState.isSaving ? null : _saveReminder,
                icon: reminderState.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(_isEditMode ? Icons.check : Icons.add),
                label: Text(
                  reminderState.isSaving 
                      ? 'Saving...' 
                      : _isEditMode ? 'Update Reminder' : 'Save Reminder'
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDayName(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }

  String _getTimeLabel(TimeOfDay time) {
    if (time.hour < 12) {
      return 'Morning';
    } else if (time.hour < 17) {
      return 'Afternoon';
    } else {
      return 'Evening';
    }
  }
}