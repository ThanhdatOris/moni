import 'dart:async';
import 'dart:math';

import 'package:uuid/uuid.dart';

import '../models/ai_budget_model.dart';
import '../models/transaction_model.dart';
import '../services/base_service.dart';
import '../services/notification_service.dart';
import '../services/offline_service.dart';
import '../services/transaction_service.dart';

/// AI Budget Agent Service - Intelligent budget monitoring and management
class AIBudgetAgentService extends BaseService {
  static final AIBudgetAgentService _instance =
      AIBudgetAgentService._internal();
  factory AIBudgetAgentService() => _instance;
  AIBudgetAgentService._internal();

  late final TransactionService _transactionService;

  final NotificationService _notificationService = NotificationService();
  final OfflineService _offlineService = OfflineService();
  final _uuid = const Uuid();

  Timer? _monitoringTimer;
  bool _isMonitoring = false;

  // Khởi tạo services sau khi constructor
  void _initializeServices() {
    _transactionService = TransactionService(offlineService: _offlineService);
  }

  /// Start intelligent budget monitoring
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    // Khởi tạo services nếu chưa được khởi tạo
    _initializeServices();

    _isMonitoring = true;
    logInfo('Starting AI budget monitoring');

    // Initial monitoring
    await monitorUserSpending();

    // Set up periodic monitoring (every 30 minutes)
    _monitoringTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => monitorUserSpending(),
    );
  }

  /// Stop monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    logInfo('Stopped AI budget monitoring');
  }

  /// Auto-monitoring user spending with AI analysis
  Future<void> monitorUserSpending() async {
    try {
      if (currentUserId == null) return;

      logInfo('Monitoring user spending for user: $currentUserId');

      final recentTransactions = await _getRecentTransactions();
      final budgets = await _getUserBudgets();

      for (final budget in budgets) {
        final analysis =
            await _analyzeSpendingPattern(budget, recentTransactions);

        // Send intelligent alerts if needed
        if (analysis.requiresAlert) {
          await _sendIntelligentAlert(budget, analysis);
        }

        // Suggest budget adjustments
        if (analysis.requiresAdjustment) {
          await _suggestBudgetAdjustment(budget, analysis);
        }

        // Update budget with AI insights
        await _updateBudgetWithAI(budget, analysis);
      }

      logInfo('Completed spending monitoring cycle');
    } catch (e) {
      logError('Error in monitoring user spending', e);
    }
  }

  /// Predictive budget analysis using AI
  Future<BudgetPrediction> predictBudgetPerformance(String budgetId) async {
    try {
      final budget = await _getBudget(budgetId);
      if (budget == null) {
        throw Exception('Budget not found');
      }

      final historicalData = await _getHistoricalData(budgetId);
      final prediction = await _runPredictiveModel(budget, historicalData);

      logInfo('Generated budget prediction for budget: $budgetId');
      return prediction;
    } catch (e) {
      logError('Error predicting budget performance', e);
      rethrow;
    }
  }

  /// Generate smart budget recommendations
  Future<List<BudgetRecommendation>> generateRecommendations() async {
    try {
      if (currentUserId == null) return [];

      final userProfile = await _getUserProfile();
      final spendingHistory = await _getSpendingHistory();
      final currentBudgets = await _getUserBudgets();

      final recommendations = await _generateSmartRecommendations(
        userProfile,
        spendingHistory,
        currentBudgets,
      );

      logInfo('Generated ${recommendations.length} budget recommendations');
      return recommendations;
    } catch (e) {
      logError('Error generating recommendations', e);
      return [];
    }
  }

  /// Generate periodic intelligent report
  Future<void> generatePeriodicReport(NotificationFrequency frequency) async {
    try {
      if (currentUserId == null) return;

      final insights = await _generateInsights();
      final recommendations = await generateRecommendations();
      final analytics = await _generateAnalytics();

      await _sendIntelligentReport(
          insights, recommendations, analytics, frequency);

      logInfo('Generated periodic report for frequency: $frequency');
    } catch (e) {
      logError('Error generating periodic report', e);
    }
  }

  /// Create new AI budget
  Future<AIBudgetModel> createAIBudget({
    required String categoryId,
    required double monthlyLimit,
    double? weeklyLimit,
    double? dailyLimit,
    AIBudgetSettings? settings,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final budget = AIBudgetModel(
        id: _uuid.v4(),
        userId: currentUserId!,
        categoryId: categoryId,
        monthlyLimit: monthlyLimit,
        weeklyLimit: weeklyLimit ?? monthlyLimit / 4,
        dailyLimit: dailyLimit ?? monthlyLimit / 30,
        settings: settings ?? _getDefaultSettings(),
        analytics: _getDefaultAnalytics(),
        createdAt: now,
        updatedAt: now,
        predictedSpending: 0.0,
        riskScore: 0.0,
        healthStatus: BudgetHealthStatus.unknown,
        insights: [],
        recommendations: [],
      );

      await firestore
          .collection('ai_budgets')
          .doc(budget.id)
          .set(budget.toFirestore());

      logInfo('Created AI budget: ${budget.id}');
      return budget;
    } catch (e) {
      logError('Error creating AI budget', e);
      rethrow;
    }
  }

  /// Update AI budget
  Future<void> updateAIBudget(AIBudgetModel budget) async {
    try {
      await firestore
          .collection('ai_budgets')
          .doc(budget.id)
          .update(budget.toFirestore());

      logInfo('Updated AI budget: ${budget.id}');
    } catch (e) {
      logError('Error updating AI budget', e);
      rethrow;
    }
  }

  /// Delete AI budget
  Future<void> deleteAIBudget(String budgetId) async {
    try {
      await firestore.collection('ai_budgets').doc(budgetId).delete();

      logInfo('Deleted AI budget: $budgetId');
    } catch (e) {
      logError('Error deleting AI budget', e);
      rethrow;
    }
  }

  /// Get user's AI budgets
  Future<List<AIBudgetModel>> getUserBudgets() async {
    try {
      if (currentUserId == null) return [];

      final snapshot = await firestore
          .collection('ai_budgets')
          .where('userId', isEqualTo: currentUserId)
          .get();

      return snapshot.docs
          .map((doc) => AIBudgetModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      logError('Error getting user budgets', e);
      return [];
    }
  }

  // Private methods

  Future<List<TransactionModel>> _getRecentTransactions() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return await _transactionService.getTransactionsByDateRange(
      thirtyDaysAgo,
      DateTime.now(),
    );
  }

  Future<List<AIBudgetModel>> _getUserBudgets() async {
    return await getUserBudgets();
  }

  Future<AIBudgetModel?> _getBudget(String budgetId) async {
    try {
      final doc = await firestore.collection('ai_budgets').doc(budgetId).get();

      if (doc.exists) {
        return AIBudgetModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      logError('Error getting budget', e);
      return null;
    }
  }

  Future<SpendingAnalysis> _analyzeSpendingPattern(
    AIBudgetModel budget,
    List<TransactionModel> transactions,
  ) async {
    final categoryTransactions =
        transactions.where((t) => t.categoryId == budget.categoryId).toList();

    final currentSpending = categoryTransactions.fold<double>(
      0.0,
      (total, t) => total + t.amount,
    );

    final averageSpending = budget.analytics.averageSpending;
    final variance = budget.analytics.spendingVariance;

    // Calculate spending velocity
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.difference(monthStart).inDays + 1;
    final projectedSpending = (currentSpending / daysPassed) * daysInMonth;

    // Risk analysis
    final riskScore = _calculateRiskScore(
      currentSpending,
      projectedSpending,
      budget.monthlyLimit,
      variance,
    );

    // Anomaly detection
    final isAnomaly = _detectSpendingAnomaly(
      currentSpending,
      averageSpending,
      variance,
    );

    return SpendingAnalysis(
      currentSpending: currentSpending,
      projectedSpending: projectedSpending,
      averageSpending: averageSpending,
      riskScore: riskScore,
      isAnomaly: isAnomaly,
      requiresAlert: riskScore > 0.7 || isAnomaly,
      requiresAdjustment: projectedSpending > budget.monthlyLimit * 1.1,
      insights: await _generateSpendingInsights(budget, categoryTransactions),
    );
  }

  double _calculateRiskScore(
    double currentSpending,
    double projectedSpending,
    double monthlyLimit,
    double variance,
  ) {
    final utilizationRate = projectedSpending / monthlyLimit;
    final varianceWeight = variance / monthlyLimit;

    // Combine utilization and variance for risk score
    final riskScore = (utilizationRate * 0.7) + (varianceWeight * 0.3);

    return riskScore.clamp(0.0, 1.0);
  }

  bool _detectSpendingAnomaly(
    double currentSpending,
    double averageSpending,
    double variance,
  ) {
    if (averageSpending == 0) return false;

    final standardDeviation = sqrt(variance);
    final zScore = (currentSpending - averageSpending) / standardDeviation;

    // Anomaly if Z-score > 2 (95% confidence)
    return zScore.abs() > 2.0;
  }

  Future<List<AIInsight>> _generateSpendingInsights(
    AIBudgetModel budget,
    List<TransactionModel> transactions,
  ) async {
    final insights = <AIInsight>[];

    // Pattern analysis
    final weekdaySpending = _analyzeWeekdaySpending(transactions);
    // Note: timeOfDaySpending analysis can be added here if needed
    // final timeOfDaySpending = _analyzeTimeOfDaySpending(transactions);

    // Generate insights based on patterns
    if (weekdaySpending.isNotEmpty) {
      final maxDay =
          weekdaySpending.entries.reduce((a, b) => a.value > b.value ? a : b);

      insights.add(AIInsight(
        id: _uuid.v4(),
        title: 'Spending Pattern Detected',
        description: 'You spend most on ${maxDay.key}s in this category',
        category: 'pattern',
        importance: 0.6,
        createdAt: DateTime.now(),
        isActionable: true,
        actionText: 'Set daily limit for ${maxDay.key}s',
      ));
    }

    return insights;
  }

  Map<String, double> _analyzeWeekdaySpending(
      List<TransactionModel> transactions) {
    final weekdaySpending = <String, double>{};

    for (final transaction in transactions) {
      final weekday = _getWeekdayName(transaction.date.weekday);
      weekdaySpending[weekday] =
          (weekdaySpending[weekday] ?? 0) + transaction.amount;
    }

    return weekdaySpending;
  }

  // Unused for now, but may be useful for future time-based analysis
  // Map<String, double> _analyzeTimeOfDaySpending(
  //     List<TransactionModel> transactions) {
  //   final timeSpending = <String, double>{};

  //   for (final transaction in transactions) {
  //     final hour = transaction.date.hour;
  //     final timeOfDay = _getTimeOfDay(hour);
  //     timeSpending[timeOfDay] =
  //         (timeSpending[timeOfDay] ?? 0) + transaction.amount;
  //   }

  //   return timeSpending;
  // }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return weekdays[weekday - 1];
  }

  String _getTimeOfDay(int hour) {
    if (hour < 6) return 'Early Morning';
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    if (hour < 21) return 'Evening';
    return 'Night';
  }

  Future<void> _sendIntelligentAlert(
    AIBudgetModel budget,
    SpendingAnalysis analysis,
  ) async {
    await _notificationService.sendIntelligentAlert(
      title: 'Budget Alert: ${budget.categoryId}',
      message:
          'Projected spending: ${analysis.projectedSpending.toStringAsFixed(0)}',
      data: {
        'budgetId': budget.id,
        'riskScore': analysis.riskScore,
        'type': 'budget_alert',
      },
    );
  }

  Future<void> _suggestBudgetAdjustment(
    AIBudgetModel budget,
    SpendingAnalysis analysis,
  ) async {
    final suggestion = BudgetAdjustmentSuggestion(
      budgetId: budget.id,
      currentLimit: budget.monthlyLimit,
      suggestedLimit: analysis.projectedSpending * 1.1,
      reason: 'Based on current spending pattern',
      confidence: analysis.riskScore,
    );

    await _notificationService.sendBudgetAdjustmentSuggestion({
      'title': 'Budget Adjustment Suggestion',
      'message': 'Consider adjusting your budget based on spending patterns',
      'budgetId': suggestion.budgetId,
      'currentLimit': suggestion.currentLimit,
      'suggestedLimit': suggestion.suggestedLimit,
      'reason': suggestion.reason,
      'confidence': suggestion.confidence,
    });
  }

  Future<void> _updateBudgetWithAI(
    AIBudgetModel budget,
    SpendingAnalysis analysis,
  ) async {
    final updatedBudget = budget.copyWith(
      predictedSpending: analysis.projectedSpending,
      riskScore: analysis.riskScore,
      healthStatus: _calculateHealthStatus(analysis.riskScore),
      insights: analysis.insights,
      updatedAt: DateTime.now(),
    );

    await updateAIBudget(updatedBudget);
  }

  BudgetHealthStatus _calculateHealthStatus(double riskScore) {
    if (riskScore < 0.3) return BudgetHealthStatus.excellent;
    if (riskScore < 0.5) return BudgetHealthStatus.good;
    if (riskScore < 0.7) return BudgetHealthStatus.warning;
    return BudgetHealthStatus.critical;
  }

  Future<List<TransactionModel>> _getHistoricalData(String budgetId) async {
    // Get last 6 months of data
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
    return await _transactionService.getTransactionsByDateRange(
      sixMonthsAgo,
      DateTime.now(),
    );
  }

  Future<BudgetPrediction> _runPredictiveModel(
    AIBudgetModel budget,
    List<TransactionModel> historicalData,
  ) async {
    // Simplified predictive model
    final categoryTransactions =
        historicalData.where((t) => t.categoryId == budget.categoryId).toList();

    if (categoryTransactions.isEmpty) {
      return BudgetPrediction(
        budgetId: budget.id,
        predictedSpending: 0.0,
        confidence: 0.0,
        factors: [],
      );
    }

    // Calculate monthly averages
    final monthlySpending = <int, double>{};
    for (final transaction in categoryTransactions) {
      final monthKey = transaction.date.year * 12 + transaction.date.month;
      monthlySpending[monthKey] =
          (monthlySpending[monthKey] ?? 0) + transaction.amount;
    }

    final averageMonthly = monthlySpending.values.isEmpty
        ? 0.0
        : monthlySpending.values.reduce((a, b) => a + b) /
            monthlySpending.length;

    // Simple trend analysis
    final trend = _calculateTrend(monthlySpending);
    final seasonality = _calculateSeasonality(monthlySpending);

    final predictedSpending = averageMonthly + trend + seasonality;
    final confidence = _calculatePredictionConfidence(monthlySpending);

    return BudgetPrediction(
      budgetId: budget.id,
      predictedSpending: predictedSpending,
      confidence: confidence,
      factors: [
        'Historical average: ${averageMonthly.toStringAsFixed(0)}',
        'Trend adjustment: ${trend.toStringAsFixed(0)}',
        'Seasonal factor: ${seasonality.toStringAsFixed(0)}',
      ],
    );
  }

  double _calculateTrend(Map<int, double> monthlySpending) {
    if (monthlySpending.length < 3) return 0.0;

    final sortedEntries = monthlySpending.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final recent = sortedEntries.reversed.take(3).map((e) => e.value).toList();
    final older = sortedEntries
        .take(sortedEntries.length - 3)
        .map((e) => e.value)
        .toList();

    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.isNotEmpty
        ? older.reduce((a, b) => a + b) / older.length
        : recentAvg;

    return recentAvg - olderAvg;
  }

  double _calculateSeasonality(Map<int, double> monthlySpending) {
    // Simple seasonal adjustment based on current month
    final currentMonth = DateTime.now().month;
    final seasonalFactors = [
      1.1, 0.9, 1.0, 1.0, 1.0, 1.0, // Jan-Jun
      1.2, 1.1, 1.0, 1.0, 1.1, 1.3, // Jul-Dec
    ];

    return monthlySpending.values.isNotEmpty
        ? monthlySpending.values.reduce((a, b) => a + b) /
            monthlySpending.length *
            (seasonalFactors[currentMonth - 1] - 1)
        : 0.0;
  }

  double _calculatePredictionConfidence(Map<int, double> monthlySpending) {
    if (monthlySpending.length < 3) return 0.3;

    final values = monthlySpending.values.toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
            values.length;
    final coefficientOfVariation = sqrt(variance) / mean;

    // Higher confidence for lower coefficient of variation
    return (1.0 / (1.0 + coefficientOfVariation)).clamp(0.0, 1.0);
  }

  Future<UserProfile> _getUserProfile() async {
    // Mock user profile - in real app, get from user settings
    return UserProfile(
      userId: currentUserId!,
      spendingStyle: 'moderate',
      riskTolerance: 0.5,
      savingsGoal: 0.2,
      primaryCategories: ['Food', 'Transportation', 'Entertainment'],
    );
  }

  Future<List<TransactionModel>> _getSpendingHistory() async {
    final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
    return await _transactionService.getTransactionsByDateRange(
      threeMonthsAgo,
      DateTime.now(),
    );
  }

  Future<List<BudgetRecommendation>> _generateSmartRecommendations(
    UserProfile userProfile,
    List<TransactionModel> spendingHistory,
    List<AIBudgetModel> currentBudgets,
  ) async {
    final recommendations = <BudgetRecommendation>[];

    // Analyze spending patterns
    final categorySpending = <String, double>{};
    for (final transaction in spendingHistory) {
      categorySpending[transaction.categoryId] =
          (categorySpending[transaction.categoryId] ?? 0) + transaction.amount;
    }

    // Find categories without budgets
    final budgetedCategories = currentBudgets.map((b) => b.categoryId).toSet();
    final unbudgetedCategories = categorySpending.keys
        .where((category) => !budgetedCategories.contains(category))
        .toList();

    // Recommend budgets for high-spending unbudgeted categories
    for (final category in unbudgetedCategories) {
      final spending = categorySpending[category] ?? 0;
      if (spending > 0) {
        final suggestedLimit = spending * 1.2; // 20% buffer

        recommendations.add(BudgetRecommendation(
          id: _uuid.v4(),
          type: 'create_budget',
          title: 'Create Budget for $category',
          description:
              'You spent ${spending.toStringAsFixed(0)} on $category last month',
          priority: spending / 1000, // Higher priority for higher spending
          suggestedLimit: suggestedLimit,
          category: category,
          confidence: 0.8,
        ));
      }
    }

    // Recommend budget adjustments
    for (final budget in currentBudgets) {
      final actualSpending = categorySpending[budget.categoryId] ?? 0;
      final utilizationRate = actualSpending / budget.monthlyLimit;

      if (utilizationRate > 1.2) {
        // Suggest increasing budget
        recommendations.add(BudgetRecommendation(
          id: _uuid.v4(),
          type: 'increase_budget',
          title: 'Increase ${budget.categoryId} Budget',
          description:
              'You exceeded this budget by ${((utilizationRate - 1) * 100).toStringAsFixed(0)}%',
          priority: utilizationRate - 1,
          suggestedLimit: actualSpending * 1.1,
          category: budget.categoryId,
          confidence: 0.9,
        ));
      } else if (utilizationRate < 0.5) {
        // Suggest decreasing budget
        recommendations.add(BudgetRecommendation(
          id: _uuid.v4(),
          type: 'decrease_budget',
          title: 'Optimize ${budget.categoryId} Budget',
          description:
              'You only used ${(utilizationRate * 100).toStringAsFixed(0)}% of this budget',
          priority: 1 - utilizationRate,
          suggestedLimit: actualSpending * 1.2,
          category: budget.categoryId,
          confidence: 0.7,
        ));
      }
    }

    return recommendations..sort((a, b) => b.priority.compareTo(a.priority));
  }

  Future<List<AIInsight>> _generateInsights() async {
    final insights = <AIInsight>[];
    final budgets = await _getUserBudgets();

    for (final budget in budgets) {
      final recentTransactions = await _getRecentTransactions();
      final categoryTransactions = recentTransactions
          .where((t) => t.categoryId == budget.categoryId)
          .toList();

      insights.addAll(
          await _generateSpendingInsights(budget, categoryTransactions));
    }

    return insights;
  }

  Future<BudgetAnalytics> _generateAnalytics() async {
    final budgets = await _getUserBudgets();
    final transactions = await _getRecentTransactions();

    return BudgetAnalytics(
      totalBudgets: budgets.length,
      totalSpending: transactions.fold(0.0, (total, t) => total + t.amount),
      averageUtilization: _calculateAverageUtilization(budgets, transactions),
      riskDistribution: _calculateRiskDistribution(budgets),
      topCategories: _getTopCategories(transactions),
    );
  }

  double _calculateAverageUtilization(
    List<AIBudgetModel> budgets,
    List<TransactionModel> transactions,
  ) {
    if (budgets.isEmpty) return 0.0;

    double totalUtilization = 0.0;

    for (final budget in budgets) {
      final categorySpending = transactions
          .where((t) => t.categoryId == budget.categoryId)
          .fold(0.0, (total, t) => total + t.amount);

      totalUtilization += categorySpending / budget.monthlyLimit;
    }

    return totalUtilization / budgets.length;
  }

  Map<String, int> _calculateRiskDistribution(List<AIBudgetModel> budgets) {
    final distribution = <String, int>{
      'low': 0,
      'medium': 0,
      'high': 0,
    };

    for (final budget in budgets) {
      if (budget.riskScore < 0.3) {
        distribution['low'] = distribution['low']! + 1;
      } else if (budget.riskScore < 0.7) {
        distribution['medium'] = distribution['medium']! + 1;
      } else {
        distribution['high'] = distribution['high']! + 1;
      }
    }

    return distribution;
  }

  List<String> _getTopCategories(List<TransactionModel> transactions) {
    final categorySpending = <String, double>{};

    for (final transaction in transactions) {
      categorySpending[transaction.categoryId] =
          (categorySpending[transaction.categoryId] ?? 0) + transaction.amount;
    }

    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories.take(5).map((e) => e.key).toList();
  }

  Future<void> _sendIntelligentReport(
    List<AIInsight> insights,
    List<BudgetRecommendation> recommendations,
    BudgetAnalytics analytics,
    NotificationFrequency frequency,
  ) async {
    await _notificationService.sendIntelligentReport(
      insights.map((insight) => insight.toFirestore()).toList(),
      recommendations
          .map((rec) => {
                'id': rec.id,
                'type': rec.type,
                'title': rec.title,
                'description': rec.description,
                'priority': rec.priority,
                'suggestedLimit': rec.suggestedLimit,
                'category': rec.category,
                'confidence': rec.confidence,
              })
          .toList(),
      {
        'totalBudgets': analytics.totalBudgets,
        'totalSpending': analytics.totalSpending,
        'averageUtilization': analytics.averageUtilization,
        'riskDistribution': analytics.riskDistribution,
        'topCategories': analytics.topCategories,
      },
      frequency.toString().split('.').last,
    );
  }

  AIBudgetSettings _getDefaultSettings() {
    return const AIBudgetSettings(
      autoAdjustment: false,
      smartNotifications: true,
      predictiveAlerts: true,
      frequency: NotificationFrequency.daily,
      alertThreshold: 0.8,
      learningMode: true,
      proactiveAdvice: true,
      riskAnalysis: true,
    );
  }

  AIBudgetAnalytics _getDefaultAnalytics() {
    return AIBudgetAnalytics(
      averageSpending: 0.0,
      spendingVariance: 0.0,
      spendingPatterns: {},
      trends: [],
      confidenceScore: 0.0,
      lastAnalyzed: DateTime.now(),
      totalTransactions: 0,
      accuracyRate: 0.0,
    );
  }

  void dispose() {
    stopMonitoring();
  }
}

// Supporting classes

class SpendingAnalysis {
  final double currentSpending;
  final double projectedSpending;
  final double averageSpending;
  final double riskScore;
  final bool isAnomaly;
  final bool requiresAlert;
  final bool requiresAdjustment;
  final List<AIInsight> insights;

  SpendingAnalysis({
    required this.currentSpending,
    required this.projectedSpending,
    required this.averageSpending,
    required this.riskScore,
    required this.isAnomaly,
    required this.requiresAlert,
    required this.requiresAdjustment,
    required this.insights,
  });
}

class BudgetPrediction {
  final String budgetId;
  final double predictedSpending;
  final double confidence;
  final List<String> factors;

  BudgetPrediction({
    required this.budgetId,
    required this.predictedSpending,
    required this.confidence,
    required this.factors,
  });
}

class BudgetRecommendation {
  final String id;
  final String type;
  final String title;
  final String description;
  final double priority;
  final double suggestedLimit;
  final String category;
  final double confidence;

  BudgetRecommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.suggestedLimit,
    required this.category,
    required this.confidence,
  });
}

class UserProfile {
  final String userId;
  final String spendingStyle;
  final double riskTolerance;
  final double savingsGoal;
  final List<String> primaryCategories;

  UserProfile({
    required this.userId,
    required this.spendingStyle,
    required this.riskTolerance,
    required this.savingsGoal,
    required this.primaryCategories,
  });
}

class BudgetAnalytics {
  final int totalBudgets;
  final double totalSpending;
  final double averageUtilization;
  final Map<String, int> riskDistribution;
  final List<String> topCategories;

  BudgetAnalytics({
    required this.totalBudgets,
    required this.totalSpending,
    required this.averageUtilization,
    required this.riskDistribution,
    required this.topCategories,
  });
}

class BudgetAdjustmentSuggestion {
  final String budgetId;
  final double currentLimit;
  final double suggestedLimit;
  final String reason;
  final double confidence;

  BudgetAdjustmentSuggestion({
    required this.budgetId,
    required this.currentLimit,
    required this.suggestedLimit,
    required this.reason,
    required this.confidence,
  });
}
