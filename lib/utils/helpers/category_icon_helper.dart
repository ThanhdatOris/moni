import 'package:flutter/material.dart';
import 'package:moni/constants/enums.dart';

import '../../models/category_model.dart';

/// Helper class để xử lý hiển thị icon cho category
class CategoryIconHelper {
  /// Build icon widget cho category
  static Widget buildIcon(
    CategoryModel category, {
    double size = 24,
    Color? color,
    bool showBackground = false,
    Color? backgroundColor,
    bool isCompact = false, // Thêm parameter để handle compact mode
  }) {
    Widget iconWidget;

    switch (category.iconType) {
      case CategoryIconType.emoji:
        iconWidget = _buildEmojiIcon(category.icon, size);
        break;
      case CategoryIconType.custom:
        iconWidget = _buildCustomIcon(category.customIconUrl, size, color);
        break;
      case CategoryIconType.material:
        iconWidget = _buildMaterialIcon(category.icon, size, color);
        break;
    }

    if (showBackground) {
      // Giảm padding khi ở compact mode (dùng trong dropdown)
      final padding = isCompact ? 6.0 : 16.0;
      final containerSize = size + padding;
      
      return Container(
        width: containerSize,
        height: containerSize,
        decoration: BoxDecoration(
          color: backgroundColor ?? Color(category.color).withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: Color(category.color).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Center(child: iconWidget),
      );
    }

    return iconWidget;
  }

  /// Build emoji icon
  static Widget _buildEmojiIcon(String emoji, double size) {
    return Text(
      emoji,
      style: TextStyle(
        fontSize: size,
        fontFamily: 'Apple Color Emoji',
        fontFamilyFallback: const ['Noto Color Emoji', 'Noto Emoji'],
      ),
    );
  }

  /// Build material icon
  static Widget _buildMaterialIcon(String iconName, double size, Color? color) {
    final iconData = _getMaterialIconData(iconName);
    return Icon(
      iconData,
      size: size,
      color: color,
    );
  }

  /// Build custom icon từ URL
  static Widget _buildCustomIcon(String? iconUrl, double size, Color? color) {
    if (iconUrl == null || iconUrl.isEmpty) {
      return _buildMaterialIcon('category', size, color);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 4),
      child: Image.network(
        iconUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildMaterialIcon('category', size, color);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      ),
    );
  }

  /// Lấy IconData từ tên icon (public method)
  static IconData getIconData(String iconName) {
    return _getMaterialIconData(iconName);
  }

  /// Map tên icon string thành IconData
  static IconData _getMaterialIconData(String iconName) {
    switch (iconName) {
      // Expense icons
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'directions_car':
        return Icons.directions_car;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'movie':
        return Icons.movie;
      case 'receipt':
        return Icons.receipt;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'flight':
        return Icons.flight;
      case 'hotel':
        return Icons.hotel;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'pets':
        return Icons.pets;
      case 'child_care':
        return Icons.child_care;
      case 'celebration':
        return Icons.celebration;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'local_bar':
        return Icons.local_bar;

      // Income icons
      case 'work':
        return Icons.work;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'trending_up':
        return Icons.trending_up;
      case 'attach_money':
        return Icons.attach_money;
      case 'account_balance':
        return Icons.account_balance;
      case 'savings':
        return Icons.savings;
      case 'business':
        return Icons.business;
      case 'sell':
        return Icons.sell;
      case 'monetization_on':
        return Icons.monetization_on;

      // Utility icons
      case 'more_horiz':
        return Icons.more_horiz;
      case 'add':
        return Icons.add;
      case 'edit':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'folder':
        return Icons.folder;
      case 'label':
        return Icons.label;

      // Default
      case 'category':
      default:
        return Icons.category;
    }
  }

  /// Lấy danh sách các material icons phổ biến cho expense
  static List<String> getPopularExpenseIcons() {
    return [
      'restaurant',
      'shopping_cart',
      'directions_car',
      'local_gas_station',
      'movie',
      'receipt',
      'local_hospital',
      'home',
      'school',
      'sports_soccer',
      'flight',
      'hotel',
      'shopping_bag',
      'fitness_center',
      'pets',
      'child_care',
      'celebration',
      'local_cafe',
      'local_bar',
    ];
  }

  /// Lấy danh sách các material icons phổ biến cho income
  static List<String> getPopularIncomeIcons() {
    return [
      'work',
      'attach_money',
      'trending_up',
      'card_giftcard',
      'account_balance',
      'savings',
      'business',
      'sell',
      'monetization_on',
    ];
  }

  /// Lấy emoji phổ biến cho expense categories
  static List<String> getPopularExpenseEmojis() {
    return [
      '🍽️',
      '🛒',
      '🚗',
      '⛽',
      '🎬',
      '🧾',
      '🏥',
      '🏠',
      '🏫',
      '⚽',
      '✈️',
      '🏨',
      '👜',
      '💪',
      '🐕',
      '👶',
      '🎉',
      '☕',
      '🍺',
      '💊',
      '📚',
      '🎮',
      '🎵',
      '💄',
      '👗',
      '⚡',
      '💧',
      '📱',
      '💻',
      '🚌',
    ];
  }

  /// Lấy emoji phổ biến cho income categories
  static List<String> getPopularIncomeEmojis() {
    return [
      '💼',
      '💰',
      '📈',
      '🎁',
      '🏦',
      '💳',
      '🏢',
      '💸',
      '🪙',
      '💎',
      '📊',
      '💹',
      '🎯',
      '🏆',
      '⭐',
      '🔥',
      '💯',
      '✨',
      '🌟',
      '💵',
    ];
  }

  /// Validate emoji string
  static bool isValidEmoji(String text) {
    if (text.isEmpty) return false;

    // Simple emoji validation - check if contains emoji characters
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
      unicode: true,
    );

    return emojiRegex.hasMatch(text);
  }

  /// Get icon preview cho picker
  static Widget buildIconPreview(
    String iconData,
    CategoryIconType iconType, {
    double size = 32,
    bool isSelected = false,
    Color? categoryColor,
  }) {
    return Container(
      width: size + 16,
      height: size + 16,
      decoration: BoxDecoration(
        color: isSelected
            ? (categoryColor ?? Colors.blue).withValues(alpha:0.2)
            : Colors.grey.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? (categoryColor ?? Colors.blue)
              : Colors.grey.withValues(alpha:0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Center(
        child: _buildIconByType(iconData, iconType, size, categoryColor),
      ),
    );
  }

  static Widget _buildIconByType(
    String iconData,
    CategoryIconType iconType,
    double size,
    Color? color,
  ) {
    switch (iconType) {
      case CategoryIconType.emoji:
        return _buildEmojiIcon(iconData, size);
      case CategoryIconType.custom:
        return _buildCustomIcon(iconData, size, color);
      case CategoryIconType.material:
        return _buildMaterialIcon(iconData, size, color);
    }
  }
}
