import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../constants/app_colors.dart';
import '../../../../widgets/charts/models/chart_data_model.dart';
import '../../../assistant/models/agent_request_model.dart';
import '../../../assistant/services/global_agent_service.dart';
import '../../widgets/assistant_error_card.dart';
import '../../widgets/assistant_loading_card.dart';
import 'widgets/analytics_chart_section.dart';
import 'widgets/analytics_insight_card.dart';
import 'widgets/analytics_quick_actions.dart';
import 'widgets/analytics_summary_card.dart';

/// Enhanced Analytics Module Screen with modern UI components
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with TickerProviderStateMixin {
  final GlobalAgentService _agentService = GetIt.instance<GlobalAgentService>();
  late TabController _tabController;
  
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String? _aiInsight;
  List<String> _recommendations = [];
  
  // Financial data
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;
  int _transactionCount = 0;
  
  // Chart data
  List<ChartDataModel> _categoryData = [];
  List<ChartDataModel> _trendData = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });
    
    try {
      // Load financial summary
      await _loadFinancialSummary();
      
      // Load chart data
      await _loadChartData();
      
      // Generate AI insights
      await _generateAIInsights();
      
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Lỗi tải dữ liệu: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFinancialSummary() async {
    // TODO: Replace with actual data from analytics coordinator
    // For now, using mock data
    setState(() {
      _totalIncome = 15000000; // 15M VND
      _totalExpense = 12000000; // 12M VND  
      _balance = _totalIncome - _totalExpense;
      _transactionCount = 45;
    });
  }

  Future<void> _loadChartData() async {
    // TODO: Replace with actual data from analytics coordinator
    // Mock category data
    setState(() {
      _categoryData = [
        ChartDataModel(
          category: 'Ăn uống',
          amount: 4000000,
          percentage: 33.3,
          icon: '🍽️',
          color: '#FF9800',
          type: 'expense',
        ),
        ChartDataModel(
          category: 'Di chuyển',
          amount: 2500000,
          percentage: 20.8,
          icon: '🚗',
          color: '#2196F3',
          type: 'expense',
        ),
        ChartDataModel(
          category: 'Mua sắm',
          amount: 3000000,
          percentage: 25.0,
          icon: '🛍️',
          color: '#E91E63',
          type: 'expense',
        ),
        ChartDataModel(
          category: 'Lương',
          amount: 15000000,
          percentage: 100.0,
          icon: '💰',
          color: '#4CAF50',
          type: 'income',
        ),
      ];
      
      _trendData = [
        ChartDataModel(
          category: 'Tuần 1',
          amount: 3000000,
          percentage: 25.0,
          icon: '',
          color: '#FF9800',
          type: 'expense',
        ),
        ChartDataModel(
          category: 'Tuần 2',
          amount: 2800000,
          percentage: 23.3,
          icon: '',
          color: '#FF9800',
          type: 'expense',
        ),
        ChartDataModel(
          category: 'Tuần 3',
          amount: 3200000,
          percentage: 26.7,
          icon: '',
          color: '#FF9800',
          type: 'expense',
        ),
        ChartDataModel(
          category: 'Tuần 4',
          amount: 3000000,
          percentage: 25.0,
          icon: '',
          color: '#FF9800',
          type: 'expense',
        ),
      ];
    });
  }

  Future<void> _generateAIInsights() async {
    try {
      final request = AgentRequest.analytics(
        message: 'Phân tích chi tiêu tháng này và đưa ra những insight quan trọng',
        parameters: {
          'period': 'month',
          'analysis_type': 'comprehensive',
          'total_income': _totalIncome,
          'total_expense': _totalExpense,
        },
      );
      
      final response = await _agentService.processRequest(request);
      
      if (response.isSuccess) {
        setState(() {
          _aiInsight = response.message;
          _recommendations = [
            'Giảm chi tiêu ăn uống xuống 25% tổng thu nhập',
            'Tăng tiết kiệm lên 20% mỗi tháng',
            'Xem xét chuyển đổi phương tiện di chuyển tiết kiệm hơn',
          ];
        });
      }
    } catch (e) {
      // AI insight generation failed, continue with other data
      setState(() {
        _aiInsight = 'Không thể tạo insight AI lúc này. Vui lòng thử lại sau.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Consistent tab bar matching other modules
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(11), // Giảm từ 12 xuống 11
              color: Colors.blue, // Solid xanh dương thay vì gradient primary
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3), // Đổi màu shadow
                  blurRadius: 4, // Giảm từ 6 xuống 4
                  offset: const Offset(0, 1), // Giảm từ 2 xuống 1
                ),
              ],
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), // Giảm từ 12 xuống 10
            unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
            dividerColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            tabs: const [
              Tab(
                height: 32, // Giảm từ 40 xuống 32
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.dashboard_outlined, size: 14), // Giảm size từ 16 xuống 14
                    SizedBox(width: 4), // Giảm từ 6 xuống 4
                    Text('Tổng quan'),
                  ],
                ),
              ),
              Tab(
                height: 40,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart, size: 14),
                    SizedBox(width: 4),
                    Text('Biểu đồ'),
                  ],
                ),
              ),
              Tab(
                height: 40,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.psychology, size: 14),
                    SizedBox(width: 4),
                    Text('AI Insights'),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Content
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: AssistantLoadingCard(
          showTitle: true,
        ),
      );
    }

    if (_hasError) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: AssistantErrorCard(
          errorMessage: _errorMessage ?? 'Có lỗi xảy ra khi tải dữ liệu',
          onRetry: _loadData,
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildChartsTab(),
        _buildInsightsTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return Container(
      color: AppColors.background,
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Financial Summary
              AnalyticsSummaryCard(
                totalIncome: _totalIncome,
                totalExpense: _totalExpense,
                balance: _balance,
                transactionCount: _transactionCount,
              ),
              
              const SizedBox(height: 16),
              
              // Quick Actions
              AnalyticsQuickActions(
                onExportReport: _exportReport,
                onSetBudgetAlert: _setBudgetAlert,
                onViewDetailedReport: _viewDetailedReport,
                onShareInsights: _shareInsights,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartsTab() {
    return Container(
      color: AppColors.background,
      child: RefreshIndicator(
        onRefresh: _loadChartData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: AnalyticsChartSection(
            categoryData: _categoryData,
            trendData: _trendData,
            onRefresh: _loadChartData,
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsTab() {
    return Container(
      color: AppColors.background,
      child: RefreshIndicator(
        onRefresh: _generateAIInsights,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: AnalyticsInsightCard(
            insight: _aiInsight,
            recommendations: _recommendations,
            onRegenerateInsight: _generateAIInsights,
          ),
        ),
      ),
    );
  }

  // Action handlers
  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang xuất báo cáo...')),
    );
  }

  void _setBudgetAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thiết lập cảnh báo ngân sách...')),
    );
  }

  void _viewDetailedReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang tải báo cáo chi tiết...')),
    );
  }

  void _shareInsights() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang chia sẻ insights...')),
    );
  }
}
