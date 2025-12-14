// ============================================
// FILE: lib/features/scan/data/repositories/scan_repository.dart
// ============================================
// This repository manages all scan operations
// It's the bridge between the app and Firebase/local storage

// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/scan.dart';
import '../models/scan_model.dart';
import '../../../../core/utils/file_storage_helper.dart';
import '../../../../core/utils/ocr_service.dart';

class ScanRepository {
  final FirebaseFirestore _firestore;
  final OCRService _ocrService;
  
  ScanRepository({
    FirebaseFirestore? firestore,
    OCRService? ocrService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _ocrService = ocrService ?? OCRService();

  /// Create a new scan from a captured image
  /// 
  /// This is the main function that:
  /// 1. Saves the image locally
  /// 2. Extracts text using OCR
  /// 3. Saves metadata to Firestore
  /// 
  /// Returns the created Scan object
  Future<Scan> createScan({
    required String userId,
    required String imagePath,
  }) async {
    try {
      print('📸 Creating new scan...');
      
      // Step 1: Generate unique ID
      final scanId = const Uuid().v4();
      final fileName = '$scanId.jpg';
      
      // Step 2: Save image locally
      print('💾 Saving image locally...');
      final localPath = await FileStorageHelper.saveImage(
        sourcePath: imagePath,
        fileName: fileName,
      );
      print('✅ Image saved: $localPath');
      
      // Step 3: Extract text using OCR
      print('🔍 Extracting text with OCR...');
      final ocrResult = await _ocrService.extractText(localPath);
      
      if (!ocrResult.success) {
        throw Exception('OCR failed: ${ocrResult.error}');
      }
      
      print('✅ Text extracted: ${ocrResult.text.substring(0, ocrResult.text.length > 50 ? 50 : ocrResult.text.length)}...');
      
      // Step 4: Create scan object
      final scan = ScanModel(
        id: scanId,
        userId: userId,
        scannedText: ocrResult.text,
        localImagePath: localPath,
        scanDate: DateTime.now(),
        confidenceScore: ocrResult.confidence,
      );
      
      // Step 5: Save to Firestore
      print('☁️ Saving to Firestore...');
      await _firestore
          .collection('userScans')
          .doc(userId)
          .collection('scans')
          .doc(scanId)
          .set(scan.toFirestore());
      
      print('✅ Scan created successfully!');
      
      return scan;
      
    } catch (e) {
      print('❌ Error creating scan: $e');
      rethrow;
    }
  }

  /// Get all scans for a user
  /// Returns a stream that updates in real-time
  Stream<List<Scan>> getUserScans(String userId) {
    return _firestore
        .collection('userScans')
        .doc(userId)
        .collection('scans')
        .orderBy('scanDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ScanModel.fromFirestore(doc);
          }).toList();
        });
  }

  /// Get a single scan by ID
  Future<Scan?> getScan({
    required String userId,
    required String scanId,
  }) async {
    try {
      final doc = await _firestore
          .collection('userScans')
          .doc(userId)
          .collection('scans')
          .doc(scanId)
          .get();
      
      if (doc.exists) {
        return ScanModel.fromFirestore(doc);
      }
      return null;
      
    } catch (e) {
      print('❌ Error getting scan: $e');
      return null;
    }
  }

  /// Delete a scan
  /// This deletes both the Firestore document and the local image
  Future<void> deleteScan({
    required String userId,
    required String scanId,
    required String localImagePath,
  }) async {
    try {
      print('🗑️ Deleting scan...');
      
      // Delete from Firestore
      await _firestore
          .collection('userScans')
          .doc(userId)
          .collection('scans')
          .doc(scanId)
          .delete();
      
      // Delete local image
      await FileStorageHelper.deleteImage(localImagePath);
      
      print('✅ Scan deleted');
      
    } catch (e) {
      print('❌ Error deleting scan: $e');
      rethrow;
    }
  }

  /// Update scan translation
  Future<void> updateTranslation({
    required String userId,
    required String scanId,
    required String translatedText,
  }) async {
    try {
      await _firestore
          .collection('userScans')
          .doc(userId)
          .collection('scans')
          .doc(scanId)
          .update({
            'translatedText': translatedText,
          });
      
      print('✅ Translation updated');
      
    } catch (e) {
      print('❌ Error updating translation: $e');
      rethrow;
    }
  }

  /// Check if scan is duplicate
  /// Compares text similarity with existing scans
  Future<bool> isDuplicateScan({
    required String userId,
    required String scannedText,
  }) async {
    try {
      final scans = await _firestore
          .collection('userScans')
          .doc(userId)
          .collection('scans')
          .get();
      
      for (final doc in scans.docs) {
        final existingText = doc.data()['scannedText'] as String?;
        if (existingText != null) {
          final similarity = _calculateSimilarity(scannedText, existingText);
          if (similarity > 0.8) {
            return true; // More than 80% similar
          }
        }
      }
      
      return false;
      
    } catch (e) {
      print('❌ Error checking duplicate: $e');
      return false;
    }
  }

  /// Calculate text similarity (simple version)
  double _calculateSimilarity(String text1, String text2) {
    final words1 = text1.toLowerCase().split(RegExp(r'\s+'));
    final words2 = text2.toLowerCase().split(RegExp(r'\s+'));
    
    final commonWords = words1.where((word) => words2.contains(word)).length;
    final totalWords = (words1.length + words2.length) / 2;
    
    return totalWords > 0 ? commonWords / totalWords : 0.0;
  }

  /// Get statistics
  Future<ScanStatistics> getStatistics(String userId) async {
    try {
      final scans = await _firestore
          .collection('userScans')
          .doc(userId)
          .collection('scans')
          .get();
      
      int totalScans = scans.docs.length;
      int successfulScans = 0;
      double totalConfidence = 0.0;
      
      for (final doc in scans.docs) {
        final confidence = (doc.data()['confidenceScore'] ?? 0.0) as double;
        totalConfidence += confidence;
        if (confidence > 0.7) successfulScans++;
      }
      
      return ScanStatistics(
        totalScans: totalScans,
        successfulScans: successfulScans,
        averageConfidence: totalScans > 0 ? totalConfidence / totalScans : 0.0,
      );
      
    } catch (e) {
      print('❌ Error getting statistics: $e');
      return ScanStatistics(
        totalScans: 0,
        successfulScans: 0,
        averageConfidence: 0.0,
      );
    }
  }

  void dispose() {
    _ocrService.dispose();
  }
}

// ============================================
// Scan Statistics Model
// ============================================
class ScanStatistics {
  final int totalScans;
  final int successfulScans;
  final double averageConfidence;

  ScanStatistics({
    required this.totalScans,
    required this.successfulScans,
    required this.averageConfidence,
  });

  int get failedScans => totalScans - successfulScans;
  
  double get successRate => totalScans > 0 
      ? (successfulScans / totalScans) * 100 
      : 0.0;
  
  String get averageConfidencePercentage => 
      '${(averageConfidence * 100).toStringAsFixed(0)}%';
}