// lib/core/utils/enhanced_ocr_confidence.dart
// ============================================
// ENHANCED OCR CONFIDENCE CALCULATOR (FIXED)
// Provides realistic confidence scores based on image quality
// ============================================

// ignore_for_file: avoid_print

import 'dart:typed_data';
import 'package:image/image.dart' as img;

enum ImageQuality {
  clear,           // Perfect conditions
  slightlyBlurred, // Minor blur
  badLighting,     // Poor lighting
  upsideDown,      // Wrong orientation
  handwritten,     // Handwritten text
  veryBlurred,     // Heavy blur
}

class EnhancedOCRConfidence {
  
  /// Main function: Calculate comprehensive OCR confidence
  static Future<double> calculateConfidence({
    required Uint8List imageBytes,
    required String extractedText,
    ImageQuality? knownQuality,
  }) async {
    
    // Get individual scores
    double imageScore = await _analyzeImageQuality(imageBytes);
    double textScore = _analyzeTextQuality(extractedText);
    double orientationScore = _detectOrientation(extractedText);
    
    // Apply quality penalty if known
    double qualityPenalty = 1.0;
    if (knownQuality != null) {
      qualityPenalty = _getQualityPenalty(knownQuality);
    }
    
    // Weighted calculation
    double finalScore = (
      (imageScore * 0.40) +
      (textScore * 0.35) +
      (orientationScore * 0.25)
    ) * qualityPenalty;
    
    return (finalScore * 100).clamp(0, 100);
  }

  // ==========================================
  // IMAGE QUALITY ANALYSIS
  // ==========================================
  
  static Future<double> _analyzeImageQuality(Uint8List bytes) async {
    try {
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return 0.3;

      // 1. Sharpness detection
      double sharpness = _calculateSharpness(image);
      
      // 2. Brightness detection
      double brightness = _analyzeBrightness(image);
      
      // 3. Contrast detection
      double contrast = _analyzeContrast(image);

      double score = 0.0;

      // Sharpness scoring
      if (sharpness > 2000) {
        score += 0.45;
      } else if (sharpness > 1000) {
        score += 0.35;
      } else if (sharpness > 500) {
        score += 0.25;
      } else if (sharpness > 200) {
        score += 0.15;
      } else {
        score += 0.05;
      }

      // Brightness scoring
      if (brightness > 0.25 && brightness < 0.75) {
        score += 0.30;
      } else if (brightness > 0.15 && brightness < 0.85) {
        score += 0.15;
      } else {
        score += 0.05;
      }

      // Contrast scoring
      if (contrast > 40) {
        score += 0.25;
      } else if (contrast > 25) {
        score += 0.15;
      } else {
        score += 0.05;
      }

      return score.clamp(0.0, 1.0);
      
    } catch (e) {
      print('❌ Image analysis error: $e');
      return 0.3;
    }
  }

  /// Calculate sharpness using Laplacian variance
  static double _calculateSharpness(img.Image image) {
    var gray = img.grayscale(image);
    
    List<int> laplacian = [
      0,  1, 0,
      1, -4, 1,
      0,  1, 0,
    ];

    img.Image filtered = img.convolution(gray, filter: laplacian);
    
    // Calculate variance
    int sum = 0;
    int count = 0;
    
    for (int y = 0; y < filtered.height; y++) {
      for (int x = 0; x < filtered.width; x++) {
        final pixel = filtered.getPixel(x, y);
        sum += pixel.r.toInt();
        count++;
      }
    }
    
    if (count == 0) return 0;
    
    double mean = sum / count;
    double variance = 0;
    
    for (int y = 0; y < filtered.height; y++) {
      for (int x = 0; x < filtered.width; x++) {
        final pixel = filtered.getPixel(x, y);
        double diff = pixel.r - mean;
        variance += diff * diff;
      }
    }
    
    return variance / count;
  }

  /// Analyze brightness (0.0 = black, 1.0 = white)
  static double _analyzeBrightness(img.Image image) {
    double sum = 0.0;
    int count = 0;

    for (int y = 0; y < image.height; y += 5) {
      for (int x = 0; x < image.width; x += 5) {
        final pixel = image.getPixel(x, y);
        sum += img.getLuminance(pixel).toDouble();
        count++;
      }
    }
    
    if (count == 0) return 0.5;
    return (sum / count) / 255.0;
  }

  /// Analyze contrast
  static double _analyzeContrast(img.Image image) {
    List<int> values = [];
    
    for (int y = 0; y < image.height; y += 5) {
      for (int x = 0; x < image.width; x += 5) {
        final pixel = image.getPixel(x, y);
        values.add(img.getLuminance(pixel).toInt());
      }
    }
    
    if (values.isEmpty) return 0;
    
    values.sort();
    int min = values.first;
    int max = values.last;
    
    return (max - min).toDouble();
  }

  // ==========================================
  // TEXT QUALITY ANALYSIS
  // ==========================================
  
  static double _analyzeTextQuality(String text) {
    if (text.trim().isEmpty) return 0.0;

    double score = 1.0;

    // Count character types
    int spaces = RegExp(r'\s').allMatches(text).length;
    int special = RegExp(r'[^A-Za-z0-9\s]').allMatches(text).length;
    int total = text.length;

    if (total == 0) return 0.0;

    // 1. Too many special characters (OCR noise)
    double specialRatio = special / total;
    if (specialRatio > 0.3) {
      score -= 0.40;  // Very noisy
    } else if (specialRatio > 0.15) {
      score -= 0.20;  // Somewhat noisy
    }

    // 2. Random character sequences (OCR confusion)
    if (RegExp(r'[A-Z0-9]{8,}').hasMatch(text)) {
      score -= 0.20;
    }

    // 3. Alternating letter-number patterns (OCR error)
    if (RegExp(r'[A-Za-z]\d[A-Za-z]\d').hasMatch(text)) {
      score -= 0.15;
    }

    // 4. Very short text (incomplete extraction)
    if (text.trim().length < 10) {
      score -= 0.25;
    } else if (text.trim().length < 20) {
      score -= 0.10;
    }

    // 5. No meaningful words detected
    if (!RegExp(r'\b[A-Za-z]{3,}\b').hasMatch(text)) {
      score -= 0.20;
    }

    // 6. Excessive or missing spaces
    double spaceRatio = spaces / total;
    if (spaceRatio > 0.5 || spaceRatio < 0.05) {
      score -= 0.15;
    }

    return score.clamp(0.0, 1.0);
  }

  // ==========================================
  // ORIENTATION DETECTION
  // ==========================================
  
  static double _detectOrientation(String text) {
    // Upside-down text patterns
    if (RegExp(r'[qpbd]{3,}').hasMatch(text.toLowerCase())) {
      return 0.2;
    }
    
    // Inverted numbers
    if (RegExp(r'[6-9]{4,}').hasMatch(text)) {
      return 0.3;
    }
    
    // Normal orientation
    if (RegExp(r'\b[A-Z][a-z]{2,}\b').hasMatch(text)) {
      return 1.0;
    }
    
    return 0.7;
  }

  // ==========================================
  // QUALITY PENALTY MULTIPLIERS
  // ==========================================
  
  static double _getQualityPenalty(ImageQuality quality) {
    switch (quality) {
      case ImageQuality.clear:
        return 1.0;
      case ImageQuality.slightlyBlurred:
        return 0.85;
      case ImageQuality.badLighting:
        return 0.75;
      case ImageQuality.upsideDown:
        return 0.50;
      case ImageQuality.handwritten:
        return 0.35;
      case ImageQuality.veryBlurred:
        return 0.25;
    }
  }

  // ==========================================
  // SIMPLE TESTING FUNCTION
  // ==========================================
  
  /// For testing without image bytes - text-only confidence
  static double calculateTextOnlyConfidence(
    String text, 
    ImageQuality quality
  ) {
    double textScore = _analyzeTextQuality(text);
    double orientationScore = _detectOrientation(text);
    double qualityPenalty = _getQualityPenalty(quality);
    
    double finalScore = (
      (textScore * 0.60) +
      (orientationScore * 0.40)
    ) * qualityPenalty;
    
    return (finalScore * 100).clamp(0, 100);
  }
}

// ==========================================
// HELPER: Test Result Model
// ==========================================

class OCRTestResult {
  final ImageQuality quality;
  final String extractedText;
  final double confidence;
  final DateTime timestamp;

  OCRTestResult({
    required this.quality,
    required this.extractedText,
    required this.confidence,
    required this.timestamp,
  });

  String get qualityLabel {
    switch (quality) {
      case ImageQuality.clear:
        return 'Clear Image';
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
}