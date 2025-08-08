import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import '../../../services/category_service.dart';
import '../../../services/transaction_service.dart';
import '../../../widgets/charts/models/chart_data_model.dart';

/// Service adapter để kết nối Assistant modules với dữ liệu thực
class RealDataService {
  static final RealDataService _instance = RealDataService._internal();
  factory RealDataService() => _instance;
  RealDataService._internal();

  final Logger _logger = Logger();
  late final TransactionService _transactionService;
  late final CategoryService _categoryService;

  bool _isInitialized = false;

  /// Initialize service với dependency injection
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _transactionService = GetIt.instance<TransactionService>();
      _categoryService = CategoryService();
      _isInitialized = true;
      _logger.i('RealDataService initialized successfully');
    } catch (e) {
      _logger.e('Error initializing RealDataService: $e');
      rethrow;
    }
  }

  /// Lấy dữ liệu analytics thực từ transactions
  Future<AnalyticsData> getAnalyticsData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month, 1);
      final end = endDate ?? now;

      // Lấy transactions trong khoảng thời gian
      final transactions =
          await _transactionService.getTransactionsByDateRange(start, end);

      // Tính toán dữ liệu analytics
      final totalIncome = transactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);

      final totalExpense = transactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);

      final balance = totalIncome - totalExpense;
      final transactionCount = transactions.length;

      // Phân tích theo category
      final categorySpending = <String, double>{};
      for (final transaction
          in transactions.where((t) => t.type == TransactionType.expense)) {
        categorySpending[transaction.categoryId] =
            (categorySpending[transaction.categoryId] ?? 0) +
                transaction.amount;
      }

      // Lấy thông tin categories
      final categories = await _categoryService.getCategories().first;
      final categoryData = <ChartDataModel>[];

      for (final entry in categorySpending.entries) {
        final category = categories.firstWhere(
          (c) => c.categoryId == entry.key,
          orElse: () => CategoryModel(
            categoryId: entry.key,
            userId: '',
            name: 'Khác',
            type: TransactionType.expense,
            icon: '💸',
            iconType: CategoryIconType.emoji,
            color: 0xFF607D8B,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final percentage =
            totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0.0;

        categoryData.add(ChartDataModel(
          category: category.name,
          amount: entry.value,
          percentage: percentage,
          icon: category.icon,
          color:
              '#${category.color.toRadixString(16).padLeft(8, '0').substring(2)}',
          type: 'expense',
        ));
      }

      // Sắp xếp theo amount giảm dần
      categoryData.sort((a, b) => b.amount.compareTo(a.amount));

      _logger.d(
          'Analytics data calculated: Income: $totalIncome, Expense: $totalExpense');

      return AnalyticsData(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: balance,
        transactionCount: transactionCount,
        categoryData: categoryData,
        trendData: await _calculateTrendData(transactions),
        period: '${_formatDate(start)} - ${_formatDate(end)}',
        insights: _generateInsights(totalIncome, totalExpense, categoryData),
      );
    } catch (e) {
      _logger.e('Error getting analytics data: $e');
      return _getEmptyAnalyticsData();
    }
  }

  /// Lấy dữ liệu budget thực
  Future<BudgetData> getBudgetData() async {
    try {
      if (!_isInitialized) await initialize();

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);

      // Lấy transactions tháng hiện tại
      final transactions = await _transactionService.getTransactionsByDateRange(
          monthStart, monthEnd);
      final categories = await _categoryService
          .getCategories(type: TransactionType.expense)
          .first;

      final categoryProgress = <CategoryBudgetProgress>[];

      for (final category in categories.take(10)) {
        // Top 10 categories
        final spent = transactions
            .where((t) =>
                t.categoryId == category.categoryId &&
                t.type == TransactionType.expense)
            .fold(0.0, (sum, t) => sum + t.amount);

        // Estimate budget based on historical data or use default
        final estimatedBudget =
            await _estimateCategoryBudget(category.categoryId) ?? spent * 1.2;

        categoryProgress.add(CategoryBudgetProgress(
          categoryId: category.categoryId,
          name: category.name,
          color:
              '#${category.color.toRadixString(16).padLeft(8, '0').substring(2)}',
          budget: estimatedBudget,
          spent: spent,
          icon: category.icon,
          percentage: estimatedBudget > 0 ? (spent / estimatedBudget) * 100 : 0,
        ));
      }

      final totalBudget =
          categoryProgress.fold(0.0, (sum, c) => sum + c.budget);
      final totalSpent = categoryProgress.fold(0.0, (sum, c) => sum + c.spent);

      return BudgetData(
        totalBudget: totalBudget,
        totalSpent: totalSpent,
        categoryProgress: categoryProgress,
        budgetPeriod: 'Tháng ${now.month}/${now.year}',
        recommendations: _generateBudgetRecommendations(categoryProgress),
      );
    } catch (e) {
      _logger.e('Error getting budget data: $e');
      return _getEmptyBudgetData();
    }
  }

  /// Lấy recent transactions cho chatbot context
  Future<List<TransactionModel>> getRecentTransactions({int limit = 20}) async {
    try {
      if (!_isInitialized) await initialize();
      return await _transactionService
          .getRecentTransactions(limit: limit)
          .first;
    } catch (e) {
      _logger.e('Error getting recent transactions: $e');
      return [];
    }
  }

  /// Lấy spending summary cho AI context
  Future<Map<String, dynamic>> getSpendingSummary() async {
    try {
      final analyticsData = await getAnalyticsData();
      final recentTransactions = await getRecentTransactions(limit: 50);

      // Phân tích patterns
      final dailySpending = <String, double>{};
      for (final transaction in recentTransactions
          .where((t) => t.type == TransactionType.expense)) {
        final dateKey = _formatDate(transaction.date);
        dailySpending[dateKey] =
            (dailySpending[dateKey] ?? 0) + transaction.amount;
      }

      final avgDailySpending = dailySpending.values.isNotEmpty
          ? dailySpending.values.reduce((a, b) => a + b) / dailySpending.length
          : 0.0;

      return {
        'total_income': analyticsData.totalIncome,
        'total_expense': analyticsData.totalExpense,
        'balance': analyticsData.balance,
        'transaction_count': analyticsData.transactionCount,
        'avg_daily_spending': avgDailySpending,
        'top_categories': analyticsData.categoryData
            .take(5)
            .map((c) => {
                  'name': c.category,
                  'amount': c.amount,
                  'percentage': c.percentage,
                })
            .toList(),
        'financial_health_score': _calculateHealthScore(analyticsData),
      };
    } catch (e) {
      _logger.e('Error getting spending summary: $e');
      return {};
    }
  }

  /// Calculate trend data từ transactions
  Future<List<ChartDataModel>> _calculateTrendData(
      List<TransactionModel> transactions) async {
    try {
      final trendData = <ChartDataModel>[];
      final dailyIncome = <String, double>{};
      final dailyExpense = <String, double>{};

      // Group by date for income and expense separately
      for (final transaction in transactions) {
        final dateKey = _formatDate(transaction.date);
        if (transaction.type == TransactionType.income) {
          dailyIncome[dateKey] =
              (dailyIncome[dateKey] ?? 0) + transaction.amount;
        } else {
          dailyExpense[dateKey] =
              (dailyExpense[dateKey] ?? 0) + transaction.amount;
        }
      }

      // Merge dates from both maps and sort
      final allDates = <String>{}
        ..addAll(dailyIncome.keys)
        ..addAll(dailyExpense.keys);
      final sortedDates = allDates.toList()..sort((a, b) => a.compareTo(b));

      // Take last 30 days entries and build data points for both types
      final lastDates = sortedDates.length > 30
          ? sortedDates.sublist(sortedDates.length - 30)
          : sortedDates;

      for (final date in lastDates) {
        final incomeAmount = dailyIncome[date] ?? 0;
        final expenseAmount = dailyExpense[date] ?? 0;

        trendData.add(ChartDataModel(
          category: date,
          amount: incomeAmount,
          percentage: 0,
          icon: '📅',
          color: '#4CAF50', // green for income
          type: 'income',
        ));

        trendData.add(ChartDataModel(
          category: date,
          amount: expenseAmount,
          percentage: 0,
          icon: '📅',
          color: '#F44336', // red for expense
          type: 'expense',
        ));
      }

      return trendData;
    } catch (e) {
      _logger.e('Error calculating trend data: $e');
      return [];
    }
  }

  /// Estimate budget for category based on historical data
  Future<double?> _estimateCategoryBudget(String categoryId) async {
    try {
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      final transactions = await _transactionService.getTransactionsByDateRange(
        threeMonthsAgo,
        DateTime.now(),
      );

      final categoryTransactions = transactions
          .where((t) =>
              t.categoryId == categoryId && t.type == TransactionType.expense)
          .toList();

      if (categoryTransactions.isEmpty) return null;

      final totalSpent =
          categoryTransactions.fold(0.0, (sum, t) => sum + t.amount);
      final avgMonthlySpending = totalSpent / 3; // 3 months average

      return avgMonthlySpending * 1.1; // Add 10% buffer
    } catch (e) {
      _logger.e('Error estimating category budget: $e');
      return null;
    }
  }

  /// Generate insights từ analytics data
  List<String> _generateInsights(
      double income, double expense, List<ChartDataModel> categoryData) {
    final insights = <String>[];

    final savingsRate = income > 0 ? ((income - expense) / income) * 100 : 0;

    if (savingsRate > 20) {
      insights.add(
          'Tuyệt vời! Bạn đang tiết kiệm ${savingsRate.toStringAsFixed(1)}% thu nhập.');
    } else if (savingsRate > 10) {
      insights.add(
          'Tốt! Tỷ lệ tiết kiệm ${savingsRate.toStringAsFixed(1)}% là hợp lý.');
    } else if (savingsRate > 0) {
      insights.add(
          'Nên cải thiện! Tỷ lệ tiết kiệm chỉ ${savingsRate.toStringAsFixed(1)}%.');
    } else {
      insights.add('Cảnh báo! Chi tiêu vượt quá thu nhập.');
    }

    if (categoryData.isNotEmpty) {
      final topCategory = categoryData.first;
      if (topCategory.percentage > 30) {
        insights.add(
            '${topCategory.category} chiếm ${topCategory.percentage.toStringAsFixed(1)}% chi tiêu - cần cân nhắc giảm bớt.');
      }
    }

    return insights;
  }

  /// Generate budget recommendations
  List<String> _generateBudgetRecommendations(
      List<CategoryBudgetProgress> categoryProgress) {
    final recommendations = <String>[];

    for (final category in categoryProgress) {
      if (category.percentage > 100) {
        recommendations.add(
            '${category.name}: Đã vượt ngân sách ${(category.percentage - 100).toStringAsFixed(1)}%');
      } else if (category.percentage > 80) {
        recommendations.add(
            '${category.name}: Sắp hết ngân sách (${category.percentage.toStringAsFixed(1)}%)');
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add('Bạn đang quản lý ngân sách tốt! Tiếp tục duy trì.');
    }

    return recommendations;
  }

  /// Calculate financial health score
  double _calculateHealthScore(AnalyticsData data) {
    double score = 50; // Base score

    // Savings rate impact
    final savingsRate = data.totalIncome > 0
        ? ((data.totalIncome - data.totalExpense) / data.totalIncome) * 100
        : -50;

    if (savingsRate > 20) {
      score += 25;
    } else if (savingsRate > 10) {
      score += 15;
    } else if (savingsRate > 0) {
      score += 5;
    } else {
      score -= 30;
    }

    // Diversification impact
    if (data.categoryData.length > 5) score += 10;
    if (data.categoryData.isNotEmpty &&
        data.categoryData.first.percentage < 40) {
      score += 15;
    }

    return score.clamp(0, 100);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  /// Empty data fallbacks
  AnalyticsData _getEmptyAnalyticsData() {
    return AnalyticsData(
      totalIncome: 0,
      totalExpense: 0,
      balance: 0,
      transactionCount: 0,
      categoryData: [],
      trendData: [],
      period: 'Không có dữ liệu',
      insights: ['Chưa có dữ liệu để phân tích. Hãy thêm giao dịch đầu tiên!'],
    );
  }

  BudgetData _getEmptyBudgetData() {
    return BudgetData(
      totalBudget: 0,
      totalSpent: 0,
      categoryProgress: [],
      budgetPeriod: 'Tháng này',
      recommendations: [
        'Chưa có dữ liệu để tạo ngân sách. Hãy thêm giao dịch đầu tiên!'
      ],
    );
  }
}

/// Analytics data model
class AnalyticsData {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int transactionCount;
  final List<ChartDataModel> categoryData;
  final List<ChartDataModel> trendData;
  final String period;
  final List<String> insights;

  AnalyticsData({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.transactionCount,
    required this.categoryData,
    required this.trendData,
    required this.period,
    required this.insights,
  });
}

/// Budget data model
class BudgetData {
  final double totalBudget;
  final double totalSpent;
  final List<CategoryBudgetProgress> categoryProgress;
  final String budgetPeriod;
  final List<String> recommendations;

  BudgetData({
    required this.totalBudget,
    required this.totalSpent,
    required this.categoryProgress,
    required this.budgetPeriod,
    required this.recommendations,
  });
}

/// Category budget progress model
class CategoryBudgetProgress {
  final String categoryId;
  final String name;
  final String color;
  final double budget;
  final double spent;
  final String icon;
  final double percentage;

  CategoryBudgetProgress({
    required this.categoryId,
    required this.name,
    required this.color,
    required this.budget,
    required this.spent,
    required this.icon,
    required this.percentage,
  });
}
