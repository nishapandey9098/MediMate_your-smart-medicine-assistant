// ============================================
// FILE: lib/features/scan/presentation/screens/scan_preview_screen.dart
// REPLACE THE ENTIRE FILE WITH THIS CODE
// ============================================
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/scan_provider.dart';

class ScanPreviewScreen extends ConsumerStatefulWidget {
  final String imagePath;

  const ScanPreviewScreen({
    super.key,
    required this.imagePath,
  });

  @override
  ConsumerState<ScanPreviewScreen> createState() => _ScanPreviewScreenState();
}

class _ScanPreviewScreenState extends ConsumerState<ScanPreviewScreen> {
  bool _isProcessing = false;
  String? _extractedText;
  double? _confidence;
  bool _processingComplete = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // ✅ FIXED: Use WidgetsBinding.addPostFrameCallback
    // This delays the processing until AFTER the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processScan();
    });
  }

// UPDATED: Only the _processScan method needs to change
// Replace your existing _processScan method with this:

Future<void> _processScan() async {
  if (!mounted) return;

  setState(() {
    _isProcessing = true;
    _error = null;
  });

  try {
    debugPrint('🔄 Starting scan processing...');

    // Call the scan controller to process the image
    // The enhanced confidence is now automatically calculated in OCRService
    final scan = await ref.read(scanControllerProvider.notifier).processScan(
          widget.imagePath,
        );

    if (scan != null && mounted) {
      setState(() {
        _extractedText = scan.scannedText;
        _confidence = scan.confidenceScore; // Now uses enhanced confidence!
        _processingComplete = true;
      });

      debugPrint('✅ Processing complete!');
      debugPrint('📝 Text: ${scan.scannedText.substring(0, scan.scannedText.length > 50 ? 50 : scan.scannedText.length)}...');
      debugPrint('📊 Enhanced Confidence: ${(scan.confidenceScore * 100).toStringAsFixed(1)}%');
    } else {
      throw Exception('Failed to process scan - returned null');
    }
  } catch (e) {
    debugPrint('❌ Error processing scan: $e');
    if (mounted) {
      setState(() {
        _error = e.toString();
      });
    }
  } finally {
    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}

  /// Save the scan and go back to home
  void _saveScan() {
    if (!_processingComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for processing to complete'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Scan is already saved in Firestore by processScan()
    // Just show success and go back
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Scan saved successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    
    // Return true to indicate success
    Navigator.pop(context, true);
  }

  /// Retake the scan (go back to camera)
  void _retakeScan() {
    // Delete the temp image file
    try {
      final file = File(widget.imagePath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      debugPrint('Error deleting temp file: $e');
    }
    
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Preview'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _retakeScan,
        ),
      ),
      body: Column(
        children: [
          // Image Preview Section
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Results Section
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: _error != null
                  ? _buildErrorView()
                  : _isProcessing
                      ? _buildProcessingView()
                      : _processingComplete
                          ? _buildResultsView()
                          : const Center(child: Text('Initializing...')),
            ),
          ),

          // Action Buttons
          if (!_isProcessing && _error == null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Retake Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _retakeScan,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retake'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Save Button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _processingComplete ? _saveScan : null,
                        icon: const Icon(Icons.check),
                        label: const Text('Save Scan'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Retry button if error
          if (_error != null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _processScan,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Processing'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _retakeScan,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take New Photo'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Show processing indicator
  Widget _buildProcessingView() {
    final progress = ref.watch(scanControllerProvider).progress;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(
          'Extracting text...',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'This may take a few seconds',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Show error message
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 24),
            Text(
              'Processing Failed',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _error ?? 'Unknown error',
                  style: TextStyle(color: Colors.red[900]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tips:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Make sure the image has clear text\n'
              '• Try better lighting\n'
              '• Hold the phone steady\n'
              '• Avoid shadows and glare',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Show OCR results
  Widget _buildResultsView() {
    final confidenceColor = _getConfidenceColor(_confidence ?? 0.0);
    final confidenceText = ((_confidence ?? 0.0) * 100).toStringAsFixed(0);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Confidence Score Card
          Card(
            color: confidenceColor.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _confidence! >= 0.7
                        ? Icons.check_circle
                        : Icons.warning,
                    color: confidenceColor,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Confidence Score',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '$confidenceText%',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: confidenceColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Extracted Text Section
          Text(
            'Extracted Text',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          // Show text or empty state
          if (_extractedText == null || _extractedText!.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.text_fields,
                      size: 48,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No text detected',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try retaking the photo with:\n'
                      '• Better lighting\n'
                      '• Clearer text\n'
                      '• Less blur',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                constraints: const BoxConstraints(minHeight: 100),
                child: SelectableText(
                  _extractedText!,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Tips for low confidence
          if (_confidence! < 0.7)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tips for better results:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• Use good lighting\n'
                          '• Hold phone steady\n'
                          '• Ensure text is clearly visible\n'
                          '• Avoid shadows and glare',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Get color based on confidence score
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}