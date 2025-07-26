/// String utility functions
class StringHelper {
  /// Capitalize first letter of each word
  static String capitalize(String text) {
    if (text.isEmpty) return text;

    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Capitalize first letter only
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Truncate text with ellipsis
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength - suffix.length) + suffix;
  }

  /// Truncate text at word boundary
  static String truncateAtWord(String text, int maxLength,
      {String suffix = '...'}) {
    if (text.length <= maxLength) return text;

    final truncated = text.substring(0, maxLength);
    final lastSpace = truncated.lastIndexOf(' ');

    if (lastSpace > 0) {
      return truncated.substring(0, lastSpace) + suffix;
    }

    return truncated + suffix;
  }

  /// Remove diacritics (accents) from Vietnamese text
  static String removeDiacritics(String text) {
    const vietnamese =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const latin =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

    String result = text;
    for (int i = 0; i < vietnamese.length; i++) {
      result = result.replaceAll(vietnamese[i], latin[i]);
    }

    return result;
  }

  /// Convert to slug (URL-friendly)
  static String toSlug(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'[-\s]+'), '-');
  }

  /// Extract initials from name
  static String getInitials(String name) {
    if (name.isEmpty) return '';

    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    }

    return words.take(2).map((word) => word[0].toUpperCase()).join('');
  }

  /// Format number with commas
  static String formatNumber(num number) {
    final parts = number.toString().split('.');
    parts[0] = _addCommas(parts[0]);
    return parts.join('.');
  }

  /// Add commas to number string
  static String _addCommas(String number) {
    final buffer = StringBuffer();
    for (int i = 0; i < number.length; i++) {
      if (i > 0 && (number.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(number[i]);
    }
    return buffer.toString();
  }

  /// Check if string is numeric
  static bool isNumeric(String text) {
    return double.tryParse(text) != null;
  }

  /// Check if string is integer
  static bool isInteger(String text) {
    return int.tryParse(text) != null;
  }

  /// Check if string contains only letters and spaces
  static bool isAlphabetic(String text) {
    return RegExp(r'^[a-zA-ZÀ-ỹ\s]+$').hasMatch(text);
  }

  /// Check if string contains only letters, numbers and spaces
  static bool isAlphanumeric(String text) {
    return RegExp(r'^[a-zA-ZÀ-ỹ0-9\s]+$').hasMatch(text);
  }

  /// Count words in text
  static int wordCount(String text) {
    if (text.isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  /// Count characters (excluding spaces)
  static int characterCount(String text) {
    return text.replaceAll(RegExp(r'\s'), '').length;
  }

  /// Reverse string
  static String reverse(String text) {
    return text.split('').reversed.join('');
  }

  /// Check if string is palindrome
  static bool isPalindrome(String text) {
    final clean = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return clean == reverse(clean);
  }

  /// Generate random string
  static String randomString(int length,
      {bool includeNumbers = true, bool includeSymbols = false}) {
    const letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String chars = letters;
    if (includeNumbers) chars += numbers;
    if (includeSymbols) chars += symbols;

    final random = List.generate(length,
        (index) => chars[DateTime.now().millisecondsSinceEpoch % chars.length]);
    return random.join('');
  }

  /// Mask sensitive data (like credit card)
  static String mask(String text,
      {int visibleStart = 4, int visibleEnd = 4, String maskChar = '*'}) {
    if (text.length <= visibleStart + visibleEnd) return text;

    final start = text.substring(0, visibleStart);
    final end = text.substring(text.length - visibleEnd);
    final masked = maskChar * (text.length - visibleStart - visibleEnd);

    return start + masked + end;
  }

  /// Extract numbers from string
  static String extractNumbers(String text) {
    return text.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Extract letters from string
  static String extractLetters(String text) {
    return text.replaceAll(RegExp(r'[^a-zA-ZÀ-ỹ]'), '');
  }

  /// Check if string starts with any of the given prefixes
  static bool startsWithAny(String text, List<String> prefixes) {
    return prefixes.any((prefix) => text.startsWith(prefix));
  }

  /// Check if string ends with any of the given suffixes
  static bool endsWithAny(String text, List<String> suffixes) {
    return suffixes.any((suffix) => text.endsWith(suffix));
  }

  /// Find most common word in text
  static String? mostCommonWord(String text) {
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    final wordCount = <String, int>{};

    for (final word in words) {
      if (word.isNotEmpty) {
        wordCount[word] = (wordCount[word] ?? 0) + 1;
      }
    }

    if (wordCount.isEmpty) return null;

    return wordCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Check if string contains any of the given words
  static bool containsAny(String text, List<String> words) {
    final lowerText = text.toLowerCase();
    return words.any((word) => lowerText.contains(word.toLowerCase()));
  }

  /// Remove extra whitespace
  static String normalizeWhitespace(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Convert camelCase to snake_case
  static String camelToSnake(String text) {
    return text.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }

  /// Convert snake_case to camelCase
  static String snakeToCamel(String text) {
    return text.replaceAllMapped(
      RegExp(r'_([a-z])'),
      (match) => match.group(1)!.toUpperCase(),
    );
  }

  /// Convert to title case
  static String toTitleCase(String text) {
    if (text.isEmpty) return text;

    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Check if string is empty or only whitespace
  static bool isBlank(String text) {
    return text.trim().isEmpty;
  }

  /// Check if string is not empty and not only whitespace
  static bool isNotBlank(String text) {
    return text.trim().isNotEmpty;
  }

  /// Repeat string n times
  static String repeat(String text, int times) {
    return List.filled(times, text).join('');
  }

  /// Pad string to specified length
  static String padLeft(String text, int length, {String padding = ' '}) {
    if (text.length >= length) return text;
    return repeat(padding, length - text.length) + text;
  }

  /// Pad string to specified length
  static String padRight(String text, int length, {String padding = ' '}) {
    if (text.length >= length) return text;
    return text + repeat(padding, length - text.length);
  }

  /// Center string with padding
  static String padCenter(String text, int length, {String padding = ' '}) {
    if (text.length >= length) return text;

    final totalPadding = length - text.length;
    final leftPadding = totalPadding ~/ 2;
    final rightPadding = totalPadding - leftPadding;

    return repeat(padding, leftPadding) + text + repeat(padding, rightPadding);
  }
}
