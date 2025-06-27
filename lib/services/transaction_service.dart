import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

import '../models/transaction_model.dart';

/// Service quản lý giao dịch tài chính
class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  /// Tạo giao dịch mới
  Future<String> createTransaction(TransactionModel transaction) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final now = DateTime.now();
      final transactionData = transaction.copyWith(
        userId: user.uid,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .add(transactionData.toMap());

      _logger.i('Tạo giao dịch thành công: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.e('Lỗi tạo giao dịch: $e');
      throw Exception('Không thể tạo giao dịch: $e');
    }
  }

  /// Cập nhật giao dịch
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final updatedTransaction = transaction.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(transaction.transactionId)
          .update(updatedTransaction.toMap());

      _logger.i('Cập nhật giao dịch thành công: ${transaction.transactionId}');
    } catch (e) {
      _logger.e('Lỗi cập nhật giao dịch: $e');
      throw Exception('Không thể cập nhật giao dịch: $e');
    }
  }

  /// Soft delete giao dịch
  Future<void> deleteTransaction(String transactionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(transactionId)
          .update({
        'is_deleted': true,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });

      _logger.i('Xóa giao dịch thành công: $transactionId');
    } catch (e) {
      _logger.e('Lỗi xóa giao dịch: $e');
      throw Exception('Không thể xóa giao dịch: $e');
    }
  }

  /// Lấy danh sách giao dịch của người dùng
  Stream<List<TransactionModel>> getTransactions({
    TransactionType? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value([]);
      }

      // Đếm số lượng filter để quyết định strategy
      int filterCount = 0;
      if (type != null) filterCount++;
      if (categoryId != null) filterCount++;
      if (startDate != null) filterCount++;
      if (endDate != null) filterCount++;

      // Nếu có nhiều filter, sử dụng fallback để tránh composite index
      if (filterCount > 1) {
        _logger.i('Sử dụng fallback query do có nhiều filter: $filterCount');
        return _getFallbackTransactions(
            type, categoryId, startDate, endDate, limit);
      }

      // Query đơn giản với ít filter
      Query query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .where('is_deleted', isEqualTo: false);

      // Áp dụng filter đơn lẻ
      if (type != null) {
        query = query.where('type', isEqualTo: type.value);
      } else if (categoryId != null) {
        query = query.where('category_id', isEqualTo: categoryId);
      } else if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      } else if (endDate != null) {
        query = query.where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      // Chỉ orderBy khi không có date filter để tránh composite index
      if (startDate == null && endDate == null) {
        query = query.orderBy('date', descending: true);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots().handleError((error) {
        _logger.e('Lỗi stream giao dịch: $error');
        // Nếu lỗi index, fallback về query đơn giản
        if (error.toString().contains('failed-precondition') ||
            error.toString().contains('index')) {
          _logger.w('Sử dụng fallback query do lỗi index');
          return _getFallbackTransactions(
              type, categoryId, startDate, endDate, limit);
        }
        return Stream.value(<TransactionModel>[]);
      }).map((snapshot) {
        var transactions = snapshot.docs.map((doc) {
          return TransactionModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        // Sắp xếp trong client nếu cần
        if (startDate != null || endDate != null) {
          transactions.sort((a, b) => b.date.compareTo(a.date));
        }

        return transactions;
      });
    } catch (e) {
      _logger.e('Lỗi lấy danh sách giao dịch: $e');
      // Fallback khi có lỗi
      return _getFallbackTransactions(
          type, categoryId, startDate, endDate, limit);
    }
  }

  /// Fallback method khi gặp lỗi index
  Stream<List<TransactionModel>> _getFallbackTransactions(
    TransactionType? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  ) {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value([]);
      }

      // Query đơn giản nhất có thể - chỉ filter is_deleted
      Query query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .where('is_deleted', isEqualTo: false);

      return query.snapshots().map((snapshot) {
        var transactions = snapshot.docs.map((doc) {
          return TransactionModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        // Filter và sắp xếp trong client
        if (type != null) {
          transactions = transactions.where((t) => t.type == type).toList();
        }

        if (categoryId != null) {
          transactions =
              transactions.where((t) => t.categoryId == categoryId).toList();
        }

        if (startDate != null) {
          transactions = transactions
              .where((t) =>
                  t.date.isAfter(startDate.subtract(const Duration(days: 1))))
              .toList();
        }

        if (endDate != null) {
          transactions = transactions
              .where(
                  (t) => t.date.isBefore(endDate.add(const Duration(days: 1))))
              .toList();
        }

        // Sắp xếp theo date descending
        transactions.sort((a, b) => b.date.compareTo(a.date));

        if (limit != null && transactions.length > limit) {
          transactions = transactions.take(limit).toList();
        }

        return transactions;
      });
    } catch (e) {
      _logger.e('Lỗi fallback query: $e');
      return Stream.value([]);
    }
  }

  /// Lấy chi tiết một giao dịch
  Future<TransactionModel?> getTransaction(String transactionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(transactionId)
          .get();

      if (doc.exists && doc.data() != null) {
        return TransactionModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      _logger.e('Lỗi lấy chi tiết giao dịch: $e');
      return null;
    }
  }

  /// Gán danh mục cho giao dịch
  Future<void> setCategory(String transactionId, String categoryId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(transactionId)
          .update({
        'category_id': categoryId,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });

      _logger.i('Gán danh mục thành công cho giao dịch: $transactionId');
    } catch (e) {
      _logger.e('Lỗi gán danh mục: $e');
      throw Exception('Không thể gán danh mục: $e');
    }
  }

  /// Lấy tổng thu nhập trong khoảng thời gian
  Future<double> getTotalIncome({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0.0;

      Query query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .where('is_deleted', isEqualTo: false)
          .where('type', isEqualTo: TransactionType.income.value);

      if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (categoryId != null) {
        query = query.where('category_id', isEqualTo: categoryId);
      }

      final snapshot = await query.get();
      double total = 0.0;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += data['amount'] as double;
      }

      return total;
    } catch (e) {
      _logger.e('Lỗi tính tổng thu nhập: $e');
      // Fallback: lấy tất cả giao dịch và filter trong client
      if (e.toString().contains('failed-precondition') ||
          e.toString().contains('index')) {
        return _getTotalIncomeFallback(startDate, endDate, categoryId);
      }
      return 0.0;
    }
  }

  /// Fallback method cho getTotalIncome
  Future<double> _getTotalIncomeFallback(
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0.0;

      // Query đơn giản chỉ với is_deleted và type
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .where('is_deleted', isEqualTo: false)
          .where('type', isEqualTo: TransactionType.income.value)
          .get();

      double total = 0.0;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final transaction = TransactionModel.fromMap(data, doc.id);

        // Filter trong client
        bool shouldInclude = true;

        if (startDate != null && transaction.date.isBefore(startDate)) {
          shouldInclude = false;
        }

        if (endDate != null && transaction.date.isAfter(endDate)) {
          shouldInclude = false;
        }

        if (categoryId != null && transaction.categoryId != categoryId) {
          shouldInclude = false;
        }

        if (shouldInclude) {
          total += transaction.amount;
        }
      }

      return total;
    } catch (e) {
      _logger.e('Lỗi fallback tính tổng thu nhập: $e');
      return 0.0;
    }
  }

  /// Lấy tổng chi tiêu trong khoảng thời gian
  Future<double> getTotalExpense({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0.0;

      Query query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .where('is_deleted', isEqualTo: false)
          .where('type', isEqualTo: TransactionType.expense.value);

      if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (categoryId != null) {
        query = query.where('category_id', isEqualTo: categoryId);
      }

      final snapshot = await query.get();
      double total = 0.0;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += data['amount'] as double;
      }

      return total;
    } catch (e) {
      _logger.e('Lỗi tính tổng chi tiêu: $e');
      // Fallback: lấy tất cả giao dịch và filter trong client
      if (e.toString().contains('failed-precondition') ||
          e.toString().contains('index')) {
        return _getTotalExpenseFallback(startDate, endDate, categoryId);
      }
      return 0.0;
    }
  }

  /// Fallback method cho getTotalExpense
  Future<double> _getTotalExpenseFallback(
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0.0;

      // Query đơn giản chỉ với is_deleted và type
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .where('is_deleted', isEqualTo: false)
          .where('type', isEqualTo: TransactionType.expense.value)
          .get();

      double total = 0.0;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final transaction = TransactionModel.fromMap(data, doc.id);

        // Filter trong client
        bool shouldInclude = true;

        if (startDate != null && transaction.date.isBefore(startDate)) {
          shouldInclude = false;
        }

        if (endDate != null && transaction.date.isAfter(endDate)) {
          shouldInclude = false;
        }

        if (categoryId != null && transaction.categoryId != categoryId) {
          shouldInclude = false;
        }

        if (shouldInclude) {
          total += transaction.amount;
        }
      }

      return total;
    } catch (e) {
      _logger.e('Lỗi fallback tính tổng chi tiêu: $e');
      return 0.0;
    }
  }

  /// Lấy số dư hiện tại
  Future<double> getCurrentBalance() async {
    try {
      final totalIncome = await getTotalIncome();
      final totalExpense = await getTotalExpense();
      return totalIncome - totalExpense;
    } catch (e) {
      _logger.e('Lỗi tính số dư: $e');
      return 0.0;
    }
  }

  /// Lấy giao dịch gần đây
  Stream<List<TransactionModel>> getRecentTransactions({int limit = 10}) {
    return getTransactions(limit: limit);
  }
}
