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

        return Column(
          children: [
            // Transaction Type Filter Section
            _buildTransactionTypeFilter(isCompact),

            // Date Filter Section
            _buildDateFilter(isCompact),
          ],
        );
      },
    );
  }

  /// Build date filter section
  Widget _buildDateFilter(bool isCompact) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
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
              size: 18,
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
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 12,
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
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  /// Build transaction type filter section
  Widget _buildTransactionTypeFilter(bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
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
        margin: const EdgeInsets.all(1.5),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
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
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
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
              size: 16,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
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
