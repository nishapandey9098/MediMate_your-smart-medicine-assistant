// ============================================
// FILE: lib/features/reminders/presentation/screens/dose_tracking_dashboard.dart
// CREATE THIS NEW FILE
// ============================================
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/dose_log.dart';
import '../providers/reminder_provider.dart';

class DoseTrackingDashboard extends ConsumerWidget {
  const DoseTrackingDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adherenceAsync = ref.watch(adherenceRateProvider);
    final recentLogsAsync = ref.watch(recentDoseLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dose Tracking'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adherenceRateProvider);
          ref.invalidate(recentDoseLogsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Adherence Score Card
            adherenceAsync.when(
              data: (adherence) => _buildAdherenceCard(context, adherence),
              loading: () => _buildLoadingCard(),
              error: (_, __) => _buildErrorCard(),
            ),

            const SizedBox(height: 20),

            // Recent Activity Header
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 12),

            // Recent Logs
            recentLogsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return _buildEmptyState(context);
                }
                return _buildLogsList(logs);
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceCard(BuildContext context, double adherence) {
    final color = adherence >= 80
        ? Colors.green
        : adherence >= 60
            ? Colors.orange
            : Colors.red;

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text(
              'Adherence Rate',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${adherence.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              adherence >= 80
                  ? '🎉 Excellent adherence!'
                  : adherence >= 60
                      ? '👍 Good, keep it up!'
                      : '💪 Let\'s improve together!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Last 7 days',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            const Text('Error loading adherence data'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No activity yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Your dose history will appear here',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(List<DoseLog> logs) {
    return Column(
      children: logs.map((log) => _DoseLogCard(log: log)).toList(),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isTaken ? Icons.check_circle : Icons.cancel,
            color: color,
          ),
        ),
        title: Text(
          log.medicineName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${DateFormat('MMM dd, hh:mm a').format(log.scheduledTime)}'
          '${log.takenAt != null ? ' • Taken at ${DateFormat('hh:mm a').format(log.takenAt!)}' : ''}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isTaken ? 'Taken' : 'Missed',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}