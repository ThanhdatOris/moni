import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../services/services.dart';
import '../../utils/helpers/category_icon_helper.dart';
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
    
    // Sync TabController with selected type
    final tabIndex = type == TransactionType.expense ? 0 : 1;
    if (_tabController.index != tabIndex) {
      _tabController.animateTo(tabIndex);
    }
    
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Tab Bar
            _buildTabBar(),
            
            // Search Bar
            _buildSearchBar(),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCategoryList(TransactionType.expense),
                  _buildCategoryList(TransactionType.income),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.grey100,
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quản lý danh mục',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Tạo và chỉnh sửa danh mục',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelPadding: const EdgeInsets.symmetric(vertical: 6),
        onTap: (index) {
          final newType = index == 0 ? TransactionType.expense : TransactionType.income;
          if (newType != _selectedType) {
            _onTypeChanged(newType);
          }
        },
        tabs: [
          Tab(
            height: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_down, size: 18),
                const SizedBox(width: 8),
                Text('Chi tiêu'),
              ],
            ),
          ),
          Tab(
            height: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up, size: 18),
                const SizedBox(width: 8),
                Text('Thu nhập'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm danh mục...',
          prefixIcon: Icon(Icons.search, color: AppColors.grey600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.grey200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.grey200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildCategoryList(TransactionType type) {
    // Load categories for the requested type
    if (type != _selectedType) {
      // Load categories for this type in background
      return FutureBuilder<List<CategoryModel>>(
        future: _categoryService.getCategories(type: type).first,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }
          
          if (snapshot.hasError) {
            return _buildErrorState('Lỗi: ${snapshot.error}');
          }
          
          final categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return _buildEmptyState(type);
          }
          
          return _buildCategoryListContent(categories, type);
        },
      );
    }

    // Use loaded data for current selected type
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_filteredCategories.isEmpty) {
      return _buildEmptyState(_selectedType);
    }

    return _buildCategoryListContent(_filteredCategories, _selectedType);
  }

  Widget _buildCategoryListContent(List<CategoryModel> categories, TransactionType type) {
    // Apply search filter if we're on the current selected type
    List<CategoryModel> filteredCategories = categories;
    if (type == _selectedType && _searchQuery.isNotEmpty) {
      filteredCategories = categories
          .where((category) => category.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    
    // Group categories: parents first, then children
    final parentCategories = filteredCategories.where((c) => c.parentId == null).toList();
    final childCategories = filteredCategories.where((c) => c.parentId != null).toList();
    
    final organizedCategories = <CategoryModel>[];
    
    // Add parent categories and their children
    for (final parent in parentCategories) {
      organizedCategories.add(parent);
      
      // Add children of this parent
      final children = childCategories.where((c) => c.parentId == parent.categoryId).toList();
      organizedCategories.addAll(children);
    }
    
    // Add orphaned children (those whose parent might be deleted)
    final orphanedChildren = childCategories.where((c) => 
      !parentCategories.any((p) => p.categoryId == c.parentId)).toList();
    organizedCategories.addAll(orphanedChildren);

    if (organizedCategories.isEmpty) {
      return _buildEmptyState(type);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: organizedCategories.length,
      itemBuilder: (context, index) {
        final category = organizedCategories[index];
        final isChild = category.parentId != null;
        return _buildCategoryItem(category, isChild);
      },
    );
  }

  Widget _buildCategoryItem(CategoryModel category, [bool isChild = false]) {
    return Container(
      margin: EdgeInsets.only(
        bottom: 12,
        left: isChild ? 24 : 0, // Indent child categories
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isChild ? Border.all(
          color: AppColors.grey200,
          width: 1,
        ) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isChild ? 0.02 : 0.04),
            blurRadius: isChild ? 4 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(isChild ? 12 : 16),
        leading: Container(
          padding: EdgeInsets.all(isChild ? 8 : 12),
          decoration: BoxDecoration(
            color: Color(category.color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(isChild ? 8 : 12),
          ),
          child: CategoryIconHelper.buildIcon(
            category,
            size: isChild ? 16 : 20,
            color: Color(category.color),
          ),
        ),
        title: Row(
          children: [
            if (isChild) ...[
              Icon(
                Icons.subdirectory_arrow_right,
                size: 16,
                color: AppColors.grey400,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                category.name,
                style: TextStyle(
                  fontSize: isChild ? 14 : 16,
                  fontWeight: isChild ? FontWeight.w500 : FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        subtitle: isChild
            ? Text(
                'Danh mục con',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.grey600,
                ),
              )
            : (category.parentId != null
                ? Text(
                    'Thuộc danh mục cha',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.grey600,
                    ),
                  )
                : null),
        trailing: category.isDefault
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Mặc định',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _editCategory(category),
                    icon: Icon(Icons.edit_outlined, color: AppColors.primary),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      padding: EdgeInsets.all(isChild ? 6 : 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _deleteCategory(category),
                    icon: Icon(Icons.delete_outline, color: AppColors.error),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.error.withValues(alpha: 0.1),
                      padding: EdgeInsets.all(isChild ? 6 : 8),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _addCategory,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          'Thêm ${_selectedType == TransactionType.expense ? 'chi tiêu' : 'thu nhập'}',
          key: ValueKey(_selectedType),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
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

  Widget _buildEmptyState([TransactionType? type]) {
    final displayType = type ?? _selectedType;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Không tìm thấy danh mục nào'
                : 'Chưa có danh mục ${displayType == TransactionType.expense ? 'chi tiêu' : 'thu nhập'}',
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
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadCategories(),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  void _addCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCategoryV2Screen(
          initialTransactionType: _selectedType,
        ),
      ),
    );

    if (result == true) {
      _showSuccessSnackBar('Đã tạo danh mục thành công');
    }
  }

  void _editCategory(CategoryModel category) async {
    if (category.isDefault) {
      _showErrorSnackBar('Không thể chỉnh sửa danh mục mặc định');
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCategoryV2Screen(
          category: category,
          initialTransactionType: category.type,
        ),
      ),
    );

    if (result == true) {
      _showSuccessSnackBar('Đã cập nhật danh mục thành công');
    }
  }

  void _deleteCategory(CategoryModel category) async {
    if (category.isDefault) {
      _showErrorSnackBar('Không thể xóa danh mục mặc định');
      return;
    }

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
