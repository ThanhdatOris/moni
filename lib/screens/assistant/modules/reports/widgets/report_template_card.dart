import 'package:flutter/material.dart';

import '../../../../../constants/app_colors.dart';
import '../../../widgets/assistant_action_button.dart';

/// Report template card with preview functionality
class ReportTemplateCard extends StatelessWidget {
  final ReportTemplate template;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback? onSelect;
  final VoidCallback? onPreview;
  final VoidCallback? onGenerate;

  const ReportTemplateCard({
    super.key,
    required this.template,
    this.isSelected = false,
    this.isLoading = false,
    this.onSelect,
    this.onPreview,
    this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(),
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: _buildCardContent(),
      ),
    );
  }

  List<Color> _getGradientColors() {
    if (isSelected) {
      return [
        AppColors.primary.withValues(alpha: 0.1),
        AppColors.primaryDark.withValues(alpha: 0.05),
      ];
    }
    
    switch (template.category) {
      case ReportCategory.financial:
        return [AppColors.success, AppColors.success.withValues(alpha: 0.8)];
      case ReportCategory.spending:
        return [AppColors.warning, AppColors.warning.withValues(alpha: 0.8)];
      case ReportCategory.budget:
        return [AppColors.info, AppColors.info.withValues(alpha: 0.8)];
      case ReportCategory.investment:
        return [AppColors.primary, AppColors.primaryDark];
      case ReportCategory.custom:
        return [AppColors.grey500, AppColors.grey600];
    }
  }

  Widget _buildCardContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(template.category),
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getCategoryLabel(template.category),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.check,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            template.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Features
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: template.features.take(3).map((feature) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  feature,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: AssistantActionButton(
                  text: 'Xem trước',
                  icon: Icons.visibility,
                  type: ButtonType.outline,
                  backgroundColor: Colors.white,
                  textColor: Colors.white,
                  onPressed: onPreview,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AssistantActionButton(
                  text: 'Tạo báo cáo',
                  icon: Icons.file_download,
                  type: ButtonType.secondary,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  textColor: Colors.white,
                  isLoading: isLoading,
                  onPressed: onGenerate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(ReportCategory category) {
    switch (category) {
      case ReportCategory.financial:
        return Icons.account_balance;
      case ReportCategory.spending:
        return Icons.trending_down;
      case ReportCategory.budget:
        return Icons.account_balance_wallet;
      case ReportCategory.investment:
        return Icons.trending_up;
      case ReportCategory.custom:
        return Icons.build;
    }
  }

  String _getCategoryLabel(ReportCategory category) {
    switch (category) {
      case ReportCategory.financial:
        return 'Báo cáo tài chính';
      case ReportCategory.spending:
        return 'Phân tích chi tiêu';
      case ReportCategory.budget:
        return 'Ngân sách';
      case ReportCategory.investment:
        return 'Đầu tư';
      case ReportCategory.custom:
        return 'Tùy chỉnh';
    }
  }
}

/// Report template model
class ReportTemplate {
  final String id;
  final String name;
  final String description;
  final ReportCategory category;
  final List<String> features;
  final Duration estimatedTime;
  final String previewImage;
  final Map<String, dynamic> parameters;

  ReportTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.features,
    required this.estimatedTime,
    required this.previewImage,
    required this.parameters,
  });
}

/// Report categories
enum ReportCategory {
  financial,
  spending,
  budget,
  investment,
  custom,
}
