import 'package:flutter/material.dart';
import 'package:moni/constants/enums.dart';
import '../helpers/string_helper.dart';
import '../validation/input_validator.dart';

/// String extensions for convenient methods
extension StringExtensions on String {
  /// Check if string is empty or only whitespace
  bool get isBlank => trim().isEmpty;

  /// Check if string is not empty and not only whitespace
  bool get isNotBlank => trim().isNotEmpty;

  /// Check if string is numeric
  bool get isNumeric => double.tryParse(this) != null;

  /// Check if string is integer
  bool get isInteger => int.tryParse(this) != null;

  /// Check if string contains only letters and spaces
  bool get isAlphabetic => RegExp(r'^[a-zA-ZÀ-ỹ\s]+$').hasMatch(this);

  /// Check if string contains only letters, numbers and spaces
  bool get isAlphanumeric => RegExp(r'^[a-zA-ZÀ-ỹ0-9\s]+$').hasMatch(this);

  /// Check if string is valid email
  bool get isValidEmail =>
      RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+$').hasMatch(this);

  /// Check if string is valid phone number (Vietnamese format)
  bool get isValidPhone => RegExp(
        r'^(0|\+84)(\s|\.)?((3[2-9])|(5[689])|(7[06-9])|(8[1-689])|(9[0-46-9]))(\d)(\s|\.)?(\d{3})(\s|\.)?(\d{3})$',
      ).hasMatch(this);

  /// Check if string is valid password
  bool get isValidPassword => RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$',
      ).hasMatch(this);

  /// Capitalize first letter of each word
  String get capitalize => StringHelper.capitalize(this);

  /// Capitalize first letter only
  String get capitalizeFirst => StringHelper.capitalizeFirst(this);

  /// Convert to title case
  String get toTitleCase => StringHelper.toTitleCase(this);

  /// Remove diacritics (accents)
  String get removeDiacritics => StringHelper.removeDiacritics(this);

  /// Convert to slug (URL-friendly)
  String get toSlug => StringHelper.toSlug(this);

  /// Extract initials from name
  String get initials => StringHelper.getInitials(this);

  /// Extract numbers only
  String get numbersOnly => StringHelper.extractNumbers(this);

  /// Extract letters only
  String get lettersOnly => StringHelper.extractLetters(this);

  /// Normalize whitespace
  String get normalizeWhitespace => StringHelper.normalizeWhitespace(this);

  /// Convert camelCase to snake_case
  String get camelToSnake => StringHelper.camelToSnake(this);

  /// Convert snake_case to camelCase
  String get snakeToCamel => StringHelper.snakeToCamel(this);

  /// Reverse string
  String get reversed => StringHelper.reverse(this);

  /// Check if string is palindrome
  bool get isPalindrome => StringHelper.isPalindrome(this);

  /// Count words
  int get wordCount => StringHelper.wordCount(this);

  /// Count characters (excluding spaces)
  int get characterCount => StringHelper.characterCount(this);

  /// Truncate with ellipsis
  String truncate(int maxLength, {String suffix = '...'}) {
    return StringHelper.truncate(this, maxLength, suffix: suffix);
  }

  /// Truncate at word boundary
  String truncateAtWord(int maxLength, {String suffix = '...'}) {
    return StringHelper.truncateAtWord(this, maxLength, suffix: suffix);
  }

  /// Mask sensitive data
  String mask(
      {int visibleStart = 4, int visibleEnd = 4, String maskChar = '*'}) {
    return StringHelper.mask(this,
        visibleStart: visibleStart, visibleEnd: visibleEnd, maskChar: maskChar);
  }

  /// Check if string starts with any of the given prefixes
  bool startsWithAny(List<String> prefixes) {
    return StringHelper.startsWithAny(this, prefixes);
  }

  /// Check if string ends with any of the given suffixes
  bool endsWithAny(List<String> suffixes) {
    return StringHelper.endsWithAny(this, suffixes);
  }

  /// Check if string contains any of the given words
  bool containsAny(List<String> words) {
    return StringHelper.containsAny(this, words);
  }

  /// Find most common word
  String? get mostCommonWord => StringHelper.mostCommonWord(this);

  /// Repeat string n times
  String repeat(int times) {
    return StringHelper.repeat(this, times);
  }

  /// Pad left
  String padLeft(int length, {String padding = ' '}) {
    return StringHelper.padLeft(this, length, padding: padding);
  }

  /// Pad right
  String padRight(int length, {String padding = ' '}) {
    return StringHelper.padRight(this, length, padding: padding);
  }

  /// Pad center
  String padCenter(int length, {String padding = ' '}) {
    return StringHelper.padCenter(this, length, padding: padding);
  }

  /// Check if string is valid emoji
  bool get isValidEmoji => InputValidator.isValidEmoji(this);

  /// Format phone number for display
  String get formatPhoneNumber => InputValidator.formatPhoneNumber(this);

  /// Sanitize input
  String get sanitize => InputValidator.sanitizeInput(this);

  /// Get validation error message
  String? getValidationError(String field) {
    return InputValidator.getValidationError(field, this);
  }

  /// Validate amount
  bool get isValidAmount => InputValidator.isValidAmount(this);

  /// Validate name
  bool get isValidName => InputValidator.isValidName(this);

  /// Validate note
  bool get isValidNote => InputValidator.isValidNote(this);

  /// Validate category name
  bool get isValidCategoryName => InputValidator.isValidCategoryName(this);

  /// Get password strength
  PasswordStrength get passwordStrength =>
      InputValidator.getPasswordStrength(this);

  /// Convert to Color (for hex color strings)
  Color? get toColor {
    if (startsWith('#') && length == 7) {
      try {
        return Color(int.parse(substring(1), radix: 16) + 0xFF000000);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Convert to int (with error handling)
  int? get toInt {
    return int.tryParse(this);
  }

  /// Convert to double (with error handling)
  double? get toDouble {
    return double.tryParse(this);
  }

  /// Convert to DateTime (with error handling)
  DateTime? get toDateTime {
    return DateTime.tryParse(this);
  }

  /// Convert to bool (with error handling)
  bool? get toBool {
    final lower = toLowerCase();
    if (lower == 'true' || lower == '1' || lower == 'yes') return true;
    if (lower == 'false' || lower == '0' || lower == 'no') return false;
    return null;
  }

  /// Split by comma and trim each part
  List<String> get splitByComma =>
      split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  /// Split by newline and trim each part
  List<String> get splitByNewline =>
      split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  /// Split by space and trim each part
  List<String> get splitBySpace =>
      split(' ').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  /// Get first character
  String get first => isNotEmpty ? this[0] : '';

  /// Get last character
  String get last => isNotEmpty ? this[length - 1] : '';

  /// Get first n characters
  String takeFirst(int n) {
    return length > n ? substring(0, n) : this;
  }

  /// Get last n characters
  String takeLast(int n) {
    return length > n ? substring(length - n) : this;
  }

  /// Remove first n characters
  String removeFirst(int n) {
    return length > n ? substring(n) : '';
  }

  /// Remove last n characters
  String removeLast(int n) {
    return length > n ? substring(0, length - n) : '';
  }

  /// Remove prefix if present
  String removePrefix(String prefix) {
    return startsWith(prefix) ? substring(prefix.length) : this;
  }

  /// Remove suffix if present
  String removeSuffix(String suffix) {
    return endsWith(suffix) ? substring(0, length - suffix.length) : this;
  }

  /// Add prefix if not present
  String addPrefix(String prefix) {
    return startsWith(prefix) ? this : '$prefix$this';
  }

  /// Add suffix if not present
  String addSuffix(String suffix) {
    return endsWith(suffix) ? this : '$this$suffix';
  }

  /// Wrap in quotes
  String get quoted => '"$this"';

  /// Wrap in single quotes
  String get singleQuoted => "'$this'";

  /// Wrap in parentheses
  String get parenthesized => '($this)';

  /// Wrap in brackets
  String get bracketed => '[$this]';

  /// Wrap in braces
  String get braced => '{$this}';

  /// Convert to lowercase with first letter uppercase
  String get sentenceCase {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }

  /// Convert to uppercase
  String get upperCase => toUpperCase();

  /// Convert to lowercase
  String get lowerCase => toLowerCase();

  /// Convert to title case (first letter of each word uppercase)
  String get titleCase => split(' ').map((word) => word.sentenceCase).join(' ');

  /// Convert to kebab-case
  String get kebabCase => toLowerCase().replaceAll(RegExp(r'\s+'), '-');

  /// Convert to snake_case
  String get snakeCase => toLowerCase().replaceAll(RegExp(r'\s+'), '_');

  /// Convert to camelCase
  String get camelCase {
    if (isEmpty) return this;
    final words = toLowerCase().split(RegExp(r'\s+'));
    return words[0] + words.skip(1).map((word) => word.sentenceCase).join('');
  }

  /// Convert to PascalCase
  String get pascalCase {
    if (isEmpty) return this;
    return split(RegExp(r'\s+')).map((word) => word.sentenceCase).join('');
  }

  /// Check if string contains only digits
  bool get isDigitsOnly => RegExp(r'^[0-9]+$').hasMatch(this);

  /// Check if string contains only letters
  bool get isLettersOnly => RegExp(r'^[a-zA-ZÀ-ỹ]+$').hasMatch(this);

  /// Check if string contains only letters and digits
  bool get isAlphanumericOnly => RegExp(r'^[a-zA-ZÀ-ỹ0-9]+$').hasMatch(this);

  /// Check if string is a valid URL
  bool get isUrl {
    try {
      Uri.parse(this);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if string is a valid IPv4 address
  bool get isIPv4 {
    final parts = split('.');
    if (parts.length != 4) return false;

    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    return true;
  }

  /// Check if string is a valid IPv6 address
  bool get isIPv6 {
    try {
      Uri.parse('http://[$this]');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if string is a valid MAC address
  bool get isMacAddress =>
      RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$').hasMatch(this);

  /// Check if string is a valid credit card number
  bool get isCreditCardNumber {
    final clean = replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^[0-9]{13,19}$').hasMatch(clean)) return false;

    // Luhn algorithm
    int sum = 0;
    bool alternate = false;

    for (int i = clean.length - 1; i >= 0; i--) {
      int n = int.parse(clean[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n = (n % 10) + 1;
      }
      sum += n;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }
}
