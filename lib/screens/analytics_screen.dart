import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart' as pie;

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/enums.dart';
import '../utils/currency_formatter.dart';
import '../widgets/charts/components/chart_insights.dart';
import '../widgets/charts/core/chart_theme.dart';
import '../widgets/charts/models/chart_config_models.dart';
import '../widgets/charts/models/chart_data_models.dart';
import '../widgets/charts/types/category_analysis_chart.dart';
import '../widgets/charts/types/income_expense_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'Tháng này';
  final List<String> _periods = ['Tuần này', 'Tháng này', 'Quý này', 'Năm nay'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        // Force rebuild when tab changes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.analytics),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Tổng quan'),
            Tab(text: 'Biểu đồ'),
            Tab(text: 'Báo cáo'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildChartsTab(),
                _buildReportsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.date_range, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPeriod,
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                    // Trigger rebuild for all tabs
                    _rebuildAllTabs();
                  });
                },
                items: _periods.map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(
                      period,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _rebuildAllTabs() {
    // Force rebuild of all tabs when period changes
    setState(() {
      // This will trigger rebuild of all tabs
    });
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildQuickStats(),
          const SizedBox(height: 24),
          _buildRecentTrends(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Tổng thu',
            '15.000.000đ',
            Icons.trending_up,
            AppColors.income,
            '+12%',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Tổng chi',
            '8.500.000đ',
            Icons.trending_down,
            AppColors.expense,
            '+5%',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    IconData icon,
    Color color,
    String change,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê nhanh',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickStatItem(
              'Số dư hiện tại', '6.500.000đ', AppColors.primary),
          _buildQuickStatItem(
              'Giao dịch trong ngày', '3 giao dịch', AppColors.info),
          _buildQuickStatItem('Chi nhiều nhất', 'Ăn uống', AppColors.food),
          _buildQuickStatItem(
              'Mục tiêu tiết kiệm', '65% đạt được', AppColors.success),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTrends() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xu hướng gần đây',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(_buildTrendChart()),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsTab() {
    final chartTheme = Theme.of(context).brightness == Brightness.dark
        ? ChartTheme.dark()
        : ChartTheme.light();

    return ChartThemeProvider(
      theme: chartTheme,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildIncomeExpenseChart(),
            const SizedBox(height: 24),
            _buildCategoryAnalysisChart(),
            const SizedBox(height: 24),
            _buildChartInsights(),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeExpenseChart() {
    final config = CompleteChartConfig(
      chart: ChartConfiguration(
        title: 'Thu chi theo thời gian',
        type: ChartType.bar,
        timePeriod: _getTimePeriodFromString(_selectedPeriod),
        showLegend: true,
        isInteractive: true,
        animationType: ChartAnimationType.fade,
        animationDuration: const Duration(milliseconds: 800),
      ),
      filter: ChartFilterConfig(
        startDate: _getStartDateFromPeriod(_selectedPeriod),
        endDate: DateTime.now(),
        includeIncome: true,
        includeExpense: true,
      ),
      legend: const ChartLegendConfig(
        show: true,
        position: LegendPosition.bottom,
        maxColumns: 2,
      ),
      tooltip: const ChartTooltipConfig(
        enabled: true,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
      ),
      style: ChartStyleConfig(
        backgroundColor: Colors.transparent,
        colorPalette: [
          AppColors.income,
          AppColors.expense,
          AppColors.food,
          AppColors.transport,
          AppColors.shopping,
          AppColors.entertainment,
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thu chi theo thời gian',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: IncomeExpenseChart(
              config: config,
              showComparison: true,
              showTrends: true,
              onDataPointTap: (dataPoint) {
                _showDataPointDetails(dataPoint);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAnalysisChart() {
    final config = CompleteChartConfig(
      chart: ChartConfiguration(
        title: 'Phân tích danh mục',
        type: ChartType.pie,
        timePeriod: _getTimePeriodFromString(_selectedPeriod),
        showLegend: true,
        isInteractive: true,
        animationType: ChartAnimationType.fade,
        animationDuration: const Duration(milliseconds: 800),
      ),
      filter: ChartFilterConfig(
        startDate: _getStartDateFromPeriod(_selectedPeriod),
        endDate: DateTime.now(),
        includeIncome: false,
        includeExpense: true,
      ),
      legend: const ChartLegendConfig(
        show: true,
        position: LegendPosition.right,
        maxColumns: 1,
      ),
      tooltip: const ChartTooltipConfig(
        enabled: true,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
      ),
      style: ChartStyleConfig(
        backgroundColor: Colors.transparent,
        colorPalette: [
          AppColors.food,
          AppColors.transport,
          AppColors.shopping,
          AppColors.entertainment,
          AppColors.bills,
          AppColors.health,
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân bố chi tiêu theo danh mục',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: CategoryAnalysisChart(
              config: config,
              showPieChart: true,
              showBarChart: true,
              showTrends: false,
              onCategoryTap: (category) {
                _showCategoryDetails(category);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartInsights() {
    // Mock insights data - trong thực tế sẽ lấy từ AI service
    final insights = [
      ChartInsight(
        title: 'Chi tiêu tăng cao',
        description:
            'Chi tiêu tháng này tăng 15% so với tháng trước. Cần kiểm soát chi tiêu tốt hơn.',
        type: InsightType.warning,
        priority: 0.8,
        generated: DateTime.now(),
      ),
      ChartInsight(
        title: 'Tiết kiệm tốt',
        description:
            'Bạn đã tiết kiệm được 25% thu nhập. Hãy duy trì thói quen này!',
        type: InsightType.positive,
        priority: 0.9,
        generated: DateTime.now(),
      ),
    ];

    return ChartInsights(
      insights: insights,
      showTrends: true,
      showRecommendations: true,
      onInsightTap: (insight) {
        _showInsightDetails(insight);
      },
    );
  }

  Widget _buildExpensePieChart() {
    final dataMap = <String, double>{
      'Ăn uống': 35,
      'Di chuyển': 20,
      'Mua sắm': 15,
      'Giải trí': 12,
      'Hóa đơn': 10,
      'Khác': 8,
    };

    final colorList = [
      AppColors.food,
      AppColors.transport,
      AppColors.shopping,
      AppColors.entertainment,
      AppColors.bills,
      AppColors.grey500,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân bố chi tiêu theo danh mục',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          pie.PieChart(
            dataMap: dataMap,
            animationDuration: const Duration(milliseconds: 800),
            chartLegendSpacing: 32,
            chartRadius: MediaQuery.of(context).size.width / 3,
            colorList: colorList,
            initialAngleInDegree: 0,
            chartType: pie.ChartType.ring,
            ringStrokeWidth: 32,
            centerText: "CHI TIÊU",
            legendOptions: const pie.LegendOptions(
              showLegendsInRow: false,
              legendPosition: pie.LegendPosition.right,
              showLegends: true,
              legendShape: BoxShape.circle,
              legendTextStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
            chartValuesOptions: const pie.ChartValuesOptions(
              showChartValueBackground: true,
              showChartValues: true,
              showChartValuesInPercentage: true,
              showChartValuesOutside: false,
              decimalPlaces: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBarChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thu chi theo tháng',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: BarChart(_buildMonthlyChart()),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryComparison() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'So sánh danh mục',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildCategoryComparisonItem(
              'Ăn uống', 2500000, 3000000, AppColors.food),
          _buildCategoryComparisonItem(
              'Di chuyển', 800000, 1000000, AppColors.transport),
          _buildCategoryComparisonItem(
              'Mua sắm', 1200000, 1500000, AppColors.shopping),
          _buildCategoryComparisonItem(
              'Giải trí', 600000, 800000, AppColors.entertainment),
        ],
      ),
    );
  }

  Widget _buildCategoryComparisonItem(
    String category,
    double current,
    double budget,
    Color color,
  ) {
    final percentage = (current / budget).clamp(0.0, 1.0);
    final isOverBudget = current > budget;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${CurrencyFormatter.formatAmountWithCurrency(current)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isOverBudget ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverBudget ? AppColors.error : color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildBudgetAlerts(),
          const SizedBox(height: 24),
          _buildFinancialInsights(),
          const SizedBox(height: 24),
          _buildSavingsGoal(),
        ],
      ),
    );
  }

  Widget _buildBudgetAlerts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                AppStrings.budgetAlert,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAlertItem(
            'Ăn uống',
            'Đã vượt ngân sách 200.000đ',
            AppColors.error,
            Icons.restaurant,
          ),
          _buildAlertItem(
            'Mua sắm',
            'Sắp đạt giới hạn ngân sách',
            AppColors.warning,
            Icons.shopping_bag,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(
      String title, String message, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialInsights() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Thông tin hữu ích',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            'Chi tiêu ăn uống tăng 15% so với tháng trước',
            'Hãy cân nhắc nấu ăn tại nhà để tiết kiệm',
            Icons.trending_up,
          ),
          _buildInsightItem(
            'Bạn đã tiết kiệm được 500.000đ trong tháng này',
            'Chúc mừng! Hãy duy trì thói quen tốt',
            Icons.savings,
          ),
          _buildInsightItem(
            'Ngày chi tiêu nhiều nhất: Thứ 7',
            'Lập kế hoạch chi tiêu cuối tuần để kiểm soát tốt hơn',
            Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsGoal() {
    const double targetAmount = 10000000;
    const double currentAmount = 6500000;
    final double progress = currentAmount / targetAmount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primaryLight.withValues(alpha: 0.1)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.savings, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Mục tiêu tiết kiệm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiến độ: ${(progress * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.grey200,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${NumberFormat('#,###').format(currentAmount)}đ / ${NumberFormat('#,###').format(targetAmount)}đ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.thumb_up, color: AppColors.success, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bạn đang trên đường đạt mục tiêu! Còn ${NumberFormat('#,###').format(targetAmount - currentAmount)}đ nữa.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildTrendChart() {
    return LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: [
            const FlSpot(0, 3),
            const FlSpot(1, 1),
            const FlSpot(2, 4),
            const FlSpot(3, 2),
            const FlSpot(4, 5),
            const FlSpot(5, 3),
            const FlSpot(6, 4),
          ],
          isCurved: true,
          color: AppColors.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  BarChartData _buildMonthlyChart() {
    return BarChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              switch (value.toInt()) {
                case 0:
                  return const Text('T1', style: TextStyle(fontSize: 10));
                case 1:
                  return const Text('T2', style: TextStyle(fontSize: 10));
                case 2:
                  return const Text('T3', style: TextStyle(fontSize: 10));
                case 3:
                  return const Text('T4', style: TextStyle(fontSize: 10));
                case 4:
                  return const Text('T5', style: TextStyle(fontSize: 10));
                case 5:
                  return const Text('T6', style: TextStyle(fontSize: 10));
                default:
                  return const Text('');
              }
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: [
        BarChartGroupData(x: 0, barRods: [
          BarChartRodData(toY: 8, color: AppColors.income, width: 20),
          BarChartRodData(toY: 5, color: AppColors.expense, width: 20),
        ]),
        BarChartGroupData(x: 1, barRods: [
          BarChartRodData(toY: 10, color: AppColors.income, width: 20),
          BarChartRodData(toY: 7, color: AppColors.expense, width: 20),
        ]),
        BarChartGroupData(x: 2, barRods: [
          BarChartRodData(toY: 12, color: AppColors.income, width: 20),
          BarChartRodData(toY: 8, color: AppColors.expense, width: 20),
        ]),
        BarChartGroupData(x: 3, barRods: [
          BarChartRodData(toY: 9, color: AppColors.income, width: 20),
          BarChartRodData(toY: 6, color: AppColors.expense, width: 20),
        ]),
        BarChartGroupData(x: 4, barRods: [
          BarChartRodData(toY: 15, color: AppColors.income, width: 20),
          BarChartRodData(toY: 9, color: AppColors.expense, width: 20),
        ]),
        BarChartGroupData(x: 5, barRods: [
          BarChartRodData(toY: 11, color: AppColors.income, width: 20),
          BarChartRodData(toY: 7, color: AppColors.expense, width: 20),
        ]),
      ],
    );
  }

  // Helper methods for chart integration
  ChartTimePeriod _getTimePeriodFromString(String period) {
    switch (period) {
      case 'Tuần này':
        return ChartTimePeriod.weekly;
      case 'Tháng này':
        return ChartTimePeriod.monthly;
      case 'Quý này':
        return ChartTimePeriod.quarterly;
      case 'Năm nay':
        return ChartTimePeriod.yearly;
      default:
        return ChartTimePeriod.monthly;
    }
  }

  DateTime _getStartDateFromPeriod(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'Tuần này':
        return now.subtract(Duration(days: now.weekday - 1));
      case 'Tháng này':
        return DateTime(now.year, now.month, 1);
      case 'Quý này':
        final quarter = ((now.month - 1) / 3).floor();
        return DateTime(now.year, quarter * 3 + 1, 1);
      case 'Năm nay':
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  void _showDataPointDetails(ChartDataPoint dataPoint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết: ${dataPoint.label}'),
        content: Text(
            'Số tiền: ${CurrencyFormatter.formatAmountWithCurrency(dataPoint.value)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showCategoryDetails(CategoryAnalysisData category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết: ${category.categoryName}'),
        content: Text(
            'Tổng chi: ${CurrencyFormatter.formatAmountWithCurrency(category.totalAmount)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showInsightDetails(ChartInsight insight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(insight.title),
        content: Text(insight.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
