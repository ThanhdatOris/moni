// =============================================================================
// AI BUDGET MODELS
// =============================================================================

// =============================================================================
// ANALYSIS MODELS
// =============================================================================

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

  Map<String, dynamic> toJson() {
    return {
      'currentSpending': currentSpending,
      'projectedSpending': projectedSpending,
      'averageSpending': averageSpending,
      'riskScore': riskScore,
      'isAnomaly': isAnomaly,
      'requiresAlert': requiresAlert,
      'requiresAdjustment': requiresAdjustment,
      'insights': insights.map((i) => i.toJson()).toList(),
    };
  }

  factory SpendingAnalysis.fromJson(Map<String, dynamic> json) {
    return SpendingAnalysis(
      currentSpending: (json['currentSpending'] ?? 0).toDouble(),
      projectedSpending: (json['projectedSpending'] ?? 0).toDouble(),
      averageSpending: (json['averageSpending'] ?? 0).toDouble(),
      riskScore: (json['riskScore'] ?? 0).toDouble(),
      isAnomaly: json['isAnomaly'] ?? false,
      requiresAlert: json['requiresAlert'] ?? false,
      requiresAdjustment: json['requiresAdjustment'] ?? false,
      insights: (json['insights'] as List<dynamic>? ?? [])
          .map((i) => AIInsight.fromJson(i))
          .toList(),
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'budgetId': budgetId,
      'predictedSpending': predictedSpending,
      'confidence': confidence,
      'factors': factors,
    };
  }

  factory BudgetPrediction.fromJson(Map<String, dynamic> json) {
    return BudgetPrediction(
      budgetId: json['budgetId'] ?? '',
      predictedSpending: (json['predictedSpending'] ?? 0).toDouble(),
      confidence: (json['confidence'] ?? 0).toDouble(),
      factors: List<String>.from(json['factors'] ?? []),
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'priority': priority,
      'suggestedLimit': suggestedLimit,
      'category': category,
      'confidence': confidence,
    };
  }

  factory BudgetRecommendation.fromJson(Map<String, dynamic> json) {
    return BudgetRecommendation(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: (json['priority'] ?? 0).toDouble(),
      suggestedLimit: (json['suggestedLimit'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'spendingStyle': spendingStyle,
      'riskTolerance': riskTolerance,
      'savingsGoal': savingsGoal,
      'primaryCategories': primaryCategories,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] ?? '',
      spendingStyle: json['spendingStyle'] ?? '',
      riskTolerance: (json['riskTolerance'] ?? 0).toDouble(),
      savingsGoal: (json['savingsGoal'] ?? 0).toDouble(),
      primaryCategories: List<String>.from(json['primaryCategories'] ?? []),
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'totalBudgets': totalBudgets,
      'totalSpending': totalSpending,
      'averageUtilization': averageUtilization,
      'riskDistribution': riskDistribution,
      'topCategories': topCategories,
    };
  }

  factory BudgetAnalytics.fromJson(Map<String, dynamic> json) {
    return BudgetAnalytics(
      totalBudgets: json['totalBudgets'] ?? 0,
      totalSpending: (json['totalSpending'] ?? 0).toDouble(),
      averageUtilization: (json['averageUtilization'] ?? 0).toDouble(),
      riskDistribution: Map<String, int>.from(json['riskDistribution'] ?? {}),
      topCategories: List<String>.from(json['topCategories'] ?? []),
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'budgetId': budgetId,
      'currentLimit': currentLimit,
      'suggestedLimit': suggestedLimit,
      'reason': reason,
      'confidence': confidence,
    };
  }

  factory BudgetAdjustmentSuggestion.fromJson(Map<String, dynamic> json) {
    return BudgetAdjustmentSuggestion(
      budgetId: json['budgetId'] ?? '',
      currentLimit: (json['currentLimit'] ?? 0).toDouble(),
      suggestedLimit: (json['suggestedLimit'] ?? 0).toDouble(),
      reason: json['reason'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
}

// =============================================================================
// SUPPORTING MODELS
// =============================================================================

class AIInsight {
  final String id;
  final String type;
  final String title;
  final String description;
  final double importance;
  final String category;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  AIInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.importance,
    required this.category,
    required this.data,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'importance': importance,
      'category': category,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AIInsight.fromJson(Map<String, dynamic> json) {
    return AIInsight(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      importance: (json['importance'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
