import 'package:intl/intl.dart';

/// Unified date formatting utility
/// Combines functionality from DateFormatter and DateHelper
class DateFormatter {
  // Format patterns
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _monthYearFormat = DateFormat('MM/yyyy');
  static final DateFormat _yearFormat = DateFormat('yyyy');
  static final DateFormat _dayOfWeekFormat = DateFormat('EEEE', 'vi_VN');

  // ===== BASIC FORMATTING =====

  /// Format date as dd/MM/yyyy
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Format time as HH:mm
  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  /// Format date and time as dd/MM/yyyy HH:mm
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Format month and year as MM/yyyy
  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  /// Format year as yyyy
  static String formatYear(DateTime date) {
    return _yearFormat.format(date);
  }

  /// Format day of week in Vietnamese
  static String formatDayOfWeek(DateTime date) {
    return _dayOfWeekFormat.format(date);
  }

  // ===== RELATIVE TIME FORMATTING =====

  /// Format relative time (1 giờ trước, 2 ngày trước, v.v.)
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  /// Get friendly date text (Hôm nay, Hôm qua, etc.)
  static String getRelativeDateText(DateTime date) {
    if (isToday(date)) {
      return 'Hôm nay';
    } else if (isYesterday(date)) {
      return 'Hôm qua';
    } else {
      final now = DateTime.now();
      final difference = now.difference(date).inDays;

      if (difference > 0 && difference < 7) {
        return '$difference ngày trước';
      } else if (difference < 0 && difference > -7) {
        return '${-difference} ngày nữa';
      } else {
        return formatDate(date);
      }
    }
  }

  // ===== DATE RANGE UTILITIES =====

  /// Get start of month
  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of month
  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  /// Get start of week (Monday)
  static DateTime getStartOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  /// Get end of week (Sunday)
  static DateTime getEndOfWeek(DateTime date) {
    final startOfWeek = getStartOfWeek(date);
    return startOfWeek
        .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  }

  /// Get start of quarter
  static DateTime getStartOfQuarter(DateTime date) {
    final quarter = ((date.month - 1) ~/ 3) + 1;
    final startMonth = (quarter - 1) * 3 + 1;
    return DateTime(date.year, startMonth, 1);
  }

  /// Get end of quarter
  static DateTime getEndOfQuarter(DateTime date) {
    final quarter = ((date.month - 1) ~/ 3) + 1;
    final endMonth = quarter * 3;
    return DateTime(date.year, endMonth + 1, 0, 23, 59, 59);
  }

  /// Get start of year
  static DateTime getStartOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  /// Get end of year
  static DateTime getEndOfYear(DateTime date) {
    return DateTime(date.year, 12, 31, 23, 59, 59);
  }

  // ===== DATE COMPARISON =====

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Check if date is in the future
  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  /// Check if date is in the past
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  // ===== PERIOD RANGES =====

  /// Get date range by period type
  static DateRange getDateRangeByPeriod(String period) {
    final now = DateTime.now();

    switch (period) {
      case 'Tuần này':
        return DateRange(
          start: getStartOfWeek(now),
          end: getEndOfWeek(now),
        );
      case 'Tháng này':
        return DateRange(
          start: getStartOfMonth(now),
          end: getEndOfMonth(now),
        );
      case 'Quý này':
        return DateRange(
          start: getStartOfQuarter(now),
          end: getEndOfQuarter(now),
        );
      case 'Năm nay':
        return DateRange(
          start: getStartOfYear(now),
          end: getEndOfYear(now),
        );
      default:
        return DateRange(
          start: getStartOfMonth(now),
          end: getEndOfMonth(now),
        );
    }
  }

  /// Get date range for last N days
  static DateRange getLastNDays(int days) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days - 1));
    return DateRange(
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  /// Get date range for current month
  static DateRange getCurrentMonth() {
    final now = DateTime.now();
    return DateRange(
      start: getStartOfMonth(now),
      end: getEndOfMonth(now),
    );
  }

  /// Get date range for current year
  static DateRange getCurrentYear() {
    final now = DateTime.now();
    return DateRange(
      start: getStartOfYear(now),
      end: getEndOfYear(now),
    );
  }

  // ===== VALIDATION =====

  /// Validate if date is valid for transactions (not in future)
  static bool isValidTransactionDate(DateTime date) {
    return !isFuture(date);
  }

  /// Get days difference between two dates
  static int getDaysDifference(DateTime date1, DateTime date2) {
    final d1 = DateTime(date1.year, date1.month, date1.day);
    final d2 = DateTime(date2.year, date2.month, date2.day);
    return d2.difference(d1).inDays;
  }

  /// Get months difference between two dates
  static int getMonthsDifference(DateTime date1, DateTime date2) {
    return (date2.year - date1.year) * 12 + (date2.month - date1.month);
  }

  /// Get years difference between two dates
  static int getYearsDifference(DateTime date1, DateTime date2) {
    return date2.year - date1.year;
  }
}

/// Unified DateRange class
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  /// Check if a date is within this range
  bool contains(DateTime date) {
    return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
        date.isBefore(end.add(const Duration(seconds: 1)));
  }

  /// Get number of days in this range
  int get dayCount {
    return end.difference(start).inDays + 1;
  }

  /// Get number of months in this range
  int get monthCount {
    return DateFormatter.getMonthsDifference(start, end) + 1;
  }

  /// Get display text for this range
  String get displayText {
    if (DateFormatter.isToday(start) && DateFormatter.isToday(end)) {
      return 'Hôm nay';
    } else if (DateFormatter.isYesterday(start) &&
        DateFormatter.isYesterday(end)) {
      return 'Hôm qua';
    } else if (start.year == end.year && start.month == end.month) {
      return '${start.day} - ${end.day}/${end.month}/${end.year}';
    } else if (start.year == end.year) {
      return '${start.day}/${start.month} - ${end.day}/${end.month}/${end.year}';
    } else {
      return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
    }
  }

  /// Get short display text
  String get shortDisplayText {
    if (DateFormatter.isToday(start) && DateFormatter.isToday(end)) {
      return 'Hôm nay';
    } else if (DateFormatter.isYesterday(start) &&
        DateFormatter.isYesterday(end)) {
      return 'Hôm qua';
    } else if (start.year == end.year && start.month == end.month) {
      return '${start.day} - ${end.day}/${end.month}';
    } else if (start.year == end.year) {
      return '${start.day}/${start.month} - ${end.day}/${end.month}';
    } else {
      return '${start.day}/${start.month} - ${end.day}/${end.month}';
    }
  }

  @override
  String toString() {
    return '${DateFormatter.formatDate(start)} - ${DateFormatter.formatDate(end)}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateRange &&
        start.isAtSameMomentAs(other.start) &&
        end.isAtSameMomentAs(other.end);
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}
