import 'package:flutter/material.dart';

import '../models/chart_data_model.dart';
import 'donut_chart.dart';
import 'trend_bar_chart.dart';

class ChartTestScreen extends StatelessWidget {
  const ChartTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for testing
    final chartData = [
      ChartDataModel(
        category: 'Ăn uống',
        amount: 2500000,
        percentage: 35.5,
        color: '#FF6B6B',
        icon: '🍽️',
        type: 'expense',
      ),
      ChartDataModel(
        category: 'Di chuyển',
        amount: 1800000,
        percentage: 25.6,
        color: '#4ECDC4',
        icon: '🚗',
        type: 'expense',
      ),
      ChartDataModel(
        category: 'Mua sắm',
        amount: 1200000,
        percentage: 17.1,
        color: '#45B7D1',
        icon: '🛍️',
        type: 'expense',
      ),
      ChartDataModel(
        category: 'Giải trí',
        amount: 900000,
        percentage: 12.8,
        color: '#96CEB4',
        icon: '🎮',
        type: 'expense',
      ),
      ChartDataModel(
        category: 'Khác',
        amount: 600000,
        percentage: 9.0,
        color: '#FECA57',
        icon: '💰',
        type: 'expense',
      ),
    ];

    final trendData = [
      TrendData(
        period: '2024-01',
        label: 'T1',
        income: 15000000,
        expense: 8500000,
      ),
      TrendData(
        period: '2024-02',
        label: 'T2',
        income: 16500000,
        expense: 9200000,
      ),
      TrendData(
        period: '2024-03',
        label: 'T3',
        income: 14800000,
        expense: 7800000,
      ),
      TrendData(
        period: '2024-04',
        label: 'T4',
        income: 18200000,
        expense: 10100000,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('FL Chart Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Donut Chart (FL Chart)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DonutChart(
              data: chartData,
              size: 300,
              onCategoryTap: (item) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tapped: ${item.category} - ${item.amount}₫'),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Trend Bar Chart (FL Chart)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TrendBarChart(
              data: trendData,
              height: 300,
              onBarTap: (item) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tapped: ${item.label} - Thu: ${item.income}₫, Chi: ${item.expense}₫'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
