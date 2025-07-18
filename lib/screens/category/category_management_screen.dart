import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../services/category_service.dart';
import '../../utils/category_icon_helper.dart';
import 'add_edit_category_screen.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GetIt _getIt = GetIt.instance;
  late final CategoryService _categoryService;

  // State
  TransactionType _selectedType = TransactionType.expense;
  List<CategoryModel> _categories = [];
  List<CategoryModel> _filteredCategories = [];
  bool _isLoading = false;
  String _searchQuery = '';

  // Controllers
  final _searchController = TextEditingController();

  // Subscriptions
  StreamSubscription<List<CategoryModel>>? _categoriesSubscription;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _categoryService = _getIt<CategoryService>();

    // Listen to auth changes
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        if (user == null) {
          Navigator.of(context).pop();
        } else {
          _loadCategories();
        }
      }
    });

    _loadCategories();
  }

  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    _authSubscription?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _categoriesSubscription?.cancel();

      _categoriesSubscription =
          _categoryService.getCategories(type: _selectedType).listen(
        (categories) {
          if (mounted) {
            setState(() {
              _categories = categories;
              _filterCategories();
              _isLoading = false;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _showErrorSnackBar('Lỗi tải danh mục: $error');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Lỗi tải danh mục: $e');
      }
    }
  }

  void _filterCategories() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredCategories = _categories;
      } else {
        _filteredCategories = _categories
            .where((category) => category.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterCategories();
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _selectedType = type;
      _searchQuery = '';
      _searchController.clear();
    });
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTypeSelector(),
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _filteredCategories.isEmpty
                    ? _buildEmptyState()
                    : _buildCategoryList(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Quản lý danh mục',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              'Chi tiêu',
              TransactionType.expense,
              Icons.remove_circle_outline,
              AppColors.expense,
            ),
          ),
          Expanded(
            child: _buildTypeButton(
              'Thu nhập',
              TransactionType.income,
              Icons.add_circle_outline,
              AppColors.income,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(
    String title,
    TransactionType type,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => _onTypeChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withValues(alpha:0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm danh mục...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha:0.7),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              child: Icon(
                Icons.clear,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Đang tải danh mục...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha:0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Không tìm thấy danh mục nào'
                : 'Chưa có danh mục ${_selectedType == TransactionType.expense ? 'chi tiêu' : 'thu nhập'}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Thử tìm kiếm với từ khóa khác'
                : 'Bấm nút + để tạo danh mục đầu tiên',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha:0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    // Group categories by parent-child relationship
    final parentCategories = _filteredCategories
        .where((category) => category.isParentCategory)
        .toList();

    final childCategories = _filteredCategories
        .where((category) => category.isChildCategory)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Parent categories
        ...parentCategories.map((category) {
          final children = childCategories
              .where((child) => child.parentId == category.categoryId)
              .toList();

          return _buildCategoryGroup(category, children);
        }),

        // Orphaned child categories (parent not found)
        ...childCategories
            .where((child) => !parentCategories
                .any((parent) => parent.categoryId == child.parentId))
            .map((category) => _buildCategoryItem(category, isChild: true)),

        const SizedBox(height: 80), // Space for FAB
      ],
    );
  }

  Widget _buildCategoryGroup(
      CategoryModel parent, List<CategoryModel> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCategoryItem(parent, isParent: true),
          if (children.isNotEmpty) ...[
            const Divider(height: 1),
            ...children
                .map((child) => _buildCategoryItem(child, isChild: true)),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    CategoryModel category, {
    bool isParent = false,
    bool isChild = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.only(
        left: isChild ? 32 : 16,
        right: 16,
        top: 8,
        bottom: 8,
      ),
      leading: CategoryIconHelper.buildIcon(
        category,
        size: 24,
        color: Color(category.color),
        showBackground: true,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              category.name,
              style: TextStyle(
                fontSize: isParent ? 16 : 15,
                fontWeight: isParent ? FontWeight.w600 : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (category.isDefault)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha:0.1),
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Edit button
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            onPressed: () => _editCategory(category),
          ),
          // Delete button (only for non-default categories)
          if (!category.isDefault)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: AppColors.error,
              ),
              onPressed: () => _deleteCategory(category),
            ),
        ],
      ),
      onTap: () => _editCategory(category),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _addCategory,
      backgroundColor: AppColors.primary,
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  void _addCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCategoryScreen(
          transactionType: _selectedType,
        ),
      ),
    );

    if (result == true) {
      _showSuccessSnackBar('Đã tạo danh mục thành công');
    }
  }

  void _editCategory(CategoryModel category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCategoryScreen(
          category: category,
          transactionType: _selectedType,
        ),
      ),
    );

    if (result == true) {
      _showSuccessSnackBar('Đã cập nhật danh mục thành công');
    }
  }

  void _deleteCategory(CategoryModel category) async {
    final confirm = await _showDeleteConfirmDialog(category);
    if (confirm != true) return;

    try {
      await _categoryService.deleteCategory(category.categoryId);
      _showSuccessSnackBar('Đã xóa danh mục thành công');
    } catch (e) {
      _showErrorSnackBar('Lỗi xóa danh mục: $e');
    }
  }

  Future<bool?> _showDeleteConfirmDialog(CategoryModel category) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa danh mục "${category.name}"?\n\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
