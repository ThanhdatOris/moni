import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

import '../../models/budget_alert_model.dart';
import '../data/transaction_service.dart';

/// Service quản lý cảnh báo ngân sách
class BudgetAlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TransactionService _transactionService;
  final Logger _logger = Logger();

  BudgetAlertService({TransactionService? transactionService})
    : _transactionService = transactionService ?? TransactionService();

  /// Tạo cảnh báo ngân sách mới
  Future<String> setAlert(BudgetAlertModel alert) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final now = DateTime.now();
      final alertData = alert.copyWith(
        userId: user.uid,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budget_alerts')
          .add(alertData.toMap());

      _logger.i('Tạo cảnh báo ngân sách thành công: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.e('Lỗi tạo cảnh báo ngân sách: $e');
      throw Exception('Không thể tạo cảnh báo ngân sách: $e');
    }
  }

  /// Cập nhật ngưỡng cảnh báo
  Future<void> updateThreshold(String alertId, double threshold) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budget_alerts')
          .doc(alertId)
          .update({
            'threshold': threshold,
            'updated_at': Timestamp.fromDate(DateTime.now()),
          });

      _logger.i('Cập nhật ngưỡng cảnh báo thành công: $alertId');
    } catch (e) {
      _logger.e('Lỗi cập nhật ngưỡng cảnh báo: $e');
      throw Exception('Không thể cập nhật ngưỡng cảnh báo: $e');
    }
  }

  /// Vô hiệu hóa cảnh báo
  Future<void> disableAlert(String alertId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budget_alerts')
          .doc(alertId)
          .update({
            'is_enabled': false,
            'updated_at': Timestamp.fromDate(DateTime.now()),
          });

      _logger.i('Vô hiệu hóa cảnh báo thành công: $alertId');
    } catch (e) {
      _logger.e('Lỗi vô hiệu hóa cảnh báo: $e');
      throw Exception('Không thể vô hiệu hóa cảnh báo: $e');
    }
  }

  /// Bật cảnh báo
  Future<void> enableAlert(String alertId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budget_alerts')
          .doc(alertId)
          .update({
            'is_enabled': true,
            'snoozed_until': null,
            'updated_at': Timestamp.fromDate(DateTime.now()),
          });

      _logger.i('Bật cảnh báo thành công: $alertId');
    } catch (e) {
      _logger.e('Lỗi bật cảnh báo: $e');
      throw Exception('Không thể bật cảnh báo: $e');
    }
  }

  /// Tạm dừng cảnh báo trong một khoảng thời gian
  Future<void> snoozeAlert(String alertId, int durationHours) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final snoozedUntil = DateTime.now().add(Duration(hours: durationHours));

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budget_alerts')
          .doc(alertId)
          .update({
            'snoozed_until': Timestamp.fromDate(snoozedUntil),
            'updated_at': Timestamp.fromDate(DateTime.now()),
          });

      _logger.i(
        'Tạm dừng cảnh báo thành công: $alertId cho $durationHours giờ',
      );
    } catch (e) {
      _logger.e('Lỗi tạm dừng cảnh báo: $e');
      throw Exception('Không thể tạm dừng cảnh báo: $e');
    }
  }

  /// Xóa cảnh báo
  Future<void> deleteAlert(String alertId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budget_alerts')
          .doc(alertId)
          .delete();

      _logger.i('Xóa cảnh báo thành công: $alertId');
    } catch (e) {
      _logger.e('Lỗi xóa cảnh báo: $e');
      throw Exception('Không thể xóa cảnh báo: $e');
    }
  }

  /// Lấy danh sách tất cả cảnh báo
  Stream<List<BudgetAlertModel>> getAlerts() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value([]);
      }

      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budget_alerts')
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              return BudgetAlertModel.fromMap(doc.data(), doc.id);
            }).toList();
          });
    } catch (e) {
      _logger.e('Lỗi lấy danh sách cảnh báo: $e');
      return Stream.value([]);
    }
  }

  /// Lấy cảnh báo đang hoạt động
  Stream<List<BudgetAlertModel>> getActiveAlerts() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value([]);
      }

      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budget_alerts')
          .where('is_enabled', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => BudgetAlertModel.fromMap(doc.data(), doc.id))
                .where((alert) => alert.isActive)
                .toList();
          });
    } catch (e) {
      _logger.e('Lỗi lấy cảnh báo hoạt động: $e');
      return Stream.value([]);
    }
  }

  /// Kiểm tra và gửi thông báo nếu vượt ngưỡng
  Future<List<String>> checkAndNotify() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final alertsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budget_alerts')
          .where('is_enabled', isEqualTo: true)
          .get();

      final alerts = alertsSnapshot.docs
          .map((doc) => BudgetAlertModel.fromMap(doc.data(), doc.id))
          .where((alert) => alert.isActive)
          .toList();

      final notifications = <String>[];

      for (final alert in alerts) {
        final currentSpending = await _getCurrentSpending(alert.categoryId);

        if (currentSpending >= alert.threshold) {
          notifications.add(alert.message);
          _logger.i('Cảnh báo ngân sách được kích hoạt: ${alert.alertId}');
        }
      }

      return notifications;
    } catch (e) {
      _logger.e('Lỗi kiểm tra cảnh báo: $e');
      return [];
    }
  }

  /// Lấy tổng chi tiêu hiện tại cho danh mục
  Future<double> _getCurrentSpending(String? categoryId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      return await _transactionService.getTotalExpense(
        startDate: startOfMonth,
        endDate: endOfMonth,
        categoryId: categoryId,
      );
    } catch (e) {
      _logger.e('Lỗi lấy tổng chi tiêu: $e');
      return 0.0;
    }
  }

  /// Lấy chi tiết một cảnh báo
  Future<BudgetAlertModel?> getAlert(String alertId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budget_alerts')
          .doc(alertId)
          .get();

      if (doc.exists && doc.data() != null) {
        return BudgetAlertModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      _logger.e('Lỗi lấy chi tiết cảnh báo: $e');
      return null;
    }
  }

  /// Cập nhật thông điệp cảnh báo
  Future<void> updateMessage(String alertId, String message) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budget_alerts')
          .doc(alertId)
          .update({
            'message': message,
            'updated_at': Timestamp.fromDate(DateTime.now()),
          });

      _logger.i('Cập nhật thông điệp cảnh báo thành công: $alertId');
    } catch (e) {
      _logger.e('Lỗi cập nhật thông điệp cảnh báo: $e');
      throw Exception('Không thể cập nhật thông điệp cảnh báo: $e');
    }
  }
}
