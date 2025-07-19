import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/enums.dart';
import '../utils/currency_formatter.dart';
import '../widgets/charts/components/chart_insights.dart';
import '../widgets/charts/core/chart_theme.dart';
import '../widgets/charts/models/chart_config_models.dart';
import '../widgets/charts/models/chart_data_models.dart';
import '../widgets/charts/types/category_analysis_chart.dart';

/// Demo screen để test chart system
class ChartDemoScreen extends StatefulWidget {
  const ChartDemoScreen({super.key});

  @override
  State<ChartDemoScreen> createState() => _ChartDemoScreenState();
}

class _ChartDemoScreenState extends State<ChartDemoScreen> {
  String _selectedPeriod = 'Tháng này';
  final List<String> _periods = ['Tuần này', 'Tháng này', 'Quý này', 'Năm nay'];

  @override
  Widget build(BuildContext context) {
    final chartTheme = Theme.of(context).brightness == Brightness.dark
        ? ChartTheme.dark()
        : ChartTheme.light();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chart System Demo - Đã cải tiến'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        centerTitle: true,
      ),
      body: ChartThemeProvider(
        theme: chartTheme,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildPeriodSelector(),
              const SizedBox(height: 24),
              _buildCategoryAnalysisChart(),
              const SizedBox(height: 24),
              _buildChartInsights(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(_periods.length, (index) {
          final isSelected = _selectedPeriod == _periods[index];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = _periods[index];
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _periods[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.textWhite
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCategoryAnalysisChart() {
    final config = CompleteChartConfig(
      chart: ChartConfiguration(
        title: 'Phân tích chi tiêu - Demo',
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
            'Phân bố chi tiêu theo danh mục - Đã cải tiến',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 350,
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
            'Phân tích nhanh',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ChartInsights(
            insights: [
              ChartInsight(
                title: 'Chi tiêu cao nhất',
                description: 'Danh mục Ăn uống chiếm 44% tổng chi tiêu',
                type: InsightType.info,
                priority: 0.8,
                generated: DateTime.now(),
              ),
              ChartInsight(
                title: 'Tiết kiệm tốt',
                description: 'Bạn đang tiết kiệm 20% thu nhập hàng tháng',
                type: InsightType.positive,
                priority: 0.9,
                generated: DateTime.now(),
              ),
            ],
            onInsightTap: (insight) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã chọn: ${insight.title}')),
              );
            },
          ),
        ],
      ),
    );
  }

  ChartTimePeriod _getTimePeriodFromString(String period) {
    switch (period) {
      case 'Tuần này':
        return ChartTimePeriod.weekly;
      case 'Quý này':
        return ChartTimePeriod.quarterly;
      case 'Năm nay':
        return ChartTimePeriod.yearly;
      case 'Tháng này':
      default:
        return ChartTimePeriod.monthly;
    }
  }

  DateTime _getStartDateFromPeriod(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'Tuần này':
        return now.subtract(Duration(days: now.weekday - 1));
      case 'Quý này':
        final quarter = ((now.month - 1) / 3).floor();
        return DateTime(now.year, quarter * 3 + 1, 1);
      case 'Năm nay':
        return DateTime(now.year, 1, 1);
      case 'Tháng này':
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  void _showCategoryDetails(CategoryAnalysisData category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết: ${category.categoryName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Tổng chi: ${CurrencyFormatter.formatAmountWithCurrency(category.totalAmount)}'),
            Text('Số giao dịch: ${category.transactionCount}'),
            Text(
                'Trung bình: ${CurrencyFormatter.formatAmountWithCurrency(category.averageTransaction)}'),
            Text('Phần trăm: ${category.percentage.toStringAsFixed(1)}%'),
            if (category.budgetAmount > 0) ...[
              const SizedBox(height: 8),
              Text(
                  'Ngân sách: ${CurrencyFormatter.formatAmountWithCurrency(category.budgetAmount)}'),
              Text(
                  'Sử dụng: ${(category.budgetUtilization * 100).toStringAsFixed(1)}%'),
            ],
          ],
        ),
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
