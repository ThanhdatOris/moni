import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../models/chart_data_model.dart';

class FinancialOverviewCards extends StatelessWidget {
  final FinancialOverviewData? data;
  final VoidCallback? onAllocationTap;
  final VoidCallback? onTrendTap;
  final VoidCallback? onComparisonTap;
  final VoidCallback? onExpenseTap;
  final VoidCallback? onIncomeTap;
  final String selectedType; // 'all', 'expense', 'income'
  final bool isLoading;

  const FinancialOverviewCards({
    super.key,
    this.data,
    this.onAllocationTap,
    this.onTrendTap,
    this.onComparisonTap,
    this.onExpenseTap,
    this.onIncomeTap,
    this.selectedType = 'all',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (data == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text('Không có dữ liệu'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header với navigation
          _buildHeader(),
          const SizedBox(height: 16),
          // Financial cards
          _buildFinancialCards(),
          const SizedBox(height: 16),
          // Comparison text
          _buildComparisonText(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.arrow_back_ios,
          size: 20,
          color: AppColors.grey600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: AppColors.grey600,
              ),
              const SizedBox(width: 4),
              const Text(
                'Tháng này',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.arrow_forward_ios,
          size: 20,
          color: AppColors.grey600,
        ),
      ],
    );
  }

  Widget _buildFinancialCards() {
    return Row(
      children: [
        // Expense Card
        Expanded(
          child: GestureDetector(
            onTap: onExpenseTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedType == 'expense'
                      ? AppColors.primary
                      : AppColors.grey300,
                  width: selectedType == 'expense' ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: selectedType == 'expense'
                            ? AppColors.primary
                            : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Chi tiêu',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: selectedType == 'expense'
                              ? AppColors.primary
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatCurrency(data!.totalExpense)}₫',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          selectedType == 'expense' ? AppColors.primary : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Income Card
        Expanded(
          child: GestureDetector(
            onTap: onIncomeTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedType == 'income'
                      ? AppColors.primary
                      : AppColors.grey300,
                  width: selectedType == 'income' ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: selectedType == 'income'
                            ? AppColors.primary
                            : Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Thu nhập',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: selectedType == 'income'
                              ? AppColors.primary
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatCurrency(data!.totalIncome)}₫',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          selectedType == 'income' ? AppColors.primary : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonText() {
    return GestureDetector(
      onTap: onComparisonTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.bar_chart,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${data!.isIncrease ? 'Tăng' : 'Giảm'} ${_formatCurrency(data!.changeAmount)}₫ so với cùng kỳ ${data!.changePeriod}',
                style: TextStyle(
                  fontSize: 14,
                  color: data!.isIncrease ? Colors.orange : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.grey600,
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
