import 'package:flutter/material.dart';

import '../../models/transaction_model.dart';
import 'ai_token_manager.dart';

/// Helper utilities for AI service
/// - Amount parsing from various formats
/// - Smart icon/emoji selection
/// - Token estimation
/// - Usage checking and token tracking
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
        'color': Colors.orange.toARGB32()
      },
      'cafe': {'icon': '☕', 'iconType': 'emoji', 'color': Colors.brown.toARGB32()},
      'nhà hàng': {
        'icon': '🍽️',
        'iconType': 'emoji',
        'color': Colors.orange.toARGB32()
      },

      // Transportation
      'di chuyển': {
        'icon': '🚗',
        'iconType': 'emoji',
        'color': Colors.blue.toARGB32()
      },
      'xe': {'icon': '🚗', 'iconType': 'emoji', 'color': Colors.blue.toARGB32()},
      'grab': {'icon': '🚕', 'iconType': 'emoji', 'color': Colors.green.toARGB32()},
      'xăng': {'icon': '⛽', 'iconType': 'emoji', 'color': Colors.red.toARGB32()},

      // Shopping
      'mua sắm': {
        'icon': '🛒',
        'iconType': 'emoji',
        'color': Colors.purple.toARGB32()
      },
      'quần áo': {
        'icon': '👔',
        'iconType': 'emoji',
        'color': Colors.pink.toARGB32()
      },

      // Entertainment
      'giải trí': {
        'icon': '🎬',
        'iconType': 'emoji',
        'color': Colors.deepPurple.toARGB32()
      },
      'phim': {
        'icon': '🎬',
        'iconType': 'emoji',
        'color': Colors.deepPurple.toARGB32()
      },
      'game': {
        'icon': '🎮',
        'iconType': 'emoji',
        'color': Colors.indigo.toARGB32()
      },

      // Health
      'y tế': {'icon': '🏥', 'iconType': 'emoji', 'color': Colors.red.toARGB32()},
      'thuốc': {
        'icon': '💊',
        'iconType': 'emoji',
        'color': Colors.redAccent.toARGB32()
      },

      // Education
      'học tập': {
        'icon': '🏫',
        'iconType': 'emoji',
        'color': Colors.teal.toARGB32()
      },
      'sách': {
        'icon': '📚',
        'iconType': 'emoji',
        'color': Colors.brown.toARGB32()
      },

      // Bills
      'hóa đơn': {
        'icon': '🧾',
        'iconType': 'emoji',
        'color': Colors.grey.toARGB32()
      },
      'điện': {
        'icon': '💡',
        'iconType': 'emoji',
        'color': Colors.yellow.toARGB32()
      },
      'nước': {
        'icon': '💧',
        'iconType': 'emoji',
        'color': Colors.blue.toARGB32()
      },
      'internet': {
        'icon': '📡',
        'iconType': 'emoji',
        'color': Colors.cyan.toARGB32()
      },

      // Income categories
      'lương': {
        'icon': '💼',
        'iconType': 'emoji',
        'color': Colors.green.toARGB32()
      },
      'thưởng': {
        'icon': '🎁',
        'iconType': 'emoji',
        'color': Colors.amber.toARGB32()
      },
      'đầu tư': {
        'icon': '📈',
        'iconType': 'emoji',
        'color': Colors.lightGreen.toARGB32()
      },
      'freelance': {
        'icon': '💻',
        'iconType': 'emoji',
        'color': Colors.blueGrey.toARGB32()
      },
      'bán hàng': {
        'icon': '💸',
        'iconType': 'emoji',
        'color': Colors.greenAccent.toARGB32()
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
        'color': Colors.green.toARGB32()
      };
    } else {
      return {'icon': '💳', 'iconType': 'emoji', 'color': Colors.blue.toARGB32()};
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

  /// Check usage before making API call
  /// Handles rate limiting automatically
  /// 
  /// Usage:
  /// ```dart
  /// await AIHelpers.checkUsageBeforeCall(tokenManager, inputText);
  /// ```
  static Future<void> checkUsageBeforeCall(
    AITokenManager tokenManager,
    String input,
  ) async {
    await tokenManager.checkRateLimit();
  }

  /// Update token usage after API call
  /// Automatically estimates tokens from input and response
  /// 
  /// Usage:
  /// ```dart
  /// await AIHelpers.updateUsageAfterCall(tokenManager, inputText, responseText);
  /// ```
  static Future<void> updateUsageAfterCall(
    AITokenManager tokenManager,
    String input,
    String response,
  ) async {
    final inputTokens = estimateTokens(input);
    final responseTokens = estimateTokens(response);
    await tokenManager.updateTokenCount(inputTokens + responseTokens);
  }

  /// Check usage before API call and update after
  /// Convenience method that combines both operations
  /// 
  /// Usage:
  /// ```dart
  /// await AIHelpers.checkAndUpdateUsage(tokenManager, inputText, responseText);
  /// ```
  static Future<void> checkAndUpdateUsage(
    AITokenManager tokenManager,
    String input,
    String response,
  ) async {
    await checkUsageBeforeCall(tokenManager, input);
    await updateUsageAfterCall(tokenManager, input, response);
  }

  /// Check usage before API call with custom input tokens
  /// Useful when you have pre-calculated token estimates
  /// 
  /// Usage:
  /// ```dart
  /// await AIHelpers.checkUsageBeforeCallWithTokens(tokenManager, estimatedTokens);
  /// ```
  static Future<void> checkUsageBeforeCallWithTokens(
    AITokenManager tokenManager,
    int estimatedTokens,
  ) async {
    await tokenManager.checkRateLimit();
  }

  /// Update token usage with custom token count
  /// Useful when you have exact token counts from API response
  /// 
  /// Usage:
  /// ```dart
  /// await AIHelpers.updateUsageWithTokens(tokenManager, tokensUsed);
  /// ```
  static Future<void> updateUsageWithTokens(
    AITokenManager tokenManager,
    int tokensUsed,
  ) async {
    await tokenManager.updateTokenCount(tokensUsed);
  }
}
