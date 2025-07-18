/// Period Selector Widget - Cho phép chọn khoảng thời gian phân tích
/// Được tách từ AnalyticsScreen để cải thiện maintainability

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

class PeriodSelectorWidget extends StatelessWidget {
  final String selectedPeriod;
  final List<String> periods;
  final ValueChanged<String> onPeriodChanged;

  const PeriodSelectorWidget({
    super.key,
    required this.selectedPeriod,
    required this.periods,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.date_range, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedPeriod,
                onChanged: (value) {
                  if (value != null) {
                    onPeriodChanged(value);
                  }
                },
                items: periods.map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(
                      period,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.primary,
                ),
                dropdownColor: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                elevation: 8,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Cập nhật',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Default periods for analytics
class AnalyticsPeriods {
  static const List<String> defaultPeriods = [
    'Tuần này',
    'Tháng này', 
    'Quý này',
    'Năm nay',
    '7 ngày qua',
    '30 ngày qua',
    '90 ngày qua',
  ];

  static const Map<String, int> periodToDays = {
    'Tuần này': 7,
    'Tháng này': 30,
    'Quý này': 90,
    'Năm nay': 365,
    '7 ngày qua': 7,
    '30 ngày qua': 30,
    '90 ngày qua': 90,
  };

  /// Get number of days for a period
  static int getDaysForPeriod(String period) {
    return periodToDays[period] ?? 30;
  }

  /// Get date range for a period
  static DateRange getDateRangeForPeriod(String period) {
    final now = DateTime.now();
    late DateTime startDate;
    late DateTime endDate;

    switch (period) {
      case 'Tuần này':
        final weekday = now.weekday;
        startDate = now.subtract(Duration(days: weekday - 1));
        endDate = now;
        break;
      case 'Tháng này':
        startDate = DateTime(now.year, now.month, 1);
        endDate = now;
        break;
      case 'Quý này':
        final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        startDate = DateTime(now.year, quarterStartMonth, 1);
        endDate = now;
        break;
      case 'Năm nay':
        startDate = DateTime(now.year, 1, 1);
        endDate = now;
        break;
      default:
        final days = getDaysForPeriod(period);
        startDate = now.subtract(Duration(days: days));
        endDate = now;
    }

    return DateRange(startDate, endDate);
  }
}

class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  const DateRange(this.startDate, this.endDate);

  /// Get number of days in this range
  int get days => endDate.difference(startDate).inDays + 1;

  /// Check if a date is within this range
  bool contains(DateTime date) {
    return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
           date.isBefore(endDate.add(const Duration(days: 1)));
  }

  /// Get display text for this range
  String get displayText {
    final format = 'dd/MM';
    final startStr = '${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}';
    final endStr = '${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}';
    
    if (startDate.year != endDate.year) {
      return '$startStr/${startDate.year} - $endStr/${endDate.year}';
    } else if (startDate.month != endDate.month || startDate.day != endDate.day) {
      return '$startStr - $endStr';
    } else {
      return startStr;
    }
  }
} 