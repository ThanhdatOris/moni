import 'package:intl/intl.dart';

/// Utility class để format date
class DateFormatter {
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _timeFormat = DateFormat('HH:mm');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  /// Format ngày
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Format thời gian
  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  /// Format ngày và thời gian
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

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
}
