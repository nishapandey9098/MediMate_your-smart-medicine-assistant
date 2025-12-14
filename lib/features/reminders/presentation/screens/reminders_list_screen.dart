// ============================================
// FILE: lib/features/reminders/presentation/screens/reminders_list_screen.dart
// ============================================
// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/reminder.dart';
import '../providers/reminder_provider.dart';
import 'add_reminder_screen.dart';
import 'reminder_detail_screen.dart';
import 'dose_tracking_dashboard.dart';
import '../../../../core/utils/oppo_settings_guide.dart';
import '../../../auth/presentation/providers/auth_provider.dart';


class RemindersListScreen extends ConsumerWidget {
  const RemindersListScreen({super.key});

@override
Widget build(BuildContext context, WidgetRef ref) {
  final remindersAsync = ref.watch(userRemindersProvider);
  
  // ✅ NEW: Check for overdue/missed reminders on app start
  ref.listen<AsyncValue<int>>(alarmFiredProvider, (previous, next) {
    next.whenData((alarmId) async {
      if (alarmId > 0) {
        print('🔔 Alarm fired (ID: $alarmId), refreshing UI');
        
        if (context.mounted) {
          final userId = ref.read(authRepositoryProvider).currentUserId;
          if (userId != null) {
            // ✅ STEP 1: Update next reminder times (auto-records missed doses)
            await ref.read(reminderRepositoryProvider)
                .refreshAllNextReminderTimes(userId);
            
            // ✅ STEP 2: Check for any other overdue reminders
            await ref.read(reminderRepositoryProvider)
                .checkOverdueReminders(userId);
            
            // ✅ STEP 3: Refresh UI
            ref.invalidate(userRemindersProvider);
            ref.invalidate(recentDoseLogsProvider);
            ref.invalidate(adherenceRateProvider);
          }
          
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Reminder taken!'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  });

  // ✅ NEW: Also check on screen load
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (userId != null) {
      await ref.read(reminderRepositoryProvider)
          .checkOverdueReminders(userId);
      ref.invalidate(recentDoseLogsProvider);
    }
  });
  // ... rest of build method stays the same
  
  // ... rest of the build method
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reminders'),
        actions: [
           IconButton(
      icon: const Icon(Icons.settings_applications),
      onPressed: () async {
        await OppoSettingsGuide.showSettingsGuide(context);
      },
      tooltip: 'Setup Guide',
    ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DoseTrackingDashboard(),
            ),
          );
        },
        tooltip: 'Dose Tracking',
      ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddReminderScreen(),
                ),
              );
            },
            tooltip: 'Add Reminder',
          ),
        ],
      ),
      body: remindersAsync.when(
        data: (reminders) {
          if (reminders.isEmpty) {
            return _buildEmptyState(context);
          }

          // Separate active and inactive reminders
          final activeReminders = reminders.where((r) => r.isActive).toList();
          final inactiveReminders = reminders.where((r) => !r.isActive).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userRemindersProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Active Reminders Section
                if (activeReminders.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Active Reminders',
                    count: activeReminders.length,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  ...activeReminders.map((reminder) => _ReminderCard(
                        reminder: reminder,
                        onTap: () => _openReminderDetail(context, reminder),
                      )),
                  const SizedBox(height: 24),
                ],

                // Inactive Reminders Section
                if (inactiveReminders.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Paused Reminders',
                    count: inactiveReminders.length,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  ...inactiveReminders.map((reminder) => _ReminderCard(
                        reminder: reminder,
                        onTap: () => _openReminderDetail(context, reminder),
                      )),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(userRemindersProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddReminderScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Reminder'),
      ),
    );
  }

  void _openReminderDetail(BuildContext context, Reminder reminder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderDetailScreen(reminder: reminder),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.alarm_off,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'No Reminders Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first reminder to never miss a dose',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddReminderScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Reminder'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Section Header Widget
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// Reminder Card Widget
class _ReminderCard extends ConsumerWidget {
  final Reminder reminder;
  final VoidCallback onTap;

  const _ReminderCard({
    required this.reminder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Medicine Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: reminder.isActive
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.medication,
                      color: reminder.isActive
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Medicine Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.medicineName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          reminder.dosage,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Toggle Switch
                  Switch(
                    value: reminder.isActive,
                    onChanged: (value) {
                      ref.read(reminderControllerProvider.notifier).toggleReminder(
                            reminderId: reminder.id,
                            isActive: value,
                          );
                    },
                  ),
                ],
              ),

              if (reminder.instructions != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reminder.instructions!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Reminder Times
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: reminder.reminderTimes.map((time) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: reminder.isActive
                          ? Colors.green[50]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: reminder.isActive
                            ? Colors.green[200]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.alarm,
                          size: 14,
                          color: reminder.isActive ? Colors.green[700] : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: reminder.isActive ? Colors.green[700] : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 8),

              // Frequency Badge
              Row(
                children: [
                  Icon(
                    reminder.frequency == ReminderFrequency.daily
                        ? Icons.today
                        : Icons.calendar_month,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    reminder.frequency == ReminderFrequency.daily
                        ? 'Every day'
                        : 'Weekly',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (reminder.nextReminderAt != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Next: ${DateFormat('MMM dd, hh:mm a').format(reminder.nextReminderAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}