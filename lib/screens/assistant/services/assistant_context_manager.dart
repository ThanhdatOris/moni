import 'package:logger/logger.dart';

import '../../../services/analytics/analytics_coordinator.dart';
import '../models/agent_request_model.dart';

/// Assistant Context Manager - quản lý context và dữ liệu chia sẻ giữa các modules
class AssistantContextManager {
  static final AssistantContextManager _instance = AssistantContextManager._internal();
  factory AssistantContextManager() => _instance;
  AssistantContextManager._internal();

  final Logger _logger = Logger();
  
  // Cached data
  Map<String, dynamic>? _cachedAnalytics;
  Map<String, dynamic>? _cachedBudgetData;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidDuration = Duration(minutes: 15);

  /// Get aggregated context for AI processing
  Future<Map<String, dynamic>> getFullContext() async {
    if (_isCacheValid()) {
      _logger.i('Returning cached context');
      return {
        'analytics': _cachedAnalytics ?? {},
        'budget': _cachedBudgetData ?? {},
        'last_updated': _lastCacheUpdate?.toIso8601String(),
      };
    }

    _logger.i('Refreshing context cache');
    
    final analytics = await _fetchAnalyticsContext();
    
    _cachedAnalytics = analytics;
    _lastCacheUpdate = DateTime.now();
    
    return {
      'analytics': analytics,
      'last_updated': _lastCacheUpdate?.toIso8601String(),
    };
  }

  /// Check if cache is still valid
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheValidDuration;
  }

  /// Clear cache to force refresh
  void clearCache() {
    _cachedAnalytics = null;
    _cachedBudgetData = null;
    _lastCacheUpdate = null;
    _logger.i('Context cache cleared');
  }

  /// Get context for specific request type
  Future<Map<String, dynamic>> getContextForRequest(AgentRequestType type) async {
    final fullContext = await getFullContext();
    
    switch (type) {
      case AgentRequestType.analytics:
        return {'analytics': fullContext['analytics']};
      case AgentRequestType.budget:
        return {'budget': fullContext['budget']};
      case AgentRequestType.report:
        return {
          'analytics': fullContext['analytics'],
          'budget': fullContext['budget'],
        };
      case AgentRequestType.chat:
        return fullContext; // Chat needs all context
    }
  }

  /// Fetch analytics context (simplified version)
  Future<Map<String, dynamic>> _fetchAnalyticsContext() async {
    try {
      final coordinator = AnalyticsCoordinator();
      final analysis = await coordinator.performComprehensiveAnalysis();
      
      return {
        'confidence_score': analysis.spendingPatterns.confidenceScore,
        'anomalies_count': analysis.anomalies.length,
        'budget_recommendations_count': analysis.budgetRecommendations.length,
        'financial_health_score': analysis.financialHealth.overallScore,
        'overall_score': analysis.overallScore,
        'categories_analyzed': analysis.spendingPatterns.categoryDistribution.length,
        'analysis_date': analysis.analysisDate.toIso8601String(),
        'has_predictions': analysis.spendingPatterns.predictions.isNotEmpty,
        'anomalies_summary': analysis.anomalies.take(3).map((a) => {
          'description': a.description,
          'severity': a.severity,
          'amount': a.transaction.amount,
          'type': a.type,
        }).toList(),
      };
    } catch (e) {
      _logger.w('Error fetching analytics context: $e');
      return {'error': e.toString(), 'available': false};
    }
  }

  /// Enhanced context sharing between modules
  Future<Map<String, dynamic>> shareContextBetweenModules(
    AgentRequestType sourceModule,
    AgentRequestType targetModule,
  ) async {
    final fullContext = await getFullContext();
    
    // Cross-module insights
    final insights = <String, dynamic>{};
    
    if (sourceModule == AgentRequestType.analytics && 
        targetModule == AgentRequestType.budget) {
      insights['analytics_for_budget'] = {
        'spending_patterns': fullContext['analytics']['categories_analyzed'],
        'anomalies_detected': fullContext['analytics']['anomalies_count'],
        'financial_health': fullContext['analytics']['financial_health_score'],
      };
    }
    
    if (sourceModule == AgentRequestType.budget && 
        targetModule == AgentRequestType.report) {
      insights['budget_for_reports'] = {
        'recommendations': fullContext['budget']['recommendations_count'],
        'priority_areas': fullContext['budget']['high_priority_count'],
        'categories': fullContext['budget']['categories_covered'],
      };
    }
    
    return {
      'source_context': await getContextForRequest(sourceModule),
      'target_context': await getContextForRequest(targetModule),
      'shared_insights': insights,
    };
  }

  /// Update context when new data is available
  Future<void> updateContextFromSource(AgentRequestType source, Map<String, dynamic> newData) async {
    switch (source) {
      case AgentRequestType.analytics:
        _cachedAnalytics = {..._cachedAnalytics ?? {}, ...newData};
        break;
      case AgentRequestType.budget:
        _cachedBudgetData = {..._cachedBudgetData ?? {}, ...newData};
        break;
      default:
        // For reports and chat, update both if relevant
        if (newData.containsKey('analytics')) {
          _cachedAnalytics = {..._cachedAnalytics ?? {}, ...newData['analytics']};
        }
        if (newData.containsKey('budget')) {
          _cachedBudgetData = {..._cachedBudgetData ?? {}, ...newData['budget']};
        }
    }
    
    _lastCacheUpdate = DateTime.now();
    _logger.i('Context updated from source: $source');
  }

  /// Get summary for AI processing
  Map<String, dynamic> getContextSummary() {
    return {
      'cache_valid': _isCacheValid(),
      'last_update': _lastCacheUpdate?.toIso8601String(),
      'analytics_available': _cachedAnalytics != null && !_cachedAnalytics!.containsKey('error'),
      'budget_available': _cachedBudgetData != null && !_cachedBudgetData!.containsKey('error'),
      'analytics_score': _cachedAnalytics?['overall_score'],
      'budget_recommendations': _cachedBudgetData?['recommendations_count'],
    };
  }
}
