import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moni/constants/enums.dart';

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
      
      logInfo('Đã lưu offline user session', data: {
        'userId': userId,
        'userName': userName,
        'email': email ?? 'N/A',
        'isOfflineMode': !await isOnline,
      });
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
      existingData.add(jsonEncode(transactionWithId.toMap()));
      
      await prefs.setStringList(_keyOfflineTransactions, existingData);
      
      logInfo('Đã lưu giao dịch offline', data: {
        'transactionId': offlineId,
        'amount': transaction.amount,
        'note': transaction.note,
        'type': transaction.type.value,
      });

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
        return TransactionModel.fromMap(map, map['transaction_id'] ?? '');
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
      final data = categories.map((category) => jsonEncode(category.toMap())).toList();
      
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

  /// Đồng bộ dữ liệu offline lên cloud
  Future<List<String>> syncOfflineTransactions() async {
    try {
      if (!await isOnline) {
        throw Exception('Không có kết nối internet');
      }

      final offlineTransactions = await getOfflineTransactions();
      if (offlineTransactions.isEmpty) {
        logInfo('Không có giao dịch offline để sync');
        return [];
      }

      logInfo('Bắt đầu sync ${offlineTransactions.length} giao dịch offline');

      final syncedIds = <String>[];
      
      // Import và sử dụng TransactionService để sync
      // Tạm thời return empty list
      // TODO: Implement actual sync with TransactionService
      
      logInfo('Sync dữ liệu offline thành công: ${syncedIds.length} giao dịch');
      return syncedIds;
    } catch (e) {
      logError('Lỗi sync dữ liệu offline', error: e);
      throw Exception('Không thể đồng bộ dữ liệu: $e');
    }
  }

  /// Xóa dữ liệu offline sau khi sync thành công
  Future<void> clearSyncedOfflineData(List<String> syncedTransactionIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getStringList(_keyOfflineTransactions) ?? [];
      
      final remainingData = existingData.where((jsonStr) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return !syncedTransactionIds.contains(map['transaction_id']);
      }).toList();
      
      await prefs.setStringList(_keyOfflineTransactions, remainingData);
      
      // Cập nhật thời gian sync
      await prefs.setString(_keyLastSyncTime, DateTime.now().toIso8601String());
      
      logInfo('Đã xóa ${syncedTransactionIds.length} giao dịch offline đã sync');
    } catch (e) {
      logError('Lỗi xóa dữ liệu offline đã sync', error: e);
    }
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
}
