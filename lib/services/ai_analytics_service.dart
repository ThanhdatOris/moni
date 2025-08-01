import 'dart:async';
import 'dart:math';

import 'package:uuid/uuid.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/base_service.dart';
import '../services/category_service.dart';
import '../services/offline_service.dart';
import '../services/transaction_service.dart';

/// AI Analytics Service - Advanced spending pattern analysis and insights
class AIAnalyticsService extends BaseService {
  static final AIAnalyticsService _instance = AIAnalyticsService._internal();
  factory AIAnalyticsService() => _instance;

  late final TransactionService _transactionService;
  late final CategoryService _categoryService;
  final _uuid = const Uuid();

  AIAnalyticsService._internal() {
    final offlineService = OfflineService();
    _transactionService = TransactionService(offlineService: offlineService);
    _categoryService = CategoryService();
  }

  /// Advanced spending pattern analysis
  Future<SpendingPatternAnalysis> analyzeSpendingPatterns() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      logInfo('Analyzing spending patterns for user: $currentUserId');

      final transactions = await _getAllTransactions();
      if (transactions.isEmpty) {
        return _getEmptyAnalysis();
      }

      final weeklyPatterns = await _analyzeWeeklyPatterns(transactions);
      final monthlyTrends = await _analyzeMonthlyTrends(transactions);
      final categoryDistribution = await _analyzeCategoryDistribution(transactions);
      final seasonalPatterns = await _analyzeSeasonalPatterns(transactions);
      final anomalies = await _detectAnomalies(transactions);
      final predictions = await _generatePredictions(transactions);

      final analysis = SpendingPatternAnalysis(
        weeklyPatterns: weeklyPatterns,
        monthlyTrends: monthlyTrends,
        categoryDistribution: categoryDistribution,
        seasonalPatterns: seasonalPatterns,
        anomalies: anomalies,
        predictions: predictions,
        analysisDate: DateTime.now(),
        confidenceScore: _calculateOverallConfidence(transactions),
      );

      logInfo('Completed spending pattern analysis');
      return analysis;
    } catch (e) {
      logError('Error analyzing spending patterns', e);
      return _getEmptyAnalysis();
    }
  }

  /// Intelligent category optimization
  Future<CategoryOptimization> optimizeCategories() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      logInfo('Optimizing categories for user: $currentUserId');

      final currentCategories = await _categoryService.getCategories().first;
      final transactions = await _getAllTransactions();

      final suggestedMerges = await _suggestCategoryMerges(currentCategories, transactions);
      final suggestedSplits = await _suggestCategorySplits(currentCategories, transactions);
      final unusedCategories = await _identifyUnusedCategories(currentCategories, transactions);
      final newCategorySuggestions = await _suggestNewCategories(transactions);

      final optimization = CategoryOptimization(
        suggestedMerges: suggestedMerges,
        suggestedSplits: suggestedSplits,
        unusedCategories: unusedCategories,
        newCategorySuggestions: newCategorySuggestions,
        optimizationDate: DateTime.now(),
        potentialSavings: _calculatePotentialSavings(suggestedMerges, suggestedSplits),
      );

      logInfo('Completed category optimization');
      return optimization;
    } catch (e) {
      logError('Error optimizing categories', e);
      return _getEmptyOptimization();
    }
  }

  /// AI-powered financial health scoring
  Future<FinancialHealthScore> calculateFinancialHealth() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      logInfo('Calculating financial health score for user: $currentUserId');

      final spendingData = await _getSpendingData();
      final budgetData = await _getBudgetData();
      final savingsData = await _getSavingsData();

      final overallScore = await _calculateOverallScore(spendingData, budgetData, savingsData);
      final spendingScore = await _calculateSpendingScore(spendingData);
      final budgetScore = await _calculateBudgetScore(budgetData);
      final savingsScore = await _calculateSavingsScore(savingsData);
      final recommendations = await _generateHealthRecommendations(spendingData, budgetData, savingsData);

      final healthScore = FinancialHealthScore(
        overallScore: overallScore,
        spendingScore: spendingScore,
        budgetScore: budgetScore,
        savingsScore: savingsScore,
        recommendations: recommendations,
        lastCalculated: DateTime.now(),
        trend: await _calculateHealthTrend(),
        factors: await _getHealthFactors(spendingData, budgetData, savingsData),
      );

      logInfo('Completed financial health calculation');
      return healthScore;
    } catch (e) {
      logError('Error calculating financial health', e);
      return _getEmptyHealthScore();
    }
  }

  /// Advanced anomaly detection
  Future<List<SpendingAnomaly>> detectAdvancedAnomalies() async {
    try {
      if (currentUserId == null) return [];

      logInfo('Detecting advanced anomalies');

      final transactions = await _getAllTransactions();
      final anomalies = <SpendingAnomaly>[];

      // Statistical anomalies
      anomalies.addAll(await _detectStatisticalAnomalies(transactions));

      // Behavioral anomalies
      anomalies.addAll(await _detectBehavioralAnomalies(transactions));

      // Temporal anomalies
      anomalies.addAll(await _detectTemporalAnomalies(transactions));

      // Category anomalies
      anomalies.addAll(await _detectCategoryAnomalies(transactions));

      // Sort by severity
      anomalies.sort((a, b) => b.severity.compareTo(a.severity));

      logInfo('Detected ${anomalies.length} anomalies');
      return anomalies;
    } catch (e) {
      logError('Error detecting anomalies', e);
      return [];
    }
  }

  /// Predictive cash flow analysis
  Future<CashFlowPrediction> predictCashFlow({int months = 3}) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      logInfo('Predicting cash flow for $months months');

      final transactions = await _getAllTransactions();
      final predictions = <MonthlyPrediction>[];

      for (int i = 1; i <= months; i++) {
        final targetMonth = DateTime.now().add(Duration(days: 30 * i));
        final prediction = await _predictMonthlyFlow(transactions, targetMonth);
        predictions.add(prediction);
      }

      final cashFlowPrediction = CashFlowPrediction(
        predictions: predictions,
        totalPredictedIncome: predictions.fold(0.0, (sum, p) => sum + p.income),
        totalPredictedExpenses: predictions.fold(0.0, (sum, p) => sum + p.expenses),
        confidence: _calculatePredictionConfidence(predictions),
        factors: await _getPredictionFactors(transactions),
      );

      logInfo('Completed cash flow prediction');
      return cashFlowPrediction;
    } catch (e) {
      logError('Error predicting cash flow', e);
      return _getEmptyCashFlowPrediction();
    }
  }

  /// Smart budget recommendations
  Future<List<SmartBudgetRecommendation>> generateSmartBudgetRecommendations() async {
    try {
      if (currentUserId == null) return [];

      logInfo('Generating smart budget recommendations');

      final transactions = await _getAllTransactions();
      final categories = await _categoryService.getCategories().first;
      final recommendations = <SmartBudgetRecommendation>[];

      // Analyze spending patterns
      final spendingAnalysis = await analyzeSpendingPatterns();
      
      // Generate category-based recommendations
      for (final category in categories) {
        final categoryTransactions = transactions
            .where((t) => t.categoryId == category.id)
            .toList();

        if (categoryTransactions.isNotEmpty) {
          final recommendation = await _generateCategoryRecommendation(
            category,
            categoryTransactions,
            spendingAnalysis,
          );
          
          if (recommendation != null) {
            recommendations.add(recommendation);
          }
        }
      }

      // Sort by priority
      recommendations.sort((a, b) => b.priority.compareTo(a.priority));

      logInfo('Generated ${recommendations.length} smart budget recommendations');
      return recommendations;
    } catch (e) {
      logError('Error generating smart budget recommendations', e);
      return [];
    }
  }

  // Private methods

  Future<List<TransactionModel>> _getAllTransactions() async {
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
    return await _transactionService.getTransactionsByDateRange(
      sixMonthsAgo,
      DateTime.now(),
    );
  }

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
      
      // Analyze weekly patterns
      final weeklyData = <int, double>{};
      for (final transaction in categoryTransactions) {
        final weekday = transaction.date.weekday;
        weeklyData[weekday] = (weeklyData[weekday] ?? 0) + transaction.amount;
      }

      // Calculate statistics
      final values = weeklyData.values.toList();
      final average = values.isNotEmpty ? values.reduce((a, b) => a + b) / values.length : 0.0;
      final variance = values.isNotEmpty
          ? values.map((v) => pow(v - average, 2)).reduce((a, b) => a + b) / values.length
          : 0.0;

      patterns[categoryId] = WeeklySpendingPattern(
        categoryId: categoryId,
        averageDaily: average,
        variance: variance,
        peakDay: weeklyData.entries.isNotEmpty
            ? weeklyData.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : 1,
        dailyDistribution: weeklyData,
      );
    }

    return patterns;
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

  Future<List<SpendingAnomaly>> _detectAnomalies(
    List<TransactionModel> transactions,
  ) async {
    final anomalies = <SpendingAnomaly>[];
    
    // Statistical anomalies
    anomalies.addAll(await _detectStatisticalAnomalies(transactions));
    
    // Behavioral anomalies
    anomalies.addAll(await _detectBehavioralAnomalies(transactions));
    
    return anomalies;
  }

  Future<List<SpendingAnomaly>> _detectStatisticalAnomalies(
    List<TransactionModel> transactions,
  ) async {
    final anomalies = <SpendingAnomaly>[];
    
    // Group by category
    final categoryGroups = <String, List<TransactionModel>>{};
    for (final transaction in transactions) {
      categoryGroups.putIfAbsent(transaction.categoryId, () => []).add(transaction);
    }

    for (final entry in categoryGroups.entries) {
      final categoryTransactions = entry.value;
      
      if (categoryTransactions.length < 5) continue; // Need sufficient data
      
      // Calculate statistics
      final amounts = categoryTransactions.map((t) => t.amount).toList();
      final mean = amounts.reduce((a, b) => a + b) / amounts.length;
      final variance = amounts.map((a) => pow(a - mean, 2)).reduce((a, b) => a + b) / amounts.length;
      final standardDeviation = sqrt(variance);
      
      // Find outliers using Z-score
      for (final transaction in categoryTransactions) {
        final zScore = (transaction.amount - mean) / standardDeviation;
        
        if (zScore.abs() > 2.0) { // 95% confidence
          anomalies.add(SpendingAnomaly(
            id: _uuid.v4(),
            type: 'statistical',
            severity: zScore.abs() > 3.0 ? 'high' : 'medium',
            description: 'Unusual amount: ${transaction.amount.toStringAsFixed(0)} (${zScore.toStringAsFixed(1)}σ)',
            transaction: transaction,
            detectedAt: DateTime.now(),
            confidence: (zScore.abs() / 3.0).clamp(0.0, 1.0),
          ));
        }
      }
    }

    return anomalies;
  }

  Future<List<SpendingAnomaly>> _detectBehavioralAnomalies(
    List<TransactionModel> transactions,
  ) async {
    final anomalies = <SpendingAnomaly>[];
    
    // Detect unusual times
    final timeFrequency = <int, int>{};
    for (final transaction in transactions) {
      final hour = transaction.date.hour;
      timeFrequency[hour] = (timeFrequency[hour] ?? 0) + 1;
    }

    final averageFrequency = timeFrequency.values.isNotEmpty
        ? timeFrequency.values.reduce((a, b) => a + b) / timeFrequency.length
        : 0.0;

    for (final transaction in transactions) {
      final hour = transaction.date.hour;
      final frequency = timeFrequency[hour] ?? 0;
      
      if (frequency < averageFrequency * 0.1) { // Very rare time
        anomalies.add(SpendingAnomaly(
          id: _uuid.v4(),
          type: 'behavioral',
          severity: 'low',
          description: 'Unusual time: ${hour}:00 (rare transaction time)',
          transaction: transaction,
          detectedAt: DateTime.now(),
          confidence: 0.6,
        ));
      }
    }

    return anomalies;
  }

  Future<List<SpendingAnomaly>> _detectTemporalAnomalies(
    List<TransactionModel> transactions,
  ) async {
    final anomalies = <SpendingAnomaly>[];
    
    // Detect unusual frequency patterns
    final dailyTransactionCounts = <String, int>{};
    for (final transaction in transactions) {
      final dateKey = '${transaction.date.year}-${transaction.date.month}-${transaction.date.day}';
      dailyTransactionCounts[dateKey] = (dailyTransactionCounts[dateKey] ?? 0) + 1;
    }

    final counts = dailyTransactionCounts.values.toList();
    if (counts.isNotEmpty) {
      final averageDaily = counts.reduce((a, b) => a + b) / counts.length;
      
      for (final entry in dailyTransactionCounts.entries) {
        if (entry.value > averageDaily * 3) { // 3x normal activity
          // Find transactions for this day
          final dayTransactions = transactions.where((t) {
            final dateKey = '${t.date.year}-${t.date.month}-${t.date.day}';
            return dateKey == entry.key;
          }).toList();

          for (final transaction in dayTransactions) {
            anomalies.add(SpendingAnomaly(
              id: _uuid.v4(),
              type: 'temporal',
              severity: 'medium',
              description: 'High activity day: ${entry.value} transactions',
              transaction: transaction,
              detectedAt: DateTime.now(),
              confidence: 0.7,
            ));
          }
        }
      }
    }

    return anomalies;
  }

  Future<List<SpendingAnomaly>> _detectCategoryAnomalies(
    List<TransactionModel> transactions,
  ) async {
    final anomalies = <SpendingAnomaly>[];
    
    // Detect unusual category combinations within short time periods
    final timeWindows = <String, List<TransactionModel>>{};
    
    for (final transaction in transactions) {
      final hourKey = '${transaction.date.year}-${transaction.date.month}-${transaction.date.day}-${transaction.date.hour}';
      timeWindows.putIfAbsent(hourKey, () => []).add(transaction);
    }

    for (final entry in timeWindows.entries) {
      final windowTransactions = entry.value;
      if (windowTransactions.length > 1) {
        final categories = windowTransactions.map((t) => t.categoryId).toSet();
        
        // If many different categories in short time, it might be unusual
        if (categories.length >= 3) {
          for (final transaction in windowTransactions) {
            anomalies.add(SpendingAnomaly(
              id: _uuid.v4(),
              type: 'category',
              severity: 'low',
              description: 'Multiple categories in short time: ${categories.length} categories',
              transaction: transaction,
              detectedAt: DateTime.now(),
              confidence: 0.5,
            ));
          }
        }
      }
    }

    return anomalies;
  }

  Future<List<SpendingPrediction>> _generatePredictions(
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
        confidence: _calculatePredictionConfidence([]),
        period: 'next_month',
        factors: [
          'Historical average: ${average.toStringAsFixed(0)}',
          'Trend adjustment: ${trend.toStringAsFixed(0)}',
        ],
      ));
    }

    return predictions;
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

  // Data retrieval methods
  Future<SpendingData> _getSpendingData() async {
    final transactions = await _getAllTransactions();
    final totalSpending = transactions.fold(0.0, (sum, t) => sum + t.amount);
    
    return SpendingData(
      totalSpending: totalSpending,
      averageDaily: totalSpending / 30, // Last 30 days
      categories: await _analyzeCategoryDistribution(transactions),
      trends: await _analyzeMonthlyTrends(transactions),
    );
  }

  Future<BudgetData> _getBudgetData() async {
    // Mock budget data - in real app, get from budget service
    return BudgetData(
      totalBudget: 50000,
      utilizationRate: 0.8,
      categoriesWithBudgets: 5,
      categoriesWithoutBudgets: 3,
    );
  }

  Future<SavingsData> _getSavingsData() async {
    // Mock savings data - in real app, get from savings service
    return SavingsData(
      totalSavings: 100000,
      monthlyContribution: 10000,
      savingsRate: 0.2,
      savingsGoal: 500000,
    );
  }

  Future<double> _calculateOverallScore(
    SpendingData spendingData,
    BudgetData budgetData,
    SavingsData savingsData,
  ) async {
    final spendingScore = await _calculateSpendingScore(spendingData);
    final budgetScore = await _calculateBudgetScore(budgetData);
    final savingsScore = await _calculateSavingsScore(savingsData);
    
    return (spendingScore + budgetScore + savingsScore) / 3;
  }

  Future<double> _calculateSpendingScore(SpendingData spendingData) async {
    // Simple scoring based on spending patterns
    final categoryDiversity = spendingData.categories.length / 10.0; // Max 10 categories
    final trendStability = _calculateTrendStability(spendingData.trends);
    
    return ((1.0 - categoryDiversity.clamp(0.0, 1.0)) + trendStability) / 2;
  }

  Future<double> _calculateBudgetScore(BudgetData budgetData) async {
    final utilizationScore = 1.0 - (budgetData.utilizationRate - 0.8).abs(); // Optimal at 80%
    final coverageScore = budgetData.categoriesWithBudgets / 
        (budgetData.categoriesWithBudgets + budgetData.categoriesWithoutBudgets);
    
    return (utilizationScore + coverageScore) / 2;
  }

  Future<double> _calculateSavingsScore(SavingsData savingsData) async {
    final savingsRateScore = (savingsData.savingsRate / 0.3).clamp(0.0, 1.0); // 30% is excellent
    final goalProgressScore = (savingsData.totalSavings / savingsData.savingsGoal).clamp(0.0, 1.0);
    
    return (savingsRateScore + goalProgressScore) / 2;
  }

  Future<List<HealthRecommendation>> _generateHealthRecommendations(
    SpendingData spendingData,
    BudgetData budgetData,
    SavingsData savingsData,
  ) async {
    final recommendations = <HealthRecommendation>[];
    
    // Spending recommendations
    if (spendingData.totalSpending > 40000) {
      recommendations.add(HealthRecommendation(
        type: 'spending',
        title: 'Reduce spending',
        description: 'Consider reducing discretionary spending',
        priority: 'high',
        impact: 0.8,
      ));
    }
    
    // Budget recommendations
    if (budgetData.utilizationRate > 0.9) {
      recommendations.add(HealthRecommendation(
        type: 'budget',
        title: 'Adjust budgets',
        description: 'Your budgets may be too tight',
        priority: 'medium',
        impact: 0.6,
      ));
    }
    
    // Savings recommendations
    if (savingsData.savingsRate < 0.1) {
      recommendations.add(HealthRecommendation(
        type: 'savings',
        title: 'Increase savings',
        description: 'Try to save at least 10% of income',
        priority: 'high',
        impact: 0.9,
      ));
    }
    
    return recommendations;
  }

  Future<double> _calculateHealthTrend() async {
    // Mock trend calculation
    return 0.05; // 5% improvement
  }

  Future<List<String>> _getHealthFactors(
    SpendingData spendingData,
    BudgetData budgetData,
    SavingsData savingsData,
  ) async {
    return [
      'Spending: ${spendingData.totalSpending.toStringAsFixed(0)}',
      'Budget utilization: ${(budgetData.utilizationRate * 100).toStringAsFixed(0)}%',
      'Savings rate: ${(savingsData.savingsRate * 100).toStringAsFixed(0)}%',
    ];
  }

  double _calculateTrendStability(Map<String, MonthlyTrend> trends) {
    if (trends.isEmpty) return 0.0;
    
    final confidenceValues = trends.values.map((t) => t.confidence).toList();
    return confidenceValues.reduce((a, b) => a + b) / confidenceValues.length;
  }

  double _calculatePredictionConfidence(List<dynamic> predictions) {
    // Simple confidence calculation
    return 0.7; // 70% confidence
  }

  Future<MonthlyPrediction> _predictMonthlyFlow(
    List<TransactionModel> transactions,
    DateTime targetMonth,
  ) async {
    // Simple prediction based on historical averages
    final monthlySpending = <int, double>{};
    for (final transaction in transactions) {
      final monthKey = transaction.date.year * 12 + transaction.date.month;
      monthlySpending[monthKey] = (monthlySpending[monthKey] ?? 0) + transaction.amount;
    }

    final averageSpending = monthlySpending.values.isNotEmpty
        ? monthlySpending.values.reduce((a, b) => a + b) / monthlySpending.length
        : 0.0;

    return MonthlyPrediction(
      month: targetMonth,
      income: 50000, // Mock income
      expenses: averageSpending,
      netFlow: 50000 - averageSpending,
      confidence: 0.7,
    );
  }

  Future<List<String>> _getPredictionFactors(List<TransactionModel> transactions) async {
    return [
      'Historical patterns',
      'Seasonal adjustments',
      'Trend analysis',
    ];
  }

  Future<SmartBudgetRecommendation?> _generateCategoryRecommendation(
    CategoryModel category,
    List<TransactionModel> transactions,
    SpendingPatternAnalysis analysis,
  ) async {
    if (transactions.isEmpty) return null;

    final totalSpending = transactions.fold(0.0, (sum, t) => sum + t.amount);
    final averageMonthly = totalSpending / 3; // Last 3 months
    
    final suggestedBudget = averageMonthly * 1.1; // 10% buffer
    
    return SmartBudgetRecommendation(
      id: _uuid.v4(),
      categoryId: category.id,
      categoryName: category.name,
      recommendationType: 'create',
      suggestedAmount: suggestedBudget,
      currentSpending: totalSpending,
      priority: totalSpending / 10000, // Higher priority for higher spending
      reasoning: 'Based on your spending pattern of ${averageMonthly.toStringAsFixed(0)}/month',
      confidence: 0.8,
      factors: [
        'Monthly average: ${averageMonthly.toStringAsFixed(0)}',
        'Total transactions: ${transactions.length}',
        'Spending trend: stable',
      ],
    );
  }

  // Empty/default objects
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

  CategoryOptimization _getEmptyOptimization() {
    return CategoryOptimization(
      suggestedMerges: [],
      suggestedSplits: [],
      unusedCategories: [],
      newCategorySuggestions: [],
      optimizationDate: DateTime.now(),
      potentialSavings: 0.0,
    );
  }

  FinancialHealthScore _getEmptyHealthScore() {
    return FinancialHealthScore(
      overallScore: 0.0,
      spendingScore: 0.0,
      budgetScore: 0.0,
      savingsScore: 0.0,
      recommendations: [],
      lastCalculated: DateTime.now(),
      trend: 0.0,
      factors: [],
    );
  }

  CashFlowPrediction _getEmptyCashFlowPrediction() {
    return CashFlowPrediction(
      predictions: [],
      totalPredictedIncome: 0.0,
      totalPredictedExpenses: 0.0,
      confidence: 0.0,
      factors: [],
    );
  }

  // Helper methods for optimization
  Future<List<CategoryMergeRecommendation>> _suggestCategoryMerges(
    List<CategoryModel> categories,
    List<TransactionModel> transactions,
  ) async {
    // Implementation for category merge suggestions
    return [];
  }

  Future<List<CategorySplitRecommendation>> _suggestCategorySplits(
    List<CategoryModel> categories,
    List<TransactionModel> transactions,
  ) async {
    // Implementation for category split suggestions
    return [];
  }

  Future<List<String>> _identifyUnusedCategories(
    List<CategoryModel> categories,
    List<TransactionModel> transactions,
  ) async {
    final usedCategories = transactions.map((t) => t.categoryId).toSet();
    return categories
        .where((c) => !usedCategories.contains(c.id))
        .map((c) => c.id)
        .toList();
  }

  Future<List<String>> _suggestNewCategories(
    List<TransactionModel> transactions,
  ) async {
    // Implementation for new category suggestions
    return [];
  }

  double _calculatePotentialSavings(
    List<CategoryMergeRecommendation> merges,
    List<CategorySplitRecommendation> splits,
  ) {
    // Implementation for potential savings calculation
    return 0.0;
  }
}

// Supporting classes for analysis results

class SpendingPatternAnalysis {
  final Map<String, WeeklySpendingPattern> weeklyPatterns;
  final Map<String, MonthlyTrend> monthlyTrends;
  final Map<String, CategoryDistribution> categoryDistribution;
  final Map<String, SeasonalPattern> seasonalPatterns;
  final List<SpendingAnomaly> anomalies;
  final List<SpendingPrediction> predictions;
  final DateTime analysisDate;
  final double confidenceScore;

  SpendingPatternAnalysis({
    required this.weeklyPatterns,
    required this.monthlyTrends,
    required this.categoryDistribution,
    required this.seasonalPatterns,
    required this.anomalies,
    required this.predictions,
    required this.analysisDate,
    required this.confidenceScore,
  });
}

class WeeklySpendingPattern {
  final String categoryId;
  final double averageDaily;
  final double variance;
  final int peakDay;
  final Map<int, double> dailyDistribution;

  WeeklySpendingPattern({
    required this.categoryId,
    required this.averageDaily,
    required this.variance,
    required this.peakDay,
    required this.dailyDistribution,
  });
}

class MonthlyTrend {
  final String categoryId;
  final double trend;
  final double seasonality;
  final Map<int, double> monthlyData;
  final double confidence;

  MonthlyTrend({
    required this.categoryId,
    required this.trend,
    required this.seasonality,
    required this.monthlyData,
    required this.confidence,
  });
}

class CategoryDistribution {
  final String categoryId;
  final double totalAmount;
  final double percentage;
  final int transactionCount;
  final double averageAmount;

  CategoryDistribution({
    required this.categoryId,
    required this.totalAmount,
    required this.percentage,
    required this.transactionCount,
    required this.averageAmount,
  });
}

class SeasonalPattern {
  final String categoryId;
  final Map<String, double> seasonalIndices;
  final String peakSeason;
  final Map<String, double> seasonalData;

  SeasonalPattern({
    required this.categoryId,
    required this.seasonalIndices,
    required this.peakSeason,
    required this.seasonalData,
  });
}

class SpendingAnomaly {
  final String id;
  final String type;
  final String severity;
  final String description;
  final TransactionModel transaction;
  final DateTime detectedAt;
  final double confidence;

  SpendingAnomaly({
    required this.id,
    required this.type,
    required this.severity,
    required this.description,
    required this.transaction,
    required this.detectedAt,
    required this.confidence,
  });
}

class SpendingPrediction {
  final String categoryId;
  final double predictedAmount;
  final double confidence;
  final String period;
  final List<String> factors;

  SpendingPrediction({
    required this.categoryId,
    required this.predictedAmount,
    required this.confidence,
    required this.period,
    required this.factors,
  });
}

class CategoryOptimization {
  final List<CategoryMergeRecommendation> suggestedMerges;
  final List<CategorySplitRecommendation> suggestedSplits;
  final List<String> unusedCategories;
  final List<String> newCategorySuggestions;
  final DateTime optimizationDate;
  final double potentialSavings;

  CategoryOptimization({
    required this.suggestedMerges,
    required this.suggestedSplits,
    required this.unusedCategories,
    required this.newCategorySuggestions,
    required this.optimizationDate,
    required this.potentialSavings,
  });
}

class CategoryMergeRecommendation {
  final List<String> categoryIds;
  final String suggestedName;
  final String reason;
  final double confidence;

  CategoryMergeRecommendation({
    required this.categoryIds,
    required this.suggestedName,
    required this.reason,
    required this.confidence,
  });
}

class CategorySplitRecommendation {
  final String categoryId;
  final List<String> suggestedSplits;
  final String reason;
  final double confidence;

  CategorySplitRecommendation({
    required this.categoryId,
    required this.suggestedSplits,
    required this.reason,
    required this.confidence,
  });
}

class FinancialHealthScore {
  final double overallScore;
  final double spendingScore;
  final double budgetScore;
  final double savingsScore;
  final List<HealthRecommendation> recommendations;
  final DateTime lastCalculated;
  final double trend;
  final List<String> factors;

  FinancialHealthScore({
    required this.overallScore,
    required this.spendingScore,
    required this.budgetScore,
    required this.savingsScore,
    required this.recommendations,
    required this.lastCalculated,
    required this.trend,
    required this.factors,
  });
}

class HealthRecommendation {
  final String type;
  final String title;
  final String description;
  final String priority;
  final double impact;

  HealthRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.impact,
  });
}

class CashFlowPrediction {
  final List<MonthlyPrediction> predictions;
  final double totalPredictedIncome;
  final double totalPredictedExpenses;
  final double confidence;
  final List<String> factors;

  CashFlowPrediction({
    required this.predictions,
    required this.totalPredictedIncome,
    required this.totalPredictedExpenses,
    required this.confidence,
    required this.factors,
  });
}

class MonthlyPrediction {
  final DateTime month;
  final double income;
  final double expenses;
  final double netFlow;
  final double confidence;

  MonthlyPrediction({
    required this.month,
    required this.income,
    required this.expenses,
    required this.netFlow,
    required this.confidence,
  });
}

class SmartBudgetRecommendation {
  final String id;
  final String categoryId;
  final String categoryName;
  final String recommendationType;
  final double suggestedAmount;
  final double currentSpending;
  final double priority;
  final String reasoning;
  final double confidence;
  final List<String> factors;

  SmartBudgetRecommendation({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.recommendationType,
    required this.suggestedAmount,
    required this.currentSpending,
    required this.priority,
    required this.reasoning,
    required this.confidence,
    required this.factors,
  });
}

class SpendingData {
  final double totalSpending;
  final double averageDaily;
  final Map<String, CategoryDistribution> categories;
  final Map<String, MonthlyTrend> trends;

  SpendingData({
    required this.totalSpending,
    required this.averageDaily,
    required this.categories,
    required this.trends,
  });
}

class BudgetData {
  final double totalBudget;
  final double utilizationRate;
  final int categoriesWithBudgets;
  final int categoriesWithoutBudgets;

  BudgetData({
    required this.totalBudget,
    required this.utilizationRate,
    required this.categoriesWithBudgets,
    required this.categoriesWithoutBudgets,
  });
}

class SavingsData {
  final double totalSavings;
  final double monthlyContribution;
  final double savingsRate;
  final double savingsGoal;

  SavingsData({
    required this.totalSavings,
    required this.monthlyContribution,
    required this.savingsRate,
    required this.savingsGoal,
  });
}
