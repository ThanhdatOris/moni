import 'package:flutter/material.dart';

import 'package:moni/constants/app_colors.dart';
import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import '../../category/category_management_screen.dart';
import 'package:moni/services/services.dart';
import '../../../utils/helpers/category_icon_helper.dart';

/// Enhanced category selector với grid layout và smart suggestions
class EnhancedCategorySelector extends StatefulWidget {
  final CategoryModel? selectedCategory;
  final List<CategoryModel> categories;
  final bool isLoading;
  final String? errorMessage;
  final Function(CategoryModel?) onCategoryChanged;
  final VoidCallback onRetry;
  final String? Function(CategoryModel?)? validator;
  final TransactionType transactionType;
  final String? transactionNote;
  final DateTime? transactionTime;

  const EnhancedCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.categories,
    required this.isLoading,
    this.errorMessage,
    required this.onCategoryChanged,
    required this.onRetry,
    this.validator,
    required this.transactionType,
    this.transactionNote,
    this.transactionTime,
  });

  @override
  State<EnhancedCategorySelector> createState() => _EnhancedCategorySelectorState();
}

class _EnhancedCategorySelectorState extends State<EnhancedCategorySelector> {
  final TextEditingController _searchController = TextEditingController();
  final CategoryUsageTracker _usageTracker = CategoryUsageTracker();
  String _searchQuery = '';
  bool _isExpanded = false;
  List<CategorySuggestion> _suggestions = [];
  List<CategoryModel> _recentCategories = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void didUpdateWidget(EnhancedCategorySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactionNote != widget.transactionNote ||
        oldWidget.transactionTime != widget.transactionTime ||
        oldWidget.transactionType != widget.transactionType) {
      _loadSuggestions();
    }
  }

  Future<void> _loadSuggestions() async {
    if (widget.categories.isEmpty) return;
    
    setState(() {
    });

    try {
      final suggestions = await _usageTracker.getSuggestedCategories(
        transactionType: widget.transactionType,
        availableCategories: widget.categories,
        transactionNote: widget.transactionNote,
        transactionTime: widget.transactionTime,
      );

      final recent = await _usageTracker.getRecentCategories(
        transactionType: widget.transactionType,
        availableCategories: widget.categories,
      );

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _recentCategories = recent;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CategoryModel> get _filteredCategories {
    if (_searchQuery.isEmpty) return widget.categories;
    
    return widget.categories.where((category) {
      return category.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Widget _buildSuggestionChip(CategorySuggestion suggestion) {
    return ActionChip(
      avatar: CircleAvatar(
        backgroundColor: Colors.blue[100],
        child: Icon(
          Icons.category,
          color: Colors.blue[600],
          size: 16,
        ),
      ),
      label: Text(
        suggestion.category.name,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.blue[50],
      onPressed: () {
        widget.onCategoryChanged(suggestion.category);
      },
    );
  }

  Widget _buildRecentCategoryChip(CategoryModel category) {
    return ActionChip(
      avatar: CircleAvatar(
        backgroundColor: Colors.green[100],
        child: Icon(
          Icons.category,
          color: Colors.green[600],
          size: 16,
        ),
      ),
      label: Text(
        category.name,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.green[50],
      onPressed: () {
        widget.onCategoryChanged(category);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          if (widget.errorMessage != null)
            _buildErrorState()
          else if (widget.isLoading)
            _buildLoadingState()
          else if (widget.categories.isEmpty)
            _buildEmptyState()
          else
            _buildCategoryContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.category_outlined,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Danh mục',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (!widget.isLoading && widget.errorMessage == null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${widget.categories.length} danh mục',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            'Lỗi tải danh mục',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.errorMessage!,
            style: TextStyle(
              color: AppColors.error.withValues(alpha: 0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: widget.onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Đang tải danh mục...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.category_outlined,
            color: Colors.orange,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Chưa có danh mục',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _navigateToManageCategories(),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Tạo danh mục'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Smart suggestions
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Gợi ý thông minh',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  child: _buildSuggestionChip(suggestion),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // Recent categories
        if (_recentCategories.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Gần đây',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recentCategories.length,
              itemBuilder: (context, index) {
                final category = _recentCategories[index];
                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  child: _buildRecentCategoryChip(category),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // Selected category display
        if (widget.selectedCategory != null)
          _buildSelectedCategory(),
        
        // Search bar
        if (widget.categories.length > 6)
          _buildSearchBar(),
        
        // Category grid - always show, but limit when not expanded
        _buildCategoryGrid(),
        
        // Expand/Collapse button - only show if more than 6 categories
        if (_filteredCategories.length > 6)
          _buildToggleButton(),
        
        // Manage categories button
        _buildManageCategoriesButton(),
      ],
    );
  }

  Widget _buildSelectedCategory() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(widget.selectedCategory!.color),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              CategoryIconHelper.getIconData(widget.selectedCategory!.icon),
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.selectedCategory!.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => widget.onCategoryChanged(null),
            icon: const Icon(Icons.close, size: 16),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Tìm kiếm danh mục...',
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = _filteredCategories;
    
    // Limit categories when not expanded
    final displayCategories = _isExpanded 
        ? categories 
        : categories.take(6).toList();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: displayCategories.length,
        itemBuilder: (context, index) {
          final category = displayCategories[index];
          final isSelected = widget.selectedCategory?.categoryId == category.categoryId;
          
          return _buildCategoryItem(category, isSelected);
        },
      ),
    );
  }

  Widget _buildCategoryItem(CategoryModel category, bool isSelected) {
    return GestureDetector(
      onTap: () => widget.onCategoryChanged(category),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected 
            ? AppColors.primary.withValues(alpha: 0.1)
            : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
              ? AppColors.primary
              : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(category.color),
                borderRadius: BorderRadius.circular(6),
              ),
              child: category.iconType == CategoryIconType.emoji
                ? Text(
                    category.icon,
                    style: const TextStyle(fontSize: 20),
                  )
                : Icon(
                    CategoryIconHelper.getIconData(category.icon),
                    color: Colors.white,
                    size: 20,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        icon: Icon(
          _isExpanded ? Icons.expand_less : Icons.expand_more,
          size: 16,
        ),
        label: Text(
          _isExpanded ? 'Thu gọn' : 'Xem thêm',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildManageCategoriesButton() {
    return Center(
      child: TextButton.icon(
        onPressed: _navigateToManageCategories,
        icon: const Icon(Icons.settings, size: 16),
        label: const Text('Quản lý danh mục'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
        ),
      ),
    );
  }

  void _navigateToManageCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryManagementScreen(),
      ),
    );
  }
}
