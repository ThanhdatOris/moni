import 'package:flutter/material.dart';

import '../../../../../constants/app_colors.dart';
import '../../../../../widgets/charts/components/combined_chart.dart';
import '../../../../../widgets/charts/components/donut_chart.dart';
import '../../../../../widgets/charts/models/chart_data_model.dart';
import '../../../widgets/assistant_action_button.dart';
import '../../../widgets/assistant_chart_container.dart';

/// Chart section for analytics displaying various financial charts
class AnalyticsChartSection extends StatefulWidget {
  final List<ChartDataModel> categoryData;
  final List<ChartDataModel> trendData;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const AnalyticsChartSection({
    super.key,
    required this.categoryData,
    required this.trendData,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  State<AnalyticsChartSection> createState() => _AnalyticsChartSectionState();
}

class _AnalyticsChartSectionState extends State<AnalyticsChartSection> {
  ChartType _selectedChartType = ChartType.category;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chart type selector
        _buildChartTypeSelector(),
        const SizedBox(height: 16),
        
        // Chart display
        AssistantChartContainer(
          title: _getChartTitle(),
          subtitle: _getChartSubtitle(),
          height: 300,
          trailing: widget.onRefresh != null
              ? IconButton(
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh),
                  color: AppColors.primary,
                )
              : null,
          chart: widget.isLoading
              ? _buildLoadingChart()
              : _buildSelectedChart(),
        ),
      ],
    );
  }

  Widget _buildChartTypeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: AssistantQuickActionChip(
              label: 'Danh mục',
              icon: Icons.pie_chart,
              isSelected: _selectedChartType == ChartType.category,
              onPressed: () => setState(() => _selectedChartType = ChartType.category),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AssistantQuickActionChip(
              label: 'Xu hướng',
              icon: Icons.trending_up,
              isSelected: _selectedChartType == ChartType.trend,
              onPressed: () => setState(() => _selectedChartType = ChartType.trend),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AssistantQuickActionChip(
              label: 'So sánh',
              icon: Icons.compare_arrows,
              isSelected: _selectedChartType == ChartType.comparison,
              onPressed: () => setState(() => _selectedChartType = ChartType.comparison),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedChart() {
    switch (_selectedChartType) {
      case ChartType.category:
        return _buildCategoryChart();
      case ChartType.trend:
        return _buildTrendChart();
      case ChartType.comparison:
        return _buildComparisonChart();
    }
  }

  Widget _buildCategoryChart() {
    if (widget.categoryData.isEmpty) {
      return _buildEmptyChart('Không có dữ liệu danh mục');
    }
    
    return DonutChart(
      data: widget.categoryData,
      size: 200,
    );
  }

  Widget _buildTrendChart() {
    if (widget.trendData.isEmpty) {
      return _buildEmptyChart('Không có dữ liệu xu hướng');
    }
    
    // Split data into income and expense
    final incomeData = widget.trendData.where((item) => item.type == 'income').toList();
    final expenseData = widget.trendData.where((item) => item.type == 'expense').toList();
    
    return CombinedChart(
      incomeData: incomeData,
      expenseData: expenseData,
      size: 200,
    );
  }

  Widget _buildComparisonChart() {
    // Split category data into income and expense for comparison
    final incomeData = widget.categoryData.where((item) => item.type == 'income').toList();
    final expenseData = widget.categoryData.where((item) => item.type == 'expense').toList();
    
    if (incomeData.isEmpty && expenseData.isEmpty) {
      return _buildEmptyChart('Không có dữ liệu so sánh');
    }
    
    return CombinedChart(
      incomeData: incomeData,
      expenseData: expenseData,
      size: 200,
    );
  }

  Widget _buildLoadingChart() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              color: AppColors.grey400,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getChartTitle() {
    switch (_selectedChartType) {
      case ChartType.category:
        return 'Phân tích theo danh mục';
      case ChartType.trend:
        return 'Xu hướng chi tiêu';
      case ChartType.comparison:
        return 'So sánh thu chi';
    }
  }

  String _getChartSubtitle() {
    switch (_selectedChartType) {
      case ChartType.category:
        return 'Phân bổ chi tiêu theo từng danh mục';
      case ChartType.trend:
        return 'Biến động thu chi theo thời gian';
      case ChartType.comparison:
        return 'So sánh thu nhập và chi tiêu';
    }
  }
}

enum ChartType { category, trend, comparison }
