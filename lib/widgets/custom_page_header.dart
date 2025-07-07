import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Widget tiêu đề tùy chỉnh cho các trang trong ứng dụng Moni
/// Sử dụng thay thế cho AppBar để tạo giao diện nhất quán giữa các trang
class CustomPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget>? actions;

  const CustomPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Title Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              // Optional actions
              if (actions != null) ...actions!,
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
