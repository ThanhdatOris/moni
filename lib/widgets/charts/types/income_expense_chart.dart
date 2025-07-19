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

/// Income vs Expense comparison chart
class IncomeExpenseChart extends ChartBase {
  final bool showBarChart;
  final bool showLineChart;
  final bool showTrends;
  final Function(ChartDataPoint)? onDataPointTap;

  const IncomeExpenseChart({
    super.key,
    required super.config,
    this.showBarChart = true,
    this.showLineChart = true,
    this.showTrends = false,
    this.onDataPointTap,
    super.onInsightTap,
  });

  @override
  State<IncomeExpenseChart> createState() => _IncomeExpenseChartState();
}

class _IncomeExpenseChartState extends ChartBaseState<IncomeExpenseChart> {
  late ChartController _controller;
  IncomeExpenseAnalysis? _analysis;
  int _selectedChartIndex = 0;
  ChartDataPoint? _activeDataPoint;
  Offset? _tooltipPosition;

  final List<String> _chartTabs = [
    'Biểu đồ cột',
    'Biểu đồ đường',
    'So sánh',
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

  Widget _buildChartTabs(ChartTheme theme) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: _chartTabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == _selectedChartIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedChartIndex = index;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                margin: const EdgeInsets.all(2),
                child: Center(
                  child: Text(
                    tab,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
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
        return _buildBarChart(theme);
      case 1:
        return _buildLineChart(theme);
      case 2:
        return _buildComparisonChart(theme);
      default:
        return _buildBarChart(theme);
    }
  }

  Widget _buildBarChart(ChartTheme theme) {
    final barGroups = _analysis!.data.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.income,
            color: Colors.green,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: data.expense,
            color: Colors.red,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxAmount() * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => theme.colorScheme.surface,
            tooltipBorder: BorderSide(
              color: theme.colorScheme.outline,
            ),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final data = _analysis!.data[group.x];
              final isIncome = rodIndex == 0;
              final amount = isIncome ? data.income : data.expense;
              final label = isIncome ? 'Thu nhập' : 'Chi tiêu';

              return BarTooltipItem(
                '$label\n${_formatCurrency(amount)}',
                TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
          touchCallback: (event, response) {
            if (response?.spot != null) {
              final data =
                  _analysis!.data[response!.spot!.touchedBarGroupIndex];
              final isIncome = response.spot!.touchedBarGroupIndex == 0;

              setState(() {
                _activeDataPoint = ChartDataPoint(
                  label: isIncome ? 'Thu nhập' : 'Chi tiêu',
                  value: isIncome ? data.income : data.expense,
                  color: isIncome ? Colors.green : Colors.red,
                );
                _tooltipPosition = event.localPosition;
              });
            } else {
              setState(() {
                _activeDataPoint = null;
                _tooltipPosition = null;
              });
            }
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= _analysis!.data.length) {
                  return const SizedBox.shrink();
                }
                final data = _analysis!.data[value.toInt()];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _formatDate(data.period),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatCurrency(value),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        barGroups: barGroups,
        gridData: const FlGridData(show: false),
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

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _getMaxAmount() / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= _analysis!.data.length) {
                  return const SizedBox.shrink();
                }
                final data = _analysis!.data[value.toInt()];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _formatDate(data.period),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatCurrency(value),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        minX: 0,
        maxX: (_analysis!.data.length - 1).toDouble(),
        minY: 0,
        maxY: _getMaxAmount() * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: incomeSpots,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withValues(alpha: 0.1),
            ),
          ),
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => theme.colorScheme.surface,
            tooltipBorder: BorderSide(
              color: theme.colorScheme.outline,
            ),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final data = _analysis!.data[touchedSpot.x.toInt()];
                final isIncome = touchedSpot.barIndex == 0;
                final amount = isIncome ? data.income : data.expense;
                final label = isIncome ? 'Thu nhập' : 'Chi tiêu';

                return LineTooltipItem(
                  '$label\n${_formatCurrency(amount)}',
                  TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
          touchCallback: (event, response) {
            if (response?.lineBarSpots != null) {
              final spot = response!.lineBarSpots!.first;
              final data = _analysis!.data[spot.x.toInt()];
              final isIncome = spot.barIndex == 0;

              setState(() {
                _activeDataPoint = ChartDataPoint(
                  label: isIncome ? 'Thu nhập' : 'Chi tiêu',
                  value: isIncome ? data.income : data.expense,
                  color: isIncome ? Colors.green : Colors.red,
                );
                _tooltipPosition = event.localPosition;
              });
            } else {
              setState(() {
                _activeDataPoint = null;
                _tooltipPosition = null;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildComparisonChart(ChartTheme theme) {
    final totalIncome =
        _analysis!.data.fold<double>(0, (sum, data) => sum + data.income);
    final totalExpense =
        _analysis!.data.fold<double>(0, (sum, data) => sum + data.expense);
    final balance = totalIncome - totalExpense;

    return Column(
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Tổng thu nhập',
                totalIncome,
                Colors.green,
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Tổng chi tiêu',
                totalExpense,
                Colors.red,
                theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Balance card
        _buildSummaryCard(
          'Số dư',
          balance,
          balance >= 0 ? Colors.blue : Colors.orange,
          theme,
        ),
        const SizedBox(height: 24),
        // Monthly breakdown
        Expanded(
          child: _buildMonthlyBreakdown(theme),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    Color color,
    ChartTheme theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(amount),
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBreakdown(ChartTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi tiết theo tháng',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _analysis!.data.length,
              itemBuilder: (context, index) {
                final data = _analysis!.data[index];
                final balance = data.income - data.expense;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatDate(data.period),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatCurrency(data.income),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatCurrency(data.expense),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatCurrency(balance),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: balance >= 0 ? Colors.blue : Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              },
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
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân tích',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._analysis!.insights.map((insight) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight.message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
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
            Icons.trending_up_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Không có dữ liệu thu chi',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm giao dịch để xem biểu đồ thu chi',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget _buildLegend(ChartTheme theme) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem('Thu nhập', Colors.green, theme),
          const SizedBox(width: 24),
          _buildLegendItem('Chi tiêu', Colors.red, theme),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, ChartTheme theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  double _getMaxAmount() {
    if (_analysis == null || _analysis!.data.isEmpty) return 0;

    double maxAmount = 0;
    for (final data in _analysis!.data) {
      maxAmount = max(maxAmount, max(data.income, data.expense));
    }
    return maxAmount;
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)}đ';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.year}';
  }
}
