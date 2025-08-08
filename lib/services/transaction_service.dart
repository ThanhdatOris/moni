import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

import '../models/transaction_model.dart';
import 'environment_service.dart';
import 'offline_service.dart';

/// Service quản lý giao dịch tài chính
class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();
  final OfflineService _offlineService;
  // Chống spam log
  final Map<String, DateTime> _lastLogTimes = {};

  TransactionService({
    required OfflineService offlineService,
  }) : _offlineService = offlineService;

  /// Tạo giao dịch mới
  Future<String> createTransaction(TransactionModel transaction) async {
    try {
      // Kiểm tra kết nối internet
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = !connectivity.contains(ConnectivityResult.none);

      if (isOnline) {
        return await _createTransactionOnline(transaction);
      } else {
        return await _createTransactionOffline(transaction);
      }
    } catch (e) {
      _logger.e('Lỗi tạo giao dịch: $e');
      throw Exception('Không thể tạo giao dịch: $e');
    }
  }

  /// Tạo giao dịch online
  Future<String> _createTransactionOnline(TransactionModel transaction) async {
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

    _logger.i('Tạo giao dịch online thành công: ${docRef.id}');
    return docRef.id;
  }

  /// Tạo giao dịch offline
  Future<String> _createTransactionOffline(TransactionModel transaction) async {
    final userSession = await _offlineService.getOfflineUserSession();
    final userId = userSession['userId'];

    if (userId == null) {
      throw Exception('Không có session offline');
    }

    final transactionId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final transactionData = transaction.copyWith(
      transactionId: transactionId,
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );

    await _offlineService.saveOfflineTransaction(transactionData);

    _logger.i('Tạo giao dịch offline thành công: $transactionId');
    return transactionId;
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

  /// Lấy danh sách giao dịch của người dùng (hỗ trợ nhiều filter + orderBy + pagination)
  Stream<List<TransactionModel>> getTransactions({
    TransactionType? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    DocumentSnapshot? startAfterDocument,
  }) {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value([]);
      }

      // Chiến lược tránh lỗi index:
      // - Khi có lọc theo khoảng thời gian (date range), chỉ orderBy + where date,
      //   các filter khác (is_deleted/type/category) sẽ lọc ở client để giảm yêu cầu composite index.
      // - Khi không có date range, vẫn orderBy date và lọc client.
      // - Giữ fallback khi vẫn gặp lỗi.

      // Sẽ lọc client cho các điều kiện dưới đây
      final bool willFilterClientType = type != null;
      final bool willFilterClientCategory = categoryId != null;

      Query query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('date', descending: true);

      if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (startAfterDocument != null) {
        query = (query as Query<Map<String, dynamic>>)
            .startAfterDocument(startAfterDocument);
      }

      if (limit != null) {
        // Nếu phải lọc client (type/category), tăng limit để bù trừ phần bị loại bỏ
        final bool hasClientFilters =
            willFilterClientType || willFilterClientCategory;
        final int effectiveLimit = hasClientFilters ? (limit * 2) : limit;
        query = query.limit(effectiveLimit);
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

        // Lọc client để đảm bảo không cần composite index
        transactions = transactions
            .where((t) => !t.isDeleted)
            .where((t) => type == null ? true : t.type == type)
            .where(
                (t) => categoryId == null ? true : t.categoryId == categoryId)
            .toList();

        // Thực thi limit sau khi lọc
        if (limit != null && transactions.length > limit) {
          transactions = transactions.take(limit).toList();
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

      // Index-less strategy: chỉ where theo date + orderBy date, lọc client
      Query query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('date', descending: true);

      if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      double total = 0.0;

      for (final doc in snapshot.docs) {
        final map = doc.data() as Map<String, dynamic>;
        final model = TransactionModel.fromMap(map, doc.id);
        if (model.isDeleted) continue;
        if (model.type != TransactionType.income) continue;
        if (categoryId != null && model.categoryId != categoryId) continue;
        total += model.amount;
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
        final data = doc.data();
        if (data.isNotEmpty) {
          final map = data;
          final transaction = TransactionModel.fromMap(map, doc.id);

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

      // Index-less strategy: chỉ where theo date + orderBy date, lọc client
      Query query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('date', descending: true);

      if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      double total = 0.0;

      for (final doc in snapshot.docs) {
        final map = doc.data() as Map<String, dynamic>;
        final model = TransactionModel.fromMap(map, doc.id);
        if (model.isDeleted) continue;
        if (model.type != TransactionType.expense) continue;
        if (categoryId != null && model.categoryId != categoryId) continue;
        total += model.amount;
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
        final data = doc.data();
        if (data.isNotEmpty) {
          final map = data;
          final transaction = TransactionModel.fromMap(map, doc.id);

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

  /// Lấy giao dịch gần đây - tối ưu cho việc hiển thị trên home
  Stream<List<TransactionModel>> getRecentTransactions({int limit = 10}) {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value([]);
      }

      // Index-less friendly: chỉ orderBy date, lọc client
      Query query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(limit * 2);

      return query.snapshots().handleError((error) {
        _logger.e('Lỗi stream giao dịch gần đây: $error');
        // Nếu lỗi index, fallback về method không order
        if (error.toString().contains('failed-precondition') ||
            error.toString().contains('index')) {
          _logger.w('Sử dụng fallback query cho giao dịch gần đây');
          return _getRecentTransactionsFallback(limit);
        }
        return Stream.value(<TransactionModel>[]);
      }).map((snapshot) {
        var list = snapshot.docs
            .map((doc) {
              return TransactionModel.fromMap(
                  doc.data() as Map<String, dynamic>, doc.id);
            })
            .where((t) => !t.isDeleted)
            .toList();
        if (list.length > limit) list = list.take(limit).toList();
        return list;
      });
    } catch (e) {
      _logger.e('Lỗi lấy giao dịch gần đây: $e');
      return _getRecentTransactionsFallback(limit);
    }
  }

  /// Fallback method cho getRecentTransactions khi gặp lỗi index
  Stream<List<TransactionModel>> _getRecentTransactionsFallback(int limit) {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value([]);
      }

      // Query đơn giản nhất - không order trên server
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

        // Sắp xếp theo ngày mới nhất và limit trong client
        transactions.sort((a, b) => b.date.compareTo(a.date));

        if (transactions.length > limit) {
          transactions = transactions.take(limit).toList();
        }

        return transactions;
      });
    } catch (e) {
      _logger.e('Lỗi fallback giao dịch gần đây: $e');
      return Stream.value([]);
    }
  }

  /// Lấy giao dịch theo khoảng thời gian cho AI services
  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Truy vấn thân thiện index: orderBy date + where theo date, lọc client is_deleted
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('date', descending: true)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final transactions = snapshot.docs
          .map((doc) {
            return TransactionModel.fromMap(doc.data(), doc.id);
          })
          .where((t) => !t.isDeleted)
          .toList();

      // Sort by date descending
      transactions.sort((a, b) => b.date.compareTo(a.date));

      // Chỉ log ở debug mode và có throttling để tránh trùng lặp
      if (EnvironmentService.debugMode) {
        // Gom theo ngày để tránh spam với các request gần nhau
        final dayStart =
            DateTime(startDate.year, startDate.month, startDate.day);
        final dayEnd = DateTime(endDate.year, endDate.month, endDate.day);
        final String key =
            'getRange_${dayStart.toIso8601String()}_${dayEnd.toIso8601String()}';
        final now = DateTime.now();
        final last = _lastLogTimes[key];
        if (last == null || now.difference(last).inSeconds > 5) {
          _logger.d(
              '💡 Lấy ${transactions.length} giao dịch từ ${startDate.toIso8601String()} đến ${endDate.toIso8601String()}');
          _lastLogTimes[key] = now;
        }
      }
      return transactions;
    } catch (e) {
      _logger.e('Lỗi lấy giao dịch theo khoảng thời gian: $e');
      // Fallback: use the stream method and convert to list
      try {
        final stream = getTransactions(startDate: startDate, endDate: endDate);
        return await stream.first;
      } catch (fallbackError) {
        _logger.e('Lỗi fallback getTransactionsByDateRange: $fallbackError');
        return [];
      }
    }
  }
}
