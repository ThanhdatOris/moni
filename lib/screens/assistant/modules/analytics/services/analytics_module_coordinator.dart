import '../../../../../core/models/analytics/analytics_models.dart';
import '../../../../../services/base_service.dart';
import 'anomaly_detector.dart';
import 'budget_recommender.dart';
import 'cashflow_predictor.dart';
import 'category_optimizer.dart';
import 'financial_health_calculator.dart';
import 'spending_pattern_analyzer.dart';
/// Analytics Module Coordinator - Analytics services for Assistant Module
/// Migrated from lib/services/analytics/ untuk modularity yang lebih baik

/// Analytics coordinator khusus untuk module Assistant/Analytics
class AnalyticsModuleCoordinator extends BaseService {
  static final AnalyticsModuleCoordinator _instance = AnalyticsModuleCoordinator._internal();
  factory AnalyticsModuleCoordinator() => _instance;
  AnalyticsModuleCoordinator._internal();

  // Analytics services - Lazy initialization
  SpendingPatternAnalyzer? _spendingAnalyzer;
  CategoryOptimizer? _categoryOptimizer;
  FinancialHealthCalculator? _healthCalculator;
  AnomalyDetector? _anomalyDetector;
  CashFlowPredictor? _cashflowPredictor;
  BudgetRecommender? _budgetRecommender;

  /// Get spending pattern analyzer instance
  SpendingPatternAnalyzer get spendingAnalyzer {
    _spendingAnalyzer ??= SpendingPatternAnalyzer();
    return _spendingAnalyzer!;
  }

  /// Get category optimizer instance
  CategoryOptimizer get categoryOptimizer {
    _categoryOptimizer ??= CategoryOptimizer();
    return _categoryOptimizer!;
  }

  /// Get financial health calculator instance
  FinancialHealthCalculator get healthCalculator {
    _healthCalculator ??= FinancialHealthCalculator();
    return _healthCalculator!;
  }

  /// Get anomaly detector instance
  AnomalyDetector get anomalyDetector {
    _anomalyDetector ??= AnomalyDetector();
    return _anomalyDetector!;
  }

  /// Get cash flow predictor instance
  CashFlowPredictor get cashflowPredictor {
    _cashflowPredictor ??= CashFlowPredictor();
    return _cashflowPredictor!;
  }

  /// Get budget recommender instance
  BudgetRecommender get budgetRecommender {
    _budgetRecommender ??= BudgetRecommender();
    return _budgetRecommender!;
  }

  /// Comprehensive analytics analysis (calls all analyzers)
  Future<ComprehensiveAnalysis> performComprehensiveAnalysis() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      logInfo('Starting comprehensive analytics analysis for user: $currentUserId');

      // Run all analytics in parallel for better performance
      final futures = await Future.wait([
        spendingAnalyzer.analyzeSpendingPatterns(),
        categoryOptimizer.optimizeCategories(),
        healthCalculator.calculateFinancialHealth(),
        anomalyDetector.detectAdvancedAnomalies(),
        cashflowPredictor.predictCashFlow(),
        budgetRecommender.generateSmartBudgetRecommendations(),
      ]);

      final analysis = ComprehensiveAnalysis(
        spendingPatterns: futures[0] as SpendingPatternAnalysis,
        categoryOptimization: futures[1] as CategoryOptimization,
        financialHealth: futures[2] as FinancialHealthScore,
        anomalies: futures[3] as List<SpendingAnomaly>,
        cashFlowPrediction: futures[4] as CashFlowPrediction,
        budgetRecommendations: futures[5] as List<SmartBudgetRecommendation>,
        analysisDate: DateTime.now(),
        overallScore: _calculateOverallScore(futures),
      );

      logInfo('Completed comprehensive analytics analysis');
      return analysis;
    } catch (e) {
      logError('Error performing comprehensive analysis', e);
      return _getEmptyAnalysis();
    }
  }

  /// Quick analysis for dashboard (lightweight version)
  Future<QuickAnalysis> performQuickAnalysis() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      logInfo('Starting quick analytics analysis for user: $currentUserId');

      // Run essential analytics only
      final futures = await Future.wait([
        spendingAnalyzer.getQuickSpendingInsights(),
        healthCalculator.getQuickHealthScore(),
        anomalyDetector.getRecentAnomalies(days: 30),
      ]);

      final analysis = QuickAnalysis(
        spendingInsights: futures[0] as Map<String, dynamic>,
        healthScore: futures[1] as double,
        recentAnomalies: futures[2] as List<SpendingAnomaly>,
        analysisDate: DateTime.now(),
      );

      logInfo('Completed quick analytics analysis');
      return analysis;
    } catch (e) {
      logError('Error performing quick analysis', e);
      return _getEmptyQuickAnalysis();
    }
  }

  /// Get analytics summary for specific category
  Future<CategoryAnalysisSummary> analyzeCategoryPerformance(String categoryId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      logInfo('Analyzing category performance for: $categoryId');

      final futures = await Future.wait([
        spendingAnalyzer.analyzeCategorySpending(categoryId),
        anomalyDetector.getCategoryAnomalies(categoryId),
        budgetRecommender.getCategoryRecommendations(categoryId),
      ]);

      final summary = CategoryAnalysisSummary(
        categoryId: categoryId,
        spendingData: futures[0] as Map<String, dynamic>,
        anomalies: futures[1] as List<SpendingAnomaly>,
        recommendations: futures[2] as List<SmartBudgetRecommendation>,
        analysisDate: DateTime.now(),
      );

      logInfo('Completed category analysis for: $categoryId');
      return summary;
    } catch (e) {
      logError('Error analyzing category performance', e);
      return _getEmptyCategoryAnalysis(categoryId);
    }
  }

  /// Get trending insights across all categories
  Future<List<TrendingInsight>> getTrendingInsights({int days = 30}) async {
    try {
      if (currentUserId == null) return [];

      logInfo('Getting trending insights for last $days days');

      final insights = await spendingAnalyzer.getTrendingInsights(days: days);
      
      logInfo('Found ${insights.length} trending insights');
      return insights;
    } catch (e) {
      logError('Error getting trending insights', e);
      return [];
    }
  }

  /// Check if user needs financial advice
  Future<bool> needsFinancialAdvice() async {
    try {
      final healthScore = await healthCalculator.getQuickHealthScore();
      final recentAnomalies = await anomalyDetector.getRecentAnomalies(days: 7);
      
      // Need advice if health score is low or there are recent anomalies
      return healthScore < 60 || recentAnomalies.isNotEmpty;
    } catch (e) {
      logError('Error checking if user needs financial advice', e);
      return false;
    }
  }

  /// Get priority actions for user
  Future<List<PriorityAction>> getPriorityActions() async {
    try {
      if (currentUserId == null) return [];

      final actions = <PriorityAction>[];

      // Get recommendations from all services
      final healthRecommendations = await healthCalculator.getPriorityRecommendations();
      final budgetRecommendations = await budgetRecommender.getHighPriorityRecommendations();
      final categoryOptimizations = await categoryOptimizer.getUrgentOptimizations();

      // Convert to priority actions
      for (final rec in healthRecommendations) {
        actions.add(PriorityAction(
          type: 'health',
          title: rec.title,
          description: rec.description,
          priority: rec.priority == 'high' ? 1.0 : 0.8,
          action: 'health_improvement',
        ));
      }

      for (final rec in budgetRecommendations) {
        actions.add(PriorityAction(
          type: 'budget',
          title: rec.categoryName,
          description: rec.reasoning,
          priority: rec.priority,
          action: 'budget_adjustment',
        ));
      }

      for (final opt in categoryOptimizations) {
        actions.add(PriorityAction(
          type: 'category',
          title: opt['title'] as String,
          description: opt['description'] as String,
          priority: (opt['priority'] as num).toDouble(),
          action: 'optimize_category',
        ));
      }

      // Sort by priority
      actions.sort((a, b) => b.priority.compareTo(a.priority));

      return actions.take(5).toList(); // Return top 5 actions
    } catch (e) {
      logError('Error getting priority actions', e);
      return [];
    }
  }

  // Helper methods

  double _calculateOverallScore(List<dynamic> analysisResults) {
    try {
      // Extract scores from different analysis results
      final financialHealth = analysisResults[2] as FinancialHealthScore;
      final anomalies = analysisResults[3] as List<SpendingAnomaly>;
      
      double score = financialHealth.overallScore;
      
      // Deduct points for critical anomalies
      final criticalAnomalies = anomalies.where((a) => a.severity == 'critical').length;
      score -= criticalAnomalies * 5; // -5 points per critical anomaly
      
      return score.clamp(0.0, 100.0);
    } catch (e) {
      logError('Error calculating overall score', e);
      return 50.0; // Default neutral score
    }
  }

  ComprehensiveAnalysis _getEmptyAnalysis() {
    return ComprehensiveAnalysis(
      spendingPatterns: _getEmptySpendingPatterns(),
      categoryOptimization: _getEmptyCategoryOptimization(),
      financialHealth: _getEmptyFinancialHealth(),
      anomalies: [],
      cashFlowPrediction: _getEmptyCashFlowPrediction(),
      budgetRecommendations: [],
      analysisDate: DateTime.now(),
      overallScore: 0.0,
    );
  }

  QuickAnalysis _getEmptyQuickAnalysis() {
    return QuickAnalysis(
      spendingInsights: {},
      healthScore: 0.0,
      recentAnomalies: [],
      analysisDate: DateTime.now(),
    );
  }

  CategoryAnalysisSummary _getEmptyCategoryAnalysis(String categoryId) {
    return CategoryAnalysisSummary(
      categoryId: categoryId,
      spendingData: {},
      anomalies: [],
      recommendations: [],
      analysisDate: DateTime.now(),
    );
  }

  // Empty model generators
  SpendingPatternAnalysis _getEmptySpendingPatterns() {
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

  CategoryOptimization _getEmptyCategoryOptimization() {
    return CategoryOptimization(
      suggestedMerges: [],
      suggestedSplits: [],
      unusedCategories: [],
      newCategorySuggestions: [],
      optimizationDate: DateTime.now(),
      potentialSavings: 0.0,
    );
  }

  FinancialHealthScore _getEmptyFinancialHealth() {
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

  /// Dispose resources
  void dispose() {
    _spendingAnalyzer = null;
    _categoryOptimizer = null;
    _healthCalculator = null;
    _anomalyDetector = null;
    _cashflowPredictor = null;
    _budgetRecommender = null;
  }
}

// Supporting classes for coordinator results

/// Comprehensive analysis result containing all analytics
class ComprehensiveAnalysis {
  final SpendingPatternAnalysis spendingPatterns;
  final CategoryOptimization categoryOptimization;
  final FinancialHealthScore financialHealth;
  final List<SpendingAnomaly> anomalies;
  final CashFlowPrediction cashFlowPrediction;
  final List<SmartBudgetRecommendation> budgetRecommendations;
  final DateTime analysisDate;
  final double overallScore;

  const ComprehensiveAnalysis({
    required this.spendingPatterns,
    required this.categoryOptimization,
    required this.financialHealth,
    required this.anomalies,
    required this.cashFlowPrediction,
    required this.budgetRecommendations,
    required this.analysisDate,
    required this.overallScore,
  });
}

/// Quick analysis for dashboard
class QuickAnalysis {
  final Map<String, dynamic> spendingInsights;
  final double healthScore;
  final List<SpendingAnomaly> recentAnomalies;
  final DateTime analysisDate;

  const QuickAnalysis({
    required this.spendingInsights,
    required this.healthScore,
    required this.recentAnomalies,
    required this.analysisDate,
  });
}

/// Category analysis summary
class CategoryAnalysisSummary {
  final String categoryId;
  final Map<String, dynamic> spendingData;
  final List<SpendingAnomaly> anomalies;
  final List<SmartBudgetRecommendation> recommendations;
  final DateTime analysisDate;

  const CategoryAnalysisSummary({
    required this.categoryId,
    required this.spendingData,
    required this.anomalies,
    required this.recommendations,
    required this.analysisDate,
  });
}

/// Priority action for user
class PriorityAction {
  final String type;
  final String title;
  final String description;
  final double priority; // 0.0 - 1.0
  final String action;

  const PriorityAction({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.action,
  });
}