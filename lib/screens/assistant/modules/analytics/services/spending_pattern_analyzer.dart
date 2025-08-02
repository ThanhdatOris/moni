import 'dart:math';
/// Spending Pattern Analyzer - Chuyên phân tích mẫu chi tiêu
/// Migrated from lib/services/analytics/ để tăng tính modularity

import '../../../../../core/models/analytics/analytics_models.dart';
import '../../../../../models/transaction_model.dart';
import '../../../../../services/base_service.dart';
import '../../../../../services/category_service.dart';
import '../../../../../services/offline_service.dart';
import '../../../../../services/transaction_service.dart';
import '../../../../../utils/logging/logging_utils.dart';

/// Service chuyên phân tích mẫu chi tiêu của người dùng
class SpendingPatternAnalyzer extends BaseService {
  static final SpendingPatternAnalyzer _instance = SpendingPatternAnalyzer._internal();
  factory SpendingPatternAnalyzer() => _instance;
  SpendingPatternAnalyzer._internal();

  late final TransactionService _transactionService;
  late final CategoryService _categoryService;

  /// Initialize services (call this before using)
  void _initializeServices() {
    final offlineService = OfflineService();
    _transactionService = TransactionService(offlineService: offlineService);
    _categoryService = CategoryService();
  }

  /// Main method: Analyze comprehensive spending patterns
  Future<SpendingPatternAnalysis> analyzeSpendingPatterns() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      _initializeServices();
      logInfo('Analyzing spending patterns for user: $currentUserId');

      final transactions = await _getAllTransactions();
      if (transactions.isEmpty) {
        return _getEmptyAnalysis();
      }

      // Run all pattern analyses in parallel
      final futures = await Future.wait([
        _analyzeWeeklyPatterns(transactions),
        _analyzeMonthlyTrends(transactions),
        _analyzeCategoryDistribution(transactions),
        _analyzeSeasonalPatterns(transactions),
        _detectPatternAnomalies(transactions),
        _generateSpendingPredictions(transactions),
      ]);

      final analysis = SpendingPatternAnalysis(
        weeklyPatterns: futures[0] as Map<String, WeeklySpendingPattern>,
        monthlyTrends: futures[1] as Map<String, MonthlyTrend>,
        categoryDistribution: futures[2] as Map<String, CategoryDistribution>,
        seasonalPatterns: futures[3] as Map<String, SeasonalPattern>,
        anomalies: futures[4] as List<SpendingAnomaly>,
        predictions: futures[5] as List<SpendingPrediction>,
        analysisDate: DateTime.now(),
        confidenceScore: _calculateOverallConfidence(transactions),
      );

      logInfo('Completed spending pattern analysis');
      return analysis;
    } catch (e) {
      logError(
        'Error analyzing spending patterns',
        className: 'SpendingPatternAnalyzer',
        methodName: 'analyzeSpendingPatterns',
        error: e,
      );
      return _getEmptyAnalysis();
    }
  }

  /// Quick spending insights for dashboard
  Future<Map<String, dynamic>> getQuickSpendingInsights() async {
    try {
      if (currentUserId == null) return {};

      _initializeServices();
      final transactions = await _getRecentTransactions(days: 30);
      
      if (transactions.isEmpty) return {};

      final totalSpending = transactions.fold(0.0, (sum, t) => sum + t.amount);
      final avgDaily = totalSpending / 30;
      final topCategory = await _getTopSpendingCategory(transactions);

      return {
        'totalSpending': totalSpending,
        'averageDaily': avgDaily,
        'transactionCount': transactions.length,
        'topCategory': topCategory,
        'spendingTrend': await _getSpendingTrend(transactions),
      };
    } catch (e) {
      logError(
        'Error getting quick spending insights',
        className: 'SpendingPatternAnalyzer',
        methodName: 'getQuickSpendingInsights',
        error: e,
      );
      return {};
    }
  }

  /// Analyze specific category spending
  Future<Map<String, dynamic>> analyzeCategorySpending(String categoryId) async {
    try {
      _initializeServices();
      final transactions = await _getAllTransactions();
      final categoryTransactions = transactions.where((t) => t.categoryId == categoryId).toList();

      if (categoryTransactions.isEmpty) return {};

      final totalAmount = categoryTransactions.fold(0.0, (sum, t) => sum + t.amount);
      final avgAmount = totalAmount / categoryTransactions.length;
      final weeklyPattern = await _analyzeWeeklyPatternsForCategory(categoryId, categoryTransactions);

      return {
        'totalAmount': totalAmount,
        'averageAmount': avgAmount,
        'transactionCount': categoryTransactions.length,
        'weeklyPattern': weeklyPattern.toJson(),
        'trend': await _getCategoryTrend(categoryTransactions),
        'frequency': _getCategoryFrequency(categoryTransactions),
      };
    } catch (e) {
      logError(
        'Error analyzing category spending',
        className: 'SpendingPatternAnalyzer',
        methodName: 'analyzeCategorySpending',
        error: e,
      );
      return {};
    }
  }

  /// Get trending insights
  Future<List<TrendingInsight>> getTrendingInsights({int days = 30}) async {
    try {
      _initializeServices();
      final transactions = await _getRecentTransactions(days: days);
      final insights = <TrendingInsight>[];

      // Analyze trends by category
      final categoryGroups = <String, List<TransactionModel>>{};
      for (final transaction in transactions) {
        categoryGroups.putIfAbsent(transaction.categoryId, () => []).add(transaction);
      }

      for (final entry in categoryGroups.entries) {
        final categoryId = entry.key;
        final categoryTransactions = entry.value;
        
        final trend = await _calculateCategoryTrendDirection(categoryTransactions);
        final impact = _calculateTrendImpact(categoryTransactions);

        if (impact > 0.1) { // Only significant trends
          insights.add(TrendingInsight(
            type: 'spending_trend',
            title: trend == 'up' ? 'Chi tiêu tăng' : 'Chi tiêu giảm',
            description: trend == 'up' ? 'Chi tiêu tăng' : 'Chi tiêu giảm',
            categoryId: categoryId,
            impact: impact,
            trend: trend,
          ));
        }
      }

      return insights;
    } catch (e) {
      logError(
        'Error getting trending insights',
        className: 'SpendingPatternAnalyzer',
        methodName: 'getTrendingInsights',
        error: e,
      );
      return [];
    }
  }

  // Private analysis methods

  Future<Map<String, WeeklySpendingPattern>> _analyzeWeeklyPatterns(
    List<TransactionModel> transactions,
  ) async {
    final patterns = <String, WeeklySpendingPattern>{};
    
    // Group by category
    final categoryGroups = <String, List<TransactionModel>>{};
    for (final transaction in transactions) {
      categoryGroups.putIfAbsent(transaction.categoryId, () => []).add(transaction);
    }

    for (final entry in categoryGroups.entries) {
      final categoryId = entry.key;
      final categoryTransactions = entry.value;
      
      patterns[categoryId] = await _analyzeWeeklyPatternsForCategory(categoryId, categoryTransactions);
    }

    return patterns;
  }

  Future<WeeklySpendingPattern> _analyzeWeeklyPatternsForCategory(
    String categoryId,
    List<TransactionModel> transactions,
  ) async {
    // Analyze weekly patterns
    final weeklyData = <int, double>{};
    for (final transaction in transactions) {
      final weekday = transaction.date.weekday;
      weeklyData[weekday] = (weeklyData[weekday] ?? 0) + transaction.amount;
    }

    // Calculate statistics
    final values = weeklyData.values.toList();
    final average = values.isNotEmpty ? values.reduce((a, b) => a + b) / values.length : 0.0;
    final variance = values.isNotEmpty
        ? values.map((v) => pow(v - average, 2)).reduce((a, b) => a + b) / values.length
        : 0.0;

    return WeeklySpendingPattern(
      categoryId: categoryId,
      averageDaily: average,
      variance: variance,
      peakDay: weeklyData.entries.isNotEmpty
          ? weeklyData.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : 1,
      dailyDistribution: weeklyData,
    );
  }

  Future<Map<String, MonthlyTrend>> _analyzeMonthlyTrends(
    List<TransactionModel> transactions,
  ) async {
    final trends = <String, MonthlyTrend>{};
    
    // Group by category and month
    final categoryMonthlyData = <String, Map<int, double>>{};
    for (final transaction in transactions) {
      final monthKey = transaction.date.year * 12 + transaction.date.month;
      categoryMonthlyData
          .putIfAbsent(transaction.categoryId, () => {})
          .update(monthKey, (v) => v + transaction.amount, ifAbsent: () => transaction.amount);
    }

    for (final entry in categoryMonthlyData.entries) {
      final categoryId = entry.key;
      final monthlyData = entry.value;
      
      // Calculate trend
      final trend = _calculateTrend(monthlyData);
      final seasonality = _calculateSeasonality(monthlyData);
      
      trends[categoryId] = MonthlyTrend(
        categoryId: categoryId,
        trend: trend,
        seasonality: seasonality,
        monthlyData: monthlyData,
        confidence: _calculateTrendConfidence(monthlyData),
      );
    }

    return trends;
  }

  Future<Map<String, CategoryDistribution>> _analyzeCategoryDistribution(
    List<TransactionModel> transactions,
  ) async {
    final distribution = <String, CategoryDistribution>{};
    
    // Calculate total spending
    final totalSpending = transactions.fold(0.0, (sum, t) => sum + t.amount);
    
    // Group by category
    final categorySpending = <String, double>{};
    final categoryCount = <String, int>{};
    
    for (final transaction in transactions) {
      categorySpending[transaction.categoryId] = 
          (categorySpending[transaction.categoryId] ?? 0) + transaction.amount;
      categoryCount[transaction.categoryId] = 
          (categoryCount[transaction.categoryId] ?? 0) + 1;
    }

    for (final entry in categorySpending.entries) {
      final categoryId = entry.key;
      final amount = entry.value;
      final count = categoryCount[categoryId] ?? 0;
      
      distribution[categoryId] = CategoryDistribution(
        categoryId: categoryId,
        totalAmount: amount,
        percentage: totalSpending > 0 ? (amount / totalSpending) * 100 : 0,
        transactionCount: count,
        averageAmount: count > 0 ? amount / count : 0,
      );
    }

    return distribution;
  }

  Future<Map<String, SeasonalPattern>> _analyzeSeasonalPatterns(
    List<TransactionModel> transactions,
  ) async {
    final patterns = <String, SeasonalPattern>{};
    
    // Group by category and season
    final categorySeasonalData = <String, Map<String, double>>{};
    
    for (final transaction in transactions) {
      final season = _getSeason(transaction.date);
      categorySeasonalData
          .putIfAbsent(transaction.categoryId, () => {})
          .update(season, (v) => v + transaction.amount, ifAbsent: () => transaction.amount);
    }

    for (final entry in categorySeasonalData.entries) {
      final categoryId = entry.key;
      final seasonalData = entry.value;
      
      // Calculate seasonal indices
      final totalAnnual = seasonalData.values.fold(0.0, (sum, v) => sum + v);
      final averageQuarterly = totalAnnual / 4;
      
      final seasonalIndices = <String, double>{};
      for (final season in seasonalData.keys) {
        seasonalIndices[season] = seasonalData[season]! / averageQuarterly;
      }

      patterns[categoryId] = SeasonalPattern(
        categoryId: categoryId,
        seasonalIndices: seasonalIndices,
        peakSeason: seasonalData.entries.isNotEmpty
            ? seasonalData.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : 'Spring',
        seasonalData: seasonalData,
      );
    }

    return patterns;
  }

  Future<List<SpendingAnomaly>> _detectPatternAnomalies(
    List<TransactionModel> transactions,
  ) async {
    final anomalies = <SpendingAnomaly>[];
    
    // Statistical anomalies based on amount patterns
    for (final transaction in transactions) {
      final categoryTransactions = transactions
          .where((t) => t.categoryId == transaction.categoryId)
          .toList();
      
      if (categoryTransactions.length < 3) continue;
      
      final amounts = categoryTransactions.map((t) => t.amount).toList();
      final mean = amounts.reduce((a, b) => a + b) / amounts.length;
      final variance = amounts.map((a) => pow(a - mean, 2)).reduce((a, b) => a + b) / amounts.length;
      final stdDev = sqrt(variance);
      
      // Check if this transaction is an outlier (>2 standard deviations)
      if ((transaction.amount - mean).abs() > 2 * stdDev) {
        anomalies.add(SpendingAnomaly(
          id: 'pattern_${transaction.transactionId}',
          type: 'statistical',
          severity: transaction.amount > mean + 2 * stdDev ? 'high' : 'medium',
          description: 'Giao dịch bất thường về số tiền so với lịch sử',
          transaction: transaction,
          detectedAt: DateTime.now(),
          confidence: 0.8,
        ));
      }
    }

    return anomalies;
  }

  Future<List<SpendingPrediction>> _generateSpendingPredictions(
    List<TransactionModel> transactions,
  ) async {
    final predictions = <SpendingPrediction>[];
    
    // Group by category
    final categoryGroups = <String, List<TransactionModel>>{};
    for (final transaction in transactions) {
      categoryGroups.putIfAbsent(transaction.categoryId, () => []).add(transaction);
    }

    for (final entry in categoryGroups.entries) {
      final categoryId = entry.key;
      final categoryTransactions = entry.value;
      
      if (categoryTransactions.length < 3) continue;
      
      // Simple prediction based on trend
      final monthlyData = <int, double>{};
      for (final transaction in categoryTransactions) {
        final monthKey = transaction.date.year * 12 + transaction.date.month;
        monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + transaction.amount;
      }

      final trend = _calculateTrend(monthlyData);
      final average = monthlyData.values.reduce((a, b) => a + b) / monthlyData.length;
      
      final nextMonthPrediction = average + trend;
      
      predictions.add(SpendingPrediction(
        categoryId: categoryId,
        predictedAmount: nextMonthPrediction,
        confidence: _calculatePredictionConfidence(monthlyData),
        period: 'next_month',
        factors: [
          'Lịch sử trung bình: ${average.toStringAsFixed(0)}',
          'Xu hướng: ${trend > 0 ? "tăng" : "giảm"} ${trend.abs().toStringAsFixed(0)}',
        ],
      ));
    }

    return predictions;
  }

  // Helper methods

  Future<List<TransactionModel>> _getAllTransactions() async {
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
    return await _transactionService.getTransactionsByDateRange(
      sixMonthsAgo,
      DateTime.now(),
    );
  }

  Future<List<TransactionModel>> _getRecentTransactions({int days = 30}) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    return await _transactionService.getTransactionsByDateRange(
      startDate,
      DateTime.now(),
    );
  }

  Future<String> _getTopSpendingCategory(List<TransactionModel> transactions) async {
    if (transactions.isEmpty) return 'Không có';
    
    final categorySpending = <String, double>{};
    for (final transaction in transactions) {
      categorySpending[transaction.categoryId] = 
          (categorySpending[transaction.categoryId] ?? 0) + transaction.amount;
    }

    final topEntry = categorySpending.entries.reduce((a, b) => a.value > b.value ? a : b);
    
    // Get category name
    try {
      final categories = await _categoryService.getCategories().first;
      final category = categories.firstWhere((c) => c.id == topEntry.key);
      return category.name;
    } catch (e) {
      return 'Danh mục khác';
    }
  }

  Future<String> _getSpendingTrend(List<TransactionModel> transactions) async {
    if (transactions.length < 14) return 'stable';
    
    // Compare first half vs second half
    final mid = transactions.length ~/ 2;
    final firstHalf = transactions.take(mid).fold(0.0, (sum, t) => sum + t.amount);
    final secondHalf = transactions.skip(mid).fold(0.0, (sum, t) => sum + t.amount);
    
    if (secondHalf > firstHalf * 1.1) return 'up';
    if (secondHalf < firstHalf * 0.9) return 'down';
    return 'stable';
  }

  Future<String> _getCategoryTrend(List<TransactionModel> transactions) async {
    if (transactions.length < 6) return 'stable';
    
    final monthlyData = <int, double>{};
    for (final transaction in transactions) {
      final monthKey = transaction.date.year * 12 + transaction.date.month;
      monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + transaction.amount;
    }

    final trend = _calculateTrend(monthlyData);
    if (trend > 0.1) return 'up';
    if (trend < -0.1) return 'down';
    return 'stable';
  }

  String _getCategoryFrequency(List<TransactionModel> transactions) {
    final days = DateTime.now().difference(transactions.first.date).inDays;
    final frequency = transactions.length / (days / 30); // transactions per month
    
    if (frequency >= 10) return 'high';
    if (frequency >= 5) return 'medium';
    return 'low';
  }

  Future<String> _calculateCategoryTrendDirection(List<TransactionModel> transactions) async {
    return await _getCategoryTrend(transactions);
  }

  double _calculateTrendImpact(List<TransactionModel> transactions) {
    final totalAmount = transactions.fold(0.0, (sum, t) => sum + t.amount);
    return (totalAmount / 1000000).clamp(0.0, 1.0); // Normalize to 0-1
  }

  double _calculateTrend(Map<int, double> monthlyData) {
    if (monthlyData.length < 2) return 0.0;
    
    final sortedEntries = monthlyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    if (sortedEntries.length < 2) return 0.0;
    
    final firstValue = sortedEntries.first.value;
    final lastValue = sortedEntries.last.value;
    
    return (lastValue - firstValue) / sortedEntries.length;
  }

  double _calculateSeasonality(Map<int, double> monthlyData) {
    // Simple seasonal calculation
    final currentMonth = DateTime.now().month;
    final seasonalFactors = [
      1.1, 0.9, 1.0, 1.0, 1.0, 1.0, // Jan-Jun
      1.2, 1.1, 1.0, 1.0, 1.1, 1.3, // Jul-Dec
    ];
    
    final average = monthlyData.values.isNotEmpty
        ? monthlyData.values.reduce((a, b) => a + b) / monthlyData.length
        : 0.0;
    
    return average * (seasonalFactors[currentMonth - 1] - 1);
  }

  double _calculateTrendConfidence(Map<int, double> monthlyData) {
    if (monthlyData.length < 3) return 0.3;
    
    final values = monthlyData.values.toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    final coefficientOfVariation = sqrt(variance) / mean;
    
    return (1.0 / (1.0 + coefficientOfVariation)).clamp(0.0, 1.0);
  }

  double _calculatePredictionConfidence(Map<int, double> monthlyData) {
    return _calculateTrendConfidence(monthlyData);
  }

  double _calculateOverallConfidence(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return 0.0;
    
    final dataPoints = transactions.length;
    final timeSpan = transactions.isNotEmpty
        ? transactions.map((t) => t.date).reduce((a, b) => a.isAfter(b) ? a : b)
            .difference(transactions.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b))
            .inDays
        : 0;
    
    // More data points and longer time span = higher confidence
    final dataScore = (dataPoints / 100.0).clamp(0.0, 1.0);
    final timeScore = (timeSpan / 180.0).clamp(0.0, 1.0); // 6 months = full score
    
    return (dataScore + timeScore) / 2;
  }

  String _getSeason(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) return 'Spring';
    if (month >= 6 && month <= 8) return 'Summer';
    if (month >= 9 && month <= 11) return 'Fall';
    return 'Winter';
  }

  SpendingPatternAnalysis _getEmptyAnalysis() {
    return SpendingPatternAnalysis(
      weeklyPatterns: {},
      monthlyTrends: {},
      categoryDistribution: {},
      seasonalPatterns: {},
      anomalies: [],
      predictions: [],
      analysisDate: DateTime.now(),
      confidenceScore: 0.0,
    );
  }
} 
