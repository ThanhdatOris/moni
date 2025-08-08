import 'dart:async';

import 'package:logger/logger.dart';

import '../models/agent_request_model.dart';

/// Enhanced Cross-module context manager for seamless data sharing
class AssistantContextManager {
  static final AssistantContextManager _instance =
      AssistantContextManager._internal();
  factory AssistantContextManager() => _instance;
  AssistantContextManager._internal();

  final Logger _logger = Logger();

  // Enhanced context storage
  final Map<String, dynamic> _globalContext = {};
  final Map<String, Map<String, dynamic>> _moduleContexts = {};
  final Map<String, List<StreamController<Map<String, dynamic>>>>
      _contextStreams = {};
  final List<ContextChangeListener> _changeListeners = [];

  // Legacy cached data - keeping for compatibility
  Map<String, dynamic>? _cachedAnalytics;
  Map<String, dynamic>? _cachedBudgetData;
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidDuration = Duration(minutes: 15);

  // Context keys
  static const String userProfile = 'user_profile';
  static const String financialData = 'financial_data';
  static const String preferences = 'preferences';
  static const String currentPeriod = 'current_period';
  static const String selectedCategories = 'selected_categories';
  static const String filters = 'filters';
  static const String sharedInsights = 'shared_insights';

  /// Set global context that's available across all modules
  void setGlobalContext(String key, dynamic value) {
    _globalContext[key] = value;
    _notifyContextChange('global', key, value);
    _logger.d('Set global context: $key');
  }

  /// Get global context
  T? getGlobalContext<T>(String key) {
    return _globalContext[key] as T?;
  }

  /// Set context for specific module
  void setModuleContext(String moduleId, String key, dynamic value) {
    _moduleContexts.putIfAbsent(moduleId, () => {});
    _moduleContexts[moduleId]![key] = value;
    _notifyContextChange(moduleId, key, value);
    _logger.d('Set module context: $moduleId.$key');
  }

  /// Get context for specific module
  T? getModuleContext<T>(String moduleId, String key) {
    return _moduleContexts[moduleId]?[key] as T?;
  }

  /// Get all context for a module
  Map<String, dynamic> getAllModuleContext(String moduleId) {
    return Map.unmodifiable(_moduleContexts[moduleId] ?? {});
  }

  /// Share data from one module to another
  void shareContextBetweenModules(
    String fromModule,
    String toModule,
    String key,
    dynamic value, {
    bool persistent = true,
  }) {
    final sharedData = SharedContextData(
      fromModule: fromModule,
      toModule: toModule,
      key: key,
      value: value,
      timestamp: DateTime.now(),
      persistent: persistent,
    );

    // Store in target module
    setModuleContext(toModule, 'shared_from_$fromModule', sharedData.toMap());

    // Also store in global shared context
    final sharedKey = 'shared_${fromModule}_to_${toModule}_$key';
    setGlobalContext(sharedKey, sharedData.toMap());

    _logger.i('Shared context: $fromModule → $toModule ($key)');
  }

  /// Subscribe to context changes for a specific module
  Stream<Map<String, dynamic>> subscribeToModuleContext(String moduleId) {
    _contextStreams.putIfAbsent(moduleId, () => []);
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _contextStreams[moduleId]!.add(controller);

    // Send initial data
    controller.add(getAllModuleContext(moduleId));

    return controller.stream;
  }

  /// Legacy method - maintained for compatibility
  Future<Map<String, dynamic>> getFullContext() async {
    if (_isCacheValid()) {
      _logger.i('Returning cached context');
      return {
        'analytics': _cachedAnalytics ?? {},
        'budget': _cachedBudgetData ?? {},
        'last_updated': _lastCacheUpdate?.toIso8601String(),
        'global': _globalContext,
        'modules': _moduleContexts,
      };
    }

    _logger.i('Refreshing context cache');

    final analytics = await _fetchAnalyticsContext();

    _cachedAnalytics = analytics;
    _lastCacheUpdate = DateTime.now();

    return {
      'analytics': analytics,
      'last_updated': _lastCacheUpdate?.toIso8601String(),
      'global': _globalContext,
      'modules': _moduleContexts,
    };
  }

  void _notifyContextChange(String moduleId, String key, dynamic value) {
    // Notify stream subscribers
    if (_contextStreams.containsKey(moduleId)) {
      final context =
          moduleId == 'global' ? _globalContext : getAllModuleContext(moduleId);
      for (final controller in _contextStreams[moduleId]!) {
        if (!controller.isClosed) {
          controller.add(Map.from(context));
        }
      }
    }

    // Notify change listeners
    for (final listener in _changeListeners) {
      listener.onContextChanged(moduleId, key, value);
    }
  }

  void clearCache() {
    _cachedAnalytics = null;
    _cachedBudgetData = null;
    _lastCacheUpdate = null;
    _logger.i('Context cache cleared');
  }

  /// Get context for specific request type
  Future<Map<String, dynamic>> getContextForRequest(
      AgentRequestType type) async {
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
    // Module Analytics đã bị gỡ; trả về rỗng để tương thích
    _logger.w('Analytics module removed; returning empty analytics context');
    return {'available': false};
  }

  /// Enhanced context sharing between modules for legacy support
  Future<Map<String, dynamic>> shareContextBetweenAgentModules(
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
  Future<void> updateContextFromSource(
      AgentRequestType source, Map<String, dynamic> newData) async {
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
          _cachedAnalytics = {
            ..._cachedAnalytics ?? {},
            ...newData['analytics']
          };
        }
        if (newData.containsKey('budget')) {
          _cachedBudgetData = {
            ..._cachedBudgetData ?? {},
            ...newData['budget']
          };
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
      'analytics_available':
          _cachedAnalytics != null && !_cachedAnalytics!.containsKey('error'),
      'budget_available':
          _cachedBudgetData != null && !_cachedBudgetData!.containsKey('error'),
      'analytics_score': _cachedAnalytics?['overall_score'],
      'budget_recommendations': _cachedBudgetData?['recommendations_count'],
      'global_keys': _globalContext.keys.toList(),
      'modules': _moduleContexts.keys.toList(),
    };
  }

  /// Check if cache is still valid
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheValidDuration;
  }

  /// Dispose resources
  void dispose() {
    for (final controllers in _contextStreams.values) {
      for (final controller in controllers) {
        controller.close();
      }
    }
    _contextStreams.clear();
    _changeListeners.clear();
    _globalContext.clear();
    _moduleContexts.clear();
  }
}

/// Shared context data model
class SharedContextData {
  final String fromModule;
  final String toModule;
  final String key;
  final dynamic value;
  final DateTime timestamp;
  final bool persistent;

  SharedContextData({
    required this.fromModule,
    required this.toModule,
    required this.key,
    required this.value,
    required this.timestamp,
    this.persistent = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'from_module': fromModule,
      'to_module': toModule,
      'key': key,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'persistent': persistent,
    };
  }

  factory SharedContextData.fromMap(Map<String, dynamic> map) {
    return SharedContextData(
      fromModule: map['from_module'],
      toModule: map['to_module'],
      key: map['key'],
      value: map['value'],
      timestamp: DateTime.parse(map['timestamp']),
      persistent: map['persistent'] ?? true,
    );
  }
}

/// Context change listener interface
abstract class ContextChangeListener {
  void onContextChanged(String moduleId, String key, dynamic value);
}

/// Helper class for common context operations
class ContextHelper {
  static final AssistantContextManager _manager = AssistantContextManager();

  /// Set user financial data accessible by all modules
  static void setFinancialData(Map<String, dynamic> data) {
    _manager.setGlobalContext(AssistantContextManager.financialData, data);
  }

  /// Get user financial data
  static Map<String, dynamic>? getFinancialData() {
    return _manager.getGlobalContext<Map<String, dynamic>>(
      AssistantContextManager.financialData,
    );
  }

  /// Set current period filter
  static void setCurrentPeriod(String period) {
    _manager.setGlobalContext(AssistantContextManager.currentPeriod, period);
  }

  /// Get current period filter
  static String? getCurrentPeriod() {
    return _manager
        .getGlobalContext<String>(AssistantContextManager.currentPeriod);
  }

  /// Share analytics insights with other modules
  static void shareAnalyticsInsights(Map<String, dynamic> insights) {
    _manager.shareContextBetweenModules(
      'analytics',
      'budget',
      'insights',
      insights,
    );
    _manager.shareContextBetweenModules(
      'analytics',
      'reports',
      'insights',
      insights,
    );
  }
}
