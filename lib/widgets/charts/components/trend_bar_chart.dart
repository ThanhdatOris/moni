import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../models/chart_data_model.dart';

class TrendBarChart extends StatefulWidget {
  final List<TrendData> data;
  final double height;
  final Function(TrendData)? onBarTap;

  const TrendBarChart({
    super.key,
    required this.data,
    required this.height,
    this.onBarTap,
  });

  @override
  State<TrendBarChart> createState() => _TrendBarChartState();
}

class _TrendBarChartState extends State<TrendBarChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text(
            'Không có dữ liệu',
            style: TextStyle(color: AppColors.grey600),
          ),
        ),
      );
    }

    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 16),
          // Chart
          Expanded(
            child: _buildChart(),
          ),
          // Selected item info
          if (_selectedIndex != null) _buildSelectedItemInfo(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.trending_up,
          color: AppColors.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        const Text(
          'Xu hướng thu chi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (_selectedIndex != null)
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = null;
              });
            },
            child: const Icon(
              Icons.close,
              size: 16,
              color: AppColors.grey600,
            ),
          )
        else
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.grey600,
          ),
      ],
    );
  }

  Widget _buildChart() {
    final maxY = _getMaxValue();
    
    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        barGroups: _buildBarGroups(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.grey300,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatCompactCurrency(value),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.grey600,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < widget.data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.data[index].label,
                      style: TextStyle(
                        fontSize: 11,
                        color: _selectedIndex == index ? AppColors.primary : AppColors.grey600,
                        fontWeight: _selectedIndex == index ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: _handleTouch,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.black87,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = widget.data[groupIndex];
              final isIncome = rodIndex == 0;
              final value = isIncome ? item.income : item.expense;
              final label = isIncome ? 'Thu nhập' : 'Chi tiêu';
              
              return BarTooltipItem(
                '$label\n${_formatCurrency(value)}₫',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isSelected = _selectedIndex == index;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          // Income bar
          BarChartRodData(
            toY: item.income,
            color: Colors.green.withValues(
              alpha: isSelected ? 1.0 : 0.7,
            ),
            width: isSelected ? 12 : 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          // Expense bar
          BarChartRodData(
            toY: item.expense,
            color: AppColors.primary.withValues(
              alpha: isSelected ? 1.0 : 0.7,
            ),
            width: isSelected ? 12 : 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        barsSpace: 4,
      );
    }).toList();
  }

  Widget _buildSelectedItemInfo() {
    if (_selectedIndex == null || _selectedIndex! >= widget.data.length) {
      return const SizedBox.shrink();
    }
    
    final selectedItem = widget.data[_selectedIndex!];
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi tiết ${selectedItem.label}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (selectedItem.income > 0) 
                _buildDetailItem(
                  'Thu nhập',
                  selectedItem.income,
                  Colors.green,
                  Icons.trending_up,
                ),
              if (selectedItem.expense > 0)
                _buildDetailItem(
                  'Chi tiêu',
                  selectedItem.expense,
                  AppColors.primary,
                  Icons.trending_down,
                ),
              _buildDetailItem(
                'Chênh lệch',
                selectedItem.income - selectedItem.expense,
                selectedItem.income >= selectedItem.expense ? Colors.green : AppColors.error,
                selectedItem.income >= selectedItem.expense ? Icons.add : Icons.remove,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, double amount, Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${amount >= 0 ? '' : '-'}${_formatCurrency(amount.abs())}₫',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  void _handleTouch(FlTouchEvent event, BarTouchResponse? barTouchResponse) {
    if (event is FlTapUpEvent && barTouchResponse?.spot != null) {
      final touchedIndex = barTouchResponse!.spot!.touchedBarGroupIndex;
      
      setState(() {
        if (_selectedIndex == touchedIndex) {
          _selectedIndex = null; // Deselect if already selected
        } else {
          _selectedIndex = touchedIndex;
          if (touchedIndex < widget.data.length) {
            widget.onBarTap?.call(widget.data[touchedIndex]);
          }
        }
      });
    }
  }

  double _getMaxValue() {
    double maxValue = 0;
    for (final item in widget.data) {
      final max = [item.expense, item.income].reduce((a, b) => a > b ? a : b);
      if (max > maxValue) maxValue = max;
    }
    return maxValue > 0 ? maxValue * 1.1 : 100; // Add 10% padding
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatCompactCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
