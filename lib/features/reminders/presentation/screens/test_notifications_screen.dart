// lib/features/reminders/presentation/screens/test_notifications_screen.dart
// ═══════════════════════════════════════════════════════════════
// ANDROID 15 NOTIFICATION TEST SCREEN
// ═══════════════════════════════════════════════════════════════
// ignore_for_file: prefer_final_fields, avoid_print, unused_element, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/utils/notification_service.dart';
import '../../../../core/utils/text_to_speech_service.dart';
import 'dart:async';

class TestNotificationsScreen extends StatefulWidget {
  const TestNotificationsScreen({super.key});

  @override
  State<TestNotificationsScreen> createState() => _TestNotificationsScreenState();
}

class _TestNotificationsScreenState extends State<TestNotificationsScreen> {
  final _notificationService = NotificationService();
  // ignore: unused_field
  final _ttsService = TextToSpeechService();

  bool _isInitialized = false;
  List<String> _logs = [];
  int _pendingCount = 0;
  Map<String, dynamic>? _permissionStatus;
  

 // ✅ ADD: Timer for auto-refresh

  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _initialize();
    
    // ✅ ADD: Auto-refresh every 2 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _updateStatus();
    });
  }

  @override
  void dispose() {
    // Cancel the periodic timer to avoid leaks and mark the field as used.
    _refreshTimer?.cancel();
    _refreshTimer = null;
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      _addLog('🔄 Initializing services...');
      await _notificationService.initialize();
      
      setState(() {
        _isInitialized = true;
      });
      
      _addLog('✅ Services initialized');
      await _updateStatus();
    } catch (e) {
      _addLog('❌ Initialization error: $e');
    }
  }

  Future<void> _updateStatus() async {
  try {
    print('🔄 Updating status...');
    
    final status = await _notificationService.getStatus();
    final pending = await _notificationService.getPendingNotifications();
    
    // ✅ FIX: Force update even if same count
    setState(() {
      _permissionStatus = status;
      _pendingCount = pending.length;
    });
    
    _addLog('📊 Status updated: ${pending.length} notifications pending');
    
    if (pending.isNotEmpty) {
      print('📋 Pending notifications:');
      for (final notif in pending) {
        print('   • ID ${notif.id}: ${notif.title}');
        _addLog('   • ID ${notif.id}: ${notif.title}');
      }
    } else {
      print('✅ No pending notifications');
      _addLog('✅ No pending notifications');
    }
  } catch (e) {
    _addLog('❌ Status update error: $e');
  }
}

/// ✅ NEW: Manually cancel a notification after it fires
Future<void> _manualCancelAfterFire(int id) async {
  try {
    print('🗑️ Manually cancelling notification ID: $id');
    await _notificationService.cancelReminder(id);
    
    // Wait for system to update
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Refresh status
    await _updateStatus();
    
    _addLog('✅ Manually cancelled ID: $id');
  } catch (e) {
    _addLog('❌ Manual cancel error: $e');
  }
}

  void _addLog(String message) {
    setState(() {
      final time = DateTime.now().toString().substring(11, 19);
      _logs.insert(0, '$time - $message');
      if (_logs.length > 100) _logs.removeLast();
    });
    print(message);
  }

  // ═══════════════════════════════════════════════════════════════
  // TEST FUNCTIONS
  // ═══════════════════════════════════════════════════════════════

  /// Test 1: Immediate notification
  Future<void> _testImmediate() async {
    _addLog('🔔 Testing immediate notification...');
    try {
      await _notificationService.showImmediateNotification(
        id: 999,
        title: '💊 Test Reminder',
        body: 'Paracetamol - 500mg\nTake with food',
        speak: false,
      );
      _addLog('✅ Immediate notification sent');
      _addLog('📱 Check your notification bar');
    } catch (e) {
      _addLog('❌ Error: $e');
    }
  }

  /// Test 2: Schedule in 10 seconds
 /// Test 2: Schedule in 10 seconds
Future<void> _testSchedule10Seconds() async {
  final scheduledTime = DateTime.now().add(const Duration(seconds: 10));
  _addLog('⏰ Scheduling for 10 seconds from now...');
  _addLog('📅 Time: ${scheduledTime.toString().substring(11, 19)}');
  
  try {
    await _notificationService.scheduleReminder(
      id: 997,
      medicineName: "Paracetamol",
      dosage: "500mg",
      scheduledTime: scheduledTime,
      instructions: "Take with food",
      speakNow: false,
    );
    
    _addLog('✅ Scheduled successfully!');
    _addLog('⏱️ Will fire in 10 seconds');
    _addLog('🔒 LOCK YOUR PHONE NOW to test');
    
    // ✅ FIX: Wait a moment then refresh status
    await Future.delayed(const Duration(milliseconds: 500));
    await _updateStatus();
    
  } catch (e) {
    _addLog('❌ Scheduling error: $e');
  }
}

  /// Test 3: Schedule in 1 minute
  Future<void> _testSchedule1Minute() async {
    final scheduledTime = DateTime.now().add(const Duration(minutes: 1));
    _addLog('⏰ Scheduling for 1 minute from now...');
    _addLog('📅 Time: ${scheduledTime.toString().substring(11, 19)}');
    
    try {
      await _notificationService.scheduleReminder(
        id: 996,
        medicineName: "Aspirin",
        dosage: "100mg",
        scheduledTime: scheduledTime,
        instructions: "Take after meals",
        speakNow: false,
      );
      
      _addLog('✅ Scheduled for 1 minute!');
      await Future.delayed(const Duration(milliseconds: 500));
      await _updateStatus();
    } catch (e) {
      _addLog('❌ Error: $e');
    }
  }

  /// Test 4: Schedule in 2 minutes
  Future<void> _testSchedule2Minutes() async {
    final scheduledTime = DateTime.now().add(const Duration(minutes: 2));
    _addLog('⏰ Scheduling for 2 minutes from now...');
    _addLog('📅 Time: ${scheduledTime.toString().substring(11, 19)}');
    
    try {
      await _notificationService.scheduleReminder(
        id: 995,
        medicineName: "Ibuprofen",
        dosage: "200mg",
        scheduledTime: scheduledTime,
        instructions: "Take with water",
        speakNow: false,
      );
      
      _addLog('✅ Scheduled for 2 minutes!');
      await Future.delayed(const Duration(milliseconds: 500));
      await _updateStatus();
    } catch (e) {
      _addLog('❌ Error: $e');
    }
  }

/// View pending notifications
Future<void> _viewPending() async {
  _addLog('📋 Fetching pending notifications...');
  try {
    final pending = await _notificationService.getPendingNotifications();
    _addLog('📊 Total pending: ${pending.length}');
    
    if (pending.isEmpty) {
      _addLog('   (No pending notifications)');
    } else {
      _addLog('═══════════════════════════════════════');
      for (final notif in pending) {
        _addLog('   ID ${notif.id}: ${notif.title ?? "No title"}');
        if (notif.body != null) {
          _addLog('      Body: ${notif.body}');
        }
      }
      _addLog('═══════════════════════════════════════');
    }
    
    await _updateStatus();
  } catch (e) {
    _addLog('❌ Error: $e');
  }
}

  /// Cancel all notifications
  Future<void> _cancelAll() async {
    _addLog('🗑️ Cancelling all notifications...');
    try {
      await _notificationService.cancelAll();
      _addLog('✅ All notifications cancelled');
      await _updateStatus();
    } catch (e) {
      _addLog('❌ Error: $e');
    }
  }

  /// Check Android 15 permissions
  Future<void> _checkPermissions() async {
    _addLog('🔍 Checking Android 15 permissions...');
    _addLog('═══════════════════════════════════════');
    
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final androidPlugin = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final notifEnabled = await androidPlugin.areNotificationsEnabled();
        final canScheduleExact = await androidPlugin.canScheduleExactNotifications();
        final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
        
        _addLog('📱 Notifications: ${notifEnabled == true ? "✅ Enabled" : "❌ Disabled"}');
        _addLog('⏰ Exact Alarms: ${canScheduleExact == true ? "✅ Enabled" : "❌ Disabled"}');
        _addLog('⚡ Battery: ${batteryStatus.isGranted ? "✅ Exempted" : "❌ Optimized"}');
        
        if (notifEnabled != true || canScheduleExact != true) {
          _addLog('⚠️ MISSING PERMISSIONS!');
          _addLog('   Tap "Request Permissions" button');
        } else {
          _addLog('✅ All permissions granted!');
        }
      }
    } catch (e) {
      _addLog('❌ Error: $e');
    }
    
    _addLog('═══════════════════════════════════════');
  }

  /// Request all permissions
  Future<void> _requestPermissions() async {
    _addLog('🔐 Requesting all permissions...');
    try {
      await _notificationService.initialize();
      _addLog('✅ Permissions requested');
      await _checkPermissions();
      await _updateStatus();
    } catch (e) {
      _addLog('❌ Error: $e');
    }
  }

  /// Check timezone
  Future<void> _checkTimezone() async {
    _addLog('🌍 Checking timezone...');
    _addLog('═══════════════════════════════════════');
    
    final now = DateTime.now();
    final tzNow = tz.TZDateTime.now(tz.local);
    
    _addLog('📍 Device: ${now.timeZoneOffset}');
    _addLog('🕐 Device Time: $now');
    _addLog('🇳🇵 TZ Location: ${tz.local.name}');
    _addLog('⏰ TZ Time: $tzNow');
    
    _addLog('═══════════════════════════════════════');
  }

  /// Open app settings
  Future<void> _openSettings() async {
    _addLog('⚙️ Opening app settings...');
    await openAppSettings();
  }

  // ═══════════════════════════════════════════════════════════════
  // UI
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications (Android 15)'),
        actions: [
           // ✅ ADD: Manual refresh button
    IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: () async {
        await _updateStatus();
        _addLog('🔄 Status manually refreshed'
        );
      },
      tooltip: 'Refresh Status',
    ),
  ],
),
      body: Column(
        children: [
          // Status Card
          _buildStatusCard(),
          
          // Test Buttons
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle('🎯 Quick Tests'),
                  const SizedBox(height: 12),
                  
                  _buildTestButton(
                    'Test Immediate',
                    'Shows notification right now',
                    Icons.notifications,
                    _testImmediate,
                    Colors.blue,
                  ),
                  
                  _buildTestButton(
                    'Schedule in 10 Seconds',
                    'Lock phone and wait',
                    Icons.timer_10,
                    _testSchedule10Seconds,
                    Colors.green,
                  ),
                  
                  _buildTestButton(
                    'Schedule in 1 Minute',
                    'Wait 1 minute',
                    Icons.timer,
                    _testSchedule1Minute,
                    Colors.orange,
                  ),
                  
                  _buildTestButton(
                    'Schedule in 2 Minutes',
                    'Wait 2 minutes',
                    Icons.schedule,
                    _testSchedule2Minutes,
                    Colors.purple,
                  ),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('📊 Management'),
                  const SizedBox(height: 12),
                  
                  _buildTestButton(
                    'View Pending ($_pendingCount)',
                    'See scheduled notifications',
                    Icons.list,
                    _viewPending,
                    Colors.grey,
                  ),
                  
                  _buildTestButton(
                      'Force Cancel Test (997)',
                      'Cancel the 10-sec test notification',
                      Icons.delete_forever,
                      () => _manualCancelAfterFire(997),
                      Colors.red,
                    ),
                    
                  _buildTestButton(
                    'Cancel All',
                    'Clear all scheduled',
                    Icons.clear_all,
                    _cancelAll,
                    Colors.red,
                  ),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('🔍 Debug'),
                  const SizedBox(height: 12),
                  
                  _buildTestButton(
                    'Check Permissions',
                    'Verify Android 15 permissions',
                    Icons.security,
                    _checkPermissions,
                    Colors.indigo,
                  ),
                  
                  _buildTestButton(
                    'Request Permissions',
                    'Grant all required permissions',
                    Icons.vpn_key,
                    _requestPermissions,
                    Colors.teal,
                  ),
                  
                  _buildTestButton(
                    'Check Timezone',
                    'Verify time settings',
                    Icons.public,
                    _checkTimezone,
                    Colors.cyan,
                  ),
                  
                  _buildTestButton(
                    'Open Settings',
                    'Configure app manually',
                    Icons.settings,
                    _openSettings,
                    Colors.brown,
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          
          // Logs
          _buildLogsSection(),
        ],
      ),
    );
  }
    
  Widget _buildStatusCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      color: _isInitialized ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _isInitialized ? Icons.check_circle : Icons.pending,
                  color: _isInitialized ? Colors.green : Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isInitialized ? 'Services Ready ✅' : 'Initializing...',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      // ✅ FIX: Animated pending count
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: Text(
                          'Pending: $_pendingCount',
                          key: ValueKey<int>(_pendingCount), // ✅ Triggers animation
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _pendingCount > 0 ? Colors.orange : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_permissionStatus != null) ...[
              const Divider(height: 24),
              _buildPermissionRow('Notifications', _permissionStatus!['notificationPermission']),
              _buildPermissionRow('Exact Alarms', _permissionStatus!['exactAlarmPermission']),
              _buildPermissionRow('Battery', _permissionStatus!['batteryOptimization']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRow(String label, dynamic value) {
    final isGranted = value == true || value == 'exempted';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isGranted ? Icons.check_circle : Icons.warning,
            size: 16,
            color: isGranted ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 13,
              color: isGranted ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTestButton(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onPressed,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: _isInitialized ? onPressed : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color, width: 2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsSection() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📝 Console Logs',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => setState(() => _logs.clear()),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'No logs yet\nRun a test!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          _logs[index],
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}