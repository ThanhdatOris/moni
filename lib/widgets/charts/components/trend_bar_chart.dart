import 'dart:math';

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../models/chart_data_model.dart';

class TrendBarChart extends StatelessWidget {
  final List<TrendData> data;
  final double height;
  final VoidCallback? onTap;

  const TrendBarChart({
    super.key,
    required this.data,
    required this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: height,
        child: const Center(
          child: Text('Không có dữ liệu'),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 16),
            // Chart
            Expanded(
              child: _buildChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.trending_up,
          color: AppColors.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        const Text(
          'Xu hướng thu chi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.grey600,
        ),
      ],
    );
  }

  Widget _buildChart() {
    final maxValue = _getMaxValue();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((item) {
        final expenseHeight = (item.expense / maxValue) * (height - 80);
        final incomeHeight = (item.income / maxValue) * (height - 80);

        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Income bar
              Container(
                width: 20,
                height: incomeHeight > 0 ? incomeHeight : 2,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Expense bar
              Container(
                width: 20,
                height: expenseHeight > 0 ? expenseHeight : 2,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              // Label
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.grey600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  double _getMaxValue() {
    double maxValue = 0;
    for (final item in data) {
      maxValue = max(maxValue, max(item.expense, item.income));
    }
    return maxValue > 0 ? maxValue : 1;
  }
}
