import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:moni/constants/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../core/logging_service.dart';

/// Service xử lý offline functionality
class OfflineService {
  static const String _keyOfflineTransactions = 'offline_transactions';
  static const String _keyOfflineCategories = 'offline_categories';
  static const String _keyOfflineUserId = 'offline_user_id';
  static const String _keyOfflineUserName = 'offline_user_name';
  static const String _keyOfflineUserEmail = 'offline_user_email';
  static const String _keyLastSyncTime = 'last_sync_time';
  static const String _keyIsOfflineMode = 'is_offline_mode';
  // Pending operations for offline update/delete
  static const String _keyPendingUpdates = 'pending_updates';
  static const String _keyPendingDeletes = 'pending_deletes';
  static const int _maxRetryAttempts = 3;

  /// Kiểm tra trạng thái kết nối
  Future<bool> get isOnline async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      return !connectivityResults.contains(ConnectivityResult.none);
    } catch (e) {
      logError('Lỗi kiểm tra kết nối', error: e);
      return false;
    }
  }

  /// Lưu user session cho offline
  Future<void> saveOfflineUserSession({
    required String userId,
    required String userName,
    String? email,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyOfflineUserId, userId);
      await prefs.setString(_keyOfflineUserName, userName);
      if (email != null) {
        await prefs.setString(_keyOfflineUserEmail, email);
      }
      await prefs.setBool(_keyIsOfflineMode, !await isOnline);

      logInfo(
        'Đã lưu offline user session',
        data: {
          'userId': userId,
          'userName': userName,
          'email': email ?? 'N/A',
          'isOfflineMode': !await isOnline,
        },
      );
    } catch (e) {
      logError('Lỗi lưu offline user session', error: e);
    }
  }

  /// Lấy thông tin user offline
  Future<Map<String, String?>> getOfflineUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'userId': prefs.getString(_keyOfflineUserId),
        'userName': prefs.getString(_keyOfflineUserName),
        'email': prefs.getString(_keyOfflineUserEmail),
      };
    } catch (e) {
      logError('Lỗi lấy offline user session', error: e);
      return {'userId': null, 'userName': null, 'email': null};
    }
  }

  /// Kiểm tra xem có session offline không
  Future<bool> hasOfflineSession() async {
    final session = await getOfflineUserSession();
    return session['userId'] != null;
  }

  /// Bật chế độ offline
  Future<void> enableOfflineMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsOfflineMode, true);
      logInfo('Đã bật chế độ offline');
    } catch (e) {
      logError('Lỗi bật chế độ offline', error: e);
    }
  }

  /// Tắt chế độ offline
  Future<void> disableOfflineMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsOfflineMode, false);
      logInfo('Đã tắt chế độ offline');
    } catch (e) {
      logError('Lỗi tắt chế độ offline', error: e);
    }
  }

  /// Kiểm tra xem có đang ở chế độ offline không
  Future<bool> isOfflineMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsOfflineMode) ?? false;
    } catch (e) {
      logError('Lỗi kiểm tra offline mode', error: e);
      return false;
    }
  }

  /// Lưu giao dịch offline
  Future<String> saveOfflineTransaction(TransactionModel transaction) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getStringList(_keyOfflineTransactions) ?? [];

      // Tạo ID duy nhất cho offline transaction
      final offlineId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      final transactionWithId = transaction.copyWith(transactionId: offlineId);

      // Thêm transaction mới
      existingData.add(jsonEncode(transactionWithId.toJsonMap()));

      await prefs.setStringList(_keyOfflineTransactions, existingData);

      logInfo(
        'Đã lưu giao dịch offline',
        data: {
          'transactionId': offlineId,
          'amount': transaction.amount,
          'note': transaction.note,
          'type': transaction.type.value,
        },
      );

      return offlineId;
    } catch (e) {
      logError('Lỗi lưu giao dịch offline', error: e);
      throw Exception('Không thể lưu giao dịch offline: $e');
    }
  }

  /// Lấy danh sách giao dịch offline
  Future<List<TransactionModel>> getOfflineTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getStringList(_keyOfflineTransactions) ?? [];

      return data.map((jsonStr) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return TransactionModel.fromJsonMap(map);
      }).toList();
    } catch (e) {
      logError('Lỗi lấy giao dịch offline', error: e);
      return [];
    }
  }

  /// Lưu danh mục offline
  Future<void> saveOfflineCategories(List<CategoryModel> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = categories
          .map((category) => jsonEncode(category.toMap()))
          .toList();

      await prefs.setStringList(_keyOfflineCategories, data);

      logInfo('Đã lưu ${categories.length} danh mục offline');
    } catch (e) {
      logError('Lỗi lưu danh mục offline', error: e);
    }
  }

  /// Lấy danh sách danh mục offline
  Future<List<CategoryModel>> getOfflineCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getStringList(_keyOfflineCategories) ?? [];

      return data.map((jsonStr) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return CategoryModel.fromMap(map, map['category_id'] ?? '');
      }).toList();
    } catch (e) {
      logError('Lỗi lấy danh mục offline', error: e);
      return [];
    }
  }

  /// Xóa một giao dịch offline
  Future<void> removeOfflineTransaction(String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getStringList(_keyOfflineTransactions) ?? [];

      final filteredData = existingData.where((jsonStr) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return map['transaction_id'] != transactionId;
      }).toList();

      await prefs.setStringList(_keyOfflineTransactions, filteredData);

      logInfo('Đã xóa giao dịch offline: $transactionId');
    } catch (e) {
      logError('Lỗi xóa giao dịch offline', error: e);
    }
  }

  /// Xóa một category offline
  Future<void> removeOfflineCategory(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = prefs.getString(_keyOfflineCategories);

      if (categoriesJson == null) return;

      final categoriesList = jsonDecode(categoriesJson) as List;
      final filteredList = categoriesList.where((categoryJson) {
        final category = categoryJson as Map<String, dynamic>;
        return category['categoryId'] != categoryId;
      }).toList();

      await prefs.setString(_keyOfflineCategories, jsonEncode(filteredList));

      logInfo('Đã xóa category offline: $categoryId');
    } catch (e) {
      logError('Lỗi xóa category offline', error: e);
    }
  }

  /// Lấy thời gian sync cuối cùng
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncTimeStr = prefs.getString(_keyLastSyncTime);

      if (syncTimeStr == null) return null;

      return DateTime.parse(syncTimeStr);
    } catch (e) {
      logError('Lỗi lấy thời gian sync cuối', error: e);
      return null;
    }
  }

  // =====================================================
  // DEPRECATED METHODS - Legacy SharedPreferences-based sync
  // Firestore Persistence automatically handles offline sync
  // =====================================================

  /// @deprecated Không còn sử dụng - Firestore Persistence tự động handle sync
  /// Legacy method từ kiến trúc cũ dùng SharedPreferences
  @Deprecated(
    'Use Firestore Persistence instead - it handles sync automatically',
  )
  Future<List<String>> syncOfflineTransactions() async {
    logWarning(
      '⚠️ syncOfflineTransactions() is DEPRECATED. '
      'Firestore Persistence handles all offline sync automatically.',
    );
    return [];
  }

  /// @deprecated Không còn sử dụng - Firestore Persistence tự động handle sync
  @Deprecated(
    'Use Firestore Persistence instead - it handles sync automatically',
  )
  Future<void> clearSyncedOfflineData(List<String> syncedTransactionIds) async {
    logWarning(
      '⚠️ clearSyncedOfflineData() is DEPRECATED. '
      'Firestore Persistence handles cleanup automatically.',
    );
  }

  /// Xóa tất cả dữ liệu offline
  Future<void> clearAllOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyOfflineTransactions);
      await prefs.remove(_keyOfflineCategories);
      await prefs.remove(_keyOfflineUserId);
      await prefs.remove(_keyOfflineUserName);
      await prefs.remove(_keyOfflineUserEmail);
      await prefs.remove(_keyIsOfflineMode);

      logInfo('Đã xóa tất cả dữ liệu offline');
    } catch (e) {
      logError('Lỗi xóa dữ liệu offline', error: e);
    }
  }

  /// Kiểm tra xem có dữ liệu offline chưa sync không
  Future<bool> hasPendingOfflineData() async {
    final offlineTransactions = await getOfflineTransactions();
    return offlineTransactions.isNotEmpty;
  }

  /// Lấy thống kê dữ liệu offline
  Future<Map<String, dynamic>> getOfflineStats() async {
    try {
      final transactions = await getOfflineTransactions();
      final categories = await getOfflineCategories();
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString(_keyLastSyncTime);
      final isOfflineMode = await this.isOfflineMode();

      final totalIncome = transactions
          .where((t) => t.type == TransactionType.income)
          .fold<double>(0.0, (sum, t) => sum + t.amount);

      final totalExpense = transactions
          .where((t) => t.type == TransactionType.expense)
          .fold<double>(0.0, (sum, t) => sum + t.amount);

      return {
        'pendingTransactions': transactions.length,
        'pendingCategories': categories.length,
        'lastSyncTime': lastSync,
        'isOfflineMode': isOfflineMode,
        'totalPendingIncome': totalIncome,
        'totalPendingExpense': totalExpense,
        'netAmount': totalIncome - totalExpense,
      };
    } catch (e) {
      logError('Lỗi lấy thống kê offline', error: e);
      return {};
    }
  }

  /// Tạo temporary user ID cho offline mode
  String generateOfflineUserId() {
    return 'offline_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Kiểm tra xem user ID có phải là offline ID không
  bool isOfflineUserId(String userId) {
    return userId.startsWith('offline_');
  }

  // =====================================================
  // PENDING OPERATIONS - Update/Delete Offline Support
  // =====================================================

  /// Lưu pending update (giao dịch cần sync update khi có mạng)
  Future<void> savePendingUpdate(TransactionModel transaction) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getStringList(_keyPendingUpdates) ?? [];

      // Remove old pending update for same transaction if exists
      final filteredData = existingData.where((jsonStr) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return map['transaction_id'] != transaction.transactionId;
      }).toList();

      // Add new pending update with retry count
      final pendingData = {
        ...transaction.toJsonMap(),
        'pending_retry_count': 0,
        'pending_created_at': DateTime.now().toIso8601String(),
      };
      filteredData.add(jsonEncode(pendingData));

      await prefs.setStringList(_keyPendingUpdates, filteredData);

      logInfo(
        'Đã lưu pending update',
        data: {
          'transactionId': transaction.transactionId,
          'amount': transaction.amount,
        },
      );
    } catch (e) {
      logError('Lỗi lưu pending update', error: e);
      throw Exception('Không thể lưu pending update: $e');
    }
  }

  /// Lưu pending delete (giao dịch cần sync delete khi có mạng)
  Future<void> savePendingDelete(String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getStringList(_keyPendingDeletes) ?? [];

      // Avoid duplicate
      final pendingData = {
        'transaction_id': transactionId,
        'pending_retry_count': 0,
        'pending_created_at': DateTime.now().toIso8601String(),
      };

      // Check if already exists
      final alreadyExists = existingData.any((jsonStr) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return map['transaction_id'] == transactionId;
      });

      if (!alreadyExists) {
        existingData.add(jsonEncode(pendingData));
        await prefs.setStringList(_keyPendingDeletes, existingData);

        logInfo('Đã lưu pending delete: $transactionId');
      }
    } catch (e) {
      logError('Lỗi lưu pending delete', error: e);
      throw Exception('Không thể lưu pending delete: $e');
    }
  }

  /// Lấy danh sách pending updates
  Future<List<PendingOperation<TransactionModel>>> getPendingUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getStringList(_keyPendingUpdates) ?? [];

      return data.map((jsonStr) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return PendingOperation<TransactionModel>(
          data: TransactionModel.fromJsonMap(map),
          retryCount: map['pending_retry_count'] ?? 0,
          createdAt:
              DateTime.tryParse(map['pending_created_at'] ?? '') ??
              DateTime.now(),
        );
      }).toList();
    } catch (e) {
      logError('Lỗi lấy pending updates', error: e);
      return [];
    }
  }

  /// Lấy danh sách pending deletes
  Future<List<PendingOperation<String>>> getPendingDeletes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getStringList(_keyPendingDeletes) ?? [];

      return data.map((jsonStr) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return PendingOperation<String>(
          data: map['transaction_id'] ?? '',
          retryCount: map['pending_retry_count'] ?? 0,
          createdAt:
              DateTime.tryParse(map['pending_created_at'] ?? '') ??
              DateTime.now(),
        );
      }).toList();
    } catch (e) {
      logError('Lỗi lấy pending deletes', error: e);
      return [];
    }
  }

  /// Xóa pending update sau khi sync thành công
  Future<void> removePendingUpdate(String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getStringList(_keyPendingUpdates) ?? [];

      final filteredData = existingData.where((jsonStr) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return map['transaction_id'] != transactionId;
      }).toList();

      await prefs.setStringList(_keyPendingUpdates, filteredData);
      logInfo('Đã xóa pending update: $transactionId');
    } catch (e) {
      logError('Lỗi xóa pending update', error: e);
    }
  }

  /// Xóa pending delete sau khi sync thành công
  Future<void> removePendingDelete(String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getStringList(_keyPendingDeletes) ?? [];

      final filteredData = existingData.where((jsonStr) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return map['transaction_id'] != transactionId;
      }).toList();

      await prefs.setStringList(_keyPendingDeletes, filteredData);
      logInfo('Đã xóa pending delete: $transactionId');
    } catch (e) {
      logError('Lỗi xóa pending delete', error: e);
    }
  }

  /// Increment retry count for pending update
  Future<bool> incrementPendingUpdateRetry(String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getStringList(_keyPendingUpdates) ?? [];

      final updatedData = <String>[];
      bool shouldRemove = false;

      for (final jsonStr in existingData) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        if (map['transaction_id'] == transactionId) {
          final retryCount = (map['pending_retry_count'] ?? 0) + 1;
          if (retryCount >= _maxRetryAttempts) {
            shouldRemove = true;
            logWarning('Đã đạt max retry cho pending update: $transactionId');
            continue; // Skip this item (remove it)
          }
          map['pending_retry_count'] = retryCount;
        }
        updatedData.add(jsonEncode(map));
      }

      await prefs.setStringList(_keyPendingUpdates, updatedData);
      return !shouldRemove;
    } catch (e) {
      logError('Lỗi increment retry count', error: e);
      return false;
    }
  }

  /// Increment retry count for pending delete
  Future<bool> incrementPendingDeleteRetry(String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getStringList(_keyPendingDeletes) ?? [];

      final updatedData = <String>[];
      bool shouldRemove = false;

      for (final jsonStr in existingData) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        if (map['transaction_id'] == transactionId) {
          final retryCount = (map['pending_retry_count'] ?? 0) + 1;
          if (retryCount >= _maxRetryAttempts) {
            shouldRemove = true;
            logWarning('Đã đạt max retry cho pending delete: $transactionId');
            continue;
          }
          map['pending_retry_count'] = retryCount;
        }
        updatedData.add(jsonEncode(map));
      }

      await prefs.setStringList(_keyPendingDeletes, updatedData);
      return !shouldRemove;
    } catch (e) {
      logError('Lỗi increment retry count', error: e);
      return false;
    }
  }

  /// Update transaction trong local offline storage (cho UI update ngay lập tức)
  Future<void> updateOfflineTransaction(TransactionModel transaction) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getStringList(_keyOfflineTransactions) ?? [];

      final updatedData = existingData.map((jsonStr) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        if (map['transaction_id'] == transaction.transactionId) {
          return jsonEncode(transaction.toJsonMap());
        }
        return jsonStr;
      }).toList();

      await prefs.setStringList(_keyOfflineTransactions, updatedData);
      logInfo('Đã update offline transaction: ${transaction.transactionId}');
    } catch (e) {
      logError('Lỗi update offline transaction', error: e);
    }
  }

  /// Kiểm tra xem có pending operations không
  Future<bool> hasPendingOperations() async {
    final updates = await getPendingUpdates();
    final deletes = await getPendingDeletes();
    final offlineTransactions = await getOfflineTransactions();
    return updates.isNotEmpty ||
        deletes.isNotEmpty ||
        offlineTransactions.isNotEmpty;
  }

  /// Get pending operations count
  Future<int> getPendingOperationsCount() async {
    final updates = await getPendingUpdates();
    final deletes = await getPendingDeletes();
    final offlineTransactions = await getOfflineTransactions();
    return updates.length + deletes.length + offlineTransactions.length;
  }
}

/// Model cho pending operation với retry tracking
class PendingOperation<T> {
  final T data;
  final int retryCount;
  final DateTime createdAt;

  PendingOperation({
    required this.data,
    required this.retryCount,
    required this.createdAt,
  });

  bool get canRetry => retryCount < 3;
}
