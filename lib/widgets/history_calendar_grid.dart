import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../models/transaction_model.dart';

class HistoryCalendarGrid extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Map<DateTime, List<TransactionModel>> transactions;
  final Function(int) onMonthChanged;
  final VoidCallback onMonthYearPicker;
  final Function(DateTime) onDaySelected;

  const HistoryCalendarGrid({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.transactions,
    required this.onMonthChanged,
    required this.onMonthYearPicker,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedDay.year, focusedDay.month, 1);
    final lastDay = DateTime(focusedDay.year, focusedDay.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday;
    final now = DateTime.now();
    final isCurrentMonth =
        focusedDay.year == now.year && focusedDay.month == now.month;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Enhanced Header with Navigation
          _buildCalendarHeader(isCurrentMonth, now),

          // Weekday headers
          _buildWeekdayHeaders(),

          // Calendar days
          _buildCalendarDays(firstWeekday, daysInMonth),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader(bool isCurrentMonth, DateTime now) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // Navigation Row
          Row(
            children: [
              // Previous Month Button
              IconButton(
                onPressed: () => onMonthChanged(-1),
                icon: Icon(
                  Icons.chevron_left,
                  color: AppColors.primary,
                  size: 28,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.8),
                  padding: const EdgeInsets.all(8),
                ),
              ),

              // Month/Year Display (Clickable)
              Expanded(
                child: GestureDetector(
                  onTap: onMonthYearPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy', 'vi_VN').format(focusedDay),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Next Month Button
              IconButton(
                onPressed: () => onMonthChanged(1),
                icon: Icon(
                  Icons.chevron_right,
                  color: AppColors.primary,
                  size: 28,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.8),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),

          // Month Stats & Quick Actions
          Container(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                // Current Month Indicator
                if (isCurrentMonth)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tháng hiện tại',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Transaction Count
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${transactions.values.fold(0, (sum, list) => sum + list.length)} giao dịch',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Today Button
                if (!isCurrentMonth)
                  GestureDetector(
                    onTap: () {
                      final today = DateTime.now();
                      onDaySelected(today);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color:
                                AppColors.primaryDark.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.today,
                            size: 12,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Hôm nay',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
            .map((day) => Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    alignment: Alignment.center,
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCalendarDays(int firstWeekday, int daysInMonth) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
        ),
        itemCount: 42, // 6 weeks
        itemBuilder: (context, index) {
          final dayNumber = index - firstWeekday + 2;
          if (dayNumber < 1 || dayNumber > daysInMonth) {
            return const SizedBox();
          }

          final day = DateTime(focusedDay.year, focusedDay.month, dayNumber);
          return _buildCalendarDay(day);
        },
      ),
    );
  }

  Widget _buildCalendarDay(DateTime day) {
    final dayTransactions = _getTransactionsForDay(day);
    final income = dayTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final expense = dayTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final hasTransactions = income > 0 || expense > 0;
    final isSelected = day.day == selectedDay.day &&
        day.month == selectedDay.month &&
        day.year == selectedDay.year;
    final isToday = day.day == DateTime.now().day &&
        day.month == DateTime.now().month &&
        day.year == DateTime.now().year;

    return GestureDetector(
      onTap: () => onDaySelected(day),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isToday
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : hasTransactions
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : null,
          borderRadius: BorderRadius.circular(8),
          border: hasTransactions
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected || isToday
                    ? Colors.white
                    : AppColors.textPrimary,
              ),
            ),
            if (hasTransactions) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (income > 0)
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (income > 0 && expense > 0) const SizedBox(width: 2),
                  if (expense > 0)
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<TransactionModel> _getTransactionsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return transactions[normalizedDay] ?? [];
  }
}
