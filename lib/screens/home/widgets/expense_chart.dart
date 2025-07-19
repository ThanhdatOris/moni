import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/enums.dart';
import '../../../utils/currency_formatter.dart';
import '../../../widgets/charts/core/chart_theme.dart';
import '../../../widgets/charts/models/chart_config_models.dart';
import '../../../widgets/charts/models/chart_data_models.dart';
import '../../../widgets/charts/types/category_analysis_chart.dart';

class ExpenseChart extends StatefulWidget {
  const ExpenseChart({super.key});

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart> {
  String _selectedPeriod = 'Tháng này';
  final List<String> _periods = ['Tháng này', 'Tuần này', '30 ngày'];

  ChartTimePeriod _getTimePeriodFromString(String period) {
    switch (period) {
      case 'Tuần này':
        return ChartTimePeriod.weekly;
      case '30 ngày':
        return ChartTimePeriod.monthly;
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
      case '30 ngày':
        return now.subtract(const Duration(days: 30));
      case 'Tháng này':
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  void _rebuildChart() {
    // Force rebuild when period changes
    setState(() {
      // This will trigger rebuild of the chart
    });
  }

  @override
  Widget build(BuildContext context) {
    final chartTheme = Theme.of(context).brightness == Brightness.dark
        ? ChartTheme.dark()
        : ChartTheme.light();

    final config = CompleteChartConfig(
      chart: ChartConfiguration(
        title: 'Phân tích chi tiêu',
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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Phân tích chi tiêu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  underline: const SizedBox(),
                  isDense: true,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  items: _periods.map((String period) {
                    return DropdownMenuItem<String>(
                      value: period,
                      child: Text(period),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedPeriod = newValue;
                      });
                      // Force rebuild when period changes
                      _rebuildChart();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: ChartThemeProvider(
              theme: chartTheme,
              child: CategoryAnalysisChart(
                config: config,
                showPieChart: true,
                showBarChart: false,
                showTrends: false,
                onCategoryTap: (category) {
                  _showCategoryDetails(category);
                },
              ),
            ),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Tổng chi: ${CurrencyFormatter.formatAmountWithCurrency(category.totalAmount)}'),
            Text('Số giao dịch: ${category.transactionCount}'),
            Text(
                'Trung bình: ${CurrencyFormatter.formatAmountWithCurrency(category.averageTransaction)}'),
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
