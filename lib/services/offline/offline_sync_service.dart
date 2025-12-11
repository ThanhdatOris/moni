import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../core/logging_service.dart';
import '../data/category_service.dart';
import '../data/transaction_service.dart';
import 'offline_service.dart';

/// Service quản lý sync dữ liệu offline với cloud
class OfflineSyncService {
  final OfflineService _offlineService;
  final TransactionService _transactionService;
  final CategoryService _categoryService;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  OfflineSyncService({
    required OfflineService offlineService,
    required TransactionService transactionService,
    required CategoryService categoryService,
  }) : _offlineService = offlineService,
       _transactionService = transactionService,
       _categoryService = categoryService;

  /// Bắt đầu monitor connectivity để auto-sync
  void startConnectivityMonitoring() {
    _connectivitySubscription?.cancel();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (!results.contains(ConnectivityResult.none)) {
        // Có kết nối internet - trigger auto sync
        _performAutoSync();
      }
    });
  }

  /// Dừng monitor connectivity
  void stopConnectivityMonitoring() {
    _connectivitySubscription?.cancel();
  }

  /// Sync tất cả dữ liệu offline
  Future<SyncResult> syncAllOfflineData() async {
    try {
      if (!await _offlineService.isOnline) {
        return SyncResult.failure('Không có kết nối internet');
      }

      final result = SyncResult();

      // Sync new offline transactions (create)
      final transactionResult = await _syncOfflineTransactions();
      result.mergeWith(transactionResult);

      // Sync pending updates
      final updateResult = await _syncPendingUpdates();
      result.mergeWith(updateResult);

      // Sync pending deletes
      final deleteResult = await _syncPendingDeletes();
      result.mergeWith(deleteResult);

      // Sync categories nếu cần
      final categoryResult = await _syncOfflineCategories();
      result.mergeWith(categoryResult);

      logInfo(
        'Sync tất cả dữ liệu offline hoàn tất',
        data: {
          'totalSuccess': result.successCount,
          'totalFailed': result.failedCount,
          'hasError': result.hasError,
        },
      );

      return result;
    } catch (e) {
      logError('Lỗi sync tất cả dữ liệu offline', error: e);
      return SyncResult.failure('Lỗi sync: $e');
    }
  }

  /// Sync giao dịch offline
  Future<SyncResult> _syncOfflineTransactions() async {
    try {
      final offlineTransactions = await _offlineService
          .getOfflineTransactions();
      if (offlineTransactions.isEmpty) {
        return SyncResult.success();
      }

      final result = SyncResult();

      for (final transaction in offlineTransactions) {
        try {
          // Tạo transaction mới trên cloud
          await _transactionService.createTransaction(transaction);

          // Xóa khỏi offline storage
          await _offlineService.removeOfflineTransaction(
            transaction.transactionId,
          );

          result.successCount++;
          logInfo('Sync thành công transaction: ${transaction.transactionId}');
        } catch (e) {
          result.failedCount++;
          result.errors.add('Transaction ${transaction.transactionId}: $e');
          logError(
            'Lỗi sync transaction ${transaction.transactionId}',
            error: e,
          );
        }
      }

      return result;
    } catch (e) {
      logError('Lỗi sync offline transactions', error: e);
      return SyncResult.failure('Lỗi sync transactions: $e');
    }
  }

  /// Sync categories offline
  Future<SyncResult> _syncOfflineCategories() async {
    try {
      final offlineCategories = await _offlineService.getOfflineCategories();
      if (offlineCategories.isEmpty) {
        return SyncResult.success();
      }

      final result = SyncResult();

      for (final category in offlineCategories) {
        try {
          // Tạo category mới trên cloud
          await _categoryService.createCategory(category);

          // Xóa khỏi offline storage
          await _offlineService.removeOfflineCategory(category.categoryId);

          result.successCount++;
          logInfo('Sync thành công category: ${category.categoryId}');
        } catch (e) {
          result.failedCount++;
          result.errors.add('Category ${category.categoryId}: $e');
          logError('Lỗi sync category ${category.categoryId}', error: e);
        }
      }

      return result;
    } catch (e) {
      logError('Lỗi sync offline categories', error: e);
      return SyncResult.failure('Lỗi sync categories: $e');
    }
  }

  /// Sync pending updates với retry mechanism
  Future<SyncResult> _syncPendingUpdates() async {
    try {
      final pendingUpdates = await _offlineService.getPendingUpdates();
      if (pendingUpdates.isEmpty) {
        return SyncResult.success();
      }

      final result = SyncResult();

      for (final pending in pendingUpdates) {
        if (!pending.canRetry) {
          // Đã hết số lần retry, skip
          continue;
        }

        try {
          // Gọi update online trực tiếp (bỏ qua connectivity check)
          await _transactionService.updateTransaction(pending.data);

          // Xóa khỏi pending queue
          await _offlineService.removePendingUpdate(pending.data.transactionId);

          result.successCount++;
          logInfo(
            'Sync thành công pending update: ${pending.data.transactionId}',
          );
        } catch (e) {
          // Increment retry count
          final canContinue = await _offlineService.incrementPendingUpdateRetry(
            pending.data.transactionId,
          );

          if (!canContinue) {
            result.failedCount++;
            result.errors.add(
              'Update ${pending.data.transactionId}: đã hết retry',
            );
          } else {
            result.failedCount++;
            result.errors.add('Update ${pending.data.transactionId}: $e');
          }

          logError(
            'Lỗi sync pending update ${pending.data.transactionId}',
            error: e,
          );
        }
      }

      return result;
    } catch (e) {
      logError('Lỗi sync pending updates', error: e);
      return SyncResult.failure('Lỗi sync updates: $e');
    }
  }

  /// Sync pending deletes với retry mechanism
  Future<SyncResult> _syncPendingDeletes() async {
    try {
      final pendingDeletes = await _offlineService.getPendingDeletes();
      if (pendingDeletes.isEmpty) {
        return SyncResult.success();
      }

      final result = SyncResult();

      for (final pending in pendingDeletes) {
        if (!pending.canRetry) {
          continue;
        }

        try {
          // Gọi delete online trực tiếp (bỏ qua connectivity check)
          await _transactionService.deleteTransaction(pending.data);

          // Xóa khỏi pending queue
          await _offlineService.removePendingDelete(pending.data);

          result.successCount++;
          logInfo('Sync thành công pending delete: ${pending.data}');
        } catch (e) {
          // Increment retry count
          final canContinue = await _offlineService.incrementPendingDeleteRetry(
            pending.data,
          );

          if (!canContinue) {
            result.failedCount++;
            result.errors.add('Delete ${pending.data}: đã hết retry');
          } else {
            result.failedCount++;
            result.errors.add('Delete ${pending.data}: $e');
          }

          logError('Lỗi sync pending delete ${pending.data}', error: e);
        }
      }

      return result;
    } catch (e) {
      logError('Lỗi sync pending deletes', error: e);
      return SyncResult.failure('Lỗi sync deletes: $e');
    }
  }

  /// Auto sync khi có kết nối (không throw exception)
  Future<void> _performAutoSync() async {
    try {
      logInfo('Bắt đầu auto-sync dữ liệu offline');

      final result = await syncAllOfflineData();

      if (result.hasError) {
        logWarning(
          'Auto-sync có lỗi',
          data: {
            'successCount': result.successCount,
            'failedCount': result.failedCount,
            'errors': result.errors,
          },
        );
      } else {
        logInfo(
          'Auto-sync thành công',
          data: {'successCount': result.successCount},
        );
      }
    } catch (e) {
      logError('Lỗi auto-sync', error: e);
    }
  }

  /// Kiểm tra có dữ liệu offline cần sync không
  Future<bool> hasOfflineDataToSync() async {
    try {
      final transactions = await _offlineService.getOfflineTransactions();
      final categories = await _offlineService.getOfflineCategories();

      return transactions.isNotEmpty || categories.isNotEmpty;
    } catch (e) {
      logError('Lỗi kiểm tra dữ liệu offline', error: e);
      return false;
    }
  }

  /// Get thống kê offline data
  Future<OfflineDataStats> getOfflineDataStats() async {
    try {
      final transactions = await _offlineService.getOfflineTransactions();
      final categories = await _offlineService.getOfflineCategories();
      final lastSync = await _offlineService.getLastSyncTime();

      return OfflineDataStats(
        transactionCount: transactions.length,
        categoryCount: categories.length,
        lastSyncTime: lastSync,
        isOnline: await _offlineService.isOnline,
      );
    } catch (e) {
      logError('Lỗi lấy thống kê offline', error: e);
      return OfflineDataStats.empty();
    }
  }

  void dispose() {
    stopConnectivityMonitoring();
  }
}

/// Kết quả sync dữ liệu
class SyncResult {
  int successCount;
  int failedCount;
  List<String> errors;

  SyncResult({
    this.successCount = 0,
    this.failedCount = 0,
    List<String>? errors,
  }) : errors = errors ?? [];

  factory SyncResult.success() => SyncResult();
  factory SyncResult.failure(String error) =>
      SyncResult(failedCount: 1, errors: [error]);

  bool get hasError => failedCount > 0 || errors.isNotEmpty;
  bool get isSuccess => !hasError && successCount > 0;
  bool get isEmpty => successCount == 0 && failedCount == 0;

  void mergeWith(SyncResult other) {
    successCount += other.successCount;
    failedCount += other.failedCount;
    errors.addAll(other.errors);
  }
}

/// Thống kê dữ liệu offline
class OfflineDataStats {
  final int transactionCount;
  final int categoryCount;
  final DateTime? lastSyncTime;
  final bool isOnline;

  OfflineDataStats({
    required this.transactionCount,
    required this.categoryCount,
    required this.lastSyncTime,
    required this.isOnline,
  });

  factory OfflineDataStats.empty() => OfflineDataStats(
    transactionCount: 0,
    categoryCount: 0,
    lastSyncTime: null,
    isOnline: false,
  );

  bool get hasOfflineData => transactionCount > 0 || categoryCount > 0;

  int get totalOfflineItems => transactionCount + categoryCount;
}
