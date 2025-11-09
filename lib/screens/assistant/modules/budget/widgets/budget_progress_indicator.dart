import 'package:flutter/material.dart';
import 'package:moni/constants/app_colors.dart';
import 'package:moni/constants/enums.dart';

import '../../../../../utils/index.dart';
import '../../../widgets/assistant_action_button.dart';
import '../../../widgets/assistant_base_card.dart';

/// Budget progress tracking and spending status
class BudgetProgressIndicator extends StatelessWidget {
  final String budgetPeriod;
  final double totalBudget;
  final double totalSpent;
  final List<CategoryBudgetProgress> categoryProgress;
  final bool isLoading;
  final VoidCallback? onViewDetails;
  final VoidCallback? onAdjustBudget;

  const BudgetProgressIndicator({
    super.key,
    required this.budgetPeriod,
    required this.totalBudget,
    required this.totalSpent,
    this.categoryProgress = const [],
    this.isLoading = false,
    this.onViewDetails,
    this.onAdjustBudget,
  });

  double get progressPercentage => totalBudget > 0 ? totalSpent / totalBudget : 0;
  double get remainingBudget => totalBudget - totalSpent;
  bool get isOverBudget => totalSpent > totalBudget;

  @override
  Widget build(BuildContext context) {
    return AssistantBaseCard(
      title: 'Tiến độ ngân sách ($budgetPeriod)',
      titleIcon: Icons.track_changes,
      isLoading: isLoading,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _getProgressColor(),
          _getProgressColor().withValues(alpha: 0.8),
        ],
      ),
      child: isLoading ? const SizedBox.shrink() : _buildProgressContent(),
    );
  }

  Color _getProgressColor() {
    if (isOverBudget) return AppColors.error;
    if (progressPercentage > 0.8) return AppColors.warning;
    return AppColors.success;
  }

  Widget _buildProgressContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall progress
        _buildOverallProgress(),
        const SizedBox(height: 20),

        // Category breakdown
        if (categoryProgress.isNotEmpty) ...[
          Text(
            'Chi tiết theo danh mục:',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...categoryProgress.take(3).map((category) => _buildCategoryProgress(category)),
          const SizedBox(height: 16),
        ],

        // Action buttons
        Row(
          children: [
            Expanded(
              child: AssistantActionButton(
                text: 'Xem chi tiết',
                icon: Icons.visibility,
                type: ButtonType.outline,
                backgroundColor: Colors.white,
                textColor: Colors.white,
                onPressed: onViewDetails,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AssistantActionButton(
                text: 'Điều chỉnh',
                icon: Icons.tune,
                type: ButtonType.secondary,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                textColor: Colors.white,
                onPressed: onAdjustBudget,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverallProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Progress bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (progressPercentage).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progressPercentage * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Financial summary
          Row(
            children: [
              Expanded(
                child: _buildAmountInfo(
                  'Đã chi tiêu',
                  totalSpent,
                  Icons.remove_circle_outline,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildAmountInfo(
                  isOverBudget ? 'Vượt ngân sách' : 'Còn lại',
                  remainingBudget.abs(),
                  isOverBudget ? Icons.warning : Icons.account_balance_wallet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Budget status message
          if (isOverBudget)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Đã vượt ngân sách',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmountInfo(String label, double amount, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.8),
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          CurrencyFormatter.formatAmountWithCurrency(amount),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryProgress(CategoryBudgetProgress category) {
    final progressPercent = category.budget > 0 ? category.spent.toDouble() / category.budget : 0.0;
    final isOverBudget = category.spent > category.budget;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(int.parse(category.color.replaceAll('#', '0xFF'))),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(progressPercent * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressPercent.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isOverBudget ? AppColors.error : Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Amount info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.formatAmountWithCurrency(category.spent),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '/ ${CurrencyFormatter.formatAmountWithCurrency(category.budget)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Category budget progress model
class CategoryBudgetProgress {
  final String name;
  final String color;
  final double budget;
  final double spent;
  final String icon;

  CategoryBudgetProgress({
    required this.name,
    required this.color,
    required this.budget,
    required this.spent,
    required this.icon,
  });
}
