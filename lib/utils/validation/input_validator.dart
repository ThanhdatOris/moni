import 'package:flutter/material.dart';
import 'package:moni/constants/enums.dart';

/// Extension for PasswordStrength color (requires Flutter)
extension PasswordStrengthColorExtension on PasswordStrength {
  Color get color {
    switch (this) {
      case PasswordStrength.none:
        return Colors.grey;
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.yellow;
      case PasswordStrength.veryStrong:
        return Colors.green;
    }
  }
}

/// Centralized input validation utilities
class InputValidator {
  // Email validation
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
  );

  // Phone validation (Vietnamese format)
  static final RegExp _phoneRegex = RegExp(
    r'^(0|\+84)(\s|\.)?((3[2-9])|(5[689])|(7[06-9])|(8[1-689])|(9[0-46-9]))(\d)(\s|\.)?(\d{3})(\s|\.)?(\d{3})$',
  );

  // Password validation
  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$',
  );

  // Amount validation
  static final RegExp _amountRegex = RegExp(r'^[0-9,]+(\.[0-9]{1,2})?$');

  // Name validation
  static final RegExp _nameRegex = RegExp(r'^[a-zA-ZÀ-ỹ\s]{2,50}$');

  // Note validation
  static final RegExp _noteRegex = RegExp(r'^[a-zA-ZÀ-ỹ0-9\s.,!?-]{0,500}$');

  /// Validate email format
  static bool isValidEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    return _emailRegex.hasMatch(email.trim());
  }

  /// Validate phone number (Vietnamese format)
  static bool isValidPhone(String? phone) {
    if (phone == null || phone.isEmpty) return false;
    return _phoneRegex.hasMatch(phone.trim());
  }

  /// Validate password strength
  static bool isValidPassword(String? password) {
    if (password == null || password.isEmpty) return false;
    return _passwordRegex.hasMatch(password);
  }

  /// Validate amount string
  static bool isValidAmount(String? amount) {
    if (amount == null || amount.isEmpty) return false;

    // Remove commas and spaces
    final cleanAmount = amount.replaceAll(RegExp(r'[,\s]'), '');

    // Check format
    if (!_amountRegex.hasMatch(cleanAmount)) return false;

    // Parse to double
    final parsedAmount = double.tryParse(cleanAmount);
    if (parsedAmount == null) return false;

    // Check range
    return parsedAmount > 0 && parsedAmount <= 1000000000; // Max 1 billion
  }

  /// Validate name (Vietnamese characters allowed)
  static bool isValidName(String? name) {
    if (name == null || name.isEmpty) return false;
    return _nameRegex.hasMatch(name.trim());
  }

  /// Validate note content
  static bool isValidNote(String? note) {
    if (note == null || note.isEmpty) return true; // Empty note is valid
    return _noteRegex.hasMatch(note.trim());
  }

  /// Validate category name
  static bool isValidCategoryName(String? name) {
    if (name == null || name.isEmpty) return false;
    final trimmed = name.trim();
    return trimmed.length >= 2 && trimmed.length <= 30;
  }

  /// Validate date range
  static bool isValidDateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return false;
    return start.isBefore(end) || start.isAtSameMomentAs(end);
  }

  /// Validate future date (not allowed for transactions)
  static bool isValidTransactionDate(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDate = DateTime(date.year, date.month, date.day);
    return !transactionDate.isAfter(today);
  }

  /// Get password strength level
  static PasswordStrength getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;

    int score = 0;

    // Length
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Character types
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    if (score <= 6) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  /// Get validation error message
  static String? getValidationError(String field, String? value) {
    switch (field.toLowerCase()) {
      case 'email':
        if (value == null || value.isEmpty) {
          return 'Email không được để trống';
        }
        if (!isValidEmail(value)) {
          return 'Email không đúng định dạng';
        }
        break;

      case 'password':
        if (value == null || value.isEmpty) {
          return 'Mật khẩu không được để trống';
        }
        if (value.length < 8) {
          return 'Mật khẩu phải có ít nhất 8 ký tự';
        }
        if (!isValidPassword(value)) {
          return 'Mật khẩu phải chứa chữ hoa, chữ thường và số';
        }
        break;

      case 'amount':
        if (value == null || value.isEmpty) {
          return 'Số tiền không được để trống';
        }
        if (!isValidAmount(value)) {
          return 'Số tiền không hợp lệ';
        }
        break;

      case 'name':
        if (value == null || value.isEmpty) {
          return 'Tên không được để trống';
        }
        if (!isValidName(value)) {
          return 'Tên chỉ được chứa chữ cái và khoảng trắng';
        }
        break;

      case 'note':
        if (value != null && value.isNotEmpty && !isValidNote(value)) {
          return 'Ghi chú chứa ký tự không hợp lệ';
        }
        break;

      case 'category':
        if (value == null || value.isEmpty) {
          return 'Tên danh mục không được để trống';
        }
        if (!isValidCategoryName(value)) {
          return 'Tên danh mục phải từ 2-30 ký tự';
        }
        break;
    }

    return null;
  }

  /// Sanitize input string
  static String sanitizeInput(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Format phone number for display
  static String formatPhoneNumber(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.length == 10) {
      return '${clean.substring(0, 4)} ${clean.substring(4, 7)} ${clean.substring(7)}';
    }
    if (clean.length == 11 && clean.startsWith('0')) {
      return '${clean.substring(0, 4)} ${clean.substring(4, 7)} ${clean.substring(7)}';
    }
    return phone;
  }

  /// Validate emoji string
  static bool isValidEmoji(String text) {
    if (text.isEmpty) return false;

    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
      unicode: true,
    );

    return emojiRegex.hasMatch(text);
  }
}