import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/transaction_model.dart';
import '../core/logging_service.dart';

/// Manager để cache pending operations (thay thế SharedPreferences trực tiếp)
/// Sử dụng với Firestore Offline Persistence để đạt Offline-First
class LocalCacheManager {
  static const String _keyPendingCreates = 'pending_creates_v2';
  static const String _keyPendingUpdates = 'pending_updates_v2';
  static const String _keyPendingDeletes = 'pending_deletes_v2';
  static const String _keyLastSyncTimestamp = 'last_sync_timestamp';

  /// Lưu transaction pending create
  Future<void> savePendingCreate(TransactionModel transaction) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_keyPendingCreates) ?? [];
      
      // Remove duplicate nếu có
      final filtered = existing.where((json) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return map['transaction_id'] != transaction.transactionId;
      }).toList();
      
      filtered.add(jsonEncode(transaction.toJsonMap()));
      await prefs.setStringList(_keyPendingCreates, filtered);
      
      logInfo('Saved pending create: ${transaction.transactionId}');
    } catch (e) {
      logError('Error saving pending create', error: e);
    }
  }

  /// Lấy tất cả pending creates
  Future<List<TransactionModel>> getPendingCreates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getStringList(_keyPendingCreates) ?? [];
      
      return data.map((json) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return TransactionModel.fromJsonMap(map);
      }).toList();
    } catch (e) {
      logError('Error getting pending creates', error: e);
      return [];
    }
  }

  /// Xóa pending create sau khi sync thành công
  Future<void> removePendingCreate(String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_keyPendingCreates) ?? [];
      
      final filtered = existing.where((json) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return map['transaction_id'] != transactionId;
      }).toList();
      
      await prefs.setStringList(_keyPendingCreates, filtered);
      logInfo('Removed pending create: $transactionId');
    } catch (e) {
      logError('Error removing pending create', error: e);
    }
  }

  /// Lưu transaction pending update
  Future<void> savePendingUpdate(TransactionModel transaction) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_keyPendingUpdates) ?? [];
      
      final filtered = existing.where((json) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return map['transaction_id'] != transaction.transactionId;
      }).toList();
      
      filtered.add(jsonEncode(transaction.toJsonMap()));
      await prefs.setStringList(_keyPendingUpdates, filtered);
      
      logInfo('Saved pending update: ${transaction.transactionId}');
    } catch (e) {
      logError('Error saving pending update', error: e);
    }
  }

  /// Lấy tất cả pending updates
  Future<List<TransactionModel>> getPendingUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getStringList(_keyPendingUpdates) ?? [];
      
      return data.map((json) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return TransactionModel.fromJsonMap(map);
      }).toList();
    } catch (e) {
      logError('Error getting pending updates', error: e);
      return [];
    }
  }

  /// Xóa pending update
  Future<void> removePendingUpdate(String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_keyPendingUpdates) ?? [];
      
      final filtered = existing.where((json) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return map['transaction_id'] != transactionId;
      }).toList();
      
      await prefs.setStringList(_keyPendingUpdates, filtered);
      logInfo('Removed pending update: $transactionId');
    } catch (e) {
      logError('Error removing pending update', error: e);
    }
  }

  /// Lưu pending delete
  Future<void> savePendingDelete(String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_keyPendingDeletes) ?? [];
      
      if (!existing.contains(transactionId)) {
        existing.add(transactionId);
        await prefs.setStringList(_keyPendingDeletes, existing);
        logInfo('Saved pending delete: $transactionId');
      }
    } catch (e) {
      logError('Error saving pending delete', error: e);
    }
  }

  /// Lấy tất cả pending deletes
  Future<List<String>> getPendingDeletes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_keyPendingDeletes) ?? [];
    } catch (e) {
      logError('Error getting pending deletes', error: e);
      return [];
    }
  }

  /// Xóa pending delete
  Future<void> removePendingDelete(String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_keyPendingDeletes) ?? [];
      
      existing.remove(transactionId);
      await prefs.setStringList(_keyPendingDeletes, existing);
      logInfo('Removed pending delete: $transactionId');
    } catch (e) {
      logError('Error removing pending delete', error: e);
    }
  }

  /// Cập nhật timestamp của lần sync cuối
  Future<void> updateLastSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastSyncTimestamp, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      logError('Error updating sync timestamp', error: e);
    }
  }

  /// Lấy timestamp của lần sync cuối
  Future<DateTime?> getLastSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_keyLastSyncTimestamp);
      return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
    } catch (e) {
      logError('Error getting sync timestamp', error: e);
      return null;
    }
  }

  /// Kiểm tra có pending operations không
  Future<bool> hasPendingOperations() async {
    final creates = await getPendingCreates();
    final updates = await getPendingUpdates();
    final deletes = await getPendingDeletes();
    return creates.isNotEmpty || updates.isNotEmpty || deletes.isNotEmpty;
  }

  /// Clear tất cả pending operations
  Future<void> clearAllPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPendingCreates);
      await prefs.remove(_keyPendingUpdates);
      await prefs.remove(_keyPendingDeletes);
      logInfo('Cleared all pending operations');
    } catch (e) {
      logError('Error clearing pending operations', error: e);
    }
  }
}

