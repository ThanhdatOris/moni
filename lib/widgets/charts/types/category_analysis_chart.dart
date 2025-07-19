import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/di/injection_container.dart';
import '../../../services/category_service.dart';
import '../../../services/transaction_service.dart';
import '../components/chart_tooltip.dart';
import '../core/chart_base.dart';
import '../core/chart_controller.dart';
import '../core/chart_theme.dart';
import '../models/analysis_models.dart';
import '../models/chart_data_models.dart';

/// Category analysis chart for spending breakdown
class CategoryAnalysisChart extends ChartBase {
  final bool showPieChart;
  final bool showBarChart;
  final bool showTrends;
  final Function(CategoryAnalysisData)? onCategoryTap;

  const CategoryAnalysisChart({
    super.key,
    required super.config,
    this.showPieChart = true,
    this.showBarChart = true,
    this.showTrends = false,
    this.onCategoryTap,
    super.onDataPointTap,
    super.onInsightTap,
  });

  @override
  State<CategoryAnalysisChart> createState() => _CategoryAnalysisChartState();
}

class _CategoryAnalysisChartState
    extends ChartBaseState<CategoryAnalysisChart> {
  late ChartController _controller;
  CategorySpendingAnalysis? _analysis;
  int _selectedChartIndex = 0;
  ChartDataPoint? _activeDataPoint;
  Offset? _tooltipPosition;

  final List<String> _chartTabs = [
    'Biểu đồ tròn',
    'Biểu đồ cột',
    'Xu hướng',
  ];

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    try {
      _controller = ChartController(
        transactionService: getIt<TransactionService>(),
        categoryService: getIt<CategoryService>(),
        initialFilter: widget.config.filter,
      );
    } catch (e) {
      // Handle initialization error
      debugPrint('ChartController initialization error: $e');
    }
  }

  @override
  Future<void> loadChartData() async {
    _analysis = await _controller.getCategorySpendingAnalysis();
  }

  @override
  Widget buildChart(BuildContext context, ChartTheme theme) {
    if (_analysis == null || _analysis!.categories.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Column(
      children: [
        _buildChartTabs(theme),
        const SizedBox(height: 16),
        Expanded(
          child: ChartTooltipOverlay(
            activeDataPoint: _activeDataPoint,
            tooltipPosition: _tooltipPosition,
            showTooltip: _activeDataPoint != null,
            theme: theme,
            child: _buildSelectedChart(theme),
          ),
        ),
        if (widget.showTrends && _analysis!.insights.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildInsights(theme),
        ],
      ],
    );
  }

  @override
  Widget _buildLegend(ChartTheme theme) {
    if (_analysis == null || _analysis!.categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Danh mục chi tiêu',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: _analysis!.categories.map((category) {
              return _buildLegendItem(category, theme);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(CategoryAnalysisData category, ChartTheme theme) {
    return GestureDetector(
      onTap: () => widget.onCategoryTap?.call(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                color: category.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                category.categoryName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${category.percentage.toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ChartTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Không có dữ liệu danh mục',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm giao dịch để xem phân tích danh mục',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChartTabs(ChartTheme theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: _chartTabs.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          final isSelected = _selectedChartIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedChartIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedChart(ChartTheme theme) {
    switch (_selectedChartIndex) {
      case 0:
        return widget.showPieChart
            ? _buildPieChart(theme)
            : _buildEmptyState(theme);
      case 1:
        return widget.showBarChart
            ? _buildBarChart(theme)
            : _buildEmptyState(theme);
      case 2:
        return widget.showTrends
            ? _buildTrendChart(theme)
            : _buildEmptyState(theme);
      default:
        return _buildEmptyState(theme);
    }
  }

  Widget _buildPieChart(ChartTheme theme) {
    final sections = _analysis!.categories.map((category) {
      return PieChartSectionData(
        value: category.totalAmount,
        title: category.percentage > 5
            ? '${category.percentage.toStringAsFixed(1)}%'
            : '',
        color: category.color,
        radius: 80,
        titleStyle: theme.textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();

    return GestureDetector(
      onTapUp: (details) => _handlePieChartTap(details, theme),
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              if (event is! FlTapUpEvent) return;

              final touchedSection = pieTouchResponse?.touchedSection;
              if (touchedSection != null &&
                  touchedSection.touchedSectionIndex <
                      _analysis!.categories.length) {
                final category =
                    _analysis!.categories[touchedSection.touchedSectionIndex];
                widget.onCategoryTap?.call(category);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(ChartTheme theme) {
    final barGroups = _analysis!.categories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: category.totalAmount,
            color: category.color,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatAmount(value),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < _analysis!.categories.length) {
                  final category = _analysis!.categories[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      category.categoryName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 1000000,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            if (barTouchResponse?.spot != null) {
              final spot = barTouchResponse!.spot!;
              final touchedIndex = spot.touchedBarGroupIndex;
              if (touchedIndex < _analysis!.categories.length) {
                final category = _analysis!.categories[touchedIndex];
                widget.onCategoryTap?.call(category);
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildTrendChart(ChartTheme theme) {
    // Implementation for trend chart would go here
    return Center(
      child: Text(
        'Biểu đồ xu hướng đang phát triển',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildInsights(ChartTheme theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân tích nhanh',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ..._analysis!.insights.take(3).map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  void _handlePieChartTap(TapUpDetails details, ChartTheme theme) {
    // Calculate which section was tapped
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    // Simple tap detection - in a real implementation, you'd calculate the exact section
    final center = renderBox.size.center(Offset.zero);
    final distance = (localPosition - center).distance;

    if (distance > 40 && distance < 120) {
      // Approximate section detection
      final angle = (localPosition - center).direction;
      final sectionIndex =
          ((angle + pi) / (2 * pi) * _analysis!.categories.length).floor();

      if (sectionIndex >= 0 && sectionIndex < _analysis!.categories.length) {
        final category = _analysis!.categories[sectionIndex];
        widget.onCategoryTap?.call(category);
      }
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}
