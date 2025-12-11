import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:moni/constants/enums.dart';

import '../../models/report_model.dart';
import '../../models/transaction_model.dart';
import '../data/transaction_service.dart';

/// Service tạo và quản lý báo cáo tài chính
class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TransactionService _transactionService;
  final Logger _logger = Logger();

  ReportService({TransactionService? transactionService})
    : _transactionService = transactionService ?? TransactionService();

  /// Tạo báo cáo mới
  Future<String> generateReport({
    required ReportType type,
    required TimePeriod timePeriod,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      // Tính toán khoảng thời gian báo cáo
      final dateRange = _calculateDateRange(timePeriod, startDate, endDate);

      // Tạo dữ liệu báo cáo
      Map<String, dynamic> reportData;
      if (type == ReportType.byTime) {
        reportData = await _generateTimeBasedReport(
          dateRange.start,
          dateRange.end,
        );
      } else {
        reportData = await _generateCategoryBasedReport(
          dateRange.start,
          dateRange.end,
        );
      }

      final now = DateTime.now();
      final report = ReportModel(
        reportId: '', // Sẽ được Firestore tự tạo
        userId: user.uid,
        type: type,
        timePeriod: timePeriod,
        data: reportData,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('reports')
          .add(report.toMap());

      _logger.i('Tạo báo cáo thành công: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.e('Lỗi tạo báo cáo: $e');
      throw Exception('Không thể tạo báo cáo: $e');
    }
  }

  /// Xem báo cáo
  Future<ReportModel?> viewReport(String reportId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('reports')
          .doc(reportId)
          .get();

      if (doc.exists && doc.data() != null) {
        return ReportModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      _logger.e('Lỗi xem báo cáo: $e');
      return null;
    }
  }

  /// Xuất báo cáo dưới dạng string
  Future<String> exportReport(String reportId) async {
    try {
      final report = await viewReport(reportId);
      if (report == null) {
        throw Exception('Không tìm thấy báo cáo');
      }

      final buffer = StringBuffer();
      buffer.writeln('=== BÁO CÁO TÀI CHÍNH MONI ===');
      buffer.writeln('Loại báo cáo: ${_getReportTypeText(report.type)}');
      buffer.writeln(
        'Khoảng thời gian: ${_getTimePeriodText(report.timePeriod)}',
      );
      buffer.writeln('Ngày tạo: ${report.createdAt}');
      buffer.writeln('');

      // Xuất dữ liệu báo cáo
      buffer.writeln('=== DỮ LIỆU ===');
      report.data.forEach((key, value) {
        buffer.writeln('$key: $value');
      });

      _logger.i('Xuất báo cáo thành công: $reportId');
      return buffer.toString();
    } catch (e) {
      _logger.e('Lỗi xuất báo cáo: $e');
      throw Exception('Không thể xuất báo cáo: $e');
    }
  }

  /// Lấy danh sách báo cáo
  Stream<List<ReportModel>> getReports({
    ReportType? type,
    TimePeriod? timePeriod,
    int? limit,
  }) {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value([]);
      }

      Query query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('reports')
          .orderBy('created_at', descending: true);

      if (type != null) {
        query = query.where('type', isEqualTo: type.value);
      }

      if (timePeriod != null) {
        query = query.where('time_period', isEqualTo: timePeriod.value);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return ReportModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
      });
    } catch (e) {
      _logger.e('Lỗi lấy danh sách báo cáo: $e');
      return Stream.value([]);
    }
  }

  /// Xóa báo cáo
  Future<void> deleteReport(String reportId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('reports')
          .doc(reportId)
          .delete();

      _logger.i('Xóa báo cáo thành công: $reportId');
    } catch (e) {
      _logger.e('Lỗi xóa báo cáo: $e');
      throw Exception('Không thể xóa báo cáo: $e');
    }
  }

  /// Tạo báo cáo theo thời gian
  Future<Map<String, dynamic>> _generateTimeBasedReport(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final totalIncome = await _transactionService.getTotalIncome(
        startDate: startDate,
        endDate: endDate,
      );

      final totalExpense = await _transactionService.getTotalExpense(
        startDate: startDate,
        endDate: endDate,
      );

      final balance = totalIncome - totalExpense;

      // Lấy chi tiết giao dịch theo ngày
      final transactions = await _getTransactionsByDateRange(
        startDate,
        endDate,
      );
      final dailyData = _groupTransactionsByDay(transactions);

      return {
        'period_start': startDate.toIso8601String(),
        'period_end': endDate.toIso8601String(),
        'total_income': totalIncome,
        'total_expense': totalExpense,
        'balance': balance,
        'daily_data': dailyData,
        'transaction_count': transactions.length,
      };
    } catch (e) {
      _logger.e('Lỗi tạo báo cáo theo thời gian: $e');
      return {};
    }
  }

  /// Tạo báo cáo theo danh mục
  Future<Map<String, dynamic>> _generateCategoryBasedReport(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final transactions = await _getTransactionsByDateRange(
        startDate,
        endDate,
      );

      // Nhóm giao dịch theo danh mục
      final incomeByCategory = <String, double>{};
      final expenseByCategory = <String, double>{};

      for (final transaction in transactions) {
        if (transaction.type == TransactionType.income) {
          incomeByCategory[transaction.categoryId] =
              (incomeByCategory[transaction.categoryId] ?? 0) +
              transaction.amount;
        } else {
          expenseByCategory[transaction.categoryId] =
              (expenseByCategory[transaction.categoryId] ?? 0) +
              transaction.amount;
        }
      }

      final totalIncome = incomeByCategory.values.fold(0.0, (a, b) => a + b);
      final totalExpense = expenseByCategory.values.fold(0.0, (a, b) => a + b);

      return {
        'period_start': startDate.toIso8601String(),
        'period_end': endDate.toIso8601String(),
        'income_by_category': incomeByCategory,
        'expense_by_category': expenseByCategory,
        'total_income': totalIncome,
        'total_expense': totalExpense,
        'balance': totalIncome - totalExpense,
        'transaction_count': transactions.length,
      };
    } catch (e) {
      _logger.e('Lỗi tạo báo cáo theo danh mục: $e');
      return {};
    }
  }

  /// Lấy giao dịch theo khoảng thời gian
  Future<List<TransactionModel>> _getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .where('is_deleted', isEqualTo: false)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      return snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      _logger.e('Lỗi lấy giao dịch theo khoảng thời gian: $e');
      return [];
    }
  }

  /// Nhóm giao dịch theo ngày
  Map<String, Map<String, double>> _groupTransactionsByDay(
    List<TransactionModel> transactions,
  ) {
    final dailyData = <String, Map<String, double>>{};

    for (final transaction in transactions) {
      final dateKey =
          '${transaction.date.year}-${transaction.date.month}-${transaction.date.day}';

      if (!dailyData.containsKey(dateKey)) {
        dailyData[dateKey] = {'income': 0.0, 'expense': 0.0};
      }

      if (transaction.type == TransactionType.income) {
        dailyData[dateKey]!['income'] =
            (dailyData[dateKey]!['income'] ?? 0) + transaction.amount;
      } else {
        dailyData[dateKey]!['expense'] =
            (dailyData[dateKey]!['expense'] ?? 0) + transaction.amount;
      }
    }

    return dailyData;
  }

  /// Tính toán khoảng thời gian báo cáo
  DateRange _calculateDateRange(
    TimePeriod timePeriod,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final now = DateTime.now();

    if (startDate != null && endDate != null) {
      return DateRange(startDate, endDate);
    }

    switch (timePeriod) {
      case TimePeriod.monthly:
        return DateRange(
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0),
        );
      case TimePeriod.quarterly:
        final quarterStart = DateTime(
          now.year,
          ((now.month - 1) ~/ 3) * 3 + 1,
          1,
        );
        final quarterEnd = DateTime(
          quarterStart.year,
          quarterStart.month + 3,
          0,
        );
        return DateRange(quarterStart, quarterEnd);
      case TimePeriod.yearly:
        return DateRange(DateTime(now.year, 1, 1), DateTime(now.year, 12, 31));
    }
  }

  String _getReportTypeText(ReportType type) {
    switch (type) {
      case ReportType.byTime:
        return 'Theo thời gian';
      case ReportType.byCategory:
        return 'Theo danh mục';
    }
  }

  String _getTimePeriodText(TimePeriod period) {
    switch (period) {
      case TimePeriod.monthly:
        return 'Hàng tháng';
      case TimePeriod.quarterly:
        return 'Hàng quý';
      case TimePeriod.yearly:
        return 'Hàng năm';
    }
  }
}

/// Class hỗ trợ cho khoảng thời gian
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);
}
