/// Financial Health Calculator - Chuyên tính toán sức khỏe tài chính
/// Được tách từ AIAnalyticsService để cải thiện maintainability

import 'dart:math';

import '../../models/analytics/analytics_models.dart';
import '../../models/transaction_model.dart';
import '../base_service.dart';
import '../offline_service.dart';
import '../transaction_service.dart';

/// Service chuyên tính toán và đánh giá sức khỏe tài chính
class FinancialHealthCalculator extends BaseService {
  static final FinancialHealthCalculator _instance = FinancialHealthCalculator._internal();
  factory FinancialHealthCalculator() => _instance;
  FinancialHealthCalculator._internal();

  late final TransactionService _transactionService;

  /// Initialize services (call this before using)
  void _initializeServices() {
    final offlineService = OfflineService();
    _transactionService = TransactionService(offlineService: offlineService);
  }

  /// Main method: Calculate comprehensive financial health score
  Future<FinancialHealthScore> calculateFinancialHealth() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      _initializeServices();
      logInfo('Calculating financial health score for user: $currentUserId');

      // Get data for analysis
      final futures = await Future.wait([
        _getSpendingData(),
        _getBudgetData(),
        _getSavingsData(),
      ]);

      final spendingData = futures[0] as SpendingData;
      final budgetData = futures[1] as BudgetData;
      final savingsData = futures[2] as SavingsData;

      // Calculate individual scores
      final scores = await Future.wait([
        _calculateSpendingScore(spendingData),
        _calculateBudgetScore(budgetData),
        _calculateSavingsScore(savingsData),
      ]);

      final spendingScore = scores[0] as double;
      final budgetScore = scores[1] as double;
      final savingsScore = scores[2] as double;
      final overallScore = (spendingScore + budgetScore + savingsScore) / 3;

      // Generate recommendations
      final recommendations = await _generateHealthRecommendations(
        spendingData, 
        budgetData, 
        savingsData,
      );

      // Calculate trend
      final trend = await _calculateHealthTrend();

      // Get health factors
      final factors = await _getHealthFactors(spendingData, budgetData, savingsData);

      final healthScore = FinancialHealthScore(
        overallScore: overallScore,
        spendingScore: spendingScore,
        budgetScore: budgetScore,
        savingsScore: savingsScore,
        recommendations: recommendations,
        lastCalculated: DateTime.now(),
        trend: trend,
        factors: factors,
      );

      logInfo('Completed financial health calculation');
      return healthScore;
    } catch (e) {
      logError('Error calculating financial health', e);
      return _getEmptyHealthScore();
    }
  }

  /// Quick health score for dashboard
  Future<double> getQuickHealthScore() async {
    try {
      _initializeServices();
      final transactions = await _getRecentTransactions(days: 30);
      
      if (transactions.isEmpty) return 50.0; // Neutral score

      // Quick scoring based on recent transactions
      final totalExpenses = transactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      final totalIncome = transactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);

      // Simple health calculation
      if (totalIncome <= 0) return 30.0; // Low score if no income

      final expenseRatio = totalExpenses / totalIncome;
      
      if (expenseRatio <= 0.5) return 90.0; // Excellent
      if (expenseRatio <= 0.7) return 75.0; // Good
      if (expenseRatio <= 0.9) return 60.0; // Fair
      if (expenseRatio <= 1.0) return 40.0; // Poor
      return 20.0; // Critical
    } catch (e) {
      logError('Error getting quick health score', e);
      return 50.0;
    }
  }

  /// Get priority recommendations (high priority only)
  Future<List<HealthRecommendation>> getPriorityRecommendations() async {
    try {
      final healthScore = await calculateFinancialHealth();
      return healthScore.priorityRecommendations;
    } catch (e) {
      logError('Error getting priority recommendations', e);
      return [];
    }
  }

  /// Check if user is in financial distress
  Future<bool> isInFinancialDistress() async {
    try {
      final score = await getQuickHealthScore();
      return score < 40.0;
    } catch (e) {
      logError('Error checking financial distress', e);
      return false;
    }
  }

  /// Get health improvement suggestions
  Future<List<String>> getHealthImprovementSuggestions() async {
    try {
      final healthScore = await calculateFinancialHealth();
      final suggestions = <String>[];

      // Based on scores, suggest improvements
      if (healthScore.spendingScore < 60) {
        suggestions.add('Giảm chi tiêu không cần thiết');
        suggestions.add('Theo dõi chi tiêu hàng ngày');
      }

      if (healthScore.budgetScore < 60) {
        suggestions.add('Thiết lập ngân sách chi tiết');
        suggestions.add('Sử dụng ứng dụng quản lý ngân sách');
      }

      if (healthScore.savingsScore < 60) {
        suggestions.add('Tăng tỷ lệ tiết kiệm');
        suggestions.add('Thiết lập mục tiêu tiết kiệm cụ thể');
      }

      return suggestions;
    } catch (e) {
      logError('Error getting health improvement suggestions', e);
      return [];
    }
  }

  // Private calculation methods

  Future<SpendingData> _getSpendingData() async {
    final transactions = await _getAllTransactions();
    final totalSpending = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    return SpendingData(
      totalSpending: totalSpending,
      averageDaily: totalSpending / 30, // Last 30 days
      categories: {}, // Simplified for now
      trends: {}, // Simplified for now
    );
  }

  Future<BudgetData> _getBudgetData() async {
    // Mock budget data - in real app, get from budget service
    return BudgetData(
      totalBudget: 50000000, // 50M VND
      utilizationRate: 0.8,
      categoriesWithBudgets: 5,
      categoriesWithoutBudgets: 3,
    );
  }

  Future<SavingsData> _getSavingsData() async {
    // Calculate savings from income vs expenses
    final transactions = await _getAllTransactions();
    
    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final totalExpenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final savings = max(0.0, totalIncome - totalExpenses);
    final savingsRate = totalIncome > 0 ? savings / totalIncome : 0.0;

    return SavingsData(
      totalSavings: savings,
      monthlyContribution: savings / 6, // Over 6 months
      savingsRate: savingsRate,
      savingsGoal: totalIncome * 3, // 3 months emergency fund
    );
  }

  Future<double> _calculateSpendingScore(SpendingData spendingData) async {
    double score = 100.0;

    // Penalize high daily spending
    if (spendingData.averageDaily > 500000) { // > 500k/day
      score -= 30.0;
    } else if (spendingData.averageDaily > 300000) { // > 300k/day
      score -= 20.0;
    } else if (spendingData.averageDaily > 200000) { // > 200k/day
      score -= 10.0;
    }

    // Check spending consistency
    final transactions = await _getAllTransactions();
    final expenseTransactions = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    if (expenseTransactions.isNotEmpty) {
      final amounts = expenseTransactions.map((t) => t.amount).toList();
      final variance = _calculateVariance(amounts);
      final mean = amounts.reduce((a, b) => a + b) / amounts.length;
      final coefficientOfVariation = variance / (mean * mean);

      // High variation in spending = lower score
      if (coefficientOfVariation > 2.0) {
        score -= 20.0;
      } else if (coefficientOfVariation > 1.0) {
        score -= 10.0;
      }
    }

    return score.clamp(0.0, 100.0);
  }

  Future<double> _calculateBudgetScore(BudgetData budgetData) async {
    double score = 100.0;

    // Score based on budget utilization
    if (budgetData.utilizationRate > 1.0) { // Over budget
      score -= 40.0;
    } else if (budgetData.utilizationRate > 0.9) { // Close to budget
      score -= 20.0;
    } else if (budgetData.utilizationRate > 0.8) { // High utilization
      score -= 10.0;
    }

    // Score based on budget coverage
    final totalCategories = budgetData.categoriesWithBudgets + budgetData.categoriesWithoutBudgets;
    if (totalCategories > 0) {
      final coverage = budgetData.categoriesWithBudgets / totalCategories;
      if (coverage < 0.5) { // Less than 50% coverage
        score -= 20.0;
      } else if (coverage < 0.7) { // Less than 70% coverage
        score -= 10.0;
      }
    }

    return score.clamp(0.0, 100.0);
  }

  Future<double> _calculateSavingsScore(SavingsData savingsData) async {
    double score = 0.0;

    // Score based on savings rate
    if (savingsData.savingsRate >= 0.3) { // >= 30%
      score = 100.0;
    } else if (savingsData.savingsRate >= 0.2) { // >= 20%
      score = 90.0;
    } else if (savingsData.savingsRate >= 0.15) { // >= 15%
      score = 75.0;
    } else if (savingsData.savingsRate >= 0.1) { // >= 10%
      score = 60.0;
    } else if (savingsData.savingsRate >= 0.05) { // >= 5%
      score = 40.0;
    } else {
      score = 20.0;
    }

    // Bonus for goal progress
    if (savingsData.savingsGoal > 0) {
      final progress = savingsData.totalSavings / savingsData.savingsGoal;
      score += progress * 10; // Up to 10 bonus points
    }

    return score.clamp(0.0, 100.0);
  }

  Future<List<HealthRecommendation>> _generateHealthRecommendations(
    SpendingData spendingData,
    BudgetData budgetData,
    SavingsData savingsData,
  ) async {
    final recommendations = <HealthRecommendation>[];

    // Spending recommendations
    if (spendingData.averageDaily > 300000) {
      recommendations.add(HealthRecommendation(
        type: 'spending',
        title: 'Giảm chi tiêu hàng ngày',
        description: 'Chi tiêu trung bình ${(spendingData.averageDaily / 1000).toInt()}k/ngày khá cao. Hãy xem xét cắt giảm các chi phí không cần thiết.',
        priority: 'high',
        impact: 25.0,
      ));
    }

    // Budget recommendations
    if (budgetData.utilizationRate > 0.9) {
      recommendations.add(HealthRecommendation(
        type: 'budget',
        title: 'Điều chỉnh ngân sách',
        description: 'Bạn đã sử dụng ${(budgetData.utilizationRate * 100).toInt()}% ngân sách. Cần cẩn thận để không vượt quá.',
        priority: budgetData.utilizationRate > 1.0 ? 'urgent' : 'high',
        impact: 30.0,
      ));
    }

    // Savings recommendations
    if (savingsData.savingsRate < 0.1) {
      recommendations.add(HealthRecommendation(
        type: 'savings',
        title: 'Tăng tỷ lệ tiết kiệm',
        description: 'Tỷ lệ tiết kiệm hiện tại ${(savingsData.savingsRate * 100).toInt()}% còn thấp. Mục tiêu nên là ít nhất 10-20%.',
        priority: 'high',
        impact: 35.0,
      ));
    }

    // Emergency fund recommendation
    if (savingsData.goalProgressPercentage < 50) {
      recommendations.add(HealthRecommendation(
        type: 'emergency',
        title: 'Xây dựng quỹ khẩn cấp',
        description: 'Nên có quỹ khẩn cấp tương đương 3-6 tháng chi tiêu để đối phó với tình huống bất ngờ.',
        priority: 'medium',
        impact: 20.0,
      ));
    }

    // Sort by priority and impact
    recommendations.sort((a, b) {
      final priorityOrder = {'urgent': 4, 'high': 3, 'medium': 2, 'low': 1};
      final aPriority = priorityOrder[a.priority] ?? 0;
      final bPriority = priorityOrder[b.priority] ?? 0;
      
      if (aPriority != bPriority) {
        return bPriority.compareTo(aPriority);
      }
      return b.impact.compareTo(a.impact);
    });

    return recommendations;
  }

  Future<double> _calculateHealthTrend() async {
    try {
      // Compare current month vs previous month
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);
      final previousMonth = DateTime(now.year, now.month - 1);

      final currentScore = await _getMonthHealthScore(currentMonth);
      final previousScore = await _getMonthHealthScore(previousMonth);

      return currentScore - previousScore;
    } catch (e) {
      logError('Error calculating health trend', e);
      return 0.0;
    }
  }

  Future<double> _getMonthHealthScore(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 1).subtract(const Duration(days: 1));
    
    final transactions = await _transactionService.getTransactionsByDateRange(
      startOfMonth,
      endOfMonth,
    );

    if (transactions.isEmpty) return 50.0;

    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final totalExpenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    if (totalIncome <= 0) return 30.0;

    final expenseRatio = totalExpenses / totalIncome;
    
    if (expenseRatio <= 0.7) return 80.0;
    if (expenseRatio <= 0.9) return 60.0;
    if (expenseRatio <= 1.0) return 40.0;
    return 20.0;
  }

  Future<List<String>> _getHealthFactors(
    SpendingData spendingData,
    BudgetData budgetData,
    SavingsData savingsData,
  ) async {
    final factors = <String>[];

    // Spending factors
    if (spendingData.averageDaily > 300000) {
      factors.add('Chi tiêu hàng ngày cao');
    }

    // Budget factors
    if (budgetData.utilizationRate > 0.9) {
      factors.add('Sử dụng ngân sách cao');
    }

    // Savings factors
    if (savingsData.savingsRate >= 0.2) {
      factors.add('Tỷ lệ tiết kiệm tốt');
    } else if (savingsData.savingsRate < 0.1) {
      factors.add('Tỷ lệ tiết kiệm thấp');
    }

    // Income stability
    final transactions = await _getAllTransactions();
    final incomeTransactions = transactions
        .where((t) => t.type == TransactionType.income)
        .toList();

    if (incomeTransactions.isNotEmpty) {
      final amounts = incomeTransactions.map((t) => t.amount).toList();
      final variance = _calculateVariance(amounts);
      final mean = amounts.reduce((a, b) => a + b) / amounts.length;
      final coefficientOfVariation = variance / (mean * mean);

      if (coefficientOfVariation < 0.3) {
        factors.add('Thu nhập ổn định');
      } else {
        factors.add('Thu nhập không đều');
      }
    }

    return factors;
  }

  // Helper methods

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

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
} 