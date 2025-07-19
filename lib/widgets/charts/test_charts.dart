import 'package:flutter/material.dart';

import 'index.dart';

/// Test screen để kiểm tra module charts
class TestChartsScreen extends StatefulWidget {
  const TestChartsScreen({super.key});

  @override
  State<TestChartsScreen> createState() => _TestChartsScreenState();
}

class _TestChartsScreenState extends State<TestChartsScreen> {
  bool _showTrendChart = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Charts'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Test Donut Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Donut Chart Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DonutChart(
                      data: _getTestChartData(),
                      size: 250,
                      onCategoryTap: () {
                        debugPrint('Category tapped in test');
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Test Trend Bar Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trend Bar Chart Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TrendBarChart(
                      data: _getTestTrendData(),
                      height: 200,
                      onTap: () {
                        debugPrint('Trend chart tapped in test');
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Test Financial Overview Cards
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Financial Overview Cards Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FinancialOverviewCards(
                      data: _getTestFinancialOverviewData(),
                      onAllocationTap: () {
                        debugPrint('Allocation tapped in test');
                      },
                      onTrendTap: () {
                        debugPrint('Trend tapped in test');
                      },
                      onComparisonTap: () {
                        debugPrint('Comparison tapped in test');
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Test Toggle Button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showTrendChart = !_showTrendChart;
                });
              },
              child: Text(
                  _showTrendChart ? 'Show Donut Chart' : 'Show Trend Chart'),
            ),
          ],
        ),
      ),
    );
  }

  // Test data methods
  List<ChartDataModel> _getTestChartData() {
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

  List<TrendData> _getTestTrendData() {
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

  FinancialOverviewData _getTestFinancialOverviewData() {
    return FinancialOverviewData(
      totalExpense: 3916644,
      totalIncome: 3700100,
      changeAmount: 1309565,
      changePeriod: 'tháng trước',
      isIncrease: true,
    );
  }
}
