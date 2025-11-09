import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:moni/constants/enums.dart';

import '../../models/transaction_model.dart';
import '../../widgets/charts/models/chart_data_model.dart';
import '../data/category_service.dart';
import '../data/transaction_service.dart';

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
    bool showParentCategories = false, // Mới: hỗ trợ hierarchy
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      // Lấy tất cả giao dịch trong khoảng thời gian
      final transactions = await _getTransactionsInPeriod(
        type: transactionType,
        startDate: startDate,
        endDate: endDate,
      );

      if (transactions.isEmpty) {
        return [];
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

      if (showParentCategories) {
        return _getGroupedByParentChartData(
          transactions,
          categories,
          totalAmount,
          transactionType,
        );
      } else {
        return _getDetailedChartData(
          transactions,
          categories,
          totalAmount,
          transactionType,
        );
      }
    } catch (e) {
      _logger.e('Lỗi lấy dữ liệu donut chart: $e');
      return [];
    }
  }

  /// Lấy dữ liệu chi tiết theo từng danh mục
  List<ChartDataModel> _getDetailedChartData(
    List<dynamic> transactions,
    List<dynamic> categories,
    double totalAmount,
    TransactionType? transactionType,
  ) {
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
        chartData.add(ChartDataModel.fromCategoryModel(
          category,
          amount,
          percentage,
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
        icon: 'more_horiz',
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
          icon: 'more_horiz',
          color: '#9E9E9E',
          type: transactionType?.value ?? 'expense',
        ));
      }
      return top5;
    }

    return chartData;
  }

  /// Lấy dữ liệu nhóm theo danh mục cha
  List<ChartDataModel> _getGroupedByParentChartData(
    List<dynamic> transactions,
    List<dynamic> categories,
    double totalAmount,
    TransactionType? transactionType,
  ) {
    // Tạo map danh mục con -> danh mục cha
    final Map<String, dynamic> categoryParentMap = {};
    final Map<String, dynamic> parentCategoryMap = {};

    for (final category in categories) {
      if (category.parentId != null && category.parentId!.isNotEmpty) {
        categoryParentMap[category.categoryId] = category.parentId;
      }
      parentCategoryMap[category.categoryId] = category;
    }

    // Nhóm giao dịch theo danh mục cha
    final parentTotals = <String, double>{};
    final parentCategoriesUsed = <String, dynamic>{};

    for (final transaction in transactions) {
      final categoryId = transaction.categoryId;
      final parentId = categoryParentMap[categoryId];

      if (parentId != null) {
        // Đây là danh mục con, gộp vào danh mục cha
        parentTotals[parentId] =
            (parentTotals[parentId] ?? 0) + transaction.amount;
        if (parentCategoryMap[parentId] != null) {
          parentCategoriesUsed[parentId] = parentCategoryMap[parentId];
        }
      } else {
        // Đây là danh mục cha hoặc không có parent
        parentTotals[categoryId] =
            (parentTotals[categoryId] ?? 0) + transaction.amount;
        if (parentCategoryMap[categoryId] != null) {
          parentCategoriesUsed[categoryId] = parentCategoryMap[categoryId];
        }
      }
    }

    // Tạo dữ liệu chart
    final chartData = <ChartDataModel>[];

    for (final entry in parentTotals.entries) {
      final categoryId = entry.key;
      final amount = entry.value;
      final category = parentCategoriesUsed[categoryId];

      if (amount > 0 && category != null) {
        final percentage = (amount / totalAmount) * 100;
        chartData.add(ChartDataModel.fromCategoryModel(
          category,
          amount,
          percentage,
        ));
      }
    }

    // Sắp xếp theo phần trăm giảm dần
    chartData.sort((a, b) => b.percentage.compareTo(a.percentage));

    return chartData;
  }

  /// Lấy dữ liệu cho trend bar chart
  Future<List<TrendData>> getTrendChartData({
    int months = 3,
    TransactionType? transactionType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
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
      return [];
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
        return FinancialOverviewData(
          totalExpense: 0,
          totalIncome: 0,
          changeAmount: 0,
          changePeriod: '',
          isIncrease: false,
        );
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
      return FinancialOverviewData(
        totalExpense: 0,
        totalIncome: 0,
        changeAmount: 0,
        changePeriod: '',
        isIncrease: false,
      );
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

  // Mock data methods removed to avoid misleading runtime fallbacks
}
