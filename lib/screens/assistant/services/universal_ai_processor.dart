import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../models/agent_request_model.dart';
import 'assistant_context_manager.dart';
import 'global_agent_service.dart';

/// Universal AI Processing Pipeline for seamless cross-module AI integration
class UniversalAIProcessor {
  static final UniversalAIProcessor _instance = UniversalAIProcessor._internal();
  factory UniversalAIProcessor() => _instance;
  UniversalAIProcessor._internal();

  final Logger _logger = Logger();
  final GlobalAgentService _agentService = GetIt.instance<GlobalAgentService>();
  final AssistantContextManager _contextManager = AssistantContextManager();

  // Processing state
  bool _isProcessing = false;
  final Map<String, StreamController<AIProcessingResult>> _moduleStreams = {};
  final List<String> _processingQueue = [];

  /// Process AI request with universal context awareness
  Future<AIProcessingResult> processRequest({
    required String moduleId,
    required AgentRequestType requestType,
    required String query,
    Map<String, dynamic>? additionalContext,
  }) async {
    if (_isProcessing) {
      _logger.w('AI processor busy, queuing request for module: $moduleId');
      return _queueRequest(moduleId, requestType, query, additionalContext);
    }

    _isProcessing = true;
    _logger.i('Processing AI request for module: $moduleId');

    try {
      // 1. Gather comprehensive context
      final context = await _gatherContext(moduleId, additionalContext);
      
      // 2. Enhance query with cross-module insights
      final enhancedQuery = _enhanceQueryWithContext(query, context, moduleId);
      
      // 3. Create agent request
      final request = AgentRequest(
        type: requestType,
        message: enhancedQuery,
        parameters: context,
      );

      // 4. Process with AI service
      final response = await _agentService.processRequest(request);
      
      // 5. Extract and share insights across modules
      await _shareInsightsAcrossModules(moduleId, response.message, context);
      
      // 6. Create result
      final result = AIProcessingResult(
        moduleId: moduleId,
        requestType: requestType,
        originalQuery: query,
        enhancedQuery: enhancedQuery,
        response: response.message,
        context: context,
        insights: _extractInsights(response.message),
        confidence: _calculateConfidence(response.message, context),
        timestamp: DateTime.now(),
      );

      // 7. Notify subscribers
      _notifyModuleSubscribers(moduleId, result);

      return result;

    } catch (e) {
      _logger.e('AI processing error for module $moduleId: $e');
      return AIProcessingResult.error(moduleId, requestType, query, e.toString());
    } finally {
      _isProcessing = false;
      _processNextInQueue();
    }
  }

  /// Subscribe to AI processing results for a module
  Stream<AIProcessingResult> subscribeToModule(String moduleId) {
    _moduleStreams.putIfAbsent(
      moduleId, 
      () => StreamController<AIProcessingResult>.broadcast(),
    );
    return _moduleStreams[moduleId]!.stream;
  }

  /// Process batch requests for multiple modules
  Future<Map<String, AIProcessingResult>> processBatchRequests(
    List<BatchRequest> requests,
  ) async {
    final results = <String, AIProcessingResult>{};
    
    // Process in priority order
    requests.sort((a, b) => b.priority.compareTo(a.priority));
    
    for (final request in requests) {
      try {
        final result = await processRequest(
          moduleId: request.moduleId,
          requestType: request.requestType,
          query: request.query,
          additionalContext: request.additionalContext,
        );
        results[request.moduleId] = result;
      } catch (e) {
        results[request.moduleId] = AIProcessingResult.error(
          request.moduleId,
          request.requestType,
          request.query,
          e.toString(),
        );
      }
    }
    
    return results;
  }

  /// Get processing status
  ProcessingStatus getProcessingStatus() {
    return ProcessingStatus(
      isProcessing: _isProcessing,
      queueLength: _processingQueue.length,
      activeModules: _moduleStreams.keys.toList(),
      lastProcessingTime: DateTime.now(),
    );
  }

  Future<Map<String, dynamic>> _gatherContext(
    String moduleId, 
    Map<String, dynamic>? additionalContext,
  ) async {
    // Get full context from context manager
    final fullContext = await _contextManager.getFullContext();
    
    // Get module-specific context
    final moduleContext = _contextManager.getAllModuleContext(moduleId);
    
    // Merge with additional context
    final context = <String, dynamic>{
      'full_context': fullContext,
      'module_context': moduleContext,
      'module_id': moduleId,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (additionalContext != null) {
      context['additional'] = additionalContext;
    }
    
    // Add cross-module insights
    context['cross_module_insights'] = await _getCrossModuleInsights(moduleId);
    
    return context;
  }

  String _enhanceQueryWithContext(
    String originalQuery,
    Map<String, dynamic> context,
    String moduleId,
  ) {
    final insights = context['cross_module_insights'] as Map<String, dynamic>? ?? {};
    final moduleContext = context['module_context'] as Map<String, dynamic>? ?? {};
    
    final enhancement = StringBuffer();
    enhancement.write(originalQuery);
    
    // Add context-aware enhancements
    if (insights.isNotEmpty) {
      enhancement.write('\n\nLưu ý từ các module khác: ');
      insights.forEach((key, value) {
        enhancement.write('$key: $value. ');
      });
    }
    
    // Add module-specific context
    if (moduleContext.isNotEmpty) {
      enhancement.write('\n\nThông tin hiện tại của module: ');
      moduleContext.forEach((key, value) {
        if (value is! Map && value is! List) {
          enhancement.write('$key: $value. ');
        }
      });
    }
    
    return enhancement.toString();
  }

  Future<Map<String, dynamic>> _getCrossModuleInsights(String currentModule) async {
    final insights = <String, dynamic>{};
    
    switch (currentModule) {
      case 'analytics':
        // Get insights from budget and reports
        final budgetData = _contextManager.getModuleContext('budget', 'shared_from_analytics');
        final reportsData = _contextManager.getModuleContext('reports', 'shared_from_analytics');
        if (budgetData != null) insights['budget_insights'] = budgetData;
        if (reportsData != null) insights['reports_insights'] = reportsData;
        break;
        
      case 'budget':
        // Get insights from analytics and reports
        final analyticsData = _contextManager.getModuleContext('analytics', 'financial_health');
        final reportsData = _contextManager.getModuleContext('reports', 'budget_template');
        if (analyticsData != null) insights['analytics_insights'] = analyticsData;
        if (reportsData != null) insights['reports_insights'] = reportsData;
        break;
        
      case 'reports':
        // Get insights from analytics and budget
        final analyticsData = _contextManager.getModuleContext('analytics', 'spending_summary');
        final budgetData = _contextManager.getModuleContext('budget', 'recommendations');
        if (analyticsData != null) insights['analytics_insights'] = analyticsData;
        if (budgetData != null) insights['budget_insights'] = budgetData;
        break;
    }
    
    return insights;
  }

  Future<void> _shareInsightsAcrossModules(
    String sourceModule,
    String response,
    Map<String, dynamic> context,
  ) async {
    final insights = _extractInsights(response);
    
    // Share with other modules based on source
    switch (sourceModule) {
      case 'analytics':
        _contextManager.shareContextBetweenModules(
          'analytics', 'budget', 'latest_insights', insights,
        );
        _contextManager.shareContextBetweenModules(
          'analytics', 'reports', 'latest_insights', insights,
        );
        break;
        
      case 'budget':
        _contextManager.shareContextBetweenModules(
          'budget', 'analytics', 'budget_updates', insights,
        );
        _contextManager.shareContextBetweenModules(
          'budget', 'reports', 'budget_updates', insights,
        );
        break;
        
      case 'reports':
        _contextManager.shareContextBetweenModules(
          'reports', 'analytics', 'report_insights', insights,
        );
        _contextManager.shareContextBetweenModules(
          'reports', 'budget', 'report_insights', insights,
        );
        break;
    }
  }

  Map<String, dynamic> _extractInsights(String response) {
    // Simple insight extraction - could be enhanced with NLP
    final insights = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'response_length': response.length,
      'has_recommendations': response.contains('khuyến nghị') || response.contains('gợi ý'),
      'has_warnings': response.contains('cảnh báo') || response.contains('lưu ý'),
      'confidence_indicators': [],
    };
    
    // Extract specific patterns
    if (response.contains('tăng') || response.contains('giảm')) {
      insights['trend_detected'] = true;
    }
    
    if (response.contains('%') || response.contains('phần trăm')) {
      insights['contains_percentages'] = true;
    }
    
    return insights;
  }

  double _calculateConfidence(String response, Map<String, dynamic> context) {
    double confidence = 0.5; // Base confidence
    
    // Increase confidence based on context availability
    if (context['full_context'] != null) confidence += 0.2;
    if (context['cross_module_insights'] != null) confidence += 0.1;
    if (context['module_context'] != null) confidence += 0.1;
    
    // Increase based on response quality
    if (response.length > 100) confidence += 0.1;
    if (response.contains('khuyến nghị') || response.contains('gợi ý')) confidence += 0.1;
    
    return confidence.clamp(0.0, 1.0);
  }

  void _notifyModuleSubscribers(String moduleId, AIProcessingResult result) {
    if (_moduleStreams.containsKey(moduleId)) {
      _moduleStreams[moduleId]!.add(result);
    }
  }

  Future<AIProcessingResult> _queueRequest(
    String moduleId,
    AgentRequestType requestType,
    String query,
    Map<String, dynamic>? additionalContext,
  ) async {
    _processingQueue.add(moduleId);
    
    // Wait for processing to complete
    final completer = Completer<AIProcessingResult>();
    
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isProcessing && _processingQueue.first == moduleId) {
        timer.cancel();
        processRequest(
          moduleId: moduleId,
          requestType: requestType,
          query: query,
          additionalContext: additionalContext,
        ).then((result) => completer.complete(result));
      }
    });
    
    return completer.future;
  }

  void _processNextInQueue() {
    if (_processingQueue.isNotEmpty) {
      _processingQueue.removeAt(0);
    }
  }

  /// Dispose resources
  void dispose() {
    for (final controller in _moduleStreams.values) {
      controller.close();
    }
    _moduleStreams.clear();
    _processingQueue.clear();
  }
}

/// AI Processing Result model
class AIProcessingResult {
  final String moduleId;
  final AgentRequestType requestType;
  final String originalQuery;
  final String enhancedQuery;
  final String response;
  final Map<String, dynamic> context;
  final Map<String, dynamic> insights;
  final double confidence;
  final DateTime timestamp;
  final bool isError;
  final String? errorMessage;

  AIProcessingResult({
    required this.moduleId,
    required this.requestType,
    required this.originalQuery,
    required this.enhancedQuery,
    required this.response,
    required this.context,
    required this.insights,
    required this.confidence,
    required this.timestamp,
    this.isError = false,
    this.errorMessage,
  });

  factory AIProcessingResult.error(
    String moduleId,
    AgentRequestType requestType,
    String query,
    String error,
  ) {
    return AIProcessingResult(
      moduleId: moduleId,
      requestType: requestType,
      originalQuery: query,
      enhancedQuery: query,
      response: 'Đã xảy ra lỗi khi xử lý yêu cầu',
      context: {},
      insights: {},
      confidence: 0.0,
      timestamp: DateTime.now(),
      isError: true,
      errorMessage: error,
    );
  }
}

/// Batch request model
class BatchRequest {
  final String moduleId;
  final AgentRequestType requestType;
  final String query;
  final Map<String, dynamic>? additionalContext;
  final int priority;

  BatchRequest({
    required this.moduleId,
    required this.requestType,
    required this.query,
    this.additionalContext,
    this.priority = 0,
  });
}

/// Processing status model
class ProcessingStatus {
  final bool isProcessing;
  final int queueLength;
  final List<String> activeModules;
  final DateTime lastProcessingTime;

  ProcessingStatus({
    required this.isProcessing,
    required this.queueLength,
    required this.activeModules,
    required this.lastProcessingTime,
  });
}
