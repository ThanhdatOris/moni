import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../utils/helpers/category_icon_helper.dart';
import '../models/chart_data_model.dart';

class CategoryList extends StatefulWidget {
  final List<ChartDataModel> data;
  final bool isCompact;
  final bool isAllFilter; // Thêm để biết khi nào filter là "all"
  final bool showParentCategories; // Thêm để biết mode hiện tại
  final Function(ChartDataModel)? onCategoryTap;
  final VoidCallback? onNavigateToHistory;
  final Function(bool)? onHierarchyModeChanged; // Callback khi chuyển tab

  const CategoryList({
    super.key,
    required this.data,
    required this.isCompact,
    this.isAllFilter = false,
    this.showParentCategories = true,
    this.onCategoryTap,
    this.onNavigateToHistory,
    this.onHierarchyModeChanged,
  });

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> with TickerProviderStateMixin {
  bool _showAllCategories = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayData = _showAllCategories ? widget.data : widget.data.take(6).toList();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppColors.grey100,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern header
            _buildModernHeader(),
            const SizedBox(height: 12),
            // Tab selector cho hierarchy mode
            _buildTabSelector(),
            const SizedBox(height: 16),
            // Grid categories
            _buildCategoriesGrid(displayData),
            // Show more section
            if (widget.data.length > 6) _buildShowMoreSection(),
          ],
        ),
      ),
    );
  }

  /// Build modern header với statistics
  Widget _buildModernHeader() {
    final totalAmount = widget.data.fold<double>(0, (sum, item) => sum + item.amount);
    final topCategory = widget.data.isNotEmpty ? widget.data.first : null;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.category,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Danh mục hàng đầu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 16,
                    color: AppColors.grey600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.data.length} danh mục • ${_formatCurrency(totalAmount)}₫',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.grey600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (topCategory != null && !widget.isAllFilter)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: _parseColor(topCategory.color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _parseColor(topCategory.color).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  size: 14,
                  color: _parseColor(topCategory.color),
                ),
                const SizedBox(width: 4),
                Text(
                  '${topCategory.percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _parseColor(topCategory.color),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Build tab selector for hierarchy mode
  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              title: 'Danh mục cha',
              icon: Icons.folder_outlined,
              isActive: widget.showParentCategories,
              onTap: () {
                if (!widget.showParentCategories) {
                  widget.onHierarchyModeChanged?.call(true);
                }
              },
            ),
          ),
          Expanded(
            child: _buildTabButton(
              title: 'Danh mục con',
              icon: Icons.account_tree_outlined,
              isActive: !widget.showParentCategories,
              onTap: () {
                if (widget.showParentCategories) {
                  widget.onHierarchyModeChanged?.call(false);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual tab button
  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppColors.primary : AppColors.grey600,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build modern grid layout
  Widget _buildCategoriesGrid(List<ChartDataModel> displayData) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive columns: 2 for compact, 3 for normal, 4 for tablet
        final crossAxisCount = widget.isCompact ? 2 : (constraints.maxWidth > 600 ? 3 : 2);
        final childAspectRatio = widget.isCompact ? 1.2 : 1.3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: displayData.length,
          itemBuilder: (context, index) {
            return _buildModernCategoryCard(displayData[index], index);
          },
        );
      },
    );
  }

  /// Build modern category card
  Widget _buildModernCategoryCard(ChartDataModel item, int index) {
    final color = _parseColor(item.color);
    
    return GestureDetector(
      onTap: () => _onCategoryItemTap(item),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200 + (index * 50)),
        curve: Curves.easeOutBack,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              color.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background pattern
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon và percentage
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: item.categoryModel != null
                              ? CategoryIconHelper.buildIcon(
                                  item.categoryModel!,
                                  size: 18,
                                  color: color,
                                )
                              : Icon(
                                  _getFallbackIconData(item.icon),
                                  color: color,
                                  size: 18,
                                ),
                        ),
                        // Percentage badge (chỉ hiển thị khi không phải filter "all")
                        if (!widget.isAllFilter)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${item.percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    // Category name
                    Text(
                      item.category,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Amount
                    Text(
                      '${_formatCurrency(item.amount)}₫',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build show more section
  Widget _buildShowMoreSection() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showAllCategories = !_showAllCategories;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _showAllCategories
                        ? [AppColors.grey200, AppColors.grey100]
                        : [AppColors.primary.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _showAllCategories 
                        ? AppColors.grey300 
                        : AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _showAllCategories ? Icons.expand_less : Icons.expand_more,
                      color: _showAllCategories ? AppColors.grey600 : AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _showAllCategories 
                          ? 'Thu gọn' 
                          : 'Xem thêm ${widget.data.length - 6} danh mục',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _showAllCategories ? AppColors.grey600 : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: widget.onNavigateToHistory,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
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
