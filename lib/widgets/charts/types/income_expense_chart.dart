import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../services/category_service.dart';
import '../../../services/transaction_service.dart';
import '../../../utils/currency_formatter.dart';
import '../core/chart_base.dart';
import '../core/chart_controller.dart';
import '../core/chart_theme.dart';
import '../models/analysis_models.dart';
import '../models/chart_data_models.dart';

/// Advanced Income vs Expense chart with multiple visualization modes
class IncomeExpenseChart extends ChartBase {
  final IncomeExpenseChartMode mode;
  final bool showComparison;
  final bool showTrends;
  final bool showProjections;

  const IncomeExpenseChart({
    super.key,
    required super.config,
    this.mode = IncomeExpenseChartMode.monthly,
    this.showComparison = true,
    this.showTrends = false,
    this.showProjections = false,
    super.onTap,
    super.onDataPointTap,
    super.onInsightTap,
  });

  @override
  State<IncomeExpenseChart> createState() => _IncomeExpenseChartState();
}

enum IncomeExpenseChartMode {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
}

class _IncomeExpenseChartState extends ChartBaseState<IncomeExpenseChart> {
  late ChartController _controller;
  IncomeExpenseAnalysis? _analysis;
  int _selectedTabIndex = 0;

  final List<String> _chartTabs = [
    'Bar Chart',
    'Line Chart',
    'Area Chart',
    'Comparison',
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
    _analysis = await _controller.getIncomeExpenseAnalysis();
  }

  @override
  Widget buildChart(BuildContext context, ChartTheme theme) {
    if (_analysis == null || _analysis!.data.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Column(
      children: [
        _buildChartTabs(theme),
        const SizedBox(height: 16),
        Expanded(child: _buildSelectedChart(theme)),
        if (widget.showTrends) ...[
          const SizedBox(height: 16),
          _buildTrendIndicators(theme),
        ],
        if (_analysis!.insights.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildInsights(theme),
        ],
      ],
    );
  }

  Widget _buildChartTabs(ChartTheme theme) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: List.generate(_chartTabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
                animateChart();
              },
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    _chartTabs[index],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectedChart(ChartTheme theme) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildBarChart(theme);
      case 1:
        return _buildLineChart(theme);
      case 2:
        return _buildAreaChart(theme);
      case 3:
        return _buildComparisonChart(theme);
      default:
        return _buildBarChart(theme);
    }
  }

  Widget _buildBarChart(ChartTheme theme) {
    final data = _prepareBarChartData();

    return Container(
      decoration: BoxDecoration(
        color: theme.defaultStyle.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          maxY: _getMaxValue() * 1.1,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => theme.colorScheme.surface,
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final value = rod.toY;
                final isIncome = rodIndex == 0;
                final type = isIncome ? 'Income' : 'Expense';
                return BarTooltipItem(
                  '$type\n${CurrencyFormatter.formatAmountWithCurrency(value)}',
                  TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            touchCallback: (FlTouchEvent event, barTouchResponse) {
              if (barTouchResponse?.spot != null &&
                  widget.onDataPointTap != null) {
                final spot = barTouchResponse!.spot!;
                final touchedIndex = spot.touchedBarGroupIndex;
                if (touchedIndex < _analysis!.data.length) {
                  final monthData = _analysis!.data[touchedIndex];
                  final isIncome = spot.touchedRodDataIndex == 0;

                  widget.onDataPointTap!(ChartDataPoint(
                    label: '${monthData.period.month}/${monthData.period.year}',
                    value: isIncome ? monthData.income : monthData.expense,
                    date: monthData.period,
                    metadata: {
                      'type': isIncome ? 'income' : 'expense',
                      'month': monthData.period,
                    },
                  ));
                }
              }
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < _analysis!.data.length) {
                    final monthData = _analysis!.data[index];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${monthData.period.month}/${monthData.period.year.toString().substring(2)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  return Text(
                    CurrencyFormatter.formatAmountShort(value),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: data,
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: _getMaxValue() / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(ChartTheme theme) {
    final incomeSpots = _analysis!.data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.income);
    }).toList();

    final expenseSpots = _analysis!.data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.expense);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.defaultStyle.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          maxY: _getMaxValue() * 1.1,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => theme.colorScheme.surface,
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final isIncome = spot.barIndex == 0;
                  final type = isIncome ? 'Income' : 'Expense';
                  final color =
                      isIncome ? theme.incomeColor : theme.expenseColor;

                  return LineTooltipItem(
                    '$type\n${CurrencyFormatter.formatAmountWithCurrency(spot.y)}',
                    TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < _analysis!.data.length) {
                    final monthData = _analysis!.data[index];
                    return Text(
                      '${monthData.period.month}/${monthData.period.year.toString().substring(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  return Text(
                    CurrencyFormatter.formatAmount(value),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: _getMaxValue() / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
          ),
          lineBarsData: [
            // Income line
            LineChartBarData(
              spots: incomeSpots,
              isCurved: true,
              color: theme.incomeColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: theme.incomeColor,
                    strokeWidth: 2,
                    strokeColor: theme.colorScheme.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
            ),
            // Expense line
            LineChartBarData(
              spots: expenseSpots,
              isCurved: true,
              color: theme.expenseColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: theme.expenseColor,
                    strokeWidth: 2,
                    strokeColor: theme.colorScheme.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaChart(ChartTheme theme) {
    final incomeSpots = _analysis!.data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.income);
    }).toList();

    final expenseSpots = _analysis!.data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.expense);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.defaultStyle.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          maxY: _getMaxValue() * 1.1,
          lineTouchData: LineTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < _analysis!.data.length) {
                    final monthData = _analysis!.data[index];
                    return Text(
                      '${monthData.period.month}/${monthData.period.year.toString().substring(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  return Text(
                    CurrencyFormatter.formatAmount(value),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: _getMaxValue() / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
          ),
          lineBarsData: [
            // Income area
            LineChartBarData(
              spots: incomeSpots,
              isCurved: true,
              color: theme.incomeColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: theme.incomeColor.withValues(alpha: 0.3),
              ),
            ),
            // Expense area
            LineChartBarData(
              spots: expenseSpots,
              isCurved: true,
              color: theme.expenseColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: theme.expenseColor.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonChart(ChartTheme theme) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: _buildBarChart(theme),
        ),
        const SizedBox(height: 16),
        Expanded(
          flex: 2,
          child: _buildSummaryCards(theme),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(ChartTheme theme) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Income',
            _analysis!.totalIncome,
            theme.incomeColor,
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Total Expense',
            _analysis!.totalExpense,
            theme.expenseColor,
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Net Income',
            _analysis!.netIncome,
            _analysis!.netIncome >= 0 ? theme.successColor : theme.errorColor,
            theme,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, double amount, Color color, ChartTheme theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.formatAmountWithCurrency(amount),
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicators(ChartTheme theme) {
    return Row(
      children: [
        Expanded(
          child: _buildTrendIndicator(
            'Income Trend',
            _analysis!.incomeTrend,
            theme.incomeColor,
            theme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTrendIndicator(
            'Expense Trend',
            _analysis!.expenseTrend,
            theme.expenseColor,
            theme,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendIndicator(
    String title,
    TrendAnalysisData trend,
    Color color,
    ChartTheme theme,
  ) {
    final isPositive = trend.isIncreasing;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;
    final trendColor = isPositive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: trendColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  '${trend.trendPercentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsights(ChartTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insights',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._analysis!.insights
              .take(3)
              .map((insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => handleInsightTap(insight),
                      child: Row(
                        children: [
                          Icon(
                            insight.typeIcon,
                            color: insight.typeColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              insight.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ChartTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No income or expense data available',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some transactions to see your financial analysis',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _prepareBarChartData() {
    return _analysis!.data.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.income,
            color: AppColors.income,
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: data.expense,
            color: AppColors.expense,
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxValue() {
    if (_analysis?.data.isEmpty ?? true) return 100;

    double maxValue = 0;
    for (final data in _analysis!.data) {
      maxValue =
          [maxValue, data.income, data.expense].reduce((a, b) => a > b ? a : b);
    }
    return maxValue;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
