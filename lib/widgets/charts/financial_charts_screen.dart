import 'package:flutter/material.dart';

import 'components/donut_chart.dart';
import 'components/financial_overview_cards.dart';
import 'components/trend_bar_chart.dart';
import 'models/chart_data_model.dart';

class FinancialChartsScreen extends StatefulWidget {
  const FinancialChartsScreen({super.key});

  @override
  State<FinancialChartsScreen> createState() => _FinancialChartsScreenState();
}

class _FinancialChartsScreenState extends State<FinancialChartsScreen> {
  bool _showTrendChart = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Financial Overview Cards
                    FinancialOverviewCards(
                      data: _getFinancialOverviewData(),
                      onAllocationTap: _onAllocationTap,
                      onTrendTap: _onTrendTap,
                      onComparisonTap: _onComparisonTap,
                    ),

                    const SizedBox(height: 20),

                    // Chart Section
                    _buildChartSection(),

                    const SizedBox(height: 20),

                    // Details Link
                    _buildDetailsLink(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text(
            'Tình hình thu chi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.visibility,
            color: Colors.pink,
            size: 20,
          ),
          const Spacer(),
          // Allocation button
          GestureDetector(
            onTap: _onAllocationTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.pink,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pie_chart,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Phân bổ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Trend button
          GestureDetector(
            onTap: _onTrendTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _showTrendChart ? Colors.pink : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.bar_chart,
                color: _showTrendChart ? Colors.white : Colors.grey[600],
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _showTrendChart
          ? TrendBarChart(
              data: _getTrendData(),
              height: 200,
              onTap: _onTrendDetailsTap,
            )
          : DonutChart(
              data: _getChartData(),
              size: 250,
              onCategoryTap: _onCategoryTap,
            ),
    );
  }

  Widget _buildDetailsLink() {
    return GestureDetector(
      onTap: _onDetailsTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Chi tiết từng danh mục (9)',
              style: TextStyle(
                color: Colors.pink,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.pink,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Mock data methods
  FinancialOverviewData _getFinancialOverviewData() {
    return FinancialOverviewData(
      totalExpense: 3916644,
      totalIncome: 3700100,
      changeAmount: 1309565,
      changePeriod: 'tháng trước',
      isIncrease: true,
    );
  }

  List<ChartDataModel> _getChartData() {
    return [
      ChartDataModel(
        category: 'Hóa đơn',
        amount: 1719500,
        percentage: 44,
        icon: 'bills',
        color: '#4CAF50',
        type: 'expense',
      ),
      ChartDataModel(
        category: 'Ăn uống',
        amount: 883000,
        percentage: 23,
        icon: 'food',
        color: '#FF9800',
        type: 'expense',
      ),
      ChartDataModel(
        category: 'Mua sắm',
        amount: 370827,
        percentage: 9,
        icon: 'shopping',
        color: '#FFC107',
        type: 'expense',
      ),
      ChartDataModel(
        category: 'Tiệc tùng',
        amount: 313317,
        percentage: 8,
        icon: 'party',
        color: '#FF5722',
        type: 'expense',
      ),
      ChartDataModel(
        category: 'Còn lại',
        amount: 626700,
        percentage: 16,
        icon: 'remaining',
        color: '#9E9E9E',
        type: 'expense',
      ),
    ];
  }

  List<TrendData> _getTrendData() {
    return [
      TrendData(
        period: 'T5',
        expense: 5700000,
        income: 5500000,
        label: 'T5',
      ),
      TrendData(
        period: 'T6',
        expense: 5700000,
        income: 5500000,
        label: 'T6',
      ),
      TrendData(
        period: 'Tháng này',
        expense: 3800000,
        income: 3700000,
        label: 'Tháng này',
      ),
    ];
  }

  // Event handlers
  void _onAllocationTap() {
    // TODO: Navigate to allocation screen
    debugPrint('Allocation tapped');
  }

  void _onTrendTap() {
    setState(() {
      _showTrendChart = !_showTrendChart;
    });
  }

  void _onComparisonTap() {
    // TODO: Navigate to comparison screen
    debugPrint('Comparison tapped');
  }

  void _onCategoryTap() {
    // TODO: Navigate to category details
    debugPrint('Category tapped');
  }

  void _onTrendDetailsTap() {
    // TODO: Navigate to trend details
    debugPrint('Trend details tapped');
  }

  void _onDetailsTap() {
    // TODO: Navigate to detailed categories
    debugPrint('Details tapped');
  }
}
