// ============================================
// FILE: lib/features/scan/presentation/screens/home_screen.dart (REPLACE ENTIRE FILE)
// ============================================
// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/scan_provider.dart';
import 'camera_screen.dart';
import 'scan_detail_screen.dart';
import '../../../reminders/presentation/screens/test_notifications_screen.dart';
import '../../../reminders/presentation/screens/reminders_list_screen.dart';
import '../../../../core/utils/oppo_settings_guide.dart';
import 'ocr_testing_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

     
  // 🔍 Run Oppo Settings Check
  WidgetsBinding.instance.addPostFrameCallback((_) {
    OppoSettingsGuide.checkAndShowWarning(context);
  });
  
    final user = ref.watch(authStateProvider).value;
    final scansAsync = ref.watch(userScansProvider);
    final statisticsAsync = ref.watch(scanStatisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MediMate'),
        actions: [
// In home_screen.dart AppBar actions:

IconButton(
  icon: const Icon(Icons.bug_report),
  onPressed: () async {
    final repo = ref.read(authRepositoryProvider);
    final user = repo.currentFirebaseUser;
    
    if (user != null) {
      final token = await user.getIdTokenResult();
      final emailVerified = token.claims?['email_verified'] ?? false;
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🔍 Token Debug'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${user.email}'),
                Text('User Object Verified: ${user.emailVerified}'),
                Text('Token Claim Verified: $emailVerified'),
                Text('Token Issued: ${token.issuedAtTime}'),
                Text('Token Expires: ${token.expirationTime}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    }
  },
  tooltip: 'Debug Token',
),

          // In HomeScreen's AppBar actions:
IconButton(
  icon: const Icon(Icons.science),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OCRTestingScreen(),
      ),
    );
  },
  tooltip: 'OCR Testing',
),

           IconButton(
      icon: const Icon(Icons.alarm),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RemindersListScreen(),
          ),
        );
      },
      tooltip: 'Reminders',
    ),
          IconButton(
    icon: const Icon(Icons.bug_report),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TestNotificationsScreen(),
        ),
      );
    },
    tooltip: 'Test Notifications',
  ),
  
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userScansProvider);
          ref.invalidate(scanStatisticsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Header Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Message
                    Text(
                      'Welcome back,',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      user?.name ?? 'User',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 24),

                    // Statistics Card
                    statisticsAsync.when(
                      data: (stats) => Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatItem(
                                icon: Icons.qr_code_scanner,
                                label: 'Total Scans',
                                value: '${stats.totalScans}',
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey[300],
                              ),
                              _StatItem(
                                icon: Icons.check_circle,
                                label: 'Success Rate',
                                value: '${stats.successRate.toStringAsFixed(0)}%',
                              ),
                            ],
                          ),
                        ),
                      ),
                      loading: () => const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      error: (_, __) => const SizedBox(),
                    ),

                    const SizedBox(height: 24),

                    // Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Scans',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextButton.icon(
                          onPressed: () {
                            // TODO: Navigate to all scans
                          },
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: const Text('View All'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Scans List
            scansAsync.when(
              data: (scans) {
                if (scans.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            size: 100,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No scans yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the scan button to get started',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final scan = scans[index];
                        return _ScanCard(scan: scan);
                      },
                      childCount: scans.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(userScansProvider);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CameraScreen(),
            ),
          );
        },
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan'),
      ),
    );
  }
}

// Statistics Item Widget
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

// Scan Card Widget
class _ScanCard extends ConsumerWidget {
  final dynamic scan;

  const _ScanCard({required this.scan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScanDetailScreen(scan: scan),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: File(scan.localImagePath).existsSync()
                      ? Image.file(
                          File(scan.localImagePath),
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image_not_supported),
                ),
              ),
              const SizedBox(width: 12),

              // Scan Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Extracted text preview
                    Text(
                      scan.scannedText.isEmpty
                          ? 'No text detected'
                          : scan.scannedText.length > 60
                              ? '${scan.scannedText.substring(0, 60)}...'
                              : scan.scannedText,
                      style: Theme.of(context).textTheme.bodyLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Date and confidence
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(scan.scanDate),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Confidence badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(scan.confidenceScore)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(scan.confidenceScore * 100).toStringAsFixed(0)}% confidence',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getConfidenceColor(scan.confidenceScore),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}