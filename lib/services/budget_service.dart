import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

import '../models/budget_model.dart';
import 'base_service.dart';

/// Budget Service - Quản lý ngân sách đơn giản và hiệu quả
class BudgetService extends BaseService {
  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;
  BudgetService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  /// Tạo ngân sách mới
  Future<String> createBudget(BudgetModel budget) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .add(budget.toFirestore());

      _logger.i('Tạo ngân sách thành công: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.e('Lỗi tạo ngân sách: $e');
      throw Exception('Không thể tạo ngân sách: $e');
    }
  }

  /// Cập nhật ngân sách
  Future<void> updateBudget(BudgetModel budget) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .doc(budget.id)
          .update(budget.toFirestore());

      _logger.i('Cập nhật ngân sách thành công: ${budget.id}');
    } catch (e) {
      _logger.e('Lỗi cập nhật ngân sách: $e');
      throw Exception('Không thể cập nhật ngân sách: $e');
    }
  }

  /// Xóa ngân sách
  Future<void> deleteBudget(String budgetId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .doc(budgetId)
          .delete();

      _logger.i('Xóa ngân sách thành công: $budgetId');
    } catch (e) {
      _logger.e('Lỗi xóa ngân sách: $e');
      throw Exception('Không thể xóa ngân sách: $e');
    }
  }

  /// Lấy danh sách ngân sách của người dùng
  Future<List<BudgetModel>> getUserBudgets() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .where('is_active', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => BudgetModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Lỗi lấy danh sách ngân sách: $e');
      return [];
    }
  }

  /// Lấy ngân sách theo category
  Future<BudgetModel?> getBudgetByCategory(String categoryId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .where('category_id', isEqualTo: categoryId)
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return BudgetModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      _logger.e('Lỗi lấy ngân sách theo category: $e');
      return null;
    }
  }

  /// Cập nhật chi tiêu hiện tại cho ngân sách
  Future<void> updateBudgetSpending(String categoryId, double amount) async {
    try {
      final budget = await getBudgetByCategory(categoryId);
      if (budget == null) {
        return; // Không có ngân sách cho category này
      }

      final updatedBudget = budget.copyWith(
        currentSpending: budget.currentSpending + amount,
        updatedAt: DateTime.now(),
      );

      await updateBudget(updatedBudget);

      // Kiểm tra và tạo cảnh báo nếu cần
      await _checkAndCreateAlert(updatedBudget);

      _logger.i('Cập nhật chi tiêu ngân sách: ${budget.categoryName}');
    } catch (e) {
      _logger.e('Lỗi cập nhật chi tiêu ngân sách: $e');
    }
  }

  /// Reset ngân sách hàng tháng
  Future<void> resetMonthlyBudgets() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return;
      }

      final budgets = await getUserBudgets();
      final now = DateTime.now();
      final newStartDate = DateTime(now.year, now.month, 1);
      final newEndDate = DateTime(now.year, now.month + 1, 0);

      for (final budget in budgets) {
        // Chỉ reset nếu đã hết tháng
        if (now.isAfter(budget.endDate)) {
          final resetBudget = budget.copyWith(
            currentSpending: 0.0,
            startDate: newStartDate,
            endDate: newEndDate,
            updatedAt: now,
          );

          await updateBudget(resetBudget);

          // Tạo cảnh báo reset
          await _createAlert(
            budgetId: budget.id,
            message: 'Ngân sách ${budget.categoryName} đã được reset cho tháng mới',
            type: BudgetAlertType.reset,
          );
        }
      }

      _logger.i('Reset ngân sách hàng tháng thành công');
    } catch (e) {
      _logger.e('Lỗi reset ngân sách hàng tháng: $e');
    }
  }

  /// Lấy thống kê ngân sách
  Future<Map<String, dynamic>> getBudgetStats() async {
    try {
      final budgets = await getUserBudgets();
      if (budgets.isEmpty) {
        return {
          'totalBudgets': 0,
          'totalLimit': 0.0,
          'totalSpending': 0.0,
          'averageUtilization': 0.0,
          'overBudgetCount': 0,
          'warningCount': 0,
        };
      }

      final totalLimit = budgets.fold(0.0, (sum, b) => sum + b.monthlyLimit);
      final totalSpending = budgets.fold(0.0, (sum, b) => sum + b.currentSpending);
      final averageUtilization = totalLimit > 0 ? totalSpending / totalLimit : 0.0;
      final overBudgetCount = budgets.where((b) => b.isOverBudget).length;
      final warningCount = budgets.where((b) => b.isNearLimit && !b.isOverBudget).length;

      return {
        'totalBudgets': budgets.length,
        'totalLimit': totalLimit,
        'totalSpending': totalSpending,
        'averageUtilization': averageUtilization,
        'overBudgetCount': overBudgetCount,
        'warningCount': warningCount,
      };
    } catch (e) {
      _logger.e('Lỗi lấy thống kê ngân sách: $e');
      return {};
    }
  }

  /// Tạo cảnh báo ngân sách
  Future<void> _createAlert({
    required String budgetId,
    required String message,
    required BudgetAlertType type,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return;
      }

      final alert = BudgetAlert(
        id: '',
        budgetId: budgetId,
        message: message,
        type: type,
        createdAt: DateTime.now(),
        isRead: false,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budget_alerts')
          .add(alert.toFirestore());

      _logger.i('Tạo cảnh báo ngân sách: $message');
    } catch (e) {
      _logger.e('Lỗi tạo cảnh báo ngân sách: $e');
    }
  }

  /// Kiểm tra và tạo cảnh báo nếu cần
  Future<void> _checkAndCreateAlert(BudgetModel budget) async {
    if (budget.isOverBudget) {
      await _createAlert(
        budgetId: budget.id,
        message: 'Ngân sách ${budget.categoryName} đã vượt quá giới hạn!',
        type: BudgetAlertType.overBudget,
      );
    } else if (budget.isNearLimit) {
      await _createAlert(
        budgetId: budget.id,
        message: 'Ngân sách ${budget.categoryName} đã sử dụng ${(budget.utilizationRate * 100).toInt()}%',
        type: BudgetAlertType.nearLimit,
      );
    }
  }

  /// Lấy danh sách cảnh báo ngân sách
  Future<List<BudgetAlert>> getBudgetAlerts({int limit = 10}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budget_alerts')
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => BudgetAlert.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Lỗi lấy cảnh báo ngân sách: $e');
      return [];
    }
  }

  /// Đánh dấu cảnh báo đã đọc
  Future<void> markAlertAsRead(String alertId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return;
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budget_alerts')
          .doc(alertId)
          .update({'is_read': true});

      _logger.i('Đánh dấu cảnh báo đã đọc: $alertId');
    } catch (e) {
      _logger.e('Lỗi đánh dấu cảnh báo đã đọc: $e');
    }
  }
} 