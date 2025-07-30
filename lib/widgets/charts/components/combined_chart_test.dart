import 'package:flutter/material.dart';

import '../models/chart_data_model.dart';
import 'combined_chart.dart';

class CombinedChartTestScreen extends StatelessWidget {
  const CombinedChartTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock income data
    final incomeData = [
      ChartDataModel(
        category: 'Lương',
        amount: 25000000,
        percentage: 65.0,
        color: '#4CAF50',
        icon: '💰',
        type: 'income',
      ),
      ChartDataModel(
        category: 'Thưởng',
        amount: 8000000,
        percentage: 20.8,
        color: '#81C784',
        icon: '🎁',
        type: 'income',
      ),
      ChartDataModel(
        category: 'Đầu tư',
        amount: 3500000,
        percentage: 9.1,
        color: '#A5D6A7',
        icon: '📈',
        type: 'income',
      ),
      ChartDataModel(
        category: 'Khác',
        amount: 2000000,
        percentage: 5.1,
        color: '#C8E6C9',
        icon: '💸',
        type: 'income',
      ),
    ];

    // Mock expense data
    final expenseData = [
      ChartDataModel(
        category: 'Ăn uống',
        amount: 8500000,
        percentage: 35.5,
        color: '#F44336',
        icon: '🍽️',
        type: 'expense',
      ),
      ChartDataModel(
        category: 'Di chuyển',
        amount: 5800000,
        percentage: 24.2,
        color: '#E57373',
        icon: '🚗',
        type: 'expense',
      ),
      ChartDataModel(
        category: 'Mua sắm',
        amount: 4200000,
        percentage: 17.5,
        color: '#EF5350',
        icon: '🛍️',
        type: 'expense',
      ),
      ChartDataModel(
        category: 'Giải trí',
        amount: 3200000,
        percentage: 13.3,
        color: '#FF5722',
        icon: '🎮',
        type: 'expense',
      ),
      ChartDataModel(
        category: 'Khác',
        amount: 2300000,
        percentage: 9.5,
        color: '#FF7043',
        icon: '💰',
        type: 'expense',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Combined Chart Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Combined Chart (Thu nhập vs Chi tiêu)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CombinedChart(
                  incomeData: incomeData,
                  expenseData: expenseData,
                  size: 350,
                  onCategoryTap: (item, type) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Tapped: ${item.category} ($type) - ${item.amount}₫',
                        ),
                        backgroundColor: type == 'income' ? Colors.green : Colors.red,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin tổng quan:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Tổng thu nhập:', _getTotalAmount(incomeData), Colors.green),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Tổng chi tiêu:', _getTotalAmount(expenseData), Colors.red),
                    const Divider(),
                    _buildSummaryRow(
                      'Chênh lệch:', 
                      _getTotalAmount(incomeData) - _getTotalAmount(expenseData), 
                      _getTotalAmount(incomeData) >= _getTotalAmount(expenseData) ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          '${_formatCurrency(amount)}₫',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  double _getTotalAmount(List<ChartDataModel> data) {
    return data.fold(0, (total, item) => total + item.amount);
  }

  String _formatCurrency(double amount) {
    return amount.abs().toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
