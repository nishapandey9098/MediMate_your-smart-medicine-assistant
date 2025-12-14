// ============================================
// FILE: lib/features/scan/presentation/providers/scan_provider.dart
// ============================================
// This manages the state of scanning operations

// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/scan_repository.dart';
import '../../domain/entities/scan.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Repository provider
final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  return ScanRepository();
});

// Stream of user's scans (real-time updates)
final userScansProvider = StreamProvider<List<Scan>>((ref) {
  final userId = ref.watch(authRepositoryProvider).currentUserId;
  
  if (userId == null) {
    return Stream.value([]);
  }
  
  return ref.watch(scanRepositoryProvider).getUserScans(userId);
});

// Scan statistics provider
final scanStatisticsProvider = FutureProvider((ref) async {
  final userId = ref.watch(authRepositoryProvider).currentUserId;
  
  if (userId == null) {
    return ScanStatistics(
      totalScans: 0,
      successfulScans: 0,
      averageConfidence: 0.0,
    );
  }
  
  return ref.watch(scanRepositoryProvider).getStatistics(userId);
});

// Scan controller state
class ScanState {
  final bool isScanning;
  final bool isProcessing;
  final double progress;
  final String? error;
  final String? successMessage;
  final Scan? currentScan;

  ScanState({
    this.isScanning = false,
    this.isProcessing = false,
    this.progress = 0.0,
    this.error,
    this.successMessage,
    this.currentScan,
  });

  ScanState copyWith({
    bool? isScanning,
    bool? isProcessing,
    double? progress,
    String? error,
    String? successMessage,
    Scan? currentScan,
  }) {
    return ScanState(
      isScanning: isScanning ?? this.isScanning,
      isProcessing: isProcessing ?? this.isProcessing,
      progress: progress ?? this.progress,
      error: error,
      successMessage: successMessage,
      currentScan: currentScan ?? this.currentScan,
    );
  }
}

// Scan controller
class ScanController extends StateNotifier<ScanState> {
  final ScanRepository _repository;
  final String _userId;

  ScanController(this._repository, this._userId) : super(ScanState());

  /// Process a captured image
  /// This is called after the user takes a photo
// In scanController processScan method:

Future<Scan?> processScan(String imagePath) async {
  state = state.copyWith(
    isProcessing: true,
    progress: 0.0,
    error: null,
  );

  try {
    state = state.copyWith(progress: 0.2);
    print('📸 Processing scan...');
    
    // Check authentication first
    print('🔍 Current user ID: $_userId');

    state = state.copyWith(progress: 0.5);
    final scan = await _repository.createScan(
      userId: _userId,
      imagePath: imagePath,
    );

    state = state.copyWith(progress: 0.8);
    final isDuplicate = await _repository.isDuplicateScan(
      userId: _userId,
      scannedText: scan.scannedText,
    );

    if (isDuplicate) {
      print('⚠️ Duplicate scan detected');
    }

    state = state.copyWith(
      isProcessing: false,
      progress: 1.0,
      currentScan: scan,
      successMessage: 'Scan processed successfully!',
    );

    return scan;

  } catch (e, stackTrace) {
    print('❌ Error processing scan: $e');
    print('📍 Stack trace: $stackTrace');
    
    // ✅ Better error message
    String errorMessage = 'Failed to process scan: $e';
    
    if (e.toString().contains('permission-denied')) {
      errorMessage = 'Permission denied. Please log out and log in again to refresh your session.';
    }
    
    state = state.copyWith(
      isProcessing: false,
      progress: 0.0,
      error: errorMessage,
    );
    return null;
  }
}

  /// Delete a scan
  Future<void> deleteScan(Scan scan) async {
    try {
      await _repository.deleteScan(
        userId: _userId,
        scanId: scan.id,
        localImagePath: scan.localImagePath,
      );
      
      state = state.copyWith(
        successMessage: 'Scan deleted',
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete scan: $e',
      );
    }
  }

  /// Clear messages
  void clearMessages() {
    state = state.copyWith(
      error: null,
      successMessage: null,
    );
  }
}

// Scan controller provider
final scanControllerProvider = StateNotifierProvider<ScanController, ScanState>((ref) {
  final repository = ref.watch(scanRepositoryProvider);
  final userId = ref.watch(authRepositoryProvider).currentUserId ?? '';
  
  return ScanController(repository, userId);
});