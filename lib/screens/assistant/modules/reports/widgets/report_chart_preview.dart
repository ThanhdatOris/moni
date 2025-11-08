import 'package:flutter/material.dart';

import '../../../../../constants/app_colors.dart';
import '../../../../../widgets/charts/components/donut_chart.dart';
import '../../../../../widgets/charts/models/chart_data_model.dart';
import '../../../widgets/assistant_chart_container.dart';

/// Mini chart previews for report sections
class ReportChartPreview extends StatelessWidget {
  final ChartPreviewData chartData;
  final ChartType chartType;
  final bool isInteractive;
  final double height;
  final VoidCallback? onTap;

  const ReportChartPreview({
    super.key,
    required this.chartData,
    required this.chartType,
    this.isInteractive = true,
    this.height = 200,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isInteractive ? onTap : null,
      child: AssistantChartContainer(
        chart: _buildChart(),
        title: chartData.title,
        subtitle: chartData.subtitle,
        height: height,
        // Loại padding nội dung ở subtab export để khớp layout chặt hơn
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildChart() {
    switch (chartType) {
      case ChartType.donut:
        return _buildDonutChart();
      case ChartType.bar:
        return _buildBarChart();
      case ChartType.line:
        return _buildLineChart();
      case ChartType.combined:
        return _buildCombinedChart();
    }
  }

  Widget _buildDonutChart() {
    final chartDataItems = chartData.data.map((item) {
      return ChartDataModel(
        category: item.label,
        amount: item.value,
        color: item.color,
        percentage: item.percentage ?? (item.value / chartData.total * 100),
        icon: '📊',
        type: 'expense',
      );
    }).toList();

    return DonutChart(
      data: chartDataItems,
      size: height - 50,
    );
  }

  Widget _buildBarChart() {
    return Container(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: chartData.data.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final maxValue = chartData.data
                    .map((e) => e.value)
                    .reduce((a, b) => a > b ? a : b);
                final barHeight = (item.value / maxValue) * 120;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      item.value.toStringAsFixed(0),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 500 + (index * 100)),
                      width: 20,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: _parseColor(item.color),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 30,
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 9,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return Container(
      padding: EdgeInsets.zero,
      child: CustomPaint(
        size: Size.infinite,
        painter: LineChartPainter(
          data: chartData.data,
          color: _parseColor(chartData.primaryColor ?? '#FFA726'),
        ),
      ),
    );
  }

  Widget _buildCombinedChart() {
    // Simplified combined chart using bar chart for preview
    return _buildBarChart();
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }
}

/// Custom line chart painter for simple line charts
class LineChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final Color color;

  LineChartPainter({
    required this.data,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minValue = data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final valueRange = maxValue - minValue;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y =
          size.height - ((data[i].value - minValue) / valueRange) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      // Draw points
      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()..color = color,
      );
    }

    // Close fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw fill and line
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// Chart preview data model
class ChartPreviewData {
  final String title;
  final String? subtitle;
  final List<ChartDataPoint> data;
  final List<ChartDataPoint>? lineData;
  final double total;
  final String? centerText;
  final String? primaryColor;
  final bool showLabels;
  final bool showPercentages;

  ChartPreviewData({
    required this.title,
    this.subtitle,
    required this.data,
    this.lineData,
    required this.total,
    this.centerText,
    this.primaryColor,
    this.showLabels = true,
    this.showPercentages = true,
  });

  static ChartPreviewData createSampleData(ChartType type) {
    final sampleData = [
      ChartDataPoint(label: 'Ăn uống', value: 8000000, color: '#FF7043'),
      ChartDataPoint(label: 'Di chuyển', value: 3000000, color: '#42A5F5'),
      ChartDataPoint(label: 'Mua sắm', value: 5000000, color: '#66BB6A'),
      ChartDataPoint(label: 'Giải trí', value: 2000000, color: '#AB47BC'),
    ];

    switch (type) {
      case ChartType.donut:
        return ChartPreviewData(
          title: 'Phân bổ chi tiêu',
          subtitle: 'Theo danh mục',
          data: sampleData,
          total: 18000000,
          centerText: '18M',
        );

      case ChartType.bar:
        return ChartPreviewData(
          title: 'Chi tiêu theo tháng',
          subtitle: '6 tháng gần nhất',
          data: [
            ChartDataPoint(label: 'T7', value: 15000000, color: '#FFA726'),
            ChartDataPoint(label: 'T8', value: 18000000, color: '#FFA726'),
            ChartDataPoint(label: 'T9', value: 16000000, color: '#FFA726'),
            ChartDataPoint(label: 'T10', value: 20000000, color: '#FFA726'),
            ChartDataPoint(label: 'T11', value: 17000000, color: '#FFA726'),
            ChartDataPoint(label: 'T12', value: 19000000, color: '#FFA726'),
          ],
          total: 105000000,
        );

      case ChartType.line:
        return ChartPreviewData(
          title: 'Xu hướng tiết kiệm',
          subtitle: 'Theo tháng',
          data: [
            ChartDataPoint(label: 'T7', value: 2000000, color: '#4CAF50'),
            ChartDataPoint(label: 'T8', value: 2500000, color: '#4CAF50'),
            ChartDataPoint(label: 'T9', value: 3000000, color: '#4CAF50'),
            ChartDataPoint(label: 'T10', value: 2800000, color: '#4CAF50'),
            ChartDataPoint(label: 'T11', value: 3500000, color: '#4CAF50'),
            ChartDataPoint(label: 'T12', value: 4000000, color: '#4CAF50'),
          ],
          total: 17800000,
          primaryColor: '#4CAF50',
        );

      case ChartType.combined:
        return ChartPreviewData(
          title: 'Thu chi và tăng trưởng',
          subtitle: 'So sánh theo tháng',
          data: sampleData,
          lineData: [
            ChartDataPoint(label: 'T7', value: 5, color: '#FF5722'),
            ChartDataPoint(label: 'T8', value: 8, color: '#FF5722'),
            ChartDataPoint(label: 'T9', value: 12, color: '#FF5722'),
            ChartDataPoint(label: 'T10', value: 15, color: '#FF5722'),
          ],
          total: 18000000,
        );
    }
  }
}

/// Chart data point model
class ChartDataPoint {
  final String label;
  final double value;
  final String color;
  final double? percentage;

  ChartDataPoint({
    required this.label,
    required this.value,
    required this.color,
    this.percentage,
  });
}

/// Chart types
enum ChartType {
  donut,
  bar,
  line,
  combined,
}
