import 'package:flutter/material.dart';

import '../../../constants/enums.dart';
import '../core/chart_theme.dart';
import '../models/chart_data_models.dart';

/// Reusable chart legend component
class ChartLegend extends StatelessWidget {
  final List<ChartSeries> series;
  final LegendPosition position;
  final bool showValues;
  final bool showPercentages;
  final VoidCallback? onSeriesTap;
  final ChartTheme? theme;

  const ChartLegend({
    super.key,
    required this.series,
    this.position = LegendPosition.bottom,
    this.showValues = true,
    this.showPercentages = false,
    this.onSeriesTap,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final chartTheme = theme ?? ChartThemeProvider.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: _buildLegendContent(chartTheme),
    );
  }

  Widget _buildLegendContent(ChartTheme theme) {
    switch (position) {
      case LegendPosition.top:
      case LegendPosition.bottom:
        return _buildHorizontalLegend(theme);
      case LegendPosition.left:
      case LegendPosition.right:
        return _buildVerticalLegend(theme);
      case LegendPosition.topLeft:
      case LegendPosition.topRight:
      case LegendPosition.bottomLeft:
      case LegendPosition.bottomRight:
        return _buildCornerLegend(theme);
    }
  }

  Widget _buildHorizontalLegend(ChartTheme theme) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children:
          series.map((series) => _buildLegendItem(series, theme)).toList(),
    );
  }

  Widget _buildVerticalLegend(ChartTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          series.map((series) => _buildLegendItem(series, theme)).toList(),
    );
  }

  Widget _buildCornerLegend(ChartTheme theme) {
    return Align(
      alignment: _getCornerAlignment(),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              series.map((series) => _buildLegendItem(series, theme)).toList(),
        ),
      ),
    );
  }

  Alignment _getCornerAlignment() {
    switch (position) {
      case LegendPosition.topLeft:
        return Alignment.topLeft;
      case LegendPosition.topRight:
        return Alignment.topRight;
      case LegendPosition.bottomLeft:
        return Alignment.bottomLeft;
      case LegendPosition.bottomRight:
        return Alignment.bottomRight;
      default:
        return Alignment.topLeft;
    }
  }

  Widget _buildLegendItem(ChartSeries series, ChartTheme theme) {
    final total =
        series.data.fold<double>(0, (sum, point) => sum + point.value);

    return GestureDetector(
      onTap: () => onSeriesTap?.call(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: series.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                series.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showValues) ...[
              const SizedBox(width: 8),
              Text(
                _formatValue(total),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (showPercentages) ...[
              const SizedBox(width: 4),
              Text(
                '(${_calculatePercentage(total)}%)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  String _calculatePercentage(double value) {
    final total = series.fold<double>(
        0,
        (sum, series) =>
            sum +
            series.data.fold<double>(0, (sum, point) => sum + point.value));

    if (total == 0) return '0';
    return ((value / total) * 100).toStringAsFixed(1);
  }
}
