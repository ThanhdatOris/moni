import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../../../models/report_model.dart';
import '../../../services/ai_processor_service.dart';
import '../../../services/report_service.dart';
import '../models/agent_request_model.dart';
import '../models/agent_response_model.dart';
import 'assistant_context_manager.dart';

/// Global Agent API - Central hub for all Assistant modules
/// This service coordinates between different AI-powered features
class GlobalAgentService {
  final GetIt _getIt = GetIt.instance;
  final Logger _logger = Logger();
  final AssistantContextManager _contextManager = AssistantContextManager();
  
  // Core services
  late final AIProcessorService _aiService;
  late final ReportService _reportService;
  
  // Singleton pattern
  static final GlobalAgentService _instance = GlobalAgentService._internal();
  factory GlobalAgentService() => _instance;
  GlobalAgentService._internal();
  
  /// Initialize the service and register dependencies
  Future<void> initialize() async {
    try {
      _aiService = _getIt<AIProcessorService>();
      _reportService = _getIt<ReportService>();
      
      _logger.i('GlobalAgentService initialized successfully');
    } catch (e) {
      _logger.e('Error initializing GlobalAgentService: $e');
      rethrow;
    }
  }

  /// Get context manager for cross-module features
  AssistantContextManager get contextManager => _contextManager;

  /// Get context summary for debugging
  Map<String, dynamic> getContextSummary() => _contextManager.getContextSummary();
  
  /// Process a request from any Assistant module
  Future<AgentResponse> processRequest(AgentRequest request) async {
    try {
      _logger.d('Processing agent request: ${request.type}');
      
      // Get relevant context for this request type
      final context = await _contextManager.getContextForRequest(request.type);
      _logger.d('Context available: ${context.keys}');
      
      switch (request.type) {
        case AgentRequestType.chat:
          return await _processChatRequest(request);
          
        case AgentRequestType.analytics:
          return await _processAnalyticsRequest(request);
          
        case AgentRequestType.budget:
          return await _processBudgetRequest(request);
          
        case AgentRequestType.report:
          return await _processReportRequest(request);
      }
    } catch (e) {
      _logger.e('Error processing agent request: $e');
      return AgentResponse.error('Đã có lỗi xảy ra khi xử lý yêu cầu: $e');
    }
  }
  
  /// Process chat/conversational requests
  Future<AgentResponse> _processChatRequest(AgentRequest request) async {
    try {
      final response = await _aiService.processChatInput(request.message);
      return AgentResponse.success(
        message: response,
        type: AgentResponseType.text,
      );
    } catch (e) {
      _logger.e('Error processing chat request: $e');
      return AgentResponse.error('Không thể xử lý tin nhắn chat');
    }
  }
  
  /// Process analytics requests
  Future<AgentResponse> _processAnalyticsRequest(AgentRequest request) async {
    try {
      // This will be implemented when analytics module is added
      // For now, delegate to AI service for text-based analytics
      final analyticsPrompt = _buildAnalyticsPrompt(request.message, request.parameters);
      final response = await _aiService.processChatInput(analyticsPrompt);
      
      return AgentResponse.success(
        message: response,
        type: AgentResponseType.analytics,
        data: {
          'analysis_type': 'spending_pattern',
          'period': request.parameters?['period'] ?? 'month',
        },
      );
    } catch (e) {
      _logger.e('Error processing analytics request: $e');
      return AgentResponse.error('Không thể thực hiện phân tích dữ liệu');
    }
  }
  
  /// Process budget-related requests
  Future<AgentResponse> _processBudgetRequest(AgentRequest request) async {
    try {
      // This will be implemented when budget AI module is added
      final budgetPrompt = _buildBudgetPrompt(request.message, request.parameters);
      final response = await _aiService.processChatInput(budgetPrompt);
      
      return AgentResponse.success(
        message: response,
        type: AgentResponseType.budget,
        data: {
          'suggestion_type': 'budget_optimization',
          'categories': request.parameters?['categories'] ?? [],
        },
      );
    } catch (e) {
      _logger.e('Error processing budget request: $e');
      return AgentResponse.error('Không thể tạo gợi ý ngân sách');
    }
  }
  
  /// Process report generation requests
  Future<AgentResponse> _processReportRequest(AgentRequest request) async {
    try {
      // Delegate to report service
      final reportType = request.parameters?['type'] ?? 'byTime';
      final timePeriod = request.parameters?['timePeriod'] ?? 'thisMonth';
      
      // Convert string types to enums with proper type safety
      final reportTypeEnum = _parseReportType(reportType);
      final timePeriodEnum = _parseTimePeriod(timePeriod);
      
      final reportUrl = await _reportService.generateReport(
        type: reportTypeEnum,
        timePeriod: timePeriodEnum,
      );

      return AgentResponse.success(
        message: 'Báo cáo đã được tạo thành công',
        type: AgentResponseType.report,
        data: {
          'report_url': reportUrl,
          'report_type': reportType,
          'time_period': timePeriod,
        },
      );
    } catch (e) {
      _logger.e('Error processing report request: $e');
      return AgentResponse.error('Không thể tạo báo cáo');
    }
  }

  /// Parse report type string to enum with validation
  ReportType _parseReportType(String reportType) {
    try {
      // Try using the model's fromString method first
      return ReportType.fromString(reportType);
    } catch (e) {
      // Fallback: try matching by name
      final lowerType = reportType.toLowerCase();
      switch (lowerType) {
        case 'bytime':
        case 'by_time':
        case 'time':
          return ReportType.byTime;
        case 'bycategory':
        case 'by_category':
        case 'category':
          return ReportType.byCategory;
        default:
          _logger.w('Unknown report type: $reportType, using default byTime');
          return ReportType.byTime;
      }
    }
  }

  /// Parse time period string to enum with validation
  TimePeriod _parseTimePeriod(String timePeriod) {
    try {
      // Try using the model's fromString method first
      return TimePeriod.fromString(timePeriod);
    } catch (e) {
      // Fallback: try matching by name and common variations
      final lowerPeriod = timePeriod.toLowerCase();
      switch (lowerPeriod) {
        case 'monthly':
        case 'month':
        case 'thismonth':
        case 'this_month':
          return TimePeriod.monthly;
        case 'quarterly':
        case 'quarter':
        case 'thisquarter':
        case 'this_quarter':
          return TimePeriod.quarterly;
        case 'yearly':
        case 'year':
        case 'thisyear':
        case 'this_year':
          return TimePeriod.yearly;
        default:
          _logger.w('Unknown time period: $timePeriod, using default monthly');
          return TimePeriod.monthly;
      }
    }
  }  /// Build specialized prompt for analytics requests
  String _buildAnalyticsPrompt(String userMessage, Map<String, dynamic>? parameters) {
    final period = parameters?['period'] ?? 'tháng này';
    final categories = parameters?['categories']?.join(', ') ?? 'tất cả danh mục';
    
    return '''
Người dùng yêu cầu phân tích dữ liệu: $userMessage

Thông tin bổ sung:
- Thời gian: $period
- Danh mục: $categories

Hãy cung cấp phân tích chi tiêu chi tiết và đưa ra những insight hữu ích về tình hình tài chính.
''';
  }
  
  /// Build specialized prompt for budget requests
  String _buildBudgetPrompt(String userMessage, Map<String, dynamic>? parameters) {
    final income = parameters?['income']?.toString() ?? 'chưa cung cấp';
    final goals = parameters?['goals']?.join(', ') ?? 'không có mục tiêu cụ thể';
    
    return '''
Người dùng yêu cầu tư vấn ngân sách: $userMessage

Thông tin bổ sung:
- Thu nhập: $income
- Mục tiêu tài chính: $goals

Hãy đưa ra gợi ý ngân sách thông minh và phù hợp với tình hình tài chính của người dùng.
''';
  }
  
  /// Check if a specific module is available
  bool isModuleAvailable(String moduleName) {
    switch (moduleName.toLowerCase()) {
      case 'chat':
      case 'chatbot':
        return true;
      case 'analytics':
        return true; // Basic analytics via AI service
      case 'budget':
        return true; // Basic budget advice via AI service  
      case 'report':
        return _getIt.isRegistered<ReportService>();
      default:
        return false;
    }
  }
  
  /// Get list of available modules
  List<String> getAvailableModules() {
    return [
      'chat',
      'analytics',
      'budget',
      if (_getIt.isRegistered<ReportService>()) 'report',
    ];
  }
}
