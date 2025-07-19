import 'package:flutter/material.dart';
import '../core/chart_theme.dart';
import '../models/chart_data_models.dart';

/// Interactive tooltip for chart data points
class ChartTooltip extends StatelessWidget {
  final ChartDataPoint dataPoint;
  final Offset position;
  final ChartTheme? theme;
  final bool showDetails;
  final VoidCallback? onTap;

  const ChartTooltip({
    super.key,
    required this.dataPoint,
    required this.position,
    this.theme,
    this.showDetails = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chartTheme = theme ?? ChartThemeProvider.of(context);

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 200),
          decoration: BoxDecoration(
            color: chartTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: chartTheme.colorScheme.shadow.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: chartTheme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: _buildTooltipContent(chartTheme),
        ),
      ),
    );
  }

  Widget _buildTooltipContent(ChartTheme theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(theme),
          if (showDetails) ...[
            const SizedBox(height: 8),
            _buildDetails(theme),
          ],
          if (dataPoint.metadata?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            _buildMetadata(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ChartTheme theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: dataPoint.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            dataPoint.label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDetails(ChartTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Giá trị:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              _formatValue(dataPoint.value),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (dataPoint.date != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ngày:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                _formatDate(dataPoint.date!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
        // Note: percentage is calculated from metadata if available
        if (dataPoint.metadata?['percentage'] != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tỷ lệ:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${(dataPoint.metadata!['percentage'] as double).toStringAsFixed(1)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMetadata(ChartTheme theme) {
    final metadata = dataPoint.metadata;
    if (metadata == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: metadata.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${entry.key}:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Flexible(
                child: Text(
                  entry.value.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M VNĐ';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K VNĐ';
    } else {
      return '${value.toStringAsFixed(0)} VNĐ';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Tooltip overlay widget for managing multiple tooltips
class ChartTooltipOverlay extends StatefulWidget {
  final Widget child;
  final ChartDataPoint? activeDataPoint;
  final Offset? tooltipPosition;
  final bool showTooltip;
  final ChartTheme? theme;

  const ChartTooltipOverlay({
    super.key,
    required this.child,
    this.activeDataPoint,
    this.tooltipPosition,
    this.showTooltip = false,
    this.theme,
  });

  @override
  State<ChartTooltipOverlay> createState() => _ChartTooltipOverlayState();
}

class _ChartTooltipOverlayState extends State<ChartTooltipOverlay> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showTooltip &&
            widget.activeDataPoint != null &&
            widget.tooltipPosition != null)
          ChartTooltip(
            dataPoint: widget.activeDataPoint!,
            position: widget.tooltipPosition!,
            theme: widget.theme,
          ),
      ],
    );
  }
}
