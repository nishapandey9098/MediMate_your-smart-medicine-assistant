// lib/core/utils/ocr_service.dart
// ============================================
// OCR SERVICE - UPDATED WITH ENHANCED CONFIDENCE
// ============================================

// ignore_for_file: avoid_print

import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'enhanced_ocr_confidence.dart';

class OCRService {
  // Create the text recognizer
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Extract text from an image file WITH ENHANCED CONFIDENCE
  /// 
  /// Parameters:
  ///   - imagePath: Full path to the image file
  ///   - knownQuality: Optional - if you know the image quality beforehand
  /// 
  /// Returns:
  ///   - OCRResult with extracted text and REALISTIC confidence score
  Future<OCRResult> extractText(
    String imagePath, {
    ImageQuality? knownQuality,
  }) async {
    try {
      print('🔍 Starting OCR processing...');
      
      // Step 1: Create InputImage from file
      final inputImage = InputImage.fromFile(File(imagePath));
      
      // Step 2: Process the image with ML Kit
      final recognizedText = await textRecognizer.processImage(inputImage);
      
      // Step 3: Extract all text
      final allText = recognizedText.text;
      
      if (allText.isEmpty) {
        print('⚠️ No text detected');
        return OCRResult(
          text: '',
          confidence: 0.0,
          success: false,
          error: 'No text detected in image',
        );
      }

      // Step 4: Calculate ENHANCED confidence score
      final imageBytes = await File(imagePath).readAsBytes();
      final confidence = await EnhancedOCRConfidence.calculateConfidence(
        imageBytes: imageBytes,
        extractedText: allText,
        knownQuality: knownQuality,
      );

      print('✅ OCR completed: ${allText.length} characters extracted');
      print('📊 Enhanced Confidence: ${confidence.toStringAsFixed(1)}%');

      return OCRResult(
        text: allText,
        confidence: confidence / 100, // Convert back to 0-1 range
        success: true,
      );

    } catch (e) {
      print('❌ OCR Error: $e');
      return OCRResult(
        text: '',
        confidence: 0.0,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Extract structured information from medicine labels
  /// This tries to identify common patterns in medicine labels
  MedicineLabelInfo extractMedicineInfo(String text) {
    final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    String? medicineName;
    String? dosage;
    String? expiryDate;
    String? batchNumber;

    for (final line in lines) {
      final lower = line.toLowerCase();

      // Try to find medicine name (usually in first few lines)
      if (medicineName == null && line.length > 3 && line.length < 50) {
        if (!lower.contains('exp') && !lower.contains('mfg') && !lower.contains('batch')) {
          medicineName = line;
        }
      }

      // Look for dosage (mg, ml, tablets)
      if (dosage == null && (lower.contains('mg') || lower.contains('ml') || lower.contains('tablet'))) {
        dosage = line;
      }

      // Look for expiry date
      if (expiryDate == null && (lower.contains('exp') || lower.contains('expiry'))) {
        expiryDate = line;
      }

      // Look for batch number
      if (batchNumber == null && (lower.contains('batch') || lower.contains('lot'))) {
        batchNumber = line;
      }
    }

    return MedicineLabelInfo(
      medicineName: medicineName,
      dosage: dosage,
      expiryDate: expiryDate,
      batchNumber: batchNumber,
      rawText: text,
    );
  }

  /// Clean up resources
  void dispose() {
    textRecognizer.close();
    print('🧹 OCR Service disposed');
  }
}

// ============================================
// OCR Result Model
// ============================================

class OCRResult {
  final String text;           // Extracted text
  final double confidence;     // Confidence score (0.0 to 1.0)
  final bool success;          // Did OCR succeed?
  final String? error;         // Error message if failed

  OCRResult({
    required this.text,
    required this.confidence,
    required this.success,
    this.error,
  });

  // Check if result is good enough to use
  bool get isHighConfidence => confidence >= 0.7;

  // Get confidence as percentage
  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(0)}%';
}

// ============================================
// Medicine Label Information Model
// ============================================

class MedicineLabelInfo {
  final String? medicineName;
  final String? dosage;
  final String? expiryDate;
  final String? batchNumber;
  final String rawText;

  MedicineLabelInfo({
    this.medicineName,
    this.dosage,
    this.expiryDate,
    this.batchNumber,
    required this.rawText,
  });

  // Check if we extracted meaningful information
  bool get hasUsefulInfo =>
      medicineName != null ||
      dosage != null ||
      expiryDate != null;
}