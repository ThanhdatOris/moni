import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/category_model.dart';
import '../../../utils/helpers/category_icon_helper.dart';

class AnimatedCategoryList extends StatefulWidget {
  final List<CategoryModel> categories;
  final List<CategoryModel> filteredCategories;
  final double swipeOffset;
  final bool isAnimating;
  final VoidCallback onAddCategory;
  final Function(CategoryModel) onEditCategory;
  final Function(CategoryModel) onDeleteCategory;

  const AnimatedCategoryList({
    super.key,
    required this.categories,
    required this.filteredCategories,
    this.swipeOffset = 0.0,
    this.isAnimating = false,
    required this.onAddCategory,
    required this.onEditCategory,
    required this.onDeleteCategory,
  });

  @override
  State<AnimatedCategoryList> createState() => _AnimatedCategoryListState();
}

class _AnimatedCategoryListState extends State<AnimatedCategoryList>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 200), // Reduced from 400ms
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 150), // Reduced from 300ms
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03), // Reduced from 0.1 to 0.03
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut, // Changed from easeOutCubic for gentler effect
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.7, // Start from 0.7 instead of 0.0 for less dramatic fade
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Start animations with slight delay to reduce jarring effect
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedCategoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filteredCategories.length != widget.filteredCategories.length) {
      // Only re-animate if significant change, and with gentler effect
      if ((oldWidget.filteredCategories.length - widget.filteredCategories.length).abs() > 1) {
        _fadeController.reset();
        _slideController.reset();
        Future.delayed(const Duration(milliseconds: 30), () {
          if (mounted) {
            _fadeController.forward();
            _slideController.forward();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group categories by parent-child relationship
    final parentCategories = widget.filteredCategories
        .where((category) => category.isParentCategory)
        .toList();

    final childCategories = widget.filteredCategories
        .where((category) => category.isChildCategory)
        .toList();

    return AnimatedBuilder(
      animation: Listenable.merge([_slideController, _fadeController]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Transform.translate(
              offset: Offset(widget.swipeOffset * 0.3, 0),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: widget.isAnimating ? 0.8 : 1.0,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Parent categories with their children
                    ...parentCategories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final category = entry.value;
                      final children = childCategories
                          .where((child) => child.parentId == category.categoryId)
                          .toList();
                      children.sort((a, b) => a.name.compareTo(b.name));

                      return AnimatedContainer(
                        duration: Duration(milliseconds: (150 + (index * 20)).round()),
                        curve: Curves.easeOut,
                        child: _buildCategoryGroup(category, children, index),
                      );
                    }),

                    // Standalone categories (không có parent valid)
                    ...() {
                      final standaloneCategories = childCategories
                          .where((child) {
                            // Kiểm tra xem parent có tồn tại trong danh sách không
                            final hasValidParent = parentCategories
                                .any((parent) => parent.categoryId == child.parentId);
                            return !hasValidParent;
                          })
                          .toList();
                      standaloneCategories.sort((a, b) => a.name.compareTo(b.name));
                      
                      return standaloneCategories.asMap().entries.map((entry) {
                        final index = entry.key + parentCategories.length;
                        final category = entry.value;
                        return AnimatedContainer(
                          duration: Duration(milliseconds: (150 + (index * 20)).round()),
                          curve: Curves.easeOut,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _buildCategoryItem(
                              category, 
                              isChild: false, 
                              index: index
                            ),
                          ),
                        );
                      });
                    }(),

                    const SizedBox(height: 80), // Space for FAB
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryGroup(
      CategoryModel parent, List<CategoryModel> children, int groupIndex) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: (200 + (groupIndex * 30)).round()), // Reduced timing
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut, // Gentler curve
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value), // Much more subtle scale effect
          child: Opacity(
            opacity: 0.3 + (0.7 * value), // Start from 0.3 instead of 0.0
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05 * value),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                  // Enhanced shadow during swipe
                  if (widget.swipeOffset.abs() > 10)
                    BoxShadow(
                      color: AppColors.primary.withValues(
                          alpha: 0.1 * (widget.swipeOffset.abs() / 100).clamp(0.0, 1.0)),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                ],
              ),
              child: Column(
                children: [
                  _buildCategoryItem(parent, isParent: true, index: groupIndex),
                  if (children.isNotEmpty) ...[
                    const Divider(height: 1),
                    ...children.asMap().entries.map((entry) {
                      final childIndex = entry.key;
                      final child = entry.value;
                      return AnimatedContainer(
                        duration: Duration(milliseconds: (100 + (childIndex * 30)).round()), // Reduced timing
                        child: _buildCategoryItem(
                          child,
                          isChild: true,
                          index: groupIndex + childIndex + 1,
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryItem(
    CategoryModel category, {
    bool isParent = false,
    bool isChild = false,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: (150 + (index * 20)).round()), // Reduced timing and stagger
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut, // Gentler curve
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset((1 - value) * 15, 0), // Reduced slide distance
          child: Opacity(
            opacity: 0.4 + (0.6 * value), // Start from 0.4 instead of 0.0
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: widget.swipeOffset.abs() > 20
                    ? AppColors.backgroundLight.withValues(alpha: 0.5)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.only(
                  left: isChild ? 32 : 16,
                  right: 16,
                  top: 8,
                  bottom: 8,
                ),
                leading: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: CategoryIconHelper.buildIcon(
                    category,
                    size: 24 + (widget.swipeOffset.abs() > 30 ? 2 : 0),
                    color: Color(category.color),
                    showBackground: true,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: isParent ? 16 : 15,
                          fontWeight: isParent ? FontWeight.w600 : FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        child: Text(category.name),
                      ),
                    ),
                    if (category.isDefault)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Mặc định',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit button with hover effect
                      _buildActionButton(
                        icon: Icons.edit_outlined,
                        color: AppColors.textSecondary,
                        onPressed: () => widget.onEditCategory(category),
                      ),
                      // Delete button (only for non-default categories)
                      if (!category.isDefault)
                        _buildActionButton(
                          icon: Icons.delete_outline,
                          color: AppColors.error,
                          onPressed: () => widget.onDeleteCategory(category),
                        ),
                    ],
                  ),
                ),
                onTap: () => widget.onEditCategory(category),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 1.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: IconButton(
            icon: Icon(
              icon,
              size: 20,
              color: color,
            ),
            onPressed: onPressed,
            splashRadius: 20,
            hoverColor: color.withValues(alpha: 0.1),
          ),
        );
      },
    );
  }
}
