// lib/features/scan/presentation/screens/ocr_testing_screen.dart
// ============================================
// OCR CONFIDENCE TESTING SCREEN (FIXED - No Freezing)
// ============================================

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/ocr_service.dart';
import '../../../../core/utils/enhanced_ocr_confidence.dart';

class OCRTestingScreen extends ConsumerStatefulWidget {
  const OCRTestingScreen({super.key});

  @override
  ConsumerState<OCRTestingScreen> createState() => _OCRTestingScreenState();
}

class _OCRTestingScreenState extends ConsumerState<OCRTestingScreen> {
  final OCRService _ocrService = OCRService();
  final List<OCRTestResult> _testResults = [];
  bool _isProcessing = false;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  /// Test a specific image type - SIMPLIFIED VERSION
  Future<void> _testImageType(ImageQuality quality) async {
    setState(() => _isProcessing = true);

    try {
      // Pick image from gallery
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024, // Reduce size to prevent freezing
        maxHeight: 1024,
      );
      
      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }

      // Show processing dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing image...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Extract text using OCR (in background)
      final ocrResult = await _ocrService.extractText(image.path);
      
      if (!ocrResult.success) {
        throw Exception('OCR failed: ${ocrResult.error}');
      }

      // Calculate SIMPLE confidence (text-only, no heavy image processing)
      final confidence = EnhancedOCRConfidence.calculateTextOnlyConfidence(
        ocrResult.text,
        quality,
      );

      // Store result
      if (mounted) {
        Navigator.pop(context); // Close dialog
        
        setState(() {
          _testResults.add(OCRTestResult(
            quality: quality,
            extractedText: ocrResult.text,
            confidence: confidence,
            timestamp: DateTime.now(),
          ));
          _testResults.sort((a, b) => a.quality.index.compareTo(b.quality.index));
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${_getQualityLabel(quality)}: ${confidence.toStringAsFixed(1)}%'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Run all tests with sample data (for demo/report)
  void _runSampleTests() {
    setState(() {
      _testResults.clear();
      _testResults.addAll([
        OCRTestResult(
          quality: ImageQuality.clear,
          extractedText: 'Paracetamol 500mg\nDosage: 1-2 tablets\nTake with water',
          confidence: 96.5,
          timestamp: DateTime.now(),
        ),
        OCRTestResult(
          quality: ImageQuality.slightlyBlurred,
          extractedText: 'Paracetamol 500mg\nDosge: 1-2 tablets',
          confidence: 76.2,
          timestamp: DateTime.now(),
        ),
        OCRTestResult(
          quality: ImageQuality.badLighting,
          extractedText: 'Paracetam0l 5OOmg\nD0sage unclear',
          confidence: 64.8,
          timestamp: DateTime.now(),
        ),
        OCRTestResult(
          quality: ImageQuality.upsideDown,
          extractedText: 'ɐɯoʇǝɔɐɹɐԀ 00ƖWɯ',
          confidence: 38.5,
          timestamp: DateTime.now(),
        ),
        OCRTestResult(
          quality: ImageQuality.handwritten,
          extractedText: 'Para... 500... take 2x',
          confidence: 26.3,
          timestamp: DateTime.now(),
        ),
        OCRTestResult(
          quality: ImageQuality.veryBlurred,
          extractedText: 'P@r#... 5##... u#c1ear',
          confidence: 14.7,
          timestamp: DateTime.now(),
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Confidence Testing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.science),
            onPressed: _runSampleTests,
            tooltip: 'Load Sample Data',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => setState(() => _testResults.clear()),
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'How to Test',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Tap a test type below\n'
                      '2. Select an image from gallery\n'
                      '3. Wait for processing\n'
                      '4. View confidence score in chart\n\n'
                      'Or tap 🧪 to load sample data instantly',
                      style: TextStyle(color: Colors.blue[800]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Test Buttons
            Text(
              'Select Test Type',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            ..._buildTestButtons(),

            const SizedBox(height: 32),

            // Chart Section
            if (_testResults.isNotEmpty) ...[
              Text(
                'Confidence Results',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildLineChart(),
              const SizedBox(height: 32),

              // Results Table
              Text(
                'Detailed Results',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildResultsTable(),
            ] else
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTestButtons() {
    return ImageQuality.values.map((quality) {
      final isTested = _testResults.any((r) => r.quality == quality);
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ElevatedButton(
          onPressed: _isProcessing ? null : () => _testImageType(quality),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            backgroundColor: _getQualityColor(quality).withOpacity(0.1),
            foregroundColor: _getQualityColor(quality),
          ),
          child: Row(
            children: [
              Icon(_getQualityIcon(quality)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getQualityLabel(quality),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isTested)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Tested',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLineChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 100,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 20,
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 20,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}%',
                        style: const TextStyle(fontSize: 12),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index < 0 || index >= _testResults.length) {
                        return Container();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _getShortLabel(_testResults[index].quality),
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey[300]!),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (int i = 0; i < _testResults.length; i++)
                      FlSpot(i.toDouble(), _testResults[i].confidence)
                  ],
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 6,
                        color: Colors.blue,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsTable() {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Confidence')),
            DataColumn(label: Text('Time')),
          ],
          rows: _testResults.map((result) {
            return DataRow(cells: [
              DataCell(Text(result.qualityLabel)),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(result.confidence).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${result.confidence.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getConfidenceColor(result.confidence),
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(DateFormat('HH:mm:ss').format(result.timestamp)),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.bar_chart, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No Test Results Yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap 🧪 for sample data or select a test type',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Color _getQualityColor(ImageQuality quality) {
    switch (quality) {
      case ImageQuality.clear:
        return Colors.green;
      case ImageQuality.slightlyBlurred:
        return Colors.lightGreen;
      case ImageQuality.badLighting:
        return Colors.orange;
      case ImageQuality.upsideDown:
        return Colors.deepOrange;
      case ImageQuality.handwritten:
        return Colors.red;
      case ImageQuality.veryBlurred:
        return Colors.red[900]!;
    }
  }

  IconData _getQualityIcon(ImageQuality quality) {
    switch (quality) {
      case ImageQuality.clear:
        return Icons.check_circle;
      case ImageQuality.slightlyBlurred:
        return Icons.blur_on;
      case ImageQuality.badLighting:
        return Icons.wb_sunny;
      case ImageQuality.upsideDown:
        return Icons.rotate_left;
      case ImageQuality.handwritten:
        return Icons.edit;
      case ImageQuality.veryBlurred:
        return Icons.blur_circular;
    }
  }

  String _getQualityLabel(ImageQuality quality) {
    switch (quality) {
      case ImageQuality.clear:
        return 'Clear Image (Good Lighting)';
      case ImageQuality.slightlyBlurred:
        return 'Slightly Blurred';
      case ImageQuality.badLighting:
        return 'Bad Lighting';
      case ImageQuality.upsideDown:
        return 'Upside Down';
      case ImageQuality.handwritten:
        return 'Handwritten';
      case ImageQuality.veryBlurred:
        return 'Very Blurred';
    }
  }

  String _getShortLabel(ImageQuality quality) {
    switch (quality) {
      case ImageQuality.clear:
        return 'Clear';
      case ImageQuality.slightlyBlurred:
        return 'Slight\nBlur';
      case ImageQuality.badLighting:
        return 'Bad\nLight';
      case ImageQuality.upsideDown:
        return 'Upside\nDown';
      case ImageQuality.handwritten:
        return 'Hand\nwritten';
      case ImageQuality.veryBlurred:
        return 'Very\nBlurred';
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.lightGreen;
    if (confidence >= 40) return Colors.orange;
    if (confidence >= 20) return Colors.deepOrange;
    return Colors.red;
  }
}