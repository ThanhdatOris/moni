import 'package:flutter/material.dart';
import 'package:moni/constants/app_colors.dart';
import 'package:moni/constants/enums.dart';

import '../../../widgets/assistant_action_button.dart';
import '../../../widgets/assistant_base_card.dart';

/// AI-generated budget recommendations and tips
class BudgetRecommendationCard extends StatelessWidget {
  final String? recommendation;
  final List<BudgetTip> tips;
  final bool isLoading;
  final VoidCallback? onRegenerateRecommendation;
  final VoidCallback? onApplyBudget;

  const BudgetRecommendationCard({
    super.key,
    this.recommendation,
    this.tips = const [],
    this.isLoading = false,
    this.onRegenerateRecommendation,
    this.onApplyBudget,
  });

  @override
  Widget build(BuildContext context) {
    return AssistantBaseCard(
      title: 'Gợi ý từ AI',
      titleIcon: Icons.lightbulb_outline,
      isLoading: isLoading,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.warning,
          AppColors.warning.withValues(alpha: 0.8),
        ],
      ),
      child:
          isLoading ? const SizedBox.shrink() : _buildRecommendationContent(),
    );
  }

  Widget _buildRecommendationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main recommendation
        if (recommendation != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recommendation!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Budget tips
        if (tips.isNotEmpty) ...[
          Text(
            'Mẹo quản lý ngân sách:',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...tips.take(3).map((tip) => _buildTipItem(tip)),
          const SizedBox(height: 16),
        ],

        // Action buttons
        Row(
          children: [
            Expanded(
              child: AssistantActionButton(
                text: 'Tạo lại gợi ý',
                icon: Icons.refresh,
                type: ButtonType.outline,
                backgroundColor: Colors.white,
                textColor: Colors.white,
                onPressed: onRegenerateRecommendation,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AssistantActionButton(
                text: 'Áp dụng ngân sách',
                icon: Icons.check,
                type: ButtonType.secondary,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                textColor: Colors.white,
                onPressed: onApplyBudget,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTipItem(BudgetTip tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _getTipCategoryColor(tip.category).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              _getTipCategoryIcon(tip.category),
              color: Colors.white.withValues(alpha: 0.8),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tip.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTipCategoryColor(BudgetTipCategory category) {
    switch (category) {
      case BudgetTipCategory.saving:
        return AppColors.success;
      case BudgetTipCategory.spending:
        return AppColors.error;
      case BudgetTipCategory.investment:
        return AppColors.info;
      case BudgetTipCategory.general:
        return AppColors.grey500;
    }
  }

  IconData _getTipCategoryIcon(BudgetTipCategory category) {
    switch (category) {
      case BudgetTipCategory.saving:
        return Icons.savings;
      case BudgetTipCategory.spending:
        return Icons.shopping_cart;
      case BudgetTipCategory.investment:
        return Icons.trending_up;
      case BudgetTipCategory.general:
        return Icons.tips_and_updates;
    }
  }
}

/// Budget tip model
class BudgetTip {
  final String title;
  final String description;
  final BudgetTipCategory category;
  final int priority; // 1-5, 5 is highest priority

  BudgetTip({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
  });
}