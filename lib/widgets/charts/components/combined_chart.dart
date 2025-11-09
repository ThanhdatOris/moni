import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:moni/constants/app_colors.dart';
import '../models/chart_data_model.dart';

class CombinedChart extends StatefulWidget {
  final List<ChartDataModel> incomeData;
  final List<ChartDataModel> expenseData;
  final double size;
  final Function(ChartDataModel, String)? onCategoryTap; // String: 'income' or 'expense'

  const CombinedChart({
    super.key,
    required this.incomeData,
    required this.expenseData,
    required this.size,
    this.onCategoryTap,
  });

  @override
  State<CombinedChart> createState() => _CombinedChartState();
}

class _CombinedChartState extends State<CombinedChart> {
  int _selectedIndex = -1;
  String _selectedType = ''; // 'income' or 'expense'

  @override
  Widget build(BuildContext context) {
    if (widget.incomeData.isEmpty && widget.expenseData.isEmpty) {
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
      child: Row(
        children: [
          // Expense Pie Chart (Left)
          Expanded(
            child: _buildHalfChart(
              data: widget.expenseData,
              title: 'Chi tiêu',
              color: Colors.red,
              type: 'expense',
              isLeft: true,
            ),
          ),
          // Center divider with totals
          _buildCenterDivider(),
          // Income Pie Chart (Right)
          Expanded(
            child: _buildHalfChart(
              data: widget.incomeData,
              title: 'Thu nhập',
              color: Colors.green,
              type: 'income',
              isLeft: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHalfChart({
    required List<ChartDataModel> data,
    required String title,
    required Color color,
    required String type,
    required bool isLeft,
  }) {
    if (data.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'expense' ? Icons.trending_down : Icons.trending_up,
            color: color.withValues(alpha: 0.3),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Không có dữ liệu',
            style: TextStyle(
              color: AppColors.grey500,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // Title
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        // Half Pie Chart
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: _buildHalfPieChartSections(data, color, type),
                  centerSpaceRadius: widget.size * 0.15,
                  sectionsSpace: 1,
                  startDegreeOffset: isLeft ? 90 : -90, // Left: bottom to top, Right: top to bottom
                  pieTouchData: PieTouchData(
                    enabled: true,
                    touchCallback: (event, response) => _handleTouch(event, response, data, type),
                  ),
                ),
              ),
              // Selected item info
              if (_selectedType == type && _selectedIndex >= 0 && _selectedIndex < data.length)
                _buildSelectedInfo(data[_selectedIndex], color),
            ],
          ),
        ),
        // Total amount
        Text(
          '${_formatCurrency(_getTotalAmount(data))}₫',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCenterDivider() {
    final totalIncome = _getTotalAmount(widget.incomeData);
    final totalExpense = _getTotalAmount(widget.expenseData);
    final balance = totalIncome - totalExpense;
    final isPositive = balance >= 0;

    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Balance icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPositive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: isPositive ? Colors.green : Colors.red,
                width: 2,
              ),
            ),
            child: Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              color: isPositive ? Colors.green : Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          // Balance label
          const Text(
            'Chênh lệch',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Balance amount
          Text(
            '${isPositive ? '+' : ''}${_formatCurrency(balance)}₫',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.green : Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Divider line
          Container(
            height: 40,
            width: 1,
            color: AppColors.grey300,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedInfo(ChartDataModel item, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.category,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${item.percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildHalfPieChartSections(List<ChartDataModel> data, Color baseColor, String type) {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isSelected = _selectedType == type && _selectedIndex == index;
      
      return PieChartSectionData(
        value: item.percentage,
        title: isSelected ? '${item.percentage.toStringAsFixed(1)}%' : '',
        color: _parseColor(item.color).withValues(alpha: isSelected ? 1.0 : 0.8),
        radius: isSelected ? widget.size * 0.12 : widget.size * 0.1,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        borderSide: BorderSide(
          color: Colors.white,
          width: isSelected ? 2 : 1,
        ),
      );
    }).toList();
  }

  void _handleTouch(FlTouchEvent event, PieTouchResponse? pieTouchResponse, List<ChartDataModel> data, String type) {
    if (event is FlTapUpEvent && pieTouchResponse?.touchedSection != null) {
      final touchedIndex = pieTouchResponse!.touchedSection!.touchedSectionIndex;
      
      setState(() {
        if (_selectedType == type && _selectedIndex == touchedIndex) {
          _selectedIndex = -1;
          _selectedType = '';
        } else {
          _selectedIndex = touchedIndex;
          _selectedType = type;
          if (touchedIndex < data.length) {
            widget.onCategoryTap?.call(data[touchedIndex], type);
          }
        }
      });
    }
  }

  double _getTotalAmount(List<ChartDataModel> data) {
    return data.fold(0, (total, item) => total + item.amount);
  }

  String _formatCurrency(double amount) {
    return amount.abs().toStringAsFixed(0).replaceAllMapped(
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
