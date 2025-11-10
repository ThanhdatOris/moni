import 'package:flutter/material.dart';

import 'package:moni/config/app_config.dart';

import '../../../models/category_model.dart';
import '../../../utils/helpers/category_icon_helper.dart';

class CategoryPreviewCard extends StatelessWidget {
  final String? selectedIcon;
  final CategoryIconType selectedIconType;
  final Color selectedColor;
  final String categoryName;
  final CategoryModel? selectedParent;

  const CategoryPreviewCard({
    super.key,
    required this.selectedIcon,
    required this.selectedIconType,
    required this.selectedColor,
    required this.categoryName,
    this.selectedParent,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            selectedColor.withValues(alpha: 0.1),
            selectedColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selectedColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selectedColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: selectedIcon != null
                ? _buildIconWidget(selectedIcon!, selectedIconType)
                : Icon(
                    Icons.category_rounded,
                    color: selectedColor,
                    size: 24,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName.isEmpty 
                      ? 'Tên danh mục...' 
                      : categoryName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: categoryName.isEmpty 
                        ? AppColors.grey400 
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (selectedParent != null) ...[
                      Text(
                        'Thuộc: ${selectedParent!.name}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey600,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Danh mục độc lập',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconWidget(String icon, CategoryIconType iconType) {
    switch (iconType) {
      case CategoryIconType.emoji:
        return Text(
          icon,
          style: const TextStyle(fontSize: 24),
        );
      case CategoryIconType.material:
        return Icon(
          CategoryIconHelper.getIconData(icon),
          color: selectedColor,
          size: 24,
        );
      case CategoryIconType.custom:
        // For now, show material icon as fallback
        return Icon(
          CategoryIconHelper.getIconData('category'),
          color: selectedColor,
          size: 24,
        );
    }
  }
}
