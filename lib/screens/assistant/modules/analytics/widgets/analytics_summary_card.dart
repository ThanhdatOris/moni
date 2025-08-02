import 'package:flutter/material.dart';

import '../../../../../constants/app_colors.dart';
import '../../../../../utils/formatting/currency_formatter.dart';
import '../../../widgets/assistant_base_card.dart';

/// Summary card showing key spending metrics
class AnalyticsSummaryCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int transactionCount;
  final bool isLoading;

  const AnalyticsSummaryCard({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.transactionCount,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AssistantBaseCard(
      title: 'Tổng quan tài chính',
      titleIcon: Icons.account_balance_wallet,
      isLoading: isLoading,
      height: 180,
      child: isLoading ? const SizedBox.shrink() : _buildSummaryContent(),
    );
  }

  Widget _buildSummaryContent() {
    return Column(
      children: [
        // Balance section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'Số dư hiện tại',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.formatAmountWithCurrency(balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Income/Expense row
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                'Thu nhập',
                CurrencyFormatter.formatAmountWithCurrency(totalIncome),
                Icons.trending_up,
                AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricItem(
                'Chi tiêu',
                CurrencyFormatter.formatAmountWithCurrency(totalExpense),
                Icons.trending_down,
                AppColors.error,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Transaction count
        Text(
          '$transactionCount giao dịch trong tháng',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
