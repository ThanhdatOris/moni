import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../utils/category_icon_helper.dart';
import '../models/chart_data_model.dart';

class CategoryList extends StatefulWidget {
  final List<ChartDataModel> data;
  final bool isCompact;
  final Function(ChartDataModel)? onCategoryTap;
  final VoidCallback? onNavigateToHistory;

  const CategoryList({
    super.key,
    required this.data,
    required this.isCompact,
    this.onCategoryTap,
    this.onNavigateToHistory,
  });

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  bool _showAllCategories = false;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayData =
        _showAllCategories ? widget.data : widget.data.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header với title và show more button
        _buildHeader(),

        const SizedBox(height: 12),

        // Categories list
        _buildCategoriesList(displayData),
      ],
    );
  }

  /// Build header với title và show more button
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Top ${_showAllCategories ? widget.data.length : 5} danh mục',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (widget.data.length > 5)
          GestureDetector(
            onTap: () {
              setState(() {
                _showAllCategories = !_showAllCategories;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _showAllCategories ? 'Thu gọn' : 'Xem tất cả',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _showAllCategories
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Build categories list
  Widget _buildCategoriesList(List<ChartDataModel> displayData) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: displayData.map((item) {
          return _buildCategoryItem(item);
        }).toList(),
      ),
    );
  }

  /// Build individual category item
  Widget _buildCategoryItem(ChartDataModel item) {
    return GestureDetector(
      onTap: () => _onCategoryItemTap(item),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.grey200,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Color indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _parseColor(item.color),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),

            // Icon - Sử dụng CategoryIconHelper nếu có CategoryModel
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _parseColor(item.color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.categoryModel != null
                  ? CategoryIconHelper.buildIcon(
                      item.categoryModel!,
                      size: 20,
                      color: _parseColor(item.color),
                    )
                  : Icon(
                      _getFallbackIconData(item.icon),
                      color: _parseColor(item.color),
                      size: 20,
                    ),
            ),
            const SizedBox(width: 12),

            // Category info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.category,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),

            // Amount
            Text(
              '${_formatCurrency(item.amount)}₫',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(width: 8),

            // Arrow icon
            Icon(
              Icons.keyboard_arrow_right,
              color: AppColors.grey400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return AppColors.grey400;
    }
  }

  /// Fallback icon data khi không có CategoryModel
  IconData _getFallbackIconData(String iconName) {
    return CategoryIconHelper.getIconData(iconName);
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  // Event handlers
  void _onCategoryItemTap(ChartDataModel item) {
    // Call parent callback
    widget.onCategoryTap?.call(item);

    // Navigate to history with category filter
    widget.onNavigateToHistory?.call();

    debugPrint('Category item tapped: ${item.category}');
  }
}
