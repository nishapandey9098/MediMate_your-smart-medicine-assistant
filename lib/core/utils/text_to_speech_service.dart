// ============================================
// FILE: lib/core/utils/text_to_speech_service.dart
// ============================================
/// Service for speaking text alerts using Text-to-Speech
/// This gives voice notifications to users!
// ignore_for_file: avoid_print

library;



import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechService {
  static final TextToSpeechService _instance = TextToSpeechService._internal();
  factory TextToSpeechService() => _instance;
  TextToSpeechService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  /// Initialize TTS with settings
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔊 Initializing Text-to-Speech...');

      // Configure TTS settings
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);  // Slower = easier to understand
      await _flutterTts.setVolume(1.0);       // Full volume
      await _flutterTts.setPitch(1.0);        // Normal pitch

      // Set up callbacks
      _flutterTts.setStartHandler(() {
        print('🔊 Speech started');
      });

      _flutterTts.setCompletionHandler(() {
        print('✅ Speech completed');
      });

      _flutterTts.setErrorHandler((msg) {
        print('❌ Speech error: $msg');
      });

      _isInitialized = true;
      print('✅ Text-to-Speech initialized');
    } catch (e) {
      print('❌ Failed to initialize TTS: $e');
    }
  }

  /// Speak a medicine reminder message
  /// 
  /// Example: "Time to take your medicine. Paracetamol, 500 milligrams."
  Future<void> speakReminder({
    required String medicineName,
    required String dosage,
    String? instructions,
  }) async {
    await initialize();

    // Build the message
    final message = _buildReminderMessage(
      medicineName: medicineName,
      dosage: dosage,
      instructions: instructions,
    );

    print('🔊 Speaking: $message');
    
    try {
      await _flutterTts.speak(message);
    } catch (e) {
      print('❌ Error speaking: $e');
    }
  }

  /// Speak custom text
  Future<void> speak(String text) async {
    await initialize();
    
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print('❌ Error speaking: $e');
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  /// Build a natural-sounding reminder message
  String _buildReminderMessage({
    required String medicineName,
    required String dosage,
    String? instructions,
  }) {
    // Start with friendly greeting
    String message = "Time to take your medicine. ";

    // Add medicine name (spoken naturally)
    message += "$medicineName, ";

    // Add dosage (convert "mg" to "milligrams" etc)
    final spokenDosage = _convertDosageToSpeech(dosage);
    message += "$spokenDosage. ";

    // Add instructions if provided
    if (instructions != null && instructions.isNotEmpty) {
      message += "$instructions. ";
    }

    // End with reminder
    message += "Please take your medicine now.";

    return message;
  }

  /// Convert written dosage to spoken format
  /// "500mg" → "500 milligrams"
  /// "2 tablets" → "2 tablets"
  String _convertDosageToSpeech(String dosage) {
    return dosage
        .replaceAll('mg', ' milligrams')
        .replaceAll('ml', ' milliliters')
        .replaceAll('g', ' grams')
        .replaceAll('mcg', ' micrograms')
        .trim();
  }

  /// Get available languages
  Future<List<dynamic>> getLanguages() async {
    await initialize();
    return await _flutterTts.getLanguages;
  }

  /// Get available voices
  Future<List<dynamic>> getVoices() async {
    await initialize();
    return await _flutterTts.getVoices;
  }

  /// Set language (for future multi-language support)
  Future<void> setLanguage(String language) async {
    await _flutterTts.setLanguage(language);
  }

  /// Set speech rate (0.0 to 1.0)
  /// 0.5 = slower (better for elderly)
  /// 1.0 = normal
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate.clamp(0.0, 1.0));
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Clean up resources
  void dispose() {
    _flutterTts.stop();
  }
}

// ============================================
// USAGE EXAMPLE:
// ============================================
// 
// final tts = TextToSpeechService();
// 
// // Speak a reminder
// await tts.speakReminder(
//   medicineName: "Paracetamol",
//   dosage: "500mg",
//   instructions: "Take with food",
// );
// 
// Output: "Time to take your medicine. Paracetamol, 500 milligrams. 
//          Take with food. Please take your medicine now."