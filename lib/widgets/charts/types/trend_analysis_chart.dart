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

/// Trend analysis chart for spending patterns
class TrendAnalysisChart extends ChartBase {
  final bool showLineChart;
  final bool showAreaChart;
  final bool showPredictions;
  final Function(ChartDataPoint)? onDataPointTap;

  const TrendAnalysisChart({
    super.key,
    required super.config,
    this.showLineChart = true,
    this.showAreaChart = true,
    this.showPredictions = false,
    this.onDataPointTap,
    super.onInsightTap,
  });

  @override
  State<TrendAnalysisChart> createState() => _TrendAnalysisChartState();
}

class _TrendAnalysisChartState extends ChartBaseState<TrendAnalysisChart> {
  late ChartController _controller;
  SpendingPatternAnalysis? _analysis;
  int _selectedChartIndex = 0;
  ChartDataPoint? _activeDataPoint;
  Offset? _tooltipPosition;

  final List<String> _chartTabs = [
    'Xu hướng',
    'Vùng',
    'Dự đoán',
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
    _analysis = await _controller.getSpendingPatternAnalysis();
  }

  @override
  Widget buildChart(BuildContext context, ChartTheme theme) {
    if (_analysis == null) {
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
        return _buildTrendLineChart(theme);
      case 1:
        return _buildAreaChart(theme);
      case 2:
        return _buildPredictionChart(theme);
      default:
        return _buildTrendLineChart(theme);
    }
  }

  Widget _buildTrendLineChart(ChartTheme theme) {
    // Generate mock trend data for demonstration
    final trendData = _generateMockTrendData();

    final spots = trendData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _getMaxAmount(trendData) / 5,
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
                if (value.toInt() >= trendData.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'T${value.toInt() + 1}',
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
        maxX: (trendData.length - 1).toDouble(),
        minY: 0,
        maxY: _getMaxAmount(trendData) * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                final amount = trendData[touchedSpot.x.toInt()];

                return LineTooltipItem(
                  'Chi tiêu\n${_formatCurrency(amount)}',
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
              final amount = trendData[spot.x.toInt()];

              setState(() {
                _activeDataPoint = ChartDataPoint(
                  label: 'Chi tiêu',
                  value: amount,
                  color: theme.colorScheme.primary,
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

  Widget _buildAreaChart(ChartTheme theme) {
    // Generate mock area data for demonstration
    final areaData = _generateMockAreaData();

    final incomeSpots = areaData['income']!.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    final expenseSpots = areaData['expense']!.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _getMaxAmount(areaData['income']!) / 5,
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
                if (value.toInt() >= areaData['income']!.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'T${value.toInt() + 1}',
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
        maxX: (areaData['income']!.length - 1).toDouble(),
        minY: 0,
        maxY: _getMaxAmount(areaData['income']!) * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: incomeSpots,
            isCurved: true,
            color: Colors.green,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withValues(alpha: 0.3),
            ),
          ),
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            color: Colors.red,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withValues(alpha: 0.3),
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
                final isIncome = touchedSpot.barIndex == 0;
                final amount = isIncome
                    ? areaData['income']![touchedSpot.x.toInt()]
                    : areaData['expense']![touchedSpot.x.toInt()];
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
              final isIncome = spot.barIndex == 0;
              final amount = isIncome
                  ? areaData['income']![spot.x.toInt()]
                  : areaData['expense']![spot.x.toInt()];

              setState(() {
                _activeDataPoint = ChartDataPoint(
                  label: isIncome ? 'Thu nhập' : 'Chi tiêu',
                  value: amount,
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

  Widget _buildPredictionChart(ChartTheme theme) {
    // Generate mock prediction data for demonstration
    final predictionData = _generateMockPredictionData();

    final historicalSpots =
        predictionData['historical']!.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    final predictionSpots =
        predictionData['prediction']!.asMap().entries.map((entry) {
      return FlSpot(
          (entry.key + predictionData['historical']!.length).toDouble(),
          entry.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _getMaxAmount(predictionData['historical']!) / 5,
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
                final totalLength = predictionData['historical']!.length +
                    predictionData['prediction']!.length;
                if (value.toInt() >= totalLength) {
                  return const SizedBox.shrink();
                }
                final isPrediction =
                    value.toInt() >= predictionData['historical']!.length;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    isPrediction
                        ? 'P${value.toInt() - predictionData['historical']!.length + 1}'
                        : 'T${value.toInt() + 1}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isPrediction
                          ? Colors.orange
                          : theme.colorScheme.onSurfaceVariant,
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
        maxX: (predictionData['historical']!.length +
                predictionData['prediction']!.length -
                1)
            .toDouble(),
        minY: 0,
        maxY: _getMaxAmount(predictionData['historical']!) * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: historicalSpots,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: false,
            ),
          ),
          LineChartBarData(
            spots: predictionSpots,
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: false,
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
                final isPrediction = touchedSpot.barIndex == 1;
                final amount = isPrediction
                    ? predictionData['prediction']![touchedSpot.x.toInt() -
                        predictionData['historical']!.length]
                    : predictionData['historical']![touchedSpot.x.toInt()];
                final label = isPrediction ? 'Dự đoán' : 'Lịch sử';

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
              final isPrediction = spot.barIndex == 1;
              final amount = isPrediction
                  ? predictionData['prediction']![
                      spot.x.toInt() - predictionData['historical']!.length]
                  : predictionData['historical']![spot.x.toInt()];

              setState(() {
                _activeDataPoint = ChartDataPoint(
                  label: isPrediction ? 'Dự đoán' : 'Lịch sử',
                  value: amount,
                  color:
                      isPrediction ? Colors.orange : theme.colorScheme.primary,
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
            'Phân tích xu hướng',
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
                    Icons.trending_up,
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
            Icons.analytics_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Không có dữ liệu xu hướng',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm giao dịch để xem phân tích xu hướng',
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
          _buildLegendItem('Xu hướng', theme.colorScheme.primary, theme),
          const SizedBox(width: 24),
          if (_selectedChartIndex == 1) ...[
            _buildLegendItem('Thu nhập', Colors.green, theme),
            const SizedBox(width: 24),
            _buildLegendItem('Chi tiêu', Colors.red, theme),
          ] else if (_selectedChartIndex == 2) ...[
            _buildLegendItem('Lịch sử', theme.colorScheme.primary, theme),
            const SizedBox(width: 24),
            _buildLegendItem('Dự đoán', Colors.orange, theme),
          ],
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

  // Mock data generation methods
  List<double> _generateMockTrendData() {
    final random = Random(42); // Fixed seed for consistent data
    final data = <double>[];
    double currentValue = 500000; // 500k VND starting point

    for (int i = 0; i < 12; i++) {
      // Add some trend with random variation
      currentValue += (random.nextDouble() - 0.5) * 100000;
      currentValue =
          currentValue.clamp(200000, 800000); // Keep within reasonable bounds
      data.add(currentValue);
    }

    return data;
  }

  Map<String, List<double>> _generateMockAreaData() {
    final random = Random(42);
    final incomeData = <double>[];
    final expenseData = <double>[];
    double incomeValue = 800000;
    double expenseValue = 500000;

    for (int i = 0; i < 12; i++) {
      incomeValue += (random.nextDouble() - 0.5) * 150000;
      expenseValue += (random.nextDouble() - 0.5) * 100000;

      incomeValue = incomeValue.clamp(600000, 1200000);
      expenseValue = expenseValue.clamp(300000, 700000);

      incomeData.add(incomeValue);
      expenseData.add(expenseValue);
    }

    return {
      'income': incomeData,
      'expense': expenseData,
    };
  }

  Map<String, List<double>> _generateMockPredictionData() {
    final random = Random(42);
    final historicalData = <double>[];
    final predictionData = <double>[];
    double currentValue = 500000;

    // Generate historical data
    for (int i = 0; i < 8; i++) {
      currentValue += (random.nextDouble() - 0.5) * 100000;
      currentValue = currentValue.clamp(300000, 700000);
      historicalData.add(currentValue);
    }

    // Generate prediction data with trend
    double trend =
        (historicalData.last - historicalData.first) / historicalData.length;
    for (int i = 0; i < 4; i++) {
      currentValue += trend + (random.nextDouble() - 0.5) * 50000;
      currentValue = currentValue.clamp(250000, 750000);
      predictionData.add(currentValue);
    }

    return {
      'historical': historicalData,
      'prediction': predictionData,
    };
  }

  double _getMaxAmount(List<double> data) {
    if (data.isEmpty) return 0;
    return data.reduce(max);
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)}đ';
  }
}
