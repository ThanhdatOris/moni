import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../models/category.dart';
import '../models/transaction.dart';

class CategorySelectorScreen extends StatefulWidget {
  final TransactionType transactionType;
  final Category? selectedCategory;

  const CategorySelectorScreen({
    super.key,
    required this.transactionType,
    this.selectedCategory,
  });

  @override
  State<CategorySelectorScreen> createState() => _CategorySelectorScreenState();
}

class _CategorySelectorScreenState extends State<CategorySelectorScreen> {
  List<Category> _categories = [];
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _selectedCategory = widget.selectedCategory;
  }

  void _loadCategories() {
    final allCategories = Category.getDefaultCategories();
    _categories = allCategories
        .where((category) => category.type == widget.transactionType)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.transactionType == TransactionType.income
            ? AppStrings.incomeCategory
            : AppStrings.expenseCategory),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildCategoryGrid(),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final isSelected = _selectedCategory?.id == category.id;
        return _buildCategoryItem(category, isSelected);
      },
    );
  }

  Widget _buildCategoryItem(Category category, bool isSelected) {
    return InkWell(
      onTap: () => _selectCategory(category),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected 
              ? category.color.withOpacity(0.2) 
              : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? category.color : AppColors.grey200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(category.icon, color: category.color, size: 32),
            const SizedBox(height: 8),
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.cancel),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _selectedCategory != null ? _confirmSelection : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Chọn danh mục'),
            ),
          ),
        ],
      ),
    );
  }

  void _selectCategory(Category category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _confirmSelection() {
    if (_selectedCategory != null) {
      Navigator.pop(context, _selectedCategory);
    }
  }
} 