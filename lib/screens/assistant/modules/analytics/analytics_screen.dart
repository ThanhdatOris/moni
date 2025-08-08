import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../constants/app_colors.dart';
import '../../../../widgets/charts/models/chart_data_model.dart';
import '../../../assistant/models/agent_request_model.dart';
import '../../../assistant/services/global_agent_service.dart';
import '../../../assistant/services/real_data_service.dart';
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

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  final GlobalAgentService _agentService = GetIt.instance<GlobalAgentService>();
  final RealDataService _realDataService = GetIt.instance<RealDataService>();
  late TabController _tabController;

  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String? _aiInsight;
  List<String> _recommendations = [];

  // Financial data từ real data service
  AnalyticsData? _analyticsData;

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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Load real analytics data (service already initialized via DI)
      _analyticsData = await _realDataService.getAnalyticsData();

      // Update UI state with real data
      if (!mounted) return;
      setState(() {
        _categoryData = _analyticsData?.categoryData ?? [];
        _trendData = _analyticsData?.trendData ?? [];
        _recommendations = _analyticsData?.insights ?? [];
      });

      // Generate AI insights với real data context
      await _generateAIInsights();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'Lỗi tải dữ liệu: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  Future<void> _generateAIInsights() async {
    if (_analyticsData == null) return;

    try {
      final request = AgentRequest.analytics(
        message:
            'Phân tích chi tiêu tháng này và đưa ra những insight quan trọng',
        parameters: {
          'period': _analyticsData!.period,
          'analysis_type': 'comprehensive',
          'total_income': _analyticsData!.totalIncome,
          'total_expense': _analyticsData!.totalExpense,
          'balance': _analyticsData!.balance,
          'transaction_count': _analyticsData!.transactionCount,
          'top_categories': _analyticsData!.categoryData
              .take(3)
              .map((c) => {
                    'name': c.category,
                    'amount': c.amount,
                    'percentage': c.percentage,
                  })
              .toList(),
        },
      );

      final response = await _agentService.processRequest(request);

      if (!mounted) return;
      if (response.isSuccess) {
        setState(() {
          _aiInsight = response.message;
        });
      } else {
        // Fallback to basic insights from real data
        setState(() {
          _aiInsight = _generateBasicInsight();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiInsight = _generateBasicInsight();
      });
    }
  }

  String _generateBasicInsight() {
    if (_analyticsData == null) return 'Chưa có dữ liệu để phân tích.';

    final data = _analyticsData!;
    final savingsRate = data.totalIncome > 0
        ? ((data.totalIncome - data.totalExpense) / data.totalIncome) * 100
        : 0;

    String insight = 'Phân tích tài chính ${data.period}:\n\n';
    insight += '💰 Thu nhập: ${_formatCurrency(data.totalIncome)}\n';
    insight += '💸 Chi tiêu: ${_formatCurrency(data.totalExpense)}\n';
    insight += '💵 Số dư: ${_formatCurrency(data.balance)}\n';
    insight += '📊 Số giao dịch: ${data.transactionCount}\n\n';

    if (savingsRate > 20) {
      insight +=
          '🎉 Tuyệt vời! Tỷ lệ tiết kiệm ${savingsRate.toStringAsFixed(1)}% rất tốt.';
    } else if (savingsRate > 0) {
      insight +=
          '👍 Tỷ lệ tiết kiệm ${savingsRate.toStringAsFixed(1)}% - có thể cải thiện thêm.';
    } else {
      insight +=
          '⚠️ Cảnh báo: Chi tiêu vượt thu nhập. Cần xem xét lại ngân sách.';
    }

    return insight;
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ';
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
            labelStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600), // Giảm từ 12 xuống 10
            unselectedLabelStyle:
                const TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
            dividerColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            tabs: const [
              Tab(
                height: 32, // Giảm từ 40 xuống 32
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.dashboard_outlined,
                        size: 14), // Giảm size từ 16 xuống 14
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
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Financial Summary từ real data
              AnalyticsSummaryCard(
                totalIncome: _analyticsData?.totalIncome ?? 0,
                totalExpense: _analyticsData?.totalExpense ?? 0,
                balance: _analyticsData?.balance ?? 0,
                transactionCount: _analyticsData?.transactionCount ?? 0,
              ),

              const SizedBox(height: 16),

              // Quick Actions
              AnalyticsQuickActions(
                onExportReport: _exportReport,
                onSetBudgetAlert: _setBudgetAlert,
                onViewDetailedReport: _viewDetailedReport,
                onShareInsights: _shareInsights,
              ),

              // Bottom spacing for menubar
              const SizedBox(height: 120),
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
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AnalyticsChartSection(
                categoryData: _categoryData,
                trendData: _trendData,
                onRefresh: _refreshData,
              ),
              // Bottom spacing for menubar
              const SizedBox(height: 120),
            ],
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
          child: Column(
            children: [
              AnalyticsInsightCard(
                insight: _aiInsight,
                recommendations: _recommendations,
                onRegenerateInsight: _generateAIInsights,
              ),
              // Bottom spacing for menubar
              const SizedBox(height: 120),
            ],
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
