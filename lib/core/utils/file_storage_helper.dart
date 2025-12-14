// ============================================
// FILE 3: lib/core/utils/file_storage_helper.dart
// ============================================
// Helper class to manage local file storage
// This handles saving images to the device

import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileStorageHelper {
  // Get the directory where we'll save scan images
  static Future<String> getScansDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final scansDir = Directory('${appDir.path}/scans');
    
    // Create directory if it doesn't exist
    if (!await scansDir.exists()) {
      await scansDir.create(recursive: true);
    }
    
    return scansDir.path;
  }

  // Save an image file locally
  // Returns the path where it was saved
  static Future<String> saveImage({
    required String sourcePath,  // Where the camera saved it
    required String fileName,     // What to name it
  }) async {
    final scansDir = await getScansDirectory();
    final newPath = '$scansDir/$fileName';
    
    // Copy the image file to our scans directory
    final sourceFile = File(sourcePath);
    await sourceFile.copy(newPath);
    
    return newPath;
  }

  // Get a file from local storage
  static Future<File?> getImage(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  // Delete an image file
  static Future<void> deleteImage(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Get all scan images
  static Future<List<File>> getAllScans() async {
    final scansDir = await getScansDirectory();
    final directory = Directory(scansDir);
    
    if (await directory.exists()) {
      final files = directory.listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.jpg') || file.path.endsWith('.png'))
          .toList();
      
      return files;
    }
    
    return [];
  }
}