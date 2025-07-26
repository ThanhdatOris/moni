import '../formatting/date_formatter.dart';

/// Date extensions for convenient methods
extension DateExtensions on DateTime {
  /// Check if date is today
  bool get isToday => DateFormatter.isToday(this);

  /// Check if date is yesterday
  bool get isYesterday => DateFormatter.isYesterday(this);

  /// Check if date is in the future
  bool get isFuture => DateFormatter.isFuture(this);

  /// Check if date is in the past
  bool get isPast => DateFormatter.isPast(this);

  /// Check if date is valid for transactions (not in future)
  bool get isValidTransactionDate => DateFormatter.isValidTransactionDate(this);

  /// Format as dd/MM/yyyy
  String get formatDate => DateFormatter.formatDate(this);

  /// Format as HH:mm
  String get formatTime => DateFormatter.formatTime(this);

  /// Format as dd/MM/yyyy HH:mm
  String get formatDateTime => DateFormatter.formatDateTime(this);

  /// Format as MM/yyyy
  String get formatMonthYear => DateFormatter.formatMonthYear(this);

  /// Format as yyyy
  String get formatYear => DateFormatter.formatYear(this);

  /// Format as day of week in Vietnamese
  String get formatDayOfWeek => DateFormatter.formatDayOfWeek(this);

  /// Format as relative time (1 giờ trước, 2 ngày trước, v.v.)
  String get formatRelativeTime => DateFormatter.formatRelativeTime(this);

  /// Get friendly date text (Hôm nay, Hôm qua, etc.)
  String get relativeDateText => DateFormatter.getRelativeDateText(this);

  /// Get start of month
  DateTime get startOfMonth => DateFormatter.getStartOfMonth(this);

  /// Get end of month
  DateTime get endOfMonth => DateFormatter.getEndOfMonth(this);

  /// Get start of week (Monday)
  DateTime get startOfWeek => DateFormatter.getStartOfWeek(this);

  /// Get end of week (Sunday)
  DateTime get endOfWeek => DateFormatter.getEndOfWeek(this);

  /// Get start of quarter
  DateTime get startOfQuarter => DateFormatter.getStartOfQuarter(this);

  /// Get end of quarter
  DateTime get endOfQuarter => DateFormatter.getEndOfQuarter(this);

  /// Get start of year
  DateTime get startOfYear => DateFormatter.getStartOfYear(this);

  /// Get end of year
  DateTime get endOfYear => DateFormatter.getEndOfYear(this);

  /// Get days difference from another date
  int daysDifferenceFrom(DateTime other) {
    return DateFormatter.getDaysDifference(other, this);
  }

  /// Get months difference from another date
  int monthsDifferenceFrom(DateTime other) {
    return DateFormatter.getMonthsDifference(other, this);
  }

  /// Get years difference from another date
  int yearsDifferenceFrom(DateTime other) {
    return DateFormatter.getYearsDifference(other, this);
  }

  /// Add days and return new DateTime
  DateTime addDays(int days) {
    return add(Duration(days: days));
  }

  /// Subtract days and return new DateTime
  DateTime subtractDays(int days) {
    return subtract(Duration(days: days));
  }

  /// Add months and return new DateTime
  DateTime addMonths(int months) {
    final newMonth = month + months;
    final newYear = year + (newMonth - 1) ~/ 12;
    final adjustedMonth = ((newMonth - 1) % 12) + 1;
    return DateTime(newYear, adjustedMonth, day);
  }

  /// Subtract months and return new DateTime
  DateTime subtractMonths(int months) {
    return addMonths(-months);
  }

  /// Add years and return new DateTime
  DateTime addYears(int years) {
    return DateTime(year + years, month, day);
  }

  /// Subtract years and return new DateTime
  DateTime subtractYears(int years) {
    return DateTime(year - years, month, day);
  }

  /// Get age in years from this date
  int get age {
    final now = DateTime.now();
    int age = now.year - year;
    if (now.month < month || (now.month == month && now.day < day)) {
      age--;
    }
    return age;
  }

  /// Check if this date is in the same day as another date
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Check if this date is in the same month as another date
  bool isSameMonth(DateTime other) {
    return year == other.year && month == other.month;
  }

  /// Check if this date is in the same year as another date
  bool isSameYear(DateTime other) {
    return year == other.year;
  }

  /// Get the day of the week (1 = Monday, 7 = Sunday)
  int get dayOfWeek => weekday;

  /// Check if this is a weekend (Saturday or Sunday)
  bool get isWeekend =>
      weekday == DateTime.saturday || weekday == DateTime.sunday;

  /// Check if this is a weekday (Monday to Friday)
  bool get isWeekday => !isWeekend;

  /// Get the quarter of the year (1-4)
  int get quarter => ((month - 1) ~/ 3) + 1;

  /// Get the week of the year
  int get weekOfYear {
    final startOfYear = DateTime(year, 1, 1);
    final daysSinceStart = difference(startOfYear).inDays;
    return ((daysSinceStart + startOfYear.weekday - 1) ~/ 7) + 1;
  }
}
