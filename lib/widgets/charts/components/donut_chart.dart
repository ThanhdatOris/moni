import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:moni/constants/app_colors.dart';
import '../models/chart_data_model.dart';

class DonutChart extends StatefulWidget {
  final List<ChartDataModel> data;
  final double size;
  final Function(ChartDataModel)? onCategoryTap;

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
  int _selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return SizedBox(
        height: widget.size,
        child: const Center(
          child: Text(
            'Không có dữ liệu',
            style: TextStyle(color: AppColors.grey600),
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.size,
      width: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // PieChart from fl_chart
          PieChart(
            PieChartData(
              sections: _buildPieChartSections(),
              centerSpaceRadius:
                  widget.size * 0.3, // 30% of size for center space
              sectionsSpace: 2, // Gap between sections
              startDegreeOffset: -90, // Start from top
              pieTouchData: PieTouchData(
                enabled: true,
                touchCallback: _handleTouch,
                mouseCursorResolver: (event, pieTouchResponse) {
                  return pieTouchResponse?.touchedSection != null
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic;
                },
              ),
            ),
          ),
          // Center content
          _buildCenterContent(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    return widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isSelected = _selectedIndex == index;

      return PieChartSectionData(
        value: item.percentage,
        title: isSelected ? '${item.percentage.toStringAsFixed(1)}%' : '',
        color: _parseColor(item.color),
        radius: isSelected
            ? widget.size * 0.2 + 10
            : widget.size * 0.2, // 20% of size + selection effect
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6,
        borderSide: BorderSide(
          color: Colors.white,
          width: isSelected ? 3 : 1,
        ),
      );
    }).toList();
  }

  Widget _buildCenterContent() {
    final selectedItem =
        _selectedIndex >= 0 && _selectedIndex < widget.data.length
            ? widget.data[_selectedIndex]
            : null;

    if (selectedItem != null) {
      return Container(
        width: widget.size * 0.6,
        height: widget.size * 0.6,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              selectedItem.category,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${selectedItem.percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_formatCurrency(selectedItem.amount)}₫',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: widget.size * 0.6,
      height: widget.size * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
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
          const SizedBox(height: 4),
          const Text(
            'Nhấn để xem chi tiết',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.grey500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleTouch(FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
    if (event is FlTapUpEvent && pieTouchResponse?.touchedSection != null) {
      final touchedIndex =
          pieTouchResponse!.touchedSection!.touchedSectionIndex;

      setState(() {
        if (_selectedIndex == touchedIndex) {
          _selectedIndex = -1; // Deselect if already selected
        } else {
          _selectedIndex = touchedIndex;
          if (touchedIndex < widget.data.length) {
            widget.onCategoryTap?.call(widget.data[touchedIndex]);
          }
        }
      });
    }
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

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return AppColors.grey400;
    }
  }
}
