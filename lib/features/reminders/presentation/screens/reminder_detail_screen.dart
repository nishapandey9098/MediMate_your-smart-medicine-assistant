// ============================================
// FILE: lib/features/reminders/presentation/screens/reminder_detail_screen.dart
// FIXED: Edit button passes Reminder entity (not ReminderModel)
// ============================================

// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/dose_log.dart';
import '../providers/reminder_provider.dart';
import 'add_reminder_screen.dart';
import '../../../../core/utils/notification_debug_helper.dart';

class ReminderDetailScreen extends ConsumerWidget {
  final Reminder reminder; // Domain entity

  const ReminderDetailScreen({
    super.key,
    required this.reminder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doseLogsAsync = ref.watch(
      reminderDoseLogsProvider(reminder.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder Details'),
        actions: [
          // Edit Button - Passes domain entity
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => AddReminderScreen(
                    existingReminder: reminder, // Pass domain entity (Reminder)
                  ),
                ),
              );
              
              // Invalidate providers after edit
              if (result == true && context.mounted) {
                ref.invalidate(userRemindersProvider);
                ref.invalidate(reminderDoseLogsProvider(reminder.id));
                ref.invalidate(adherenceRateProvider);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Reminder updated'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            tooltip: 'Edit',
          ),
          
          // Delete Button
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(context, ref),
            tooltip: 'Delete',
          ),
          
          // Debug Button
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              await NotificationDebugHelper.printDebugInfo();
              
              final status = await NotificationDebugHelper.checkNotificationStatus();
              
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('🔍 Notification Debug'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _debugRow('Notification Permission', status['notificationPermission'].toString()),
                          _debugRow('Exact Alarm Permission', status['exactAlarmPermission'].toString()),
                          _debugRow('Pending Count', status['pendingCount'].toString()),
                          const SizedBox(height: 16),
                          
                          if (status['pendingCount'] == 0)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange[700]),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'No notifications scheduled! Try toggling the reminder off and on again.',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                      if (status['notificationPermission'] != true)
                        FilledButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await NotificationDebugHelper.requestAllPermissions();
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Permissions requested. Check settings if needed.'),
                                ),
                              );
                            }
                          },
                          child: const Text('Request Permissions'),
                        ),
                    ],
                  ),
                );
              }
            },
            tooltip: 'Debug Notifications',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(context),
            const SizedBox(height: 16),
            _buildScheduleSection(context),
            const SizedBox(height: 16),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Dose History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            doseLogsAsync.when(
  data: (logs) {
    if (logs.isEmpty) {
      return _buildEmptyDoseHistory(context);
    }
    
    final sortedLogs = List<DoseLog>.from(logs)
      ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
    
    return _buildDoseLogsList(context, sortedLogs);
  },
  loading: () => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: CircularProgressIndicator(),
    ),
  ),
  error: (error, stack) {
    print('❌ Dose logs error: $error');
    
    // Check if it's the index error
    if (error.toString().contains('failed-precondition') || 
        error.toString().contains('index')) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.warning_amber, size: 48, color: Colors.orange[300]),
            const SizedBox(height: 12),
            Text(
              'Dose History Setup Required',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'A database index needs to be created.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Show instructions
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Create Database Index'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'To view dose history, create a Firestore index:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          const Text('1. Go to Firebase Console'),
                          const Text('2. Select Firestore → Indexes'),
                          const Text('3. Click "Create Index"'),
                          const SizedBox(height: 12),
                          const Text('Add these fields:'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.grey[200],
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• Collection: logs'),
                                Text('• Field 1: reminderId (Ascending)'),
                                Text('• Field 2: scheduledTime (Descending)'),
                                Text('• Query scope: Collection'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Got it'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.help_outline),
              label: const Text('Show Instructions'),
            ),
          ],
        ),
      );
    }
    
    // Other errors
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 12),
          Text(
            'Error loading dose history',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  },
),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _markDoseAsTaken(context, ref),
        icon: const Icon(Icons.check_circle),
        label: const Text('Mark as Taken'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: reminder.isActive ? Colors.white : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  reminder.isActive ? Icons.check_circle : Icons.pause_circle,
                  size: 16,
                  color: reminder.isActive ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  reminder.isActive ? 'Active' : 'Paused',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: reminder.isActive ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              const Icon(Icons.medication, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.medicineName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reminder.dosage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (reminder.instructions != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      reminder.instructions!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    reminder.frequency == ReminderFrequency.daily
                        ? Icons.today
                        : Icons.calendar_month,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Frequency',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        reminder.frequency == ReminderFrequency.daily
                            ? 'Every Day'
                            : 'Weekly',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.alarm,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Reminder Times',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: reminder.reminderTimes.map((time) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Text(
                          time,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          
          if (reminder.nextReminderAt != null) ...[
            const SizedBox(height: 12),
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Reminder',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                          ),
                        ),
                        Text(
                          DateFormat('EEE, MMM dd • hh:mm a')
                              .format(reminder.nextReminderAt!),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyDoseHistory(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No dose history yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Mark your first dose to start tracking',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoseLogsList(BuildContext context, List<DoseLog> logs) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _DoseLogCard(log: log);
      },
    );
  }

  Future<void> _markDoseAsTaken(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Recording dose...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );
    
    await ref.read(reminderControllerProvider.notifier).markDoseAsTaken(
      reminderId: reminder.id,
      medicineName: reminder.medicineName,
      scheduledTime: DateTime.now(),
    );
    
    if (context.mounted) {
      ref.invalidate(reminderDoseLogsProvider(reminder.id));
      ref.invalidate(recentDoseLogsProvider);
      ref.invalidate(adherenceRateProvider);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Dose marked as taken'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder?'),
        content: Text(
          'Are you sure you want to delete the reminder for ${reminder.medicineName}?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(reminderControllerProvider.notifier)
          .deleteReminder(reminder.id);

      if (success && context.mounted) {
        ref.invalidate(userRemindersProvider);
        ref.invalidate(adherenceRateProvider);
        
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  static Widget _debugRow(String label, String value) {
    final isGood = value.toLowerCase() == 'true' || value.contains('true');
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.check_circle : Icons.warning,
            size: 16,
            color: isGood ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}

class _DoseLogCard extends StatelessWidget {
  final DoseLog log;

  const _DoseLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final isTaken = log.status == DoseStatus.taken;
    final color = isTaken ? Colors.green : Colors.orange;
    final icon = isTaken ? Icons.check_circle : Icons.cancel;
    final statusText = isTaken ? 'Taken' : 'Missed';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEE, MMM dd, yyyy').format(log.scheduledTime),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('hh:mm a').format(log.scheduledTime),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      if (log.takenAt != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.check, size: 14, color: Colors.green[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Taken at ${DateFormat('hh:mm a').format(log.takenAt!)}',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (log.notes != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        log.notes!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}