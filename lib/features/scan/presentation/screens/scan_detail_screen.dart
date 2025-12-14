// ============================================
// FILE: lib/features/scan/presentation/screens/scan_detail_screen.dart
// ============================================
// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:medimate/core/utils/ocr_service.dart';
import '../../domain/entities/scan.dart';
import '../providers/scan_provider.dart';
import '../../../reminders/presentation/screens/add_reminder_screen.dart';


class ScanDetailScreen extends ConsumerWidget {
  final Scan scan;

  const ScanDetailScreen({
    super.key,
    required this.scan,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMMM dd, yyyy • hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.black,
              child: File(scan.localImagePath).existsSync()
                  ? InteractiveViewer(
                      child: Image.file(
                        File(scan.localImagePath),
                        fit: BoxFit.contain,
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 60,
                            color: Colors.white,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Image not found',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
            ),

            // Info Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Card
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Scanned On'),
                      subtitle: Text(dateFormat.format(scan.scanDate)),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Confidence Card
                  Card(
                    child: ListTile(
                      leading: Icon(
                        scan.confidenceScore >= 0.7
                            ? Icons.check_circle
                            : Icons.warning,
                        color: _getConfidenceColor(scan.confidenceScore),
                      ),
                      title: const Text('OCR Confidence'),
                      subtitle: Text(
                        '${(scan.confidenceScore * 100).toStringAsFixed(0)}%',
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getConfidenceColor(scan.confidenceScore)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          scan.confidenceScore >= 0.8
                              ? 'High'
                              : scan.confidenceScore >= 0.6
                                  ? 'Medium'
                                  : 'Low',
                          style: TextStyle(
                            color: _getConfidenceColor(scan.confidenceScore),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Extracted Text Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Extracted Text',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: scan.scannedText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Text copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Card(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      constraints: const BoxConstraints(minHeight: 150),
                      child: scan.scannedText.isEmpty
                          ? const Center(
                              child: Text(
                                'No text detected',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          : SelectableText(
                              scan.scannedText,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Actions Section
                  Text(
                    'Actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.translate),
                          title: const Text('Translate to Nepali'),
                          subtitle: const Text('Coming soon'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Translation feature coming soon!'),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.alarm),
                          title: const Text('Set Reminder'),
                          subtitle: const Text('Coming soon'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reminder feature coming soon!'),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.alarm_add),
                          title: const Text('Set Reminder'),
                          subtitle: const Text('Never miss a dose'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Extract medicine info from the scan
                            final ocrService = OCRService();
                            final medicineInfo = ocrService.extractMedicineInfo(scan.scannedText);
                            
                            // Navigate to add reminder screen with pre-filled data
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddReminderScreen(
                                  medicineName: medicineInfo.medicineName ?? 'Medicine',
                                  dosage: medicineInfo.dosage ?? '',
                                  scanId: scan.id,
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.share),
                          title: const Text('Share'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // TODO: Implement share
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Share feature coming soon!'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Delete Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showDeleteDialog(context, ref),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        'Delete Scan',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
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

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scan'),
        content: const Text(
          'Are you sure you want to delete this scan? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              try {
                await ref.read(scanControllerProvider.notifier).deleteScan(scan);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Scan deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context); // Go back to home
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}