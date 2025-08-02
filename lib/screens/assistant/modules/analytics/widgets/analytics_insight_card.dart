import 'package:flutter/material.dart';

import '../../../../../constants/app_colors.dart';
import '../../../widgets/assistant_action_button.dart';
import '../../../widgets/assistant_base_card.dart';

/// Card displaying AI-generated insights and recommendations
class AnalyticsInsightCard extends StatelessWidget {
  final String? insight;
  final List<String> recommendations;
  final bool isLoading;
  final VoidCallback? onRegenerateInsight;

  const AnalyticsInsightCard({
    super.key,
    this.insight,
    this.recommendations = const [],
    this.isLoading = false,
    this.onRegenerateInsight,
  });

  @override
  Widget build(BuildContext context) {
    return AssistantBaseCard(
      title: 'AI Insights',
      titleIcon: Icons.psychology,
      isLoading: isLoading,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.info,
          AppColors.info.withValues(alpha: 0.8),
        ],
      ),
      child: isLoading ? const SizedBox.shrink() : _buildInsightContent(),
    );
  }

  Widget _buildInsightContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main insight
        if (insight != null) ...[
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
                  Icons.lightbulb_outline,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight!,
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

        // Recommendations
        if (recommendations.isNotEmpty) ...[
          Text(
            'Gợi ý cải thiện:',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...recommendations.take(3).map((recommendation) => 
            _buildRecommendationItem(recommendation)
          ),
          const SizedBox(height: 16),
        ],

        // Action buttons
        Row(
          children: [
            Expanded(
              child: AssistantActionButton(
                text: 'Tạo lại insight',
                icon: Icons.refresh,
                type: ButtonType.outline,
                backgroundColor: Colors.white,
                textColor: Colors.white,
                onPressed: onRegenerateInsight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AssistantActionButton(
                text: 'Chi tiết',
                icon: Icons.arrow_forward,
                type: ButtonType.secondary,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                textColor: Colors.white,
                onPressed: () {
                  // TODO: Navigate to detailed insights
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecommendationItem(String recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
