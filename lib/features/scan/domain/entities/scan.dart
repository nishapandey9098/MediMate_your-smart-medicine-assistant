// ============================================
// FILE 1: lib/features/scan/domain/entities/scan.dart
// ============================================
// This is the PURE ENTITY - represents what a Scan IS
// No Firebase code here - just pure data

class Scan {
  final String id;                    // Unique ID for this scan
  final String userId;                // Who created this scan
  final String scannedText;           // Text extracted by OCR
  final String? translatedText;       // Nepali translation (future)
  final String localImagePath;        // Where image is saved on device
  final DateTime scanDate;            // When was it scanned
  final double confidenceScore;       // How confident is the OCR (0.0 to 1.0)
  final bool isDuplicate;             // Is this a duplicate scan?
  final String? matchedMedicineId;    // Link to medicine database (future)

  Scan({
    required this.id,
    required this.userId,
    required this.scannedText,
    this.translatedText,
    required this.localImagePath,
    required this.scanDate,
    this.confidenceScore = 0.0,
    this.isDuplicate = false,
    this.matchedMedicineId,
  });

  // Helper method to create a copy with some fields changed
  Scan copyWith({
    String? id,
    String? userId,
    String? scannedText,
    String? translatedText,
    String? localImagePath,
    DateTime? scanDate,
    double? confidenceScore,
    bool? isDuplicate,
    String? matchedMedicineId,
  }) {
    return Scan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      scannedText: scannedText ?? this.scannedText,
      translatedText: translatedText ?? this.translatedText,
      localImagePath: localImagePath ?? this.localImagePath,
      scanDate: scanDate ?? this.scanDate,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      matchedMedicineId: matchedMedicineId ?? this.matchedMedicineId,
    );
  }
}