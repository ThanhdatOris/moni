// =============================================================================
// AI MODEL EXTENSIONS
// =============================================================================

import 'ai_models.dart';

// =============================================================================
// BUDGET ANALYTICS EXTENSIONS
// =============================================================================

extension BudgetAnalyticsExtension on BudgetAnalytics {
  Map<String, dynamic> toJson() {
    return {
      'totalBudgets': totalBudgets,
      'totalSpending': totalSpending,
      'averageUtilization': averageUtilization,
      'riskDistribution': riskDistribution,
      'topCategories': topCategories,
    };
  }
}

extension BudgetRecommendationExtension on BudgetRecommendation {
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
}

// =============================================================================
// NOTIFICATION EXTENSIONS
// =============================================================================

extension AIInsightExtension on AIInsight {
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
}
