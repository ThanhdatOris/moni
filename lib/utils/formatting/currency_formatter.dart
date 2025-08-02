import 'package:flutter/services.dart';
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
      return '${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  /// Format số tiền với đơn vị VNĐ (alias for formatAmountWithCurrency)
  /// Ví dụ: 1000000 -> "1,000,000đ"
  static String formatVND(double amount) {
    return formatAmountWithCurrency(amount);
  }

  /// Format currency (alias for formatAmountWithCurrency)
  /// Ví dụ: 1000000 -> "1,000,000đ"
  static String formatCurrency(double amount) {
    return formatAmountWithCurrency(amount);
  }

  // ===== INPUT FORMATTING METHODS =====

  /// Lấy raw value (số nguyên) từ formatted text
  /// Ví dụ: "1,000,000" -> 1000000
  static int getRawValue(String formattedText) {
    if (formattedText.isEmpty) return 0;
    final digitsOnly = formattedText.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digitsOnly) ?? 0;
  }

  /// Format raw value thành display text
  /// Ví dụ: 1000000 -> "1,000,000"
  static String formatDisplay(int rawValue) {
    if (rawValue == 0) return '';
    return _formatter.format(rawValue);
  }

  /// Parse amount từ formatted text về double
  /// Ví dụ: "1,000,000" -> 1000000.0
  static double parseFormattedAmount(String formattedText) {
    return getRawValue(formattedText).toDouble();
  }

  /// Validate amount string
  /// Trả về true nếu string có thể parse thành số hợp lệ
  static bool isValidAmount(String amountString) {
    if (amountString.isEmpty) return false;
    final rawValue = getRawValue(amountString);
    return rawValue > 0;
  }

  /// Format amount cho input field với validation
  /// Trả về formatted string hoặc empty string nếu không hợp lệ
  static String formatForInput(dynamic amount) {
    if (amount == null) return '';

    int safeAmount;
    if (amount is int) {
      safeAmount = amount;
    } else if (amount is double) {
      safeAmount = amount.toInt();
    } else if (amount is String) {
      safeAmount = int.tryParse(amount) ?? 0;
    } else {
      safeAmount = 0;
    }

    return formatDisplay(safeAmount);
  }
}

/// Custom TextInputFormatter cho currency input
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Sử dụng tryParse thay vì parse để tránh FormatException
    final num = int.tryParse(digitsOnly);
    if (num == null) {
      return oldValue; // Giữ lại giá trị cũ nếu parse thất bại
    }

    final formatted = CurrencyFormatter.formatDisplay(num);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
