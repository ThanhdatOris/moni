import 'package:flutter/material.dart';

import 'package:moni/constants/app_colors.dart';

class ChartFilter extends StatefulWidget {
  final DateTime selectedDate;
  final String selectedTransactionType;
  final bool isLoading;
  final Function(DateTime) onDateChanged;
  final Function(String) onTransactionTypeChanged;

  const ChartFilter({
    super.key,
    required this.selectedDate,
    required this.selectedTransactionType,
    this.isLoading = false,
    required this.onDateChanged,
    required this.onTransactionTypeChanged,
  });

  @override
  State<ChartFilter> createState() => _ChartFilterState();
}

class _ChartFilterState extends State<ChartFilter> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                AppColors.grey100,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Date Filter Section
              _buildDateFilter(isCompact),

              // Transaction Type Filter Section
              _buildTransactionTypeFilter(isCompact),
            ],
          ),
        );
      },
    );
  }

  /// Build date filter section
  Widget _buildDateFilter(bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          GestureDetector(
            onTap: _previousMonth,
            child: const Icon(
              Icons.chevron_left,
              color: Colors.white,
              size: 20,
            ),
          ),

          // Current month display
          GestureDetector(
            onTap: _showDatePicker,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_getMonthName(widget.selectedDate.month)} - ${widget.selectedDate.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),

          // Next button
          GestureDetector(
            onTap: _nextMonth,
            child: const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// Build transaction type filter section
  Widget _buildTransactionTypeFilter(bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [          
          // Filter options
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.grey200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Tất cả
                Expanded(
                  child: _buildModernFilterButton(
                    'Tất cả',
                    Icons.analytics_outlined,
                    AppColors.primary,
                    widget.selectedTransactionType == 'all',
                    () => widget.onTransactionTypeChanged('all'),
                  ),
                ),

                // Chi tiêu
                Expanded(
                  child: _buildModernFilterButton(
                    'Chi tiêu',
                    Icons.trending_down,
                    Colors.red,
                    widget.selectedTransactionType == 'expense',
                    () => widget.onTransactionTypeChanged('expense'),
                  ),
                ),

                // Thu nhập
                Expanded(
                  child: _buildModernFilterButton(
                    'Thu nhập',
                    Icons.trending_up,
                    Colors.green,
                    widget.selectedTransactionType == 'income',
                    () => widget.onTransactionTypeChanged('income'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFilterButton(
    String title,
    IconData icon,
    Color color,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    color,
                    color.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : color,
              size: 18,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  void _previousMonth() {
    final newDate =
        DateTime(widget.selectedDate.year, widget.selectedDate.month - 1);
    widget.onDateChanged(newDate);
  }

  void _nextMonth() {
    final newDate =
        DateTime(widget.selectedDate.year, widget.selectedDate.month + 1);
    widget.onDateChanged(newDate);
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      final newDate = DateTime(picked.year, picked.month);
      widget.onDateChanged(newDate);
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12'
    ];
    return months[month - 1];
  }
}
