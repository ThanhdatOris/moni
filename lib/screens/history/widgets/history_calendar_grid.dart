import 'package:flutter/material.dart';

import 'package:moni/config/app_config.dart';

import '../../../models/transaction_model.dart';

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

          // Calendar Footer
          _buildCalendarFooter(isCurrentMonth),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader(bool isCurrentMonth, DateTime now) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.primaryDark.withValues(alpha: 0.8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Previous Month Button
          IconButton(
            onPressed: () => onMonthChanged(-1),
            icon: Icon(
              Icons.chevron_left,
              color: Colors.white,
              size: 24,
            ),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
          ),

          const SizedBox(width: 8),

          // Month/Year Display
          Expanded(
            child: GestureDetector(
              onTap: onMonthYearPicker,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tháng ${focusedDay.month} - ${focusedDay.year}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Next Month Button
          IconButton(
            onPressed: () => onMonthChanged(1),
            icon: Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 24,
            ),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarFooter(bool isCurrentMonth) {
    final now = DateTime.now();
    final isTodaySelected = selectedDay.year == now.year &&
        selectedDay.month == now.month &&
        selectedDay.day == now.day;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Interactive Buttons Section
          Expanded(
            child: Row(
              children: [
                // Current Month Indicator or Navigation Button
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
                  )
                else
                  // Navigation to Current Month Button
                  GestureDetector(
                    onTap: () {
                      //final currentMonth = DateTime(now.year, now.month, 1);
                      // Trigger month change to current month
                      final monthDiff = (now.year - focusedDay.year) * 12 +
                          (now.month - focusedDay.month);
                      onMonthChanged(monthDiff);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.home,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Về tháng hiện tại',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const Spacer(),

                // Today Button (show when not today is selected)
                if (!isTodaySelected)
                  GestureDetector(
                    onTap: () {
                      final today = DateTime.now();
                      // First navigate to current month if not already there
                      if (!isCurrentMonth) {
                        final monthDiff = (today.year - focusedDay.year) * 12 +
                            (today.month - focusedDay.month);
                        onMonthChanged(monthDiff);
                      }
                      // Then select today's date
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

          // Vertical Divider
          if (transactions.values.fold(0, (count, list) => count + list.length) >
              0) ...[
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: Colors.grey.withValues(alpha: 0.2),
            ),

            // Transaction Count Info
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${transactions.values.fold(0, (count, list) => count + list.length)} giao dịch',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
        .fold(0.0, (total, t) => total + t.amount);
    final expense = dayTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (total, t) => total + t.amount);
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
