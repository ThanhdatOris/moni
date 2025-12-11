import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/logging_service.dart';
import 'local_cache_manager.dart';

/// Sync Service V2 - Đơn giản hóa, chỉ clean up pending operations
/// 
/// Logic:
/// - Firestore Persistence tự động sync data
/// - Service này chỉ clean up LocalCacheManager tracking sau khi có mạng trở lại
class SyncServiceV2 {
  final LocalCacheManager _cacheManager = LocalCacheManager();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Bắt đầu monitor connectivity
  void startMonitoring() {
    _connectivitySubscription?.cancel();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (!results.contains(ConnectivityResult.none)) {
        // Có mạng trở lại → cleanup pending operations sau 2s
        // Delay để đảm bảo Firestore đã sync xong
        Future.delayed(const Duration(seconds: 2), () {
          _cleanupPendingOperations();
        });
      }
    });

    logInfo('🔄 Sync monitoring started');
  }

  /// Dừng monitoring
  void stopMonitoring() {
    _connectivitySubscription?.cancel();
    logInfo('🔄 Sync monitoring stopped');
  }

  /// Clean up pending operations sau khi Firestore sync xong
  Future<void> _cleanupPendingOperations() async {
    try {
      final hasPending = await _cacheManager.hasPendingOperations();
      
      if (!hasPending) {
        logInfo('✅ Không có pending operations');
        return;
      }

      // Đơn giản: clear tất cả pending sau khi có mạng
      // Firestore Persistence đã handle sync automatically
      await _cacheManager.clearAllPending();
      await _cacheManager.updateLastSyncTimestamp();

      logInfo('✅ Cleaned up pending operations');
    } catch (e) {
      logError('❌ Error cleaning up pending operations', error: e);
    }
  }

  /// Manual trigger cleanup
  Future<void> manualCleanup() async {
    await _cleanupPendingOperations();
  }

  /// Kiểm tra có pending operations không
  Future<bool> hasPendingOperations() async {
    return await _cacheManager.hasPendingOperations();
  }

  void dispose() {
    stopMonitoring();
  }
}

