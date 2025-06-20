import 'package:intl/intl.dart';

class DateHelper {
  static final DateFormat _dayFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _fullFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _monthYearFormat = DateFormat('MM/yyyy');
  static final DateFormat _yearFormat = DateFormat('yyyy');
  
  /// Format ngày theo định dạng dd/MM/yyyy
  static String formatDate(DateTime date) {
    return _dayFormat.format(date);
  }
  
  /// Format giờ theo định dạng HH:mm
  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }
  
  /// Format ngày giờ đầy đủ theo định dạng dd/MM/yyyy HH:mm
  static String formatDateTime(DateTime date) {
    return _fullFormat.format(date);
  }
  
  /// Format tháng năm theo định dạng MM/yyyy
  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }
  
  /// Format năm theo định dạng yyyy
  static String formatYear(DateTime date) {
    return _yearFormat.format(date);
  }
  
  /// Lấy ngày đầu tháng
  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
  
  /// Lấy ngày cuối tháng
  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }
  
  /// Lấy ngày đầu tuần (Thứ 2)
  static DateTime getStartOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }
  
  /// Lấy ngày cuối tuần (Chủ nhật)
  static DateTime getEndOfWeek(DateTime date) {
    final startOfWeek = getStartOfWeek(date);
    return startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  }
  
  /// Lấy ngày đầu quý
  static DateTime getStartOfQuarter(DateTime date) {
    final quarter = ((date.month - 1) ~/ 3) + 1;
    final startMonth = (quarter - 1) * 3 + 1;
    return DateTime(date.year, startMonth, 1);
  }
  
  /// Lấy ngày cuối quý
  static DateTime getEndOfQuarter(DateTime date) {
    final quarter = ((date.month - 1) ~/ 3) + 1;
    final endMonth = quarter * 3;
    return DateTime(date.year, endMonth + 1, 0, 23, 59, 59);
  }
  
  /// Lấy ngày đầu năm
  static DateTime getStartOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }
  
  /// Lấy ngày cuối năm
  static DateTime getEndOfYear(DateTime date) {
    return DateTime(date.year, 12, 31, 23, 59, 59);
  }
  
  /// Kiểm tra xem ngày có phải hôm nay không
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
  
  /// Kiểm tra xem ngày có phải hôm qua không
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }
  
  /// Lấy text hiển thị thân thiện cho ngày
  /// Ví dụ: "Hôm nay", "Hôm qua", "2 ngày trước", "dd/MM/yyyy"
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
  
  /// Lấy range ngày theo loại period
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
}

/// Class đại diện cho một khoảng thời gian
class DateRange {
  final DateTime start;
  final DateTime end;
  
  DateRange({required this.start, required this.end});
  
  /// Kiểm tra xem một ngày có nằm trong khoảng không
  bool contains(DateTime date) {
    return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
           date.isBefore(end.add(const Duration(seconds: 1)));
  }
  
  /// Lấy số ngày trong khoảng
  int get dayCount {
    return end.difference(start).inDays + 1;
  }
  
  @override
  String toString() {
    return '${DateHelper.formatDate(start)} - ${DateHelper.formatDate(end)}';
  }
} 