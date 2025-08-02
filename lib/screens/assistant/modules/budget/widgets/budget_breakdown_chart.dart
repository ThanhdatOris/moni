import 'package:flutter/material.dart';

import '../../../../../constants/app_colors.dart';
import '../../../../../utils/formatting/currency_formatter.dart';
import '../../../../../widgets/charts/components/donut_chart.dart';
import '../../../../../widgets/charts/models/chart_data_model.dart';
import '../../../widgets/assistant_chart_container.dart';

/// Visual budget breakdown with interactive donut chart
class BudgetBreakdownChart extends StatelessWidget {
  final List<BudgetAllocation> allocations;
  final double totalBudget;
  final bool isLoading;

  const BudgetBreakdownChart({
    super.key,
    required this.allocations,
    required this.totalBudget,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingChart();
    }

    return AssistantChartContainer(
      title: 'Phân bổ ngân sách',
      subtitle: 'Tổng: ${CurrencyFormatter.formatAmountWithCurrency(totalBudget)}',
      height: 350,
      chart: Column(
        children: [
          // Donut chart
          Expanded(
            flex: 2,
            child: DonutChart(
              data: _convertToChartData(),
              size: 200,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Legend with percentages
          Expanded(
            flex: 1,
            child: _buildLegend(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingChart() {
    return Container(
      height: 350,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildLegend() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 8,
        childAspectRatio: 3.5,
      ),
      itemCount: allocations.length,
      itemBuilder: (context, index) {
        final allocation = allocations[index];
        return _buildLegendItem(allocation);
      },
    );
  }

  Widget _buildLegendItem(BudgetAllocation allocation) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _parseColor(allocation.color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _parseColor(allocation.color).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _parseColor(allocation.color),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  allocation.category,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${allocation.percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 10,
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

  List<ChartDataModel> _convertToChartData() {
    return allocations.map((allocation) => ChartDataModel(
      category: allocation.category,
      amount: allocation.amount,
      percentage: allocation.percentage,
      icon: allocation.icon,
      color: allocation.color,
      type: 'expense',
    )).toList();
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }
}

/// Budget allocation model
class BudgetAllocation {
  final String category;
  final double amount;
  final double percentage;
  final String icon;
  final String color;
  final String description;

  BudgetAllocation({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.icon,
    required this.color,
    required this.description,
  });
}
