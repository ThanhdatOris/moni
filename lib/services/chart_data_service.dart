import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

import '../models/transaction_model.dart';
import '../widgets/charts/models/chart_data_model.dart';
import 'category_service.dart';
import 'transaction_service.dart';

/// Service để xử lý dữ liệu cho charts
class ChartDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();
  final CategoryService _categoryService;

  ChartDataService({
    required TransactionService transactionService,
    required CategoryService categoryService,
  }) : _categoryService = categoryService;

  /// Lấy dữ liệu cho donut chart (phân bổ chi tiêu theo danh mục)
  Future<List<ChartDataModel>> getDonutChartData({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? transactionType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return _getMockDonutChartData();
      }

      // Lấy tất cả giao dịch trong khoảng thời gian
      final transactions = await _getTransactionsInPeriod(
        type: transactionType,
        startDate: startDate,
        endDate: endDate,
      );

      if (transactions.isEmpty) {
        return _getMockDonutChartData();
      }

      // Lấy danh sách danh mục
      final categories = await _categoryService
          .getCategoriesOptimized(
            type: transactionType ?? TransactionType.expense,
          )
          .first;

      // Tính toán tổng
      final totalAmount = transactions.fold<double>(
        0,
        (total, transaction) => total + transaction.amount,
      );

      // Nhóm giao dịch theo danh mục
      final categoryTotals = <String, double>{};
      for (final transaction in transactions) {
        final categoryId = transaction.categoryId;
        categoryTotals[categoryId] =
            (categoryTotals[categoryId] ?? 0) + transaction.amount;
      }

      // Tạo dữ liệu chart
      final chartData = <ChartDataModel>[];
      final processedCategories = <String>{};

      for (final category in categories) {
        final amount = categoryTotals[category.categoryId] ?? 0;
        if (amount > 0) {
          final percentage = (amount / totalAmount) * 100;
          chartData.add(ChartDataModel(
            category: category.name,
            amount: amount,
            percentage: percentage,
            icon: _getCategoryIcon(category.icon),
            color: _getCategoryColor(category.color),
            type: transactionType?.value ?? 'expense',
          ));
          processedCategories.add(category.categoryId);
        }
      }

      // Thêm danh mục "Còn lại" nếu có giao dịch không thuộc danh mục nào
      final unprocessedAmount = transactions
          .where((t) => !processedCategories.contains(t.categoryId))
          .fold<double>(0, (total, t) => total + t.amount);

      if (unprocessedAmount > 0) {
        final percentage = (unprocessedAmount / totalAmount) * 100;
        chartData.add(ChartDataModel(
          category: 'Còn lại',
          amount: unprocessedAmount,
          percentage: percentage,
          icon: 'remaining',
          color: '#9E9E9E',
          type: transactionType?.value ?? 'expense',
        ));
      }

      // Sắp xếp theo phần trăm giảm dần
      chartData.sort((a, b) => b.percentage.compareTo(a.percentage));

      // Giới hạn top 5 danh mục và gộp phần còn lại
      if (chartData.length > 5) {
        final top5 = chartData.take(5).toList();
        final remaining = chartData.skip(5);
        final remainingAmount =
            remaining.fold<double>(0, (total, item) => total + item.amount);
        final remainingPercentage =
            remaining.fold<double>(0, (total, item) => total + item.percentage);

        if (remainingAmount > 0) {
          top5.add(ChartDataModel(
            category: 'Còn lại',
            amount: remainingAmount,
            percentage: remainingPercentage,
            icon: 'remaining',
            color: '#9E9E9E',
            type: transactionType?.value ?? 'expense',
          ));
        }
        return top5;
      }

      return chartData;
    } catch (e) {
      _logger.e('Lỗi lấy dữ liệu donut chart: $e');
      return _getMockDonutChartData();
    }
  }

  /// Lấy dữ liệu cho trend bar chart
  Future<List<TrendData>> getTrendChartData({
    int months = 3,
    TransactionType? transactionType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return _getMockTrendData();
      }

      final now = DateTime.now();
      final trendData = <TrendData>[];

      for (int i = months - 1; i >= 0; i--) {
        final monthStart = DateTime(now.year, now.month - i, 1);
        final monthEnd = DateTime(now.year, now.month - i + 1, 0, 23, 59, 59);

        final monthTransactions = await _getTransactionsInPeriod(
          startDate: monthStart,
          endDate: monthEnd,
        );

        if (transactionType != null) {
          // Nếu có filter type, chỉ lấy giao dịch theo type đó
          final filteredTransactions = monthTransactions
              .where((t) => t.type == transactionType)
              .toList();

          final amount = filteredTransactions.fold<double>(
              0, (total, t) => total + t.amount);

          final label = _getMonthLabel(monthStart);
          trendData.add(TrendData(
            period: monthStart.toIso8601String(),
            expense: transactionType == TransactionType.expense ? amount : 0,
            income: transactionType == TransactionType.income ? amount : 0,
            label: label,
          ));
        } else {
          // Nếu không có filter, lấy cả thu và chi
          final expense = monthTransactions
              .where((t) => t.type == TransactionType.expense)
              .fold<double>(0, (total, t) => total + t.amount);

          final income = monthTransactions
              .where((t) => t.type == TransactionType.income)
              .fold<double>(0, (total, t) => total + t.amount);

          final label = _getMonthLabel(monthStart);
          trendData.add(TrendData(
            period: monthStart.toIso8601String(),
            expense: expense,
            income: income,
            label: label,
          ));
        }
      }

      return trendData;
    } catch (e) {
      _logger.e('Lỗi lấy dữ liệu trend chart: $e');
      return _getMockTrendData();
    }
  }

  /// Lấy dữ liệu tổng quan tài chính
  Future<FinancialOverviewData> getFinancialOverviewData({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? transactionType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return _getMockFinancialOverviewData();
      }

      // Lấy giao dịch trong khoảng thời gian hiện tại
      final currentTransactions = await _getTransactionsInPeriod(
        startDate: startDate,
        endDate: endDate,
        type: transactionType,
      );

      if (transactionType != null) {
        // Nếu có filter type, chỉ tính theo type đó
        final totalAmount =
            currentTransactions.fold<double>(0, (total, t) => total + t.amount);

        // Tính toán thay đổi so với tháng trước
        final now = DateTime.now();
        final previousMonthStart = DateTime(now.year, now.month - 1, 1);
        final previousMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

        final previousTransactions = await _getTransactionsInPeriod(
          startDate: previousMonthStart,
          endDate: previousMonthEnd,
          type: transactionType,
        );

        final previousAmount = previousTransactions.fold<double>(
            0, (total, t) => total + t.amount);

        final changeAmount = totalAmount - previousAmount;
        final isIncrease = changeAmount >= 0;

        return FinancialOverviewData(
          totalExpense:
              transactionType == TransactionType.expense ? totalAmount : 0,
          totalIncome:
              transactionType == TransactionType.income ? totalAmount : 0,
          changeAmount: changeAmount.abs(),
          changePeriod: 'tháng trước',
          isIncrease: isIncrease,
        );
      } else {
        // Nếu không có filter, tính cả thu và chi
        final totalExpense = currentTransactions
            .where((t) => t.type == TransactionType.expense)
            .fold<double>(0, (total, t) => total + t.amount);

        final totalIncome = currentTransactions
            .where((t) => t.type == TransactionType.income)
            .fold<double>(0, (total, t) => total + t.amount);

        // Tính toán thay đổi so với tháng trước
        final now = DateTime.now();
        final previousMonthStart = DateTime(now.year, now.month - 1, 1);
        final previousMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

        final previousTransactions = await _getTransactionsInPeriod(
          startDate: previousMonthStart,
          endDate: previousMonthEnd,
        );

        final previousExpense = previousTransactions
            .where((t) => t.type == TransactionType.expense)
            .fold<double>(0, (total, t) => total + t.amount);

        final previousIncome = previousTransactions
            .where((t) => t.type == TransactionType.income)
            .fold<double>(0, (total, t) => total + t.amount);

        final currentTotal = totalExpense + totalIncome;
        final previousTotal = previousExpense + previousIncome;
        final changeAmount = currentTotal - previousTotal;
        final isIncrease = changeAmount >= 0;

        return FinancialOverviewData(
          totalExpense: totalExpense,
          totalIncome: totalIncome,
          changeAmount: changeAmount.abs(),
          changePeriod: 'tháng trước',
          isIncrease: isIncrease,
        );
      }
    } catch (e) {
      _logger.e('Lỗi lấy dữ liệu financial overview: $e');
      return _getMockFinancialOverviewData();
    }
  }

  /// Helper method để lấy giao dịch trong khoảng thời gian
  Future<List<TransactionModel>> _getTransactionsInPeriod({
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      Query query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .where('is_deleted', isEqualTo: false);

      // Áp dụng filter type nếu có
      if (type != null) {
        query = query.where('type', isEqualTo: type.value);
      }

      // Lấy tất cả giao dịch và filter trong client để tránh composite index
      final snapshot = await query.get();
      var transactions = snapshot.docs.map((doc) {
        return TransactionModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      // Filter theo date range trong client
      if (startDate != null) {
        transactions = transactions
            .where((t) =>
                t.date.isAfter(startDate.subtract(const Duration(seconds: 1))))
            .toList();
      }

      if (endDate != null) {
        transactions = transactions
            .where(
                (t) => t.date.isBefore(endDate.add(const Duration(seconds: 1))))
            .toList();
      }

      // Sort theo date giảm dần
      transactions.sort((a, b) => b.date.compareTo(a.date));

      return transactions;
    } catch (e) {
      _logger.e('Lỗi lấy giao dịch trong khoảng thời gian: $e');
      return [];
    }
  }

  /// Helper method để lấy icon từ category
  String _getCategoryIcon(String? icon) {
    if (icon == null || icon.isEmpty) return 'category';

    // Map emoji icons to icon names
    switch (icon) {
      case '🍽️':
        return 'food';
      case '🛍️':
        return 'shopping';
      case '🚗':
        return 'transport';
      case '🎮':
        return 'entertainment';
      case '📄':
        return 'bills';
      case '💊':
        return 'health';
      case '🎉':
        return 'party';
      default:
        return 'category';
    }
  }

  /// Helper method để lấy màu từ category
  String _getCategoryColor(int color) {
    // Convert int color to hex string
    return '#${color.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// Helper method để lấy label tháng
  String _getMonthLabel(DateTime date) {
    final months = [
      'T1',
      'T2',
      'T3',
      'T4',
      'T5',
      'T6',
      'T7',
      'T8',
      'T9',
      'T10',
      'T11',
      'T12'
    ];
    return months[date.month - 1];
  }

  // Mock data methods
  List<ChartDataModel> _getMockDonutChartData() {
    return [
      ChartDataModel(
        category: 'Hóa đơn',
        amount: 1719500,
        percentage: 44,
        icon: 'bills',
        color: '#4CAF50',
        type: 'expense',
      ),
      ChartDataModel(
        category: 'Ăn uống',
        amount: 883000,
        percentage: 23,
        icon: 'food',
        color: '#FF9800',
        type: 'expense',
      ),
      ChartDataModel(
        category: 'Mua sắm',
        amount: 370827,
        percentage: 9,
        icon: 'shopping',
        color: '#FFC107',
        type: 'expense',
      ),
      ChartDataModel(
        category: 'Tiệc tùng',
        amount: 313317,
        percentage: 8,
        icon: 'party',
        color: '#FF5722',
        type: 'expense',
      ),
      ChartDataModel(
        category: 'Còn lại',
        amount: 626700,
        percentage: 16,
        icon: 'remaining',
        color: '#9E9E9E',
        type: 'expense',
      ),
    ];
  }

  List<TrendData> _getMockTrendData() {
    return [
      TrendData(
        period: 'T5',
        expense: 5700000,
        income: 5500000,
        label: 'T5',
      ),
      TrendData(
        period: 'T6',
        expense: 5700000,
        income: 5500000,
        label: 'T6',
      ),
      TrendData(
        period: 'Tháng này',
        expense: 3800000,
        income: 3700000,
        label: 'Tháng này',
      ),
    ];
  }

  FinancialOverviewData _getMockFinancialOverviewData() {
    return FinancialOverviewData(
      totalExpense: 3916644,
      totalIncome: 3700100,
      changeAmount: 1309565,
      changePeriod: 'tháng trước',
      isIncrease: true,
    );
  }
}
