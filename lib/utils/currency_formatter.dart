import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat('#,###', 'vi_VN');

  /// Format số tiền thành chuỗi với dấu phẩy ngăn cách
  /// Ví dụ: 1000000 -> "1,000,000"
  static String formatAmount(double amount) {
    return _formatter.format(amount);
  }

  /// Format số tiền thành chuỗi với đơn vị VNĐ
  /// Ví dụ: 1000000 -> "1,000,000đ"
  static String formatAmountWithCurrency(double amount) {
    return '${formatAmount(amount)}đ';
  }

  /// Format số tiền với dấu + hoặc - tùy theo loại giao dịch
  /// Ví dụ: 1000000, true -> "+1,000,000đ"
  static String formatAmountWithSign(double amount, bool isIncome) {
    final formattedAmount = formatAmountWithCurrency(amount);
    return isIncome ? '+$formattedAmount' : '-$formattedAmount';
  }

  /// Parse chuỗi số tiền về double
  /// Ví dụ: "1,000,000" -> 1000000.0
  static double parseAmount(String amountString) {
    // Loại bỏ dấu phẩy và ký tự không phải số
    final cleanString = amountString.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanString) ?? 0.0;
  }

  /// Format số tiền rút gọn cho hiển thị
  /// Ví dụ: 1000000 -> "1M", 1500000 -> "1.5M"
  static String formatAmountShort(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  /// Format số tiền với đơn vị VNĐ (alias for formatAmountWithCurrency)
  /// Ví dụ: 1000000 -> "1,000,000đ"
  static String formatVND(double amount) {
    return formatAmountWithCurrency(amount);
  }
}
