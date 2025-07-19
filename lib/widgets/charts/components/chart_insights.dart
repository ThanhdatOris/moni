import 'package:flutter/material.dart';
import '../core/chart_theme.dart';
import '../models/chart_data_models.dart';
import '../../../constants/enums.dart';

/// AI insights panel for chart analysis
class ChartInsights extends StatelessWidget {
  final List<ChartInsight> insights;
  final ChartTheme? theme;
  final Function(ChartInsight)? onInsightTap;
  final bool showTrends;
  final bool showRecommendations;

  const ChartInsights({
    super.key,
    required this.insights,
    this.theme,
    this.onInsightTap,
    this.showTrends = true,
    this.showRecommendations = true,
  });

  @override
  Widget build(BuildContext context) {
    final chartTheme = theme ?? ChartThemeProvider.of(context);
    
    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: chartTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chartTheme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(chartTheme),
          const SizedBox(height: 12),
          _buildInsightsList(chartTheme),
        ],
      ),
    );
  }

  Widget _buildHeader(ChartTheme theme) {
    return Row(
      children: [
        Icon(
          Icons.psychology,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Phân tích AI',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          '${insights.length} insights',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsList(ChartTheme theme) {
    return Column(
      children: insights.map((insight) => _buildInsightCard(insight, theme)).toList(),
    );
  }

  Widget _buildInsightCard(ChartInsight insight, ChartTheme theme) {
    return GestureDetector(
      onTap: () => onInsightTap?.call(insight),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getInsightBackgroundColor(insight.type, theme),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getInsightBorderColor(insight.type, theme),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInsightHeader(insight, theme),
            const SizedBox(height: 8),
            _buildInsightContent(insight, theme),
            // Note: trend and recommendations are not available in ChartInsight
            // They would be available in the parent analysis object
          ],
        ),
      ),
    );
  }

  Widget _buildInsightHeader(ChartInsight insight, ChartTheme theme) {
    return Row(
      children: [
        Icon(
          _getInsightIcon(insight.type),
          color: _getInsightIconColor(insight.type, theme),
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            insight.title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Note: confidence is not available in ChartInsight
        // Using priority instead
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${(insight.priority * 100).toInt()}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightContent(ChartInsight insight, ChartTheme theme) {
    return Text(
      insight.description,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Color _getInsightBackgroundColor(InsightType type, ChartTheme theme) {
    switch (type) {
      case InsightType.positive:
        return Colors.green.withValues(alpha: 0.1);
      case InsightType.warning:
        return Colors.orange.withValues(alpha: 0.1);
      case InsightType.negative:
        return Colors.red.withValues(alpha: 0.1);
      case InsightType.critical:
        return Colors.red.withValues(alpha: 0.15);
      case InsightType.info:
        return theme.colorScheme.primaryContainer.withValues(alpha: 0.1);
    }
  }

  Color _getInsightBorderColor(InsightType type, ChartTheme theme) {
    switch (type) {
      case InsightType.positive:
        return Colors.green.withValues(alpha: 0.3);
      case InsightType.warning:
        return Colors.orange.withValues(alpha: 0.3);
      case InsightType.negative:
        return Colors.red.withValues(alpha: 0.3);
      case InsightType.critical:
        return Colors.red.withValues(alpha: 0.4);
      case InsightType.info:
        return theme.colorScheme.primary.withValues(alpha: 0.3);
    }
  }

  Color _getInsightIconColor(InsightType type, ChartTheme theme) {
    switch (type) {
      case InsightType.positive:
        return Colors.green;
      case InsightType.warning:
        return Colors.orange;
      case InsightType.negative:
        return Colors.red;
      case InsightType.critical:
        return Colors.red.shade700;
      case InsightType.info:
        return theme.colorScheme.primary;
    }
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.positive:
        return Icons.check_circle;
      case InsightType.warning:
        return Icons.warning;
      case InsightType.negative:
        return Icons.error;
      case InsightType.critical:
        return Icons.dangerous;
      case InsightType.info:
        return Icons.info;
    }
  }
}

/// Compact insights widget for limited space
class CompactChartInsights extends StatelessWidget {
  final List<ChartInsight> insights;
  final ChartTheme? theme;
  final Function(ChartInsight)? onInsightTap;
  final int maxInsights;

  const CompactChartInsights({
    super.key,
    required this.insights,
    this.theme,
    this.onInsightTap,
    this.maxInsights = 3,
  });

  @override
  Widget build(BuildContext context) {
    final chartTheme = theme ?? ChartThemeProvider.of(context);
    final displayInsights = insights.take(maxInsights).toList();
    
    if (displayInsights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: chartTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: chartTheme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: chartTheme.colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Insights',
                style: chartTheme.textTheme.titleSmall?.copyWith(
                  color: chartTheme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (insights.length > maxInsights) ...[
                const Spacer(),
                Text(
                  '+${insights.length - maxInsights} more',
                  style: chartTheme.textTheme.bodySmall?.copyWith(
                    color: chartTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          ...displayInsights.map((insight) => _buildCompactInsight(insight, chartTheme)),
        ],
      ),
    );
  }

  Widget _buildCompactInsight(ChartInsight insight, ChartTheme theme) {
    return GestureDetector(
      onTap: () => onInsightTap?.call(insight),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(
              _getInsightIcon(insight.type),
              color: _getInsightIconColor(insight.type, theme),
              size: 14,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                insight.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getInsightIconColor(InsightType type, ChartTheme theme) {
    switch (type) {
      case InsightType.positive:
        return Colors.green;
      case InsightType.warning:
        return Colors.orange;
      case InsightType.negative:
        return Colors.red;
      case InsightType.critical:
        return Colors.red.shade700;
      case InsightType.info:
        return theme.colorScheme.primary;
    }
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.positive:
        return Icons.check_circle;
      case InsightType.warning:
        return Icons.warning;
      case InsightType.negative:
        return Icons.error;
      case InsightType.critical:
        return Icons.dangerous;
      case InsightType.info:
        return Icons.info;
    }
  }
} 