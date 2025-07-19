import 'package:flutter/material.dart';

import '../../../utils/currency_formatter.dart';
import '../core/chart_theme.dart';
import '../models/chart_data_models.dart';

/// Expandable list component để hiển thị chi tiết category
/// Thay thế popup với UX tốt hơn
class CategoryDetailsList extends StatefulWidget {
  final List<CategoryAnalysisData> categories;
  final ChartTheme? theme;
  final int initialDisplayCount;
  final Function(CategoryAnalysisData)? onCategoryTap;

  const CategoryDetailsList({
    super.key,
    required this.categories,
    this.theme,
    this.initialDisplayCount = 3,
    this.onCategoryTap,
  });

  @override
  State<CategoryDetailsList> createState() => _CategoryDetailsListState();
}

class _CategoryDetailsListState extends State<CategoryDetailsList>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;
  int _displayCount = 3;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _displayCount = widget.initialDisplayCount;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _displayCount = widget.categories.length;
        _animationController.forward();
      } else {
        _displayCount = widget.initialDisplayCount;
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? ChartThemeProvider.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryList(theme),
          if (widget.categories.length > widget.initialDisplayCount) ...[
            const SizedBox(height: 8),
            _buildExpandButton(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryList(ChartTheme theme) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: _animation,
          child: Column(
            children: widget.categories
                .take(_displayCount)
                .map((category) => _buildCategoryItem(category, theme))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildCategoryItem(CategoryAnalysisData category, ChartTheme theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: InkWell(
        onTap: () => widget.onCategoryTap?.call(category),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Category color indicator với animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: category.color,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: category.color.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Category info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category.categoryName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: category.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${category.percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: category.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            CurrencyFormatter.formatVND(category.totalAmount),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${category.transactionCount} giao dịch',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Trung bình: ${CurrencyFormatter.formatVND(category.averageTransaction)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
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

  Widget _buildExpandButton(ChartTheme theme) {
    return InkWell(
      onTap: _toggleExpansion,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _isExpanded
                  ? 'Thu gọn'
                  : 'Xem thêm ${widget.categories.length - widget.initialDisplayCount} danh mục',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
