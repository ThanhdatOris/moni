import 'package:flutter/material.dart';

import '../../../constants/enums.dart';
import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import '../../../services/category_service.dart';
import '../../../services/transaction_service.dart';
import '../models/analysis_models.dart';
import '../models/chart_config_models.dart';
import '../models/chart_data_models.dart';

/// Controller for managing chart data and state
class ChartController extends ChangeNotifier {
  final TransactionService _transactionService;
  final CategoryService _categoryService;

  ChartFilterConfig _currentFilter;
  bool _isLoading = false;
  String? _error;

  ChartController({
    required TransactionService transactionService,
    required CategoryService categoryService,
    ChartFilterConfig? initialFilter,
  })  : _transactionService = transactionService,
        _categoryService = categoryService,
        _currentFilter = initialFilter ?? const ChartFilterConfig();

  /// Current filter configuration
  ChartFilterConfig get currentFilter => _currentFilter;

  /// Whether data is currently loading
  bool get isLoading => _isLoading;

  /// Current error message if any
  String? get error => _error;

  /// Update filter and refresh data
  void updateFilter(ChartFilterConfig newFilter) {
    _currentFilter = newFilter;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Set error state
  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  /// Get filtered transactions based on current filter
  Future<List<TransactionModel>> getFilteredTransactions() async {
    try {
      _setLoading(true);
      _setError(null);

      // Get date range
      final now = DateTime.now();
      final startDate =
          _currentFilter.startDate ?? DateTime(now.year, now.month - 1, 1);
      final endDate =
          _currentFilter.endDate ?? DateTime(now.year, now.month + 1, 0);

      // Get transactions stream and convert to list
      final transactionsStream = _transactionService.getTransactions(
        startDate: startDate,
        endDate: endDate,
      );

      final transactions = await transactionsStream.first;

      // Apply additional filters
      var filteredTransactions = transactions.where((transaction) {
        // Filter by transaction type
        if (!_currentFilter.includeIncome &&
            transaction.type == TransactionType.income) {
          return false;
        }
        if (!_currentFilter.includeExpense &&
            transaction.type == TransactionType.expense) {
          return false;
        }

        // Filter by category
        if (_currentFilter.categoryIds?.isNotEmpty == true &&
            !_currentFilter.categoryIds!.contains(transaction.categoryId)) {
          return false;
        }

        // Exclude categories
        if (_currentFilter.excludeCategoryIds
                ?.contains(transaction.categoryId) ==
            true) {
          return false;
        }

        // Filter by amount range
        if (_currentFilter.minAmount != null &&
            transaction.amount < _currentFilter.minAmount!) {
          return false;
        }
        if (_currentFilter.maxAmount != null &&
            transaction.amount > _currentFilter.maxAmount!) {
          return false;
        }

        return true;
      }).toList();

      _setLoading(false);
      return filteredTransactions;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return [];
    }
  }

  /// Get categories with color mapping
  Future<List<CategoryModel>> getCategories() async {
    try {
      final incomeCategories = await _categoryService
          .getCategories(type: TransactionType.income)
          .first;
      final expenseCategories = await _categoryService
          .getCategories(type: TransactionType.expense)
          .first;

      return [...incomeCategories, ...expenseCategories];
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  /// Get income vs expense analysis data
  Future<IncomeExpenseAnalysis> getIncomeExpenseAnalysis() async {
    try {
      _setLoading(true);
      _setError(null);

      final transactions = await getFilteredTransactions();
      final analysis = await _processIncomeExpenseData(transactions);

      _setLoading(false);
      return analysis;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return _getEmptyIncomeExpenseAnalysis();
    }
  }

  /// Get category spending analysis
  Future<CategorySpendingAnalysis> getCategorySpendingAnalysis() async {
    try {
      _setLoading(true);
      _setError(null);

      final transactions = await getFilteredTransactions();
      final categories = await getCategories();
      final analysis =
          await _processCategorySpendingData(transactions, categories);

      _setLoading(false);
      return analysis;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return _getEmptyCategorySpendingAnalysis();
    }
  }

  /// Get spending pattern analysis
  Future<SpendingPatternAnalysis> getSpendingPatternAnalysis() async {
    try {
      _setLoading(true);
      _setError(null);

      // Use placeholder for now - would integrate with actual analytics methods
      final analysis = _getEmptySpendingPatternAnalysis();

      _setLoading(false);
      return analysis;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return _getEmptySpendingPatternAnalysis();
    }
  }

  /// Get budget performance analysis
  Future<BudgetPerformanceAnalysis> getBudgetPerformanceAnalysis() async {
    try {
      _setLoading(true);
      _setError(null);

      // Use placeholder for now - would integrate with budget service
      final analysis = _getEmptyBudgetPerformanceAnalysis();

      _setLoading(false);
      return analysis;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return _getEmptyBudgetPerformanceAnalysis();
    }
  }

  /// Get financial health data
  Future<FinancialHealthData> getFinancialHealthData() async {
    try {
      _setLoading(true);
      _setError(null);

      // Use placeholder for now - would integrate with actual analytics methods
      final healthData = _getEmptyFinancialHealthData();

      _setLoading(false);
      return healthData;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return _getEmptyFinancialHealthData();
    }
  }

  /// Process income vs expense data
  Future<IncomeExpenseAnalysis> _processIncomeExpenseData(
    List<TransactionModel> transactions,
  ) async {
    // Group transactions by month
    final monthlyData = <DateTime, IncomeExpenseData>{};

    for (final transaction in transactions) {
      final monthKey =
          DateTime(transaction.date.year, transaction.date.month, 1);

      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = IncomeExpenseData(
          income: 0,
          expense: 0,
          period: monthKey,
        );
      }

      final currentData = monthlyData[monthKey]!;
      if (transaction.type == TransactionType.income) {
        monthlyData[monthKey] = currentData.copyWith(
          income: currentData.income + transaction.amount,
        );
      } else {
        monthlyData[monthKey] = currentData.copyWith(
          expense: currentData.expense + transaction.amount,
        );
      }
    }

    final sortedData = monthlyData.values.toList()
      ..sort((a, b) => a.period.compareTo(b.period));

    // Calculate totals and trends
    final totalIncome = sortedData.fold(0.0, (sum, data) => sum + data.income);
    final totalExpense =
        sortedData.fold(0.0, (sum, data) => sum + data.expense);
    final netIncome = totalIncome - totalExpense;
    final savingsRate = totalIncome > 0 ? netIncome / totalIncome : 0.0;

    // Create trend data
    final incomeTrend = _createTrendAnalysis(
      sortedData
          .map((d) => ChartDataPoint(
                label: '${d.period.month}/${d.period.year}',
                value: d.income,
                date: d.period,
              ))
          .toList(),
    );

    final expenseTrend = _createTrendAnalysis(
      sortedData
          .map((d) => ChartDataPoint(
                label: '${d.period.month}/${d.period.year}',
                value: d.expense,
                date: d.period,
              ))
          .toList(),
    );

    // Generate insights
    final insights = _generateIncomeExpenseInsights(
      totalIncome,
      totalExpense,
      savingsRate,
    );

    return IncomeExpenseAnalysis(
      data: sortedData,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netIncome: netIncome,
      averageMonthlyIncome:
          sortedData.isNotEmpty ? totalIncome / sortedData.length : 0,
      averageMonthlyExpense:
          sortedData.isNotEmpty ? totalExpense / sortedData.length : 0,
      savingsRate: savingsRate,
      incomeTrend: incomeTrend,
      expenseTrend: expenseTrend,
      insights: insights,
      analysisDate: DateTime.now(),
    );
  }

  /// Process category spending data
  Future<CategorySpendingAnalysis> _processCategorySpendingData(
    List<TransactionModel> transactions,
    List<CategoryModel> categories,
  ) async {
    final categoryMap = {for (var c in categories) c.categoryId: c};
    final categoryData = <String, CategoryAnalysisData>{};
    final categoryTransactions = <String, List<TransactionModel>>{};

    // Group transactions by category
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        categoryTransactions
            .putIfAbsent(transaction.categoryId, () => [])
            .add(transaction);
      }
    }

    // Process each category
    final totalSpending = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    for (final entry in categoryTransactions.entries) {
      final categoryId = entry.key;
      final categoryTransactions = entry.value;
      final category = categoryMap[categoryId];

      if (category == null) continue;

      final totalAmount =
          categoryTransactions.fold(0.0, (sum, t) => sum + t.amount);
      final percentage =
          totalSpending > 0 ? (totalAmount / totalSpending) * 100 : 0;
      final averageTransaction = categoryTransactions.isNotEmpty
          ? totalAmount / categoryTransactions.length
          : 0;

      // Create trend data for this category
      final trendData = _createCategoryTrendData(categoryTransactions);

      categoryData[categoryId] = CategoryAnalysisData(
        categoryId: categoryId,
        categoryName: category.name,
        totalAmount: totalAmount,
        percentage: percentage.toDouble(),
        averageTransaction: averageTransaction.toDouble(),
        transactionCount: categoryTransactions.length,
        budgetAmount: 0, // Would come from budget service
        color: _getCategoryColor(categoryId),
        trend: trendData,
      );
    }

    final sortedCategories = categoryData.values.toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final topSpendingCategory = sortedCategories.isNotEmpty
        ? sortedCategories.first
        : _getEmptyCategoryAnalysis();

    // Generate insights
    final insights = _generateCategoryInsights(sortedCategories);

    return CategorySpendingAnalysis(
      categories: sortedCategories,
      topSpendingCategory: topSpendingCategory,
      mostImprovedCategory: topSpendingCategory, // Simplified for now
      mostDeterioratedCategory: topSpendingCategory, // Simplified for now
      totalSpending: totalSpending,
      categoryTrends: {},
      overBudgetCategories: [],
      insights: insights,
      analysisDate: DateTime.now(),
    );
  }

  /// Create trend analysis from data points
  TrendAnalysisData _createTrendAnalysis(List<ChartDataPoint> data) {
    if (data.length < 2) {
      return TrendAnalysisData(
        data: data,
        trendPercentage: 0.0,
        trendDirection: 'stable',
        confidence: 0.0,
      );
    }

    final firstValue = data.first.value;
    final lastValue = data.last.value;
    final trendPercentage =
        firstValue > 0 ? ((lastValue - firstValue) / firstValue) * 100 : 0.0;

    String trendDirection;
    if (trendPercentage > 5) {
      trendDirection = 'up';
    } else if (trendPercentage < -5) {
      trendDirection = 'down';
    } else {
      trendDirection = 'stable';
    }

    return TrendAnalysisData(
      data: data,
      trendPercentage: trendPercentage,
      trendDirection: trendDirection,
      confidence: 0.8, // Simplified confidence calculation
    );
  }

  /// Create category trend data
  List<ChartDataPoint> _createCategoryTrendData(
      List<TransactionModel> transactions) {
    // Group by month and sum amounts
    final monthlyAmounts = <DateTime, double>{};

    for (final transaction in transactions) {
      final monthKey =
          DateTime(transaction.date.year, transaction.date.month, 1);
      monthlyAmounts[monthKey] =
          (monthlyAmounts[monthKey] ?? 0) + transaction.amount;
    }

    return monthlyAmounts.entries
        .map((entry) => ChartDataPoint(
              label: '${entry.key.month}/${entry.key.year}',
              value: entry.value,
              date: entry.key,
            ))
        .toList()
      ..sort((a, b) => a.date!.compareTo(b.date!));
  }

  /// Get category color (simplified)
  Color _getCategoryColor(String categoryId) {
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.grey,
      Colors.green,
      Colors.red,
      Colors.cyan,
    ];
    return colors[categoryId.hashCode % colors.length];
  }

  /// Generate income expense insights
  List<ChartInsight> _generateIncomeExpenseInsights(
    double totalIncome,
    double totalExpense,
    double savingsRate,
  ) {
    final insights = <ChartInsight>[];

    if (savingsRate >= 0.2) {
      insights.add(ChartInsight(
        title: 'Excellent Savings Rate',
        description:
            'You\'re saving ${(savingsRate * 100).toStringAsFixed(1)}% of your income. Great job!',
        type: InsightType.positive,
        priority: 0.8,
        generated: DateTime.now(),
      ));
    } else if (savingsRate < 0) {
      insights.add(ChartInsight(
        title: 'Spending Alert',
        description:
            'Your expenses exceed your income. Consider reviewing your spending.',
        type: InsightType.warning,
        priority: 1.0,
        generated: DateTime.now(),
      ));
    }

    return insights;
  }

  /// Generate category insights
  List<ChartInsight> _generateCategoryInsights(
      List<CategoryAnalysisData> categories) {
    final insights = <ChartInsight>[];

    if (categories.isNotEmpty) {
      final topCategory = categories.first;
      if (topCategory.percentage > 40) {
        insights.add(ChartInsight(
          title: 'High Category Spending',
          description:
              '${topCategory.categoryName} accounts for ${topCategory.percentage.toStringAsFixed(1)}% of your spending.',
          type: InsightType.info,
          priority: 0.7,
          generated: DateTime.now(),
        ));
      }
    }

    return insights;
  }

  // Empty data generators for error cases
  IncomeExpenseAnalysis _getEmptyIncomeExpenseAnalysis() {
    return IncomeExpenseAnalysis(
      data: [],
      totalIncome: 0,
      totalExpense: 0,
      netIncome: 0,
      averageMonthlyIncome: 0,
      averageMonthlyExpense: 0,
      savingsRate: 0,
      incomeTrend: TrendAnalysisData(
        data: [],
        trendPercentage: 0,
        trendDirection: 'stable',
        confidence: 0,
      ),
      expenseTrend: TrendAnalysisData(
        data: [],
        trendPercentage: 0,
        trendDirection: 'stable',
        confidence: 0,
      ),
      insights: [],
      analysisDate: DateTime.now(),
    );
  }

  CategorySpendingAnalysis _getEmptyCategorySpendingAnalysis() {
    return CategorySpendingAnalysis(
      categories: [],
      topSpendingCategory: _getEmptyCategoryAnalysis(),
      mostImprovedCategory: _getEmptyCategoryAnalysis(),
      mostDeterioratedCategory: _getEmptyCategoryAnalysis(),
      totalSpending: 0,
      categoryTrends: {},
      overBudgetCategories: [],
      insights: [],
      analysisDate: DateTime.now(),
    );
  }

  CategoryAnalysisData _getEmptyCategoryAnalysis() {
    return CategoryAnalysisData(
      categoryId: '',
      categoryName: 'No Data',
      totalAmount: 0,
      percentage: 0,
      averageTransaction: 0,
      transactionCount: 0,
      budgetAmount: 0,
      color: Colors.grey,
      trend: [],
    );
  }

  SpendingPatternAnalysis _getEmptySpendingPatternAnalysis() {
    return SpendingPatternAnalysis(
      dailyPatterns: {},
      monthlyPatterns: {},
      hourlyPatterns: {},
      spendingPeaks: [],
      spendingLows: [],
      seasonalAnalysis: const SeasonalAnalysis(
        seasonalSpending: {},
        seasonalCategories: {},
        highestSpendingSeason: '',
        lowestSpendingSeason: '',
        seasonalVariance: 0,
      ),
      anomalies: [],
      insights: [],
      analysisDate: DateTime.now(),
    );
  }

  BudgetPerformanceAnalysis _getEmptyBudgetPerformanceAnalysis() {
    return BudgetPerformanceAnalysis(
      totalBudget: 0,
      totalSpent: 0,
      remainingBudget: 0,
      categoryPerformances: [],
      alerts: [],
      projection: BudgetProjection(
        projectedSpending: 0,
        projectedOverage: 0,
        willExceedBudget: false,
        projectedExceedDate: DateTime.now(),
        categoryProjections: [],
      ),
      insights: [],
      analysisDate: DateTime.now(),
    );
  }

  FinancialHealthData _getEmptyFinancialHealthData() {
    return FinancialHealthData(
      overallScore: 0,
      spendingScore: 0,
      savingsScore: 0,
      budgetScore: 0,
      categoryScores: {},
      recommendations: [],
      lastCalculated: DateTime.now(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
