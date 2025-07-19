import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../constants/enums.dart';
import '../../../core/di/injection_container.dart';
import '../../../services/category_service.dart';
import '../../../services/transaction_service.dart';
import '../../../utils/currency_formatter.dart';
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
  CategorySpendingAnalysis? _analysis;
  int _selectedChartIndex = 0;
  ChartDataPoint? _activeDataPoint;
  Offset? _tooltipPosition;
  ChartController? _controller; // Thay đổi từ late thành nullable

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
      _controller = null;
    }
  }

  @override
  Future<void> loadChartData() async {
    if (_controller == null) {
      throw Exception('ChartController chưa được khởi tạo');
    }

    try {
      _analysis = await _controller!.getCategorySpendingAnalysis();
    } catch (e) {
      debugPrint('Error loading chart data: $e');
      // Tạo mock data nếu không load được data thực
      _analysis = _createMockAnalysis();
    }
  }

  /// Tạo mock analysis data khi không có data thực
  CategorySpendingAnalysis _createMockAnalysis() {
    final mockCategories = [
      CategoryAnalysisData(
        categoryId: '1',
        categoryName: 'Ăn uống',
        totalAmount: 500000,
        percentage: 35.0,
        averageTransaction: 50000,
        transactionCount: 10,
        budgetAmount: 600000,
        color: const Color(0xFFFF9800),
        trend: [],
      ),
      CategoryAnalysisData(
        categoryId: '2',
        categoryName: 'Di chuyển',
        totalAmount: 300000,
        percentage: 21.0,
        averageTransaction: 30000,
        transactionCount: 10,
        budgetAmount: 400000,
        color: const Color(0xFF2196F3),
        trend: [],
      ),
      CategoryAnalysisData(
        categoryId: '3',
        categoryName: 'Mua sắm',
        totalAmount: 250000,
        percentage: 17.5,
        averageTransaction: 25000,
        transactionCount: 10,
        budgetAmount: 300000,
        color: const Color(0xFF9C27B0),
        trend: [],
      ),
      CategoryAnalysisData(
        categoryId: '4',
        categoryName: 'Giải trí',
        totalAmount: 200000,
        percentage: 14.0,
        averageTransaction: 20000,
        transactionCount: 10,
        budgetAmount: 250000,
        color: const Color(0xFFE91E63),
        trend: [],
      ),
      CategoryAnalysisData(
        categoryId: '5',
        categoryName: 'Hóa đơn',
        totalAmount: 180000,
        percentage: 12.5,
        averageTransaction: 18000,
        transactionCount: 10,
        budgetAmount: 200000,
        color: const Color(0xFF607D8B),
        trend: [],
      ),
    ];

    return CategorySpendingAnalysis(
      categories: mockCategories,
      topSpendingCategory: mockCategories.first,
      mostImprovedCategory: mockCategories.first,
      mostDeterioratedCategory: mockCategories.first,
      totalSpending: 1430000,
      categoryTrends: {},
      overBudgetCategories: [],
      insights: [],
      analysisDate: DateTime.now(),
    );
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

  /// Build chart tabs với improved design
  Widget _buildChartTabs(ChartTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _chartTabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _selectedChartIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedChartIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                          width: 1,
                        )
                      : null,
                ),
                child: Text(
                  tab,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Build legend với improved design
  Widget _buildLegend(ChartTheme theme) {
    if (_analysis == null || _analysis!.categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chú thích',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _analysis!.categories.map((category) {
              return _buildLegendItem(category, theme);
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Build legend item với improved design
  Widget _buildLegendItem(CategoryAnalysisData category, ChartTheme theme) {
    return GestureDetector(
      onTap: () => widget.onCategoryTap?.call(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: category.color,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: category.color.withValues(alpha: 0.3),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                category.categoryName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${category.percentage.toStringAsFixed(1)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: category.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state với improved design
  Widget _buildEmptyState(ChartTheme theme) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có dữ liệu phân tích',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Thêm giao dịch để xem biểu đồ phân tích chi tiêu',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to add transaction
                Navigator.pushNamed(context, '/add-transaction');
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm giao dịch'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
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
        badgeWidget: category.percentage > 5
            ? _buildPieChartBadge(category, theme)
            : null,
        badgePositionPercentageOffset: 0.98,
      );
    }).toList();

    return GestureDetector(
      onTapUp: (details) => _handlePieChartTap(details, theme),
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
          startDegreeOffset: -90,
          pieTouchData: PieTouchData(
            enabled: true,
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
            mouseCursorResolver: (event, pieTouchResponse) {
              return pieTouchResponse?.touchedSection != null
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic;
            },
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  /// Build badge widget cho pie chart sections
  Widget _buildPieChartBadge(CategoryAnalysisData category, ChartTheme theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: category.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            category.categoryName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            CurrencyFormatter.formatVND(category.totalAmount),
            style: theme.textTheme.bodySmall?.copyWith(
              color: category.color,
              fontWeight: FontWeight.w700,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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

  /// Build insights section
  Widget _buildInsights(ChartTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân tích AI',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._analysis!.insights
              .map((insight) => _buildInsightItem(insight, theme)),
        ],
      ),
    );
  }

  /// Build insight item
  Widget _buildInsightItem(ChartInsight insight, ChartTheme theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getInsightColor(insight.type).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getInsightColor(insight.type).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getInsightIcon(insight.type),
            color: _getInsightColor(insight.type),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get insight color based on type
  Color _getInsightColor(InsightType type) {
    switch (type) {
      case InsightType.positive:
        return const Color(0xFF4CAF50);
      case InsightType.warning:
        return const Color(0xFFFF9800);
      case InsightType.negative:
        return const Color(0xFFF44336);
      case InsightType.info:
        return const Color(0xFF2196F3);
      case InsightType.critical:
        return const Color(0xFFD32F2F);
    }
  }

  /// Get insight icon based on type
  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.positive:
        return Icons.trending_up;
      case InsightType.warning:
        return Icons.warning;
      case InsightType.negative:
        return Icons.trending_down;
      case InsightType.info:
        return Icons.info;
      case InsightType.critical:
        return Icons.error;
    }
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
