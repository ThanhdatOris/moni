// =============================================================================
// AI ANALYTICS MODELS
// =============================================================================

import '../transaction_model.dart';

// =============================================================================
// PATTERN ANALYSIS MODELS
// =============================================================================

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

  Map<String, dynamic> toJson() {
    return {
      'weeklyPatterns': weeklyPatterns.map((k, v) => MapEntry(k, v.toJson())),
      'monthlyTrends': monthlyTrends.map((k, v) => MapEntry(k, v.toJson())),
      'categoryDistribution': categoryDistribution.map((k, v) => MapEntry(k, v.toJson())),
      'seasonalPatterns': seasonalPatterns.map((k, v) => MapEntry(k, v.toJson())),
      'anomalies': anomalies.map((a) => a.toJson()).toList(),
      'predictions': predictions.map((p) => p.toJson()).toList(),
      'analysisDate': analysisDate.toIso8601String(),
      'confidenceScore': confidenceScore,
    };
  }

  factory SpendingPatternAnalysis.fromJson(Map<String, dynamic> json) {
    return SpendingPatternAnalysis(
      weeklyPatterns: (json['weeklyPatterns'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, WeeklySpendingPattern.fromJson(v))),
      monthlyTrends: (json['monthlyTrends'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, MonthlyTrend.fromJson(v))),
      categoryDistribution: (json['categoryDistribution'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, CategoryDistribution.fromJson(v))),
      seasonalPatterns: (json['seasonalPatterns'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, SeasonalPattern.fromJson(v))),
      anomalies: (json['anomalies'] as List<dynamic>? ?? [])
          .map((a) => SpendingAnomaly.fromJson(a))
          .toList(),
      predictions: (json['predictions'] as List<dynamic>? ?? [])
          .map((p) => SpendingPrediction.fromJson(p))
          .toList(),
      analysisDate: DateTime.parse(json['analysisDate'] ?? DateTime.now().toIso8601String()),
      confidenceScore: (json['confidenceScore'] ?? 0).toDouble(),
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'averageDaily': averageDaily,
      'variance': variance,
      'peakDay': peakDay,
      'dailyDistribution': dailyDistribution,
    };
  }

  factory WeeklySpendingPattern.fromJson(Map<String, dynamic> json) {
    return WeeklySpendingPattern(
      categoryId: json['categoryId'] ?? '',
      averageDaily: (json['averageDaily'] ?? 0).toDouble(),
      variance: (json['variance'] ?? 0).toDouble(),
      peakDay: json['peakDay'] ?? 1,
      dailyDistribution: Map<int, double>.from(json['dailyDistribution'] ?? {}),
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'trend': trend,
      'seasonality': seasonality,
      'monthlyData': monthlyData,
      'confidence': confidence,
    };
  }

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) {
    return MonthlyTrend(
      categoryId: json['categoryId'] ?? '',
      trend: (json['trend'] ?? 0).toDouble(),
      seasonality: (json['seasonality'] ?? 0).toDouble(),
      monthlyData: Map<int, double>.from(json['monthlyData'] ?? {}),
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'totalAmount': totalAmount,
      'percentage': percentage,
      'transactionCount': transactionCount,
      'averageAmount': averageAmount,
    };
  }

  factory CategoryDistribution.fromJson(Map<String, dynamic> json) {
    return CategoryDistribution(
      categoryId: json['categoryId'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
      transactionCount: json['transactionCount'] ?? 0,
      averageAmount: (json['averageAmount'] ?? 0).toDouble(),
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'seasonalIndices': seasonalIndices,
      'peakSeason': peakSeason,
      'seasonalData': seasonalData,
    };
  }

  factory SeasonalPattern.fromJson(Map<String, dynamic> json) {
    return SeasonalPattern(
      categoryId: json['categoryId'] ?? '',
      seasonalIndices: Map<String, double>.from(json['seasonalIndices'] ?? {}),
      peakSeason: json['peakSeason'] ?? '',
      seasonalData: Map<String, double>.from(json['seasonalData'] ?? {}),
    );
  }
}

// =============================================================================
// ANOMALY DETECTION MODELS
// =============================================================================

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'severity': severity,
      'description': description,
      'transaction': {
        'transactionId': transaction.transactionId,
        'amount': transaction.amount,
        'categoryId': transaction.categoryId,
        'note': transaction.note,
        'date': transaction.date.toIso8601String(),
        'type': transaction.type.value,
      },
      'detectedAt': detectedAt.toIso8601String(),
      'confidence': confidence,
    };
  }

  factory SpendingAnomaly.fromJson(Map<String, dynamic> json) {
    return SpendingAnomaly(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      severity: json['severity'] ?? '',
      description: json['description'] ?? '',
      transaction: TransactionModel(
        transactionId: json['transaction']['transactionId'] ?? '',
        amount: (json['transaction']['amount'] ?? 0).toDouble(),
        categoryId: json['transaction']['categoryId'] ?? '',
        note: json['transaction']['note'] ?? '',
        date: DateTime.parse(json['transaction']['date'] ?? DateTime.now().toIso8601String()),
        type: TransactionType.fromString(json['transaction']['type'] ?? 'EXPENSE'),
        userId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      detectedAt: DateTime.parse(json['detectedAt'] ?? DateTime.now().toIso8601String()),
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
}

// =============================================================================
// PREDICTION MODELS
// =============================================================================

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

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'predictedAmount': predictedAmount,
      'confidence': confidence,
      'period': period,
      'factors': factors,
    };
  }

  factory SpendingPrediction.fromJson(Map<String, dynamic> json) {
    return SpendingPrediction(
      categoryId: json['categoryId'] ?? '',
      predictedAmount: (json['predictedAmount'] ?? 0).toDouble(),
      confidence: (json['confidence'] ?? 0).toDouble(),
      period: json['period'] ?? '',
      factors: List<String>.from(json['factors'] ?? []),
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'predictions': predictions.map((p) => p.toJson()).toList(),
      'totalPredictedIncome': totalPredictedIncome,
      'totalPredictedExpenses': totalPredictedExpenses,
      'confidence': confidence,
      'factors': factors,
    };
  }

  factory CashFlowPrediction.fromJson(Map<String, dynamic> json) {
    return CashFlowPrediction(
      predictions: (json['predictions'] as List<dynamic>? ?? [])
          .map((p) => MonthlyPrediction.fromJson(p))
          .toList(),
      totalPredictedIncome: (json['totalPredictedIncome'] ?? 0).toDouble(),
      totalPredictedExpenses: (json['totalPredictedExpenses'] ?? 0).toDouble(),
      confidence: (json['confidence'] ?? 0).toDouble(),
      factors: List<String>.from(json['factors'] ?? []),
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'month': month.toIso8601String(),
      'income': income,
      'expenses': expenses,
      'netFlow': netFlow,
      'confidence': confidence,
    };
  }

  factory MonthlyPrediction.fromJson(Map<String, dynamic> json) {
    return MonthlyPrediction(
      month: DateTime.parse(json['month'] ?? DateTime.now().toIso8601String()),
      income: (json['income'] ?? 0).toDouble(),
      expenses: (json['expenses'] ?? 0).toDouble(),
      netFlow: (json['netFlow'] ?? 0).toDouble(),
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
}

// =============================================================================
// CATEGORY OPTIMIZATION MODELS
// =============================================================================

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

  Map<String, dynamic> toJson() {
    return {
      'suggestedMerges': suggestedMerges.map((m) => m.toJson()).toList(),
      'suggestedSplits': suggestedSplits.map((s) => s.toJson()).toList(),
      'unusedCategories': unusedCategories,
      'newCategorySuggestions': newCategorySuggestions,
      'optimizationDate': optimizationDate.toIso8601String(),
      'potentialSavings': potentialSavings,
    };
  }

  factory CategoryOptimization.fromJson(Map<String, dynamic> json) {
    return CategoryOptimization(
      suggestedMerges: (json['suggestedMerges'] as List<dynamic>? ?? [])
          .map((m) => CategoryMergeRecommendation.fromJson(m))
          .toList(),
      suggestedSplits: (json['suggestedSplits'] as List<dynamic>? ?? [])
          .map((s) => CategorySplitRecommendation.fromJson(s))
          .toList(),
      unusedCategories: List<String>.from(json['unusedCategories'] ?? []),
      newCategorySuggestions: List<String>.from(json['newCategorySuggestions'] ?? []),
      optimizationDate: DateTime.parse(json['optimizationDate'] ?? DateTime.now().toIso8601String()),
      potentialSavings: (json['potentialSavings'] ?? 0).toDouble(),
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'categoryIds': categoryIds,
      'suggestedName': suggestedName,
      'reason': reason,
      'confidence': confidence,
    };
  }

  factory CategoryMergeRecommendation.fromJson(Map<String, dynamic> json) {
    return CategoryMergeRecommendation(
      categoryIds: List<String>.from(json['categoryIds'] ?? []),
      suggestedName: json['suggestedName'] ?? '',
      reason: json['reason'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'suggestedSplits': suggestedSplits,
      'reason': reason,
      'confidence': confidence,
    };
  }

  factory CategorySplitRecommendation.fromJson(Map<String, dynamic> json) {
    return CategorySplitRecommendation(
      categoryId: json['categoryId'] ?? '',
      suggestedSplits: List<String>.from(json['suggestedSplits'] ?? []),
      reason: json['reason'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
}

// =============================================================================
// FINANCIAL HEALTH MODELS
// =============================================================================

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

  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'spendingScore': spendingScore,
      'budgetScore': budgetScore,
      'savingsScore': savingsScore,
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
      'lastCalculated': lastCalculated.toIso8601String(),
      'trend': trend,
      'factors': factors,
    };
  }

  factory FinancialHealthScore.fromJson(Map<String, dynamic> json) {
    return FinancialHealthScore(
      overallScore: (json['overallScore'] ?? 0).toDouble(),
      spendingScore: (json['spendingScore'] ?? 0).toDouble(),
      budgetScore: (json['budgetScore'] ?? 0).toDouble(),
      savingsScore: (json['savingsScore'] ?? 0).toDouble(),
      recommendations: (json['recommendations'] as List<dynamic>? ?? [])
          .map((r) => HealthRecommendation.fromJson(r))
          .toList(),
      lastCalculated: DateTime.parse(json['lastCalculated'] ?? DateTime.now().toIso8601String()),
      trend: (json['trend'] ?? 0).toDouble(),
      factors: List<String>.from(json['factors'] ?? []),
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'priority': priority,
      'impact': impact,
    };
  }

  factory HealthRecommendation.fromJson(Map<String, dynamic> json) {
    return HealthRecommendation(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? '',
      impact: (json['impact'] ?? 0).toDouble(),
    );
  }
}

// =============================================================================
// BUDGET RECOMMENDATION MODELS
// =============================================================================

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'recommendationType': recommendationType,
      'suggestedAmount': suggestedAmount,
      'currentSpending': currentSpending,
      'priority': priority,
      'reasoning': reasoning,
      'confidence': confidence,
      'factors': factors,
    };
  }

  factory SmartBudgetRecommendation.fromJson(Map<String, dynamic> json) {
    return SmartBudgetRecommendation(
      id: json['id'] ?? '',
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      recommendationType: json['recommendationType'] ?? '',
      suggestedAmount: (json['suggestedAmount'] ?? 0).toDouble(),
      currentSpending: (json['currentSpending'] ?? 0).toDouble(),
      priority: (json['priority'] ?? 0).toDouble(),
      reasoning: json['reasoning'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
      factors: List<String>.from(json['factors'] ?? []),
    );
  }
}

// =============================================================================
// SUPPORTING DATA MODELS
// =============================================================================

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

  Map<String, dynamic> toJson() {
    return {
      'totalSpending': totalSpending,
      'averageDaily': averageDaily,
      'categories': categories.map((k, v) => MapEntry(k, v.toJson())),
      'trends': trends.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  factory SpendingData.fromJson(Map<String, dynamic> json) {
    return SpendingData(
      totalSpending: (json['totalSpending'] ?? 0).toDouble(),
      averageDaily: (json['averageDaily'] ?? 0).toDouble(),
      categories: (json['categories'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, CategoryDistribution.fromJson(v))),
      trends: (json['trends'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, MonthlyTrend.fromJson(v))),
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'totalBudget': totalBudget,
      'utilizationRate': utilizationRate,
      'categoriesWithBudgets': categoriesWithBudgets,
      'categoriesWithoutBudgets': categoriesWithoutBudgets,
    };
  }

  factory BudgetData.fromJson(Map<String, dynamic> json) {
    return BudgetData(
      totalBudget: (json['totalBudget'] ?? 0).toDouble(),
      utilizationRate: (json['utilizationRate'] ?? 0).toDouble(),
      categoriesWithBudgets: json['categoriesWithBudgets'] ?? 0,
      categoriesWithoutBudgets: json['categoriesWithoutBudgets'] ?? 0,
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'totalSavings': totalSavings,
      'monthlyContribution': monthlyContribution,
      'savingsRate': savingsRate,
      'savingsGoal': savingsGoal,
    };
  }

  factory SavingsData.fromJson(Map<String, dynamic> json) {
    return SavingsData(
      totalSavings: (json['totalSavings'] ?? 0).toDouble(),
      monthlyContribution: (json['monthlyContribution'] ?? 0).toDouble(),
      savingsRate: (json['savingsRate'] ?? 0).toDouble(),
      savingsGoal: (json['savingsGoal'] ?? 0).toDouble(),
    );
  }
}

// =============================================================================
// TRENDING INSIGHTS MODELS
// =============================================================================

class TrendingInsight {
  final String type;
  final String title;
  final String description;
  final String categoryId;
  final double impact;
  final String trend; // 'up', 'down', 'stable'

  const TrendingInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.impact,
    required this.trend,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'impact': impact,
      'trend': trend,
    };
  }

  factory TrendingInsight.fromJson(Map<String, dynamic> json) {
    return TrendingInsight(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      categoryId: json['categoryId'] ?? '',
      impact: (json['impact'] ?? 0).toDouble(),
      trend: json['trend'] ?? 'stable',
    );
  }
}
