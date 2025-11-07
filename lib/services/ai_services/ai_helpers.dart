import 'package:flutter/material.dart';

import '../../models/transaction_model.dart';

/// Helper utilities for AI service
/// - Amount parsing from various formats
/// - Smart icon/emoji selection
/// - Token estimation
class AIHelpers {
  /// Parse amount from various formats (18k, 1tr, 18000, etc.)
  static double parseAmount(dynamic rawAmount) {
    // Null-safe fallback
    if (rawAmount == null) return 0;

    if (rawAmount is num) {
      return rawAmount.toDouble();
    }

    if (rawAmount is String) {
      // Normalize common Vietnamese money formats
      String cleanAmount = rawAmount.trim().toLowerCase();

      // Handle 'k' = thousand
      if (cleanAmount.endsWith('k')) {
        final numPart = cleanAmount.substring(0, cleanAmount.length - 1).trim();
        return (double.tryParse(numPart) ?? 0) * 1000;
      }

      // Handle 'tr' or 'triệu' = million
      if (cleanAmount.endsWith('tr') ||
          cleanAmount.endsWith('triệu') ||
          cleanAmount.endsWith('m')) {
        String numPart;
        if (cleanAmount.endsWith('triệu')) {
          numPart =
              cleanAmount.substring(0, cleanAmount.length - 5).trim(); // 'triệu'
        } else if (cleanAmount.endsWith('tr')) {
          numPart =
              cleanAmount.substring(0, cleanAmount.length - 2).trim(); // 'tr'
        } else {
          numPart = cleanAmount.substring(0, cleanAmount.length - 1).trim(); // 'm'
        }
        return (double.tryParse(numPart) ?? 0) * 1000000;
      }

      // Handle 'tỷ' or 'b' = billion
      if (cleanAmount.endsWith('tỷ') ||
          cleanAmount.endsWith('ty') ||
          cleanAmount.endsWith('b')) {
        String numPart;
        if (cleanAmount.endsWith('tỷ')) {
          numPart = cleanAmount.substring(0, cleanAmount.length - 2).trim();
        } else if (cleanAmount.endsWith('ty')) {
          numPart = cleanAmount.substring(0, cleanAmount.length - 2).trim();
        } else {
          numPart = cleanAmount.substring(0, cleanAmount.length - 1).trim();
        }
        return (double.tryParse(numPart) ?? 0) * 1000000000;
      }

      // Default: parse as plain number
      return double.tryParse(cleanAmount) ?? 0;
    }

    return 0;
  }

  /// Get smart icon for category based on name and type
  static Map<String, dynamic> getSmartIconForCategory(
      String categoryName, TransactionType type) {
    final lowerName = categoryName.toLowerCase();

    // Predefined emoji-category mapping
    final Map<String, Map<String, dynamic>> emojiMap = {
      // Food & Drink
      'ăn uống': {
        'icon': '🍽️',
        'iconType': 'emoji',
        'color': Colors.orange.value
      },
      'cafe': {'icon': '☕', 'iconType': 'emoji', 'color': Colors.brown.value},
      'nhà hàng': {
        'icon': '🍽️',
        'iconType': 'emoji',
        'color': Colors.orange.value
      },

      // Transportation
      'di chuyển': {
        'icon': '🚗',
        'iconType': 'emoji',
        'color': Colors.blue.value
      },
      'xe': {'icon': '🚗', 'iconType': 'emoji', 'color': Colors.blue.value},
      'grab': {'icon': '🚕', 'iconType': 'emoji', 'color': Colors.green.value},
      'xăng': {'icon': '⛽', 'iconType': 'emoji', 'color': Colors.red.value},

      // Shopping
      'mua sắm': {
        'icon': '🛒',
        'iconType': 'emoji',
        'color': Colors.purple.value
      },
      'quần áo': {
        'icon': '👔',
        'iconType': 'emoji',
        'color': Colors.pink.value
      },

      // Entertainment
      'giải trí': {
        'icon': '🎬',
        'iconType': 'emoji',
        'color': Colors.deepPurple.value
      },
      'phim': {
        'icon': '🎬',
        'iconType': 'emoji',
        'color': Colors.deepPurple.value
      },
      'game': {
        'icon': '🎮',
        'iconType': 'emoji',
        'color': Colors.indigo.value
      },

      // Health
      'y tế': {'icon': '🏥', 'iconType': 'emoji', 'color': Colors.red.value},
      'thuốc': {
        'icon': '💊',
        'iconType': 'emoji',
        'color': Colors.redAccent.value
      },

      // Education
      'học tập': {
        'icon': '🏫',
        'iconType': 'emoji',
        'color': Colors.teal.value
      },
      'sách': {
        'icon': '📚',
        'iconType': 'emoji',
        'color': Colors.brown.value
      },

      // Bills
      'hóa đơn': {
        'icon': '🧾',
        'iconType': 'emoji',
        'color': Colors.grey.value
      },
      'điện': {
        'icon': '💡',
        'iconType': 'emoji',
        'color': Colors.yellow.value
      },
      'nước': {
        'icon': '💧',
        'iconType': 'emoji',
        'color': Colors.blue.value
      },
      'internet': {
        'icon': '📡',
        'iconType': 'emoji',
        'color': Colors.cyan.value
      },

      // Income categories
      'lương': {
        'icon': '💼',
        'iconType': 'emoji',
        'color': Colors.green.value
      },
      'thưởng': {
        'icon': '🎁',
        'iconType': 'emoji',
        'color': Colors.amber.value
      },
      'đầu tư': {
        'icon': '📈',
        'iconType': 'emoji',
        'color': Colors.lightGreen.value
      },
      'freelance': {
        'icon': '💻',
        'iconType': 'emoji',
        'color': Colors.blueGrey.value
      },
      'bán hàng': {
        'icon': '💸',
        'iconType': 'emoji',
        'color': Colors.greenAccent.value
      },
    };

    // Try to match category name
    for (final entry in emojiMap.entries) {
      if (lowerName.contains(entry.key)) {
        return entry.value;
      }
    }

    // Default fallback based on transaction type
    if (type == TransactionType.income) {
      return {
        'icon': '💰',
        'iconType': 'emoji',
        'color': Colors.green.value
      };
    } else {
      return {'icon': '💳', 'iconType': 'emoji', 'color': Colors.blue.value};
    }
  }

  /// Estimate token count for a given text
  /// Rough approximation: ~4 characters per token for Vietnamese
  static int estimateTokens(String text) {
    // Vietnamese uses more tokens than English due to diacritics
    // Rough estimate: 1 token ≈ 4 characters for Vietnamese
    return (text.length / 4).ceil();
  }

  /// Get error type from exception
  static String getErrorType(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('quota') || errorString.contains('429')) {
      return 'QUOTA_EXCEEDED';
    } else if (errorString.contains('api key') ||
        errorString.contains('401') ||
        errorString.contains('403')) {
      return 'AUTH_ERROR';
    } else if (errorString.contains('socketexception')) {
      return 'NETWORK_ERROR';
    } else if (errorString.contains('timeoutexception')) {
      return 'TIMEOUT_ERROR';
    }

    return 'GENERIC_ERROR';
  }

  /// Get user-friendly error message
  static String getUserFriendlyErrorMessage(String errorType) {
    switch (errorType) {
      case 'QUOTA_EXCEEDED':
        return 'Xin lỗi, bạn đã vượt quá giới hạn sử dụng AI hôm nay. Vui lòng thử lại vào ngày mai! 🙏';
      case 'AUTH_ERROR':
        return 'Lỗi xác thực API. Vui lòng liên hệ support để được hỗ trợ. 🔑';
      case 'NETWORK_ERROR':
        return 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối internet. 📡';
      case 'TIMEOUT_ERROR':
        return 'Yêu cầu mất quá nhiều thời gian. Vui lòng thử lại. ⏱️';
      default:
        return 'Đã có lỗi xảy ra. Vui lòng thử lại sau. 😅';
    }
  }
}
