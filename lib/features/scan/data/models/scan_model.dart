
// ============================================
// FILE 2: lib/features/scan/data/models/scan_model.dart
// ============================================
// This is the MODEL - knows how to convert to/from Firebase
// Extends the pure entity and adds Firebase functionality

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/scan.dart';

class ScanModel extends Scan {
  ScanModel({
    required super.id,
    required super.userId,
    required super.scannedText,
    super.translatedText,
    required super.localImagePath,
    required super.scanDate,
    super.confidenceScore,
    super.isDuplicate,
    super.matchedMedicineId,
  });

  // Convert Firebase document to ScanModel
  // This is called when we READ from Firestore
  factory ScanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ScanModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      scannedText: data['scannedText'] ?? '',
      translatedText: data['translatedText'],
      localImagePath: data['localImagePath'] ?? '',
      scanDate: (data['scanDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      confidenceScore: (data['confidenceScore'] ?? 0.0).toDouble(),
      isDuplicate: data['isDuplicate'] ?? false,
      matchedMedicineId: data['matchedMedicineId'],
    );
  }

  // Convert ScanModel to Map for Firebase
  // This is called when we WRITE to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'scannedText': scannedText,
      'translatedText': translatedText,
      'localImagePath': localImagePath,
      'scanDate': Timestamp.fromDate(scanDate),
      'confidenceScore': confidenceScore,
      'isDuplicate': isDuplicate,
      'matchedMedicineId': matchedMedicineId,
    };
  }

  // Create a ScanModel from a pure Scan entity
  factory ScanModel.fromEntity(Scan scan) {
    return ScanModel(
      id: scan.id,
      userId: scan.userId,
      scannedText: scan.scannedText,
      translatedText: scan.translatedText,
      localImagePath: scan.localImagePath,
      scanDate: scan.scanDate,
      confidenceScore: scan.confidenceScore,
      isDuplicate: scan.isDuplicate,
      matchedMedicineId: scan.matchedMedicineId,
    );
  }
}