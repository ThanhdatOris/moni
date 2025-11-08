import 'package:flutter/material.dart';

import 'package:moni/constants/app_colors.dart';
import '../../../models/category_model.dart';
import '../../../utils/helpers/category_icon_helper.dart';
import '../../category/category_management_screen.dart';

class TransactionCategorySelector extends StatelessWidget {
  final CategoryModel? selectedCategory;
  final List<CategoryModel> categories;
  final bool isLoading;
  final String? errorMessage;
  final Function(CategoryModel?) onCategoryChanged;
  final VoidCallback onRetry;
  final String? Function(CategoryModel?)? validator;

  const TransactionCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.categories,
    required this.isLoading,
    this.errorMessage,
    required this.onCategoryChanged,
    required this.onRetry,
    this.validator,
  });

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
          Row(
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
              if (!isLoading && errorMessage == null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${categories.length} danh mục',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (errorMessage != null)
            _buildErrorState()
          else if (isLoading)
            _buildLoadingState()
          else if (categories.isEmpty)
            _buildEmptyState()
          else
            Column(
              children: [
                _buildCategoryDropdown(),
                _buildManageCategoriesButton(context),
              ],
            ),
        ],
      ),
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
            errorMessage!,
            style: TextStyle(
              color: AppColors.error.withValues(alpha: 0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onRetry,
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
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Chưa có danh mục nào. Vui lòng tạo danh mục trước.',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      children: [
        DropdownButtonFormField<CategoryModel>(
          initialValue: selectedCategory,
          decoration: InputDecoration(
            hintText: 'Chọn danh mục',
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: categories.map((category) {
            return DropdownMenuItem<CategoryModel>(
              value: category,
              child: Row(
                mainAxisSize: MainAxisSize.min, // Fix unbounded width constraint
                children: [
                  // Icon hiển thị bằng CategoryIconHelper
                  CategoryIconHelper.buildIcon(
                    category,
                    size: 12, // size = 12
                    color: Color(category.color),
                    showBackground: true,
                    isCompact: true, // Compact mode cho dropdown: 12 + 6 = 18 < 24
                  ),
                  const SizedBox(width: 8),
                  Flexible( // Thay Expanded bằng Flexible
                    child: Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis, // Handle long text
                    ),
                  ),
                  // Hiển thị badge cho parent/child category
                  if (category.isChildCategory)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Color(category.color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Con',
                        style: TextStyle(
                          fontSize: 9,
                          color: Color(category.color),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: onCategoryChanged,
          validator: validator ?? _defaultValidator,
          dropdownColor: Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildManageCategoriesButton(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _navigateToCategoryManagement(context),
            icon: Icon(
              Icons.settings,
              size: 16,
              color: AppColors.primary,
            ),
            label: Text(
              'Quản lý danh mục',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToCategoryManagement(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryManagementScreen(),
      ),
    );
  }

  String? _defaultValidator(CategoryModel? value) {
    if (value == null) {
      return 'Vui lòng chọn danh mục';
    }
    return null;
  }
}
