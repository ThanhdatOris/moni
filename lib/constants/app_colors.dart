import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFFFFA726);
  static const Color primaryDark = Color(0xFFFF7043);
  static const Color primaryLight = Color(0xFFFFCC80);
  
  // Background colors
  static const Color background = Color(0xFFF2F2F7);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF1A1A1A);
  
  // Text colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  static const Color textWhite = Color(0xFFFFFFFF);
  
  // Category colors
  static const Color income = Color(0xFF4CAF50);
  static const Color expense = Color(0xFFF44336);
  static const Color food = Color(0xFFFF9800);
  static const Color transport = Color(0xFF2196F3);
  static const Color shopping = Color(0xFF9C27B0);
  static const Color entertainment = Color(0xFFE91E63);
  static const Color bills = Color(0xFF607D8B);
  static const Color health = Color(0xFF8BC34A);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Neutral colors
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFE0E0E0);
  static const Color grey300 = Color(0xFFBDBDBD);
  static const Color grey400 = Color(0xFF9E9E9E);
  static const Color grey500 = Color(0xFF757575);
  static const Color grey600 = Color(0xFF616161);
  static const Color grey700 = Color(0xFF424242);
  static const Color grey800 = Color(0xFF212121);
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [backgroundLight, grey100],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
} 