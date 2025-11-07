import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/transaction_model.dart';

/// Service quản lý giới hạn chi tiêu
class SpendingLimitService {
  static const String _limitsKey = 'spending_limits';
  static const String _spendingHistoryKey = 'spending_history';
  static const String _notificationSettingsKey = 'limit_notifications';

  final Logger _logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Lưu giới hạn chi tiêu
  Future<void> setSpendingLimit(SpendingLimit limit) async {
    try {
      // Đồng bộ Firestore trước
      final user = _auth.currentUser;
      if (user != null) {
        final docRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('limits')
            .doc(limit.id);

        await docRef.set({
          'id': limit.id,
          'categoryId': limit.categoryId,
          'categoryName': limit.categoryName,
          'amount': limit.amount,
          'type': limit.type.toString(),
          'isActive': limit.isActive,
          'allowOverride': limit.allowOverride,
          'created_at': Timestamp.fromDate(limit.createdAt),
          'updated_at': Timestamp.fromDate(limit.updatedAt),
        }, SetOptions(merge: true));
      }

      final prefs = await SharedPreferences.getInstance();
      final limits = await getSpendingLimits();

      // Cập nhật hoặc thêm mới
      final existingIndex = limits.indexWhere(
          (l) => l.categoryId == limit.categoryId && l.type == limit.type);

      if (existingIndex >= 0) {
        limits[existingIndex] = limit;
      } else {
        limits.add(limit);
      }

      final limitsJson = limits.map((l) => l.toJson()).toList();
      await prefs.setString(_limitsKey, jsonEncode(limitsJson));
    } catch (e) {
      _logger.e('Error setting spending limit: $e');
    }
  }

  /// Lấy tất cả giới hạn chi tiêu
  Future<List<SpendingLimit>> getSpendingLimits() async {
    try {
      // Ưu tiên đọc Firestore
      final user = _auth.currentUser;
      if (user != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('limits')
            .orderBy('updated_at', descending: true)
            .get();

        final limits = snapshot.docs.map((doc) {
          final data = doc.data();
          return SpendingLimit(
            id: data['id'] ?? doc.id,
            categoryId: data['categoryId'] ?? 'all',
            categoryName: data['categoryName'] ?? 'Tất cả',
            amount: (data['amount'] as num?)?.toDouble() ?? 0,
            type: _parseLimitType(data['type'] as String?),
            isActive: data['isActive'] ?? true,
            allowOverride: data['allowOverride'] ?? false,
            createdAt:
                (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt:
                (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }).toList();

        // Cache local
        try {
          final prefs = await SharedPreferences.getInstance();
          final limitsJson = limits.map((l) => l.toJson()).toList();
          await prefs.setString(_limitsKey, jsonEncode(limitsJson));
        } catch (_) {}

        return limits;
      }

      // Fallback local
      final prefs = await SharedPreferences.getInstance();
      final limitsString = prefs.getString(_limitsKey);
      if (limitsString == null) return [];
      final limitsJson = jsonDecode(limitsString) as List;
      return limitsJson.map((json) => SpendingLimit.fromJson(json)).toList();
    } catch (e) {
      _logger.e('Error getting spending limits: $e');
      return [];
    }
  }

  /// Xóa giới hạn chi tiêu
  Future<void> removeSpendingLimit(String categoryId, LimitType type) async {
    try {
      // Xóa trên Firestore
      final user = _auth.currentUser;
      if (user != null) {
        // Tìm doc theo categoryId + type
        final query = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('limits')
            .where('categoryId', isEqualTo: categoryId)
            .where('type', isEqualTo: type.toString())
            .get();
        for (final doc in query.docs) {
          await doc.reference.delete();
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final limits = await getSpendingLimits();

      limits.removeWhere((l) => l.categoryId == categoryId && l.type == type);

      final limitsJson = limits.map((l) => l.toJson()).toList();
      await prefs.setString(_limitsKey, jsonEncode(limitsJson));
    } catch (e) {
      _logger.e('Error removing spending limit: $e');
    }
  }

  /// Kiểm tra giới hạn chi tiêu trước khi lưu transaction
  Future<LimitCheckResult> checkSpendingLimit({
    required double amount,
    required String categoryId,
    required DateTime transactionDate,
    required List<TransactionModel> recentTransactions,
  }) async {
    try {
      final limits = await getSpendingLimits();
      final warnings = <LimitWarning>[];

      for (final limit in limits) {
        if (limit.categoryId != categoryId && limit.categoryId != 'all') {
          continue;
        }

        final currentSpending = await _calculateCurrentSpending(
          categoryId: limit.categoryId,
          limitType: limit.type,
          transactionDate: transactionDate,
          recentTransactions: recentTransactions,
        );

        final newTotal = currentSpending + amount;
        final limitAmount = limit.amount;
        final usagePercentage = (newTotal / limitAmount) * 100;

        // Kiểm tra các ngưỡng cảnh báo
        if (newTotal > limitAmount) {
          warnings.add(LimitWarning(
            limit: limit,
            currentSpending: currentSpending,
            newTotal: newTotal,
            usagePercentage: usagePercentage,
            severity: WarningSeverity.critical,
            message:
                'Vượt quá giới hạn ${_getLimitTypeDisplayName(limit.type)}',
          ));
        } else if (usagePercentage >= 90) {
          warnings.add(LimitWarning(
            limit: limit,
            currentSpending: currentSpending,
            newTotal: newTotal,
            usagePercentage: usagePercentage,
            severity: WarningSeverity.high,
            message:
                'Sắp đạt giới hạn ${_getLimitTypeDisplayName(limit.type)} (${usagePercentage.toInt()}%)',
          ));
        } else if (usagePercentage >= 75) {
          warnings.add(LimitWarning(
            limit: limit,
            currentSpending: currentSpending,
            newTotal: newTotal,
            usagePercentage: usagePercentage,
            severity: WarningSeverity.medium,
            message:
                'Đã sử dụng ${usagePercentage.toInt()}% giới hạn ${_getLimitTypeDisplayName(limit.type)}',
          ));
        }
      }

      return LimitCheckResult(
        hasWarnings: warnings.isNotEmpty,
        warnings: warnings,
        shouldBlock: warnings.any((w) =>
            w.severity == WarningSeverity.critical &&
            !_isLimitOverrideAllowed(w.limit)),
      );
    } catch (e) {
      _logger.e('Error checking spending limit: $e');
      return LimitCheckResult(
          hasWarnings: false, warnings: [], shouldBlock: false);
    }
  }

  /// Tính toán chi tiêu hiện tại
  Future<double> _calculateCurrentSpending({
    required String categoryId,
    required LimitType limitType,
    required DateTime transactionDate,
    required List<TransactionModel> recentTransactions,
  }) async {
    final relevantTransactions = _filterTransactionsByPeriod(
      recentTransactions,
      limitType,
      transactionDate,
    );

    double totalSpent;
    if (categoryId == 'all') {
      totalSpent = relevantTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);
    } else {
      totalSpent = relevantTransactions
          .where((t) =>
              t.categoryId == categoryId && t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);
    }

    return totalSpent;
  }

  /// Lọc transactions theo khoảng thời gian
  List<TransactionModel> _filterTransactionsByPeriod(
    List<TransactionModel> transactions,
    LimitType limitType,
    DateTime referenceDate,
  ) {
    final now = referenceDate;
    DateTime startDate;

    switch (limitType) {
      case LimitType.daily:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case LimitType.weekly:
        final weekday = now.weekday;
        startDate = now.subtract(Duration(days: weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case LimitType.monthly:
        startDate = DateTime(now.year, now.month, 1);
        break;
    }

    return transactions
        .where((t) =>
            t.date.isAfter(startDate) &&
            t.date.isBefore(now.add(const Duration(days: 1))))
        .toList();
  }

  /// Kiểm tra có cho phép vượt giới hạn không
  bool _isLimitOverrideAllowed(SpendingLimit limit) {
    return limit.allowOverride;
  }

  /// Lấy tên hiển thị cho loại giới hạn
  String _getLimitTypeDisplayName(LimitType type) {
    switch (type) {
      case LimitType.daily:
        return 'hàng ngày';
      case LimitType.weekly:
        return 'hàng tuần';
      case LimitType.monthly:
        return 'hàng tháng';
    }
  }

  /// Lưu lịch sử chi tiêu
  Future<void> recordSpending({
    required String categoryId,
    required double amount,
    required DateTime date,
  }) async {
    try {
      // Ghi tổng hợp usage sang Firestore
      final user = _auth.currentUser;
      if (user != null) {
        final key = '${categoryId}_expense';
        final docRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('category_usage')
            .doc(key);

        await docRef.set({
          'categoryId': categoryId,
          'type': 'expense',
          'count': FieldValue.increment(1),
          'totalAmount': FieldValue.increment(amount),
          'lastUsed': Timestamp.fromDate(date),
        }, SetOptions(merge: true));

        // Cập nhật hourly usage
        final hour = date.hour.toString();
        await docRef.set({
          'hourlyUsage.$hour': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }

      final prefs = await SharedPreferences.getInstance();
      final historyString = prefs.getString(_spendingHistoryKey);

      List<SpendingRecord> history = [];
      if (historyString != null) {
        final historyJson = jsonDecode(historyString) as List;
        history =
            historyJson.map((json) => SpendingRecord.fromJson(json)).toList();
      }

      history.add(SpendingRecord(
        categoryId: categoryId,
        amount: amount,
        date: date,
      ));

      // Giữ lại 30 ngày gần nhất
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      history = history.where((r) => r.date.isAfter(cutoffDate)).toList();

      final historyJson = history.map((r) => r.toJson()).toList();
      await prefs.setString(_spendingHistoryKey, jsonEncode(historyJson));
    } catch (e) {
      _logger.e('Error recording spending: $e');
    }
  }

  /// Lấy thống kê chi tiêu
  Future<SpendingStats> getSpendingStats({
    required String categoryId,
    required LimitType limitType,
    DateTime? referenceDate,
  }) async {
    try {
      final date = referenceDate ?? DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      final historyString = prefs.getString(_spendingHistoryKey);

      if (historyString == null) {
        return SpendingStats(
          totalSpent: 0,
          transactionCount: 0,
          averageAmount: 0,
          period: limitType,
        );
      }

      final historyJson = jsonDecode(historyString) as List;
      final history =
          historyJson.map((json) => SpendingRecord.fromJson(json)).toList();

      final relevantRecords = _filterRecordsByPeriod(history, limitType, date);
      final categoryRecords = categoryId == 'all'
          ? relevantRecords
          : relevantRecords.where((r) => r.categoryId == categoryId).toList();

      final totalSpent = categoryRecords.fold(0.0, (sum, r) => sum + r.amount);
      final transactionCount = categoryRecords.length;
      final averageAmount = transactionCount > 0
          ? (totalSpent / transactionCount).toDouble()
          : 0.0;

      return SpendingStats(
        totalSpent: totalSpent,
        transactionCount: transactionCount,
        averageAmount: averageAmount,
        period: limitType,
      );
    } catch (e) {
      _logger.e('Error getting spending stats: $e');
      return SpendingStats(
        totalSpent: 0,
        transactionCount: 0,
        averageAmount: 0,
        period: limitType,
      );
    }
  }

  LimitType _parseLimitType(String? raw) {
    switch (raw) {
      case 'LimitType.daily':
      case 'daily':
        return LimitType.daily;
      case 'LimitType.weekly':
      case 'weekly':
        return LimitType.weekly;
      case 'LimitType.monthly':
      case 'monthly':
      default:
        return LimitType.monthly;
    }
  }

  /// Lọc records theo khoảng thời gian
  List<SpendingRecord> _filterRecordsByPeriod(
    List<SpendingRecord> records,
    LimitType limitType,
    DateTime referenceDate,
  ) {
    final now = referenceDate;
    DateTime startDate;

    switch (limitType) {
      case LimitType.daily:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case LimitType.weekly:
        final weekday = now.weekday;
        startDate = now.subtract(Duration(days: weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case LimitType.monthly:
        startDate = DateTime(now.year, now.month, 1);
        break;
    }

    return records
        .where((r) =>
            r.date.isAfter(startDate) &&
            r.date.isBefore(now.add(const Duration(days: 1))))
        .toList();
  }

  /// Cài đặt thông báo giới hạn
  Future<void> setNotificationSettings(
      LimitNotificationSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _notificationSettingsKey, jsonEncode(settings.toJson()));
    } catch (e) {
      _logger.e('Error setting notification settings: $e');
    }
  }

  /// Lấy cài đặt thông báo
  Future<LimitNotificationSettings> getNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsString = prefs.getString(_notificationSettingsKey);

      if (settingsString == null) {
        return LimitNotificationSettings.defaultSettings();
      }

      final settingsJson = jsonDecode(settingsString);
      return LimitNotificationSettings.fromJson(settingsJson);
    } catch (e) {
      _logger.e('Error getting notification settings: $e');
      return LimitNotificationSettings.defaultSettings();
    }
  }
}

/// Model cho giới hạn chi tiêu
class SpendingLimit {
  final String id;
  final String categoryId; // 'all' for all categories
  final String categoryName;
  final double amount;
  final LimitType type;
  final bool isActive;
  final bool allowOverride;
  final DateTime createdAt;
  final DateTime updatedAt;

  SpendingLimit({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.type,
    required this.isActive,
    required this.allowOverride,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'amount': amount,
      'type': type.toString(),
      'isActive': isActive,
      'allowOverride': allowOverride,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SpendingLimit.fromJson(Map<String, dynamic> json) {
    return SpendingLimit(
      id: json['id'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      amount: json['amount'].toDouble(),
      type: LimitType.values.firstWhere(
        (type) => type.toString() == json['type'],
      ),
      isActive: json['isActive'],
      allowOverride: json['allowOverride'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

/// Loại giới hạn
enum LimitType {
  daily,
  weekly,
  monthly,
}

/// Kết quả kiểm tra giới hạn
class LimitCheckResult {
  final bool hasWarnings;
  final List<LimitWarning> warnings;
  final bool shouldBlock;

  LimitCheckResult({
    required this.hasWarnings,
    required this.warnings,
    required this.shouldBlock,
  });
}

/// Cảnh báo giới hạn
class LimitWarning {
  final SpendingLimit limit;
  final double currentSpending;
  final double newTotal;
  final double usagePercentage;
  final WarningSeverity severity;
  final String message;

  LimitWarning({
    required this.limit,
    required this.currentSpending,
    required this.newTotal,
    required this.usagePercentage,
    required this.severity,
    required this.message,
  });
}

/// Mức độ cảnh báo
enum WarningSeverity {
  low,
  medium,
  high,
  critical,
}

/// Record chi tiêu
class SpendingRecord {
  final String categoryId;
  final double amount;
  final DateTime date;

  SpendingRecord({
    required this.categoryId,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory SpendingRecord.fromJson(Map<String, dynamic> json) {
    return SpendingRecord(
      categoryId: json['categoryId'],
      amount: json['amount'].toDouble(),
      date: DateTime.parse(json['date']),
    );
  }
}

/// Thống kê chi tiêu
class SpendingStats {
  final double totalSpent;
  final int transactionCount;
  final double averageAmount;
  final LimitType period;

  SpendingStats({
    required this.totalSpent,
    required this.transactionCount,
    required this.averageAmount,
    required this.period,
  });
}

/// Cài đặt thông báo giới hạn
class LimitNotificationSettings {
  final bool enableNotifications;
  final bool notifyAt75Percent;
  final bool notifyAt90Percent;
  final bool notifyAtLimit;
  final bool notifyAtOverLimit;

  LimitNotificationSettings({
    required this.enableNotifications,
    required this.notifyAt75Percent,
    required this.notifyAt90Percent,
    required this.notifyAtLimit,
    required this.notifyAtOverLimit,
  });

  Map<String, dynamic> toJson() {
    return {
      'enableNotifications': enableNotifications,
      'notifyAt75Percent': notifyAt75Percent,
      'notifyAt90Percent': notifyAt90Percent,
      'notifyAtLimit': notifyAtLimit,
      'notifyAtOverLimit': notifyAtOverLimit,
    };
  }

  factory LimitNotificationSettings.fromJson(Map<String, dynamic> json) {
    return LimitNotificationSettings(
      enableNotifications: json['enableNotifications'],
      notifyAt75Percent: json['notifyAt75Percent'],
      notifyAt90Percent: json['notifyAt90Percent'],
      notifyAtLimit: json['notifyAtLimit'],
      notifyAtOverLimit: json['notifyAtOverLimit'],
    );
  }

  factory LimitNotificationSettings.defaultSettings() {
    return LimitNotificationSettings(
      enableNotifications: true,
      notifyAt75Percent: true,
      notifyAt90Percent: true,
      notifyAtLimit: true,
      notifyAtOverLimit: true,
    );
  }
}
