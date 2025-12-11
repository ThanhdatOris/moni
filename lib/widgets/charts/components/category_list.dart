import 'package:flutter/material.dart';
import 'package:moni/constants/app_colors.dart';

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

class _CategoryListState extends State<CategoryList>
    with TickerProviderStateMixin {
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
      return _buildEmptyState();
    }

    final displayData = _showAllCategories
        ? widget.data
        : widget.data.take(6).toList();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern header
          // _buildModernHeader(),
          // const SizedBox(height: 12),
          // Tab selector cho hierarchy mode
          _buildTabSelector(),
          // Grid categories
          _buildCategoriesGrid(displayData),
          // Show more section
          if (widget.data.length > 6) _buildShowMoreSection(),
        ],
      ),
    );
  }

  /// Empty state khi không có dữ liệu danh mục
  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // _buildModernHeader(),
          // const SizedBox(height: 12),
          _buildTabSelector(),
          const SizedBox(height: 24),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pie_chart_outline,
                    color: AppColors.grey600,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Không có dữ liệu danh mục',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.isAllFilter
                      ? 'Không có dữ liệu trong khoảng thời gian đã chọn'
                      : 'Thêm giao dịch để xem phân tích theo danh mục',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.grey600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build tab selector for hierarchy mode with sliding indicator
  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Stack(
        children: [
          // Sliding indicator
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: widget.showParentCategories
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Tab buttons
          Row(
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
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? AppColors.primary : AppColors.grey600,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
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
    return Container(
      margin: const EdgeInsets.only(top: 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive columns: 2 for compact, 3 for normal, 4 for tablet
          final crossAxisCount = widget.isCompact
              ? 2
              : (constraints.maxWidth > 600 ? 3 : 2);
          final childAspectRatio = widget.isCompact ? 1.35 : 1.5;

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
      ),
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
            colors: [Colors.white, color.withValues(alpha: 0.02)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
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
                padding: const EdgeInsets.all(8.0), // Reduced from 10
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // Distribute space
                  children: [
                    // Icon và percentage
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
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
                                  size: 16,
                                ),
                        ),
                        // Percentage badge (chỉ hiển thị khi không phải filter "all")
                        if (!widget.isAllFilter)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),
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
                    // const SizedBox(height: 2), // Removed fixed spacing
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category name
                        Text(
                          item.category,
                          style: const TextStyle(
                            fontSize: 12, // Reduced from 13
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1), // Reduced spacing
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
                        : [
                            AppColors.primary.withValues(alpha: 0.1),
                            AppColors.primary.withValues(alpha: 0.05),
                          ],
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
                      _showAllCategories
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: _showAllCategories
                          ? AppColors.grey600
                          : AppColors.primary,
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
                        color: _showAllCategories
                            ? AppColors.grey600
                            : AppColors.primary,
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
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
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
    debugPrint('📝 Category List item tapped: ${item.category}');
    
    // Call parent callback để navigate với filter
    widget.onCategoryTap?.call(item);
  }
}
