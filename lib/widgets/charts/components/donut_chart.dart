import 'dart:math';

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../models/chart_data_model.dart';

class DonutChart extends StatefulWidget {
  final List<ChartDataModel> data;
  final double size;
  final VoidCallback? onCategoryTap;

  const DonutChart({
    super.key,
    required this.data,
    required this.size,
    this.onCategoryTap,
  });

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> {
  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return SizedBox(
        height: widget.size,
        child: const Center(
          child: Text('Không có dữ liệu'),
        ),
      );
    }

    return SizedBox(
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Chart
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: DonutChartPainter(widget.data),
          ),
          // Center text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Tổng',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatCurrency(_getTotalAmount())}₫',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _getTotalAmount() {
    return widget.data.fold(0, (total, item) => total + item.amount);
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<ChartDataModel> data;

  DonutChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.6;
    final strokeWidth = radius - innerRadius;

    double startAngle = -pi / 2; // Start from top

    for (final item in data) {
      final sweepAngle = (item.percentage / 100) * 2 * pi;

      // Draw arc
      final paint = Paint()
        ..color = _parseColor(item.color)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return AppColors.grey400;
    }
  }
}
