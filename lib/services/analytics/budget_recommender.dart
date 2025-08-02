/// Budget Recommender - Chuyên đưa ra gợi ý ngân sách thông minh
/// Được tách từ AIAnalyticsService để cải thiện maintainability

import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../core/models/analytics/analytics_models.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../base_service.dart';
import '../category_service.dart';
import '../offline_service.dart';
import '../transaction_service.dart';

/// Service chuyên tạo gợi ý ngân sách thông minh
class BudgetRecommender extends BaseService {
  static final BudgetRecommender _instance = BudgetRecommender._internal();
  factory BudgetRecommender() => _instance;
  BudgetRecommender._internal();

  late final TransactionService _transactionService;
  late final CategoryService _categoryService;
  final _uuid = const Uuid();

  /// Initialize services (call this before using)
  void _initializeServices() {
    final offlineService = OfflineService();
    _transactionService = TransactionService(offlineService: offlineService);
    _categoryService = CategoryService();
  }

  /// Main method: Generate smart budget recommendations
  Future<List<SmartBudgetRecommendation>> generateSmartBudgetRecommendations() async {
    try {
      if (currentUserId == null) return [];

      _initializeServices();
      logInfo('Generating smart budget recommendations');

      final transactions = await _getAllTransactions();
      final categories = await _categoryService.getCategories().first;
      final recommendations = <SmartBudgetRecommendation>[];

      if (transactions.isEmpty || categories.isEmpty) {
        return recommendations;
      }

      // Analyze spending patterns for recommendations
      for (final category in categories) {
        final categoryTransactions = transactions
            .where((t) => t.categoryId == category.id)
            .toList();

        if (categoryTransactions.isNotEmpty) {
          final recommendation = await _generateCategoryRecommendation(
            category,
            categoryTransactions,
            transactions,
          );
          
          if (recommendation != null) {
            recommendations.add(recommendation);
          }
        }
      }

      // Sort by priority and confidence
      recommendations.sort((a, b) {
        final priorityDiff = b.priority.compareTo(a.priority);
        if (priorityDiff != 0) return priorityDiff;
        return b.confidence.compareTo(a.confidence);
      });

      logInfo('Generated ${recommendations.length} smart budget recommendations');
      return recommendations.take(10).toList(); // Top 10 recommendations
    } catch (e) {
      logError('Error generating smart budget recommendations', e);
      return [];
    }
  }

  /// Get high priority recommendations only
  Future<List<SmartBudgetRecommendation>> getHighPriorityRecommendations() async {
    try {
      final allRecommendations = await generateSmartBudgetRecommendations();
      return allRecommendations.where((r) => r.priority >= 0.7).toList();
    } catch (e) {
      logError('Error getting high priority recommendations', e);
      return [];
    }
  }

  /// Get recommendations for specific category
  Future<List<SmartBudgetRecommendation>> getCategoryRecommendations(String categoryId) async {
    try {
      _initializeServices();
      final categories = await _categoryService.getCategories().first;
      final category = categories.firstWhere((c) => c.id == categoryId);
      
      final transactions = await _getAllTransactions();
      final categoryTransactions = transactions
          .where((t) => t.categoryId == categoryId)
          .toList();

      if (categoryTransactions.isEmpty) return [];

      final recommendation = await _generateCategoryRecommendation(
        category,
        categoryTransactions,
        transactions,
      );

      return recommendation != null ? [recommendation] : [];
    } catch (e) {
      logError('Error getting category recommendations', e);
      return [];
    }
  }

  /// Recommend budget for new category
  Future<double> recommendBudgetForNewCategory(String categoryName, TransactionType type) async {
    try {
      _initializeServices();
      final transactions = await _getAllTransactions();
      
      // Get similar category spending as baseline
      final similarSpending = await _findSimilarCategorySpending(categoryName, type, transactions);
      
      if (similarSpending > 0) {
        return similarSpending * 1.1; // 10% buffer
      }

      // Default recommendations based on category type
      if (type == TransactionType.income) {
        return 10000000; // 10M VND default for income categories
      } else {
        return 2000000; // 2M VND default for expense categories
      }
    } catch (e) {
      logError('Error recommending budget for new category', e);
      return 1000000; // 1M VND fallback
    }
  }

  /// Get budget optimization suggestions
  Future<List<String>> getBudgetOptimizationSuggestions() async {
    try {
      final recommendations = await generateSmartBudgetRecommendations();
      final suggestions = <String>[];

      for (final rec in recommendations.take(5)) {
        if (rec.recommendationType == 'decrease') {
          suggestions.add('Giảm ngân sách ${rec.categoryName}: ${rec.reasoning}');
        } else if (rec.recommendationType == 'increase') {
          suggestions.add('Tăng ngân sách ${rec.categoryName}: ${rec.reasoning}');
        }
      }

      return suggestions;
    } catch (e) {
      logError('Error getting budget optimization suggestions', e);
      return [];
    }
  }

  // Private recommendation methods

  Future<SmartBudgetRecommendation?> _generateCategoryRecommendation(
    CategoryModel category,
    List<TransactionModel> categoryTransactions,
    List<TransactionModel> allTransactions,
  ) async {
    // Calculate current spending statistics
    final currentSpending = categoryTransactions
        .fold(0.0, (sum, t) => sum + t.amount);
    final monthlyAverage = currentSpending / 6; // Over 6 months
    
    // Analyze spending patterns
    final spendingAnalysis = _analyzeCategorySpending(categoryTransactions);
    
    // Determine recommendation type and amount
    final recommendationData = _determineRecommendation(
      category,
      spendingAnalysis,
      monthlyAverage,
    );

    if (recommendationData == null) return null;

    // Calculate confidence based on data quality
    final confidence = _calculateRecommendationConfidence(categoryTransactions);
    
    // Calculate priority based on impact and urgency
    final priority = _calculateRecommendationPriority(
      spendingAnalysis,
      recommendationData['suggestedAmount'] as double,
      monthlyAverage,
    );

    return SmartBudgetRecommendation(
      id: _uuid.v4(),
      categoryId: category.id,
      categoryName: category.name,
      recommendationType: recommendationData['type'] as String,
      suggestedAmount: recommendationData['suggestedAmount'] as double,
      currentSpending: monthlyAverage,
      priority: priority,
      reasoning: recommendationData['reasoning'] as String,
      confidence: confidence,
      factors: recommendationData['factors'] as List<String>,
    );
  }

  Map<String, dynamic> _analyzeCategorySpending(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return {
        'trend': 'stable',
        'variance': 0.0,
        'frequency': 0.0,
        'isIncreasing': false,
        'isVolatile': false,
      };
    }

    // Calculate monthly spending
    final monthlySpending = <int, double>{};
    for (final transaction in transactions) {
      final monthKey = transaction.date.year * 12 + transaction.date.month;
      monthlySpending[monthKey] = (monthlySpending[monthKey] ?? 0) + transaction.amount;
    }

    // Calculate trend
    final trend = _calculateTrend(monthlySpending);
    final isIncreasing = trend > 0.1;

    // Calculate variance
    final amounts = transactions.map((t) => t.amount).toList();
    final variance = amounts.isNotEmpty ? _calculateVariance(amounts) : 0.0;
    final mean = amounts.isNotEmpty ? amounts.reduce((a, b) => a + b) / amounts.length : 0.0;
    final isVolatile = mean > 0 && (variance / (mean * mean)) > 1.0;

    // Calculate frequency
    final totalDays = transactions.isNotEmpty 
        ? transactions.last.date.difference(transactions.first.date).inDays + 1
        : 1;
    final frequency = transactions.length / (totalDays / 30.0); // transactions per month

    return {
      'trend': isIncreasing ? 'increasing' : (trend < -0.1 ? 'decreasing' : 'stable'),
      'variance': variance,
      'frequency': frequency,
      'isIncreasing': isIncreasing,
      'isVolatile': isVolatile,
    };
  }

  Map<String, dynamic>? _determineRecommendation(
    CategoryModel category,
    Map<String, dynamic> analysis,
    double monthlyAverage,
  ) {
    final isIncreasing = analysis['isIncreasing'] as bool;
    final isVolatile = analysis['isVolatile'] as bool;
    final frequency = analysis['frequency'] as double;

    // Recommendation logic
    if (category.type == TransactionType.expense) {
      if (isIncreasing && monthlyAverage > 1000000) { // > 1M per month
        // Suggest decrease for high increasing expenses
        return {
          'type': 'decrease',
          'suggestedAmount': monthlyAverage * 0.8, // 20% reduction
          'reasoning': 'Chi tiêu đang tăng và khá cao, nên giảm bớt',
          'factors': ['Xu hướng tăng', 'Số tiền lớn', 'Cần kiểm soát'],
        };
      } else if (isVolatile) {
        // Suggest maintain but with buffer for volatile expenses
        return {
          'type': 'maintain',
          'suggestedAmount': monthlyAverage * 1.2, // 20% buffer
          'reasoning': 'Chi tiêu không đều, nên có dự phòng',
          'factors': ['Chi tiêu biến động', 'Cần dự phòng', 'Khó dự đoán'],
        };
      } else if (frequency < 1.0) { // Less than 1 transaction per month
        // Suggest decrease for infrequent categories
        return {
          'type': 'decrease',
          'suggestedAmount': monthlyAverage * 0.5, // 50% reduction
          'reasoning': 'Ít sử dụng, có thể giảm ngân sách',
          'factors': ['Sử dụng ít', 'Tối ưu hóa', 'Tiết kiệm'],
        };
      }
    } else if (category.type == TransactionType.income) {
      if (!isIncreasing && monthlyAverage > 0) {
        // Suggest increase income targets
        return {
          'type': 'increase',
          'suggestedAmount': monthlyAverage * 1.1, // 10% increase
          'reasoning': 'Thu nhập chưa tăng, nên đặt mục tiêu cao hơn',
          'factors': ['Thu nhập ổn định', 'Có thể cải thiện', 'Tăng trưởng'],
        };
      }
    }

    // Default: maintain current level
    if (monthlyAverage > 0) {
      return {
        'type': 'maintain',
        'suggestedAmount': monthlyAverage,
        'reasoning': 'Mức chi tiêu hiện tại hợp lý',
        'factors': ['Ổn định', 'Hợp lý', 'Duy trì'],
      };
    }

    return null; // No recommendation needed
  }

  double _calculateRecommendationConfidence(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return 0.0;

    double confidence = 0.0;

    // Data volume confidence
    if (transactions.length >= 20) {
      confidence += 0.4;
    } else if (transactions.length >= 10) {
      confidence += 0.3;
    } else if (transactions.length >= 5) {
      confidence += 0.2;
    } else {
      confidence += 0.1;
    }

    // Time span confidence
    final timeSpan = transactions.isNotEmpty 
        ? transactions.last.date.difference(transactions.first.date).inDays
        : 0;
    
    if (timeSpan >= 120) { // 4+ months
      confidence += 0.3;
    } else if (timeSpan >= 60) { // 2+ months
      confidence += 0.2;
    } else {
      confidence += 0.1;
    }

    // Consistency confidence
    final amounts = transactions.map((t) => t.amount).toList();
    final consistency = _calculateConsistency(amounts);
    confidence += consistency * 0.3;

    return confidence.clamp(0.0, 1.0);
  }

  double _calculateRecommendationPriority(
    Map<String, dynamic> analysis,
    double suggestedAmount,
    double currentSpending,
  ) {
    double priority = 0.5; // Base priority

    // Impact on amount
    final impact = (suggestedAmount - currentSpending).abs() / currentSpending;
    priority += (impact * 0.3).clamp(0.0, 0.3);

    // Urgency based on trends
    if (analysis['isIncreasing'] as bool) {
      priority += 0.2; // Higher priority for increasing expenses
    }

    // Volatility adds priority
    if (analysis['isVolatile'] as bool) {
      priority += 0.15;
    }

    // High spending adds priority
    if (currentSpending > 2000000) { // > 2M per month
      priority += 0.15;
    }

    return priority.clamp(0.0, 1.0);
  }

  Future<double> _findSimilarCategorySpending(
    String categoryName,
    TransactionType type,
    List<TransactionModel> transactions,
  ) async {
    // This is a simplified implementation
    // In a real app, you'd use NLP or ML to find truly similar categories
    
    final typeTransactions = transactions
        .where((t) => t.type == type)
        .toList();

    if (typeTransactions.isEmpty) return 0.0;

    // Group by category and find average
    final categorySpending = <String, double>{};
    final categoryCount = <String, int>{};

    for (final transaction in typeTransactions) {
      categorySpending[transaction.categoryId] = 
          (categorySpending[transaction.categoryId] ?? 0) + transaction.amount;
      categoryCount[transaction.categoryId] = 
          (categoryCount[transaction.categoryId] ?? 0) + 1;
    }

    // Calculate average spending per category
    final averages = <double>[];
    for (final categoryId in categorySpending.keys) {
      final total = categorySpending[categoryId]!;
      final count = categoryCount[categoryId]!;
      final monthlyAverage = total / 6; // 6 months
      averages.add(monthlyAverage);
    }

    if (averages.isEmpty) return 0.0;

    // Return median as a reasonable estimate
    averages.sort();
    return averages[averages.length ~/ 2];
  }

  // Helper methods

  double _calculateTrend(Map<int, double> monthlyData) {
    if (monthlyData.length < 2) return 0.0;
    
    final sortedEntries = monthlyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    if (sortedEntries.length < 2) return 0.0;
    
    final firstValue = sortedEntries.first.value;
    final lastValue = sortedEntries.last.value;
    
    return (lastValue - firstValue) / sortedEntries.length;
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  double _calculateConsistency(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = _calculateVariance(values);
    final coefficientOfVariation = sqrt(variance) / mean;
    
    // Lower variation = higher consistency
    return (1.0 / (1.0 + coefficientOfVariation)).clamp(0.0, 1.0);
  }

  Future<List<TransactionModel>> _getAllTransactions() async {
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
    return await _transactionService.getTransactionsByDateRange(
      sixMonthsAgo,
      DateTime.now(),
    );
  }
} 