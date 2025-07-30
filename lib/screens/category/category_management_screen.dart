import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../services/category_service.dart';
import 'add_edit_category_v2_screen.dart';
import 'widgets/animated_category_list.dart';
import 'widgets/animated_floating_action_button.dart';
import 'widgets/animated_search_bar.dart';
import 'widgets/animated_type_selector.dart';

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
  bool _isSwipeInProgress = false;
  double _swipeOffset = 0.0;
  bool _isAnimating = false;

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

  Future<void> _performSwipeAnimation(TransactionType newType) async {
    setState(() {
      _isAnimating = true;
    });

    // Animate to full swipe position with easing
    await Future.delayed(const Duration(milliseconds: 80));
    setState(() {
      _swipeOffset = newType == TransactionType.expense ? 60.0 : -60.0;
    });

    // Brief pause before changing tab
    await Future.delayed(const Duration(milliseconds: 120));
    _onTypeChanged(newType);

    // Smooth reset animation
    await Future.delayed(const Duration(milliseconds: 80));
    setState(() {
      _swipeOffset = 0.0;
    });
    
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      _isAnimating = false;
      _isSwipeInProgress = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Transform.translate(
            offset: Offset(_swipeOffset * 0.2, 0),
            child: AnimatedTypeSelector(
              selectedType: _selectedType,
              onTypeChanged: _onTypeChanged,
              swipeOffset: _swipeOffset,
              isAnimating: _isAnimating,
            ),
          ),
          Transform.translate(
            offset: Offset(_swipeOffset * 0.1, 0),
            child: AnimatedSearchBar(
              controller: _searchController,
              onChanged: _onSearchChanged,
              searchQuery: _searchQuery,
              swipeOffset: _swipeOffset,
              isAnimating: _isAnimating,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onPanStart: (details) {
                if (!_isAnimating) {
                  _isSwipeInProgress = false;
                  _swipeOffset = 0.0;
                }
              },
              onPanUpdate: (details) {
                if (!_isAnimating) {
                  setState(() {
                    _swipeOffset += details.delta.dx;
                    // Limit swipe offset to reasonable bounds
                    _swipeOffset = _swipeOffset.clamp(-100.0, 100.0);
                  });

                  // Detect horizontal swipe with minimum threshold
                  if (!_isSwipeInProgress && details.delta.dx.abs() > 20) {
                    if (details.delta.dx > 0) {
                      // Swipe right - switch to expense (previous tab)
                      if (_selectedType != TransactionType.expense) {
                        _isSwipeInProgress = true;
                        _performSwipeAnimation(TransactionType.expense);
                      }
                    } else {
                      // Swipe left - switch to income (next tab)
                      if (_selectedType != TransactionType.income) {
                        _isSwipeInProgress = true;
                        _performSwipeAnimation(TransactionType.income);
                      }
                    }
                  }
                }
              },
              onPanEnd: (details) {
                if (!_isAnimating && !_isSwipeInProgress) {
                  // Reset swipe offset if no tab change occurred
                  setState(() {
                    _swipeOffset = 0.0;
                  });
                }
              },
              child: AnimatedOpacity(
                opacity: _isAnimating ? 0.7 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Transform.translate(
                  offset: Offset(_swipeOffset * 0.5, 0),
                  child: _isLoading
                      ? _buildLoadingState()
                      : _filteredCategories.isEmpty
                          ? _buildEmptyState()
                          : AnimatedCategoryList(
                              categories: _categories,
                              filteredCategories: _filteredCategories,
                              swipeOffset: _swipeOffset,
                              isAnimating: _isAnimating,
                              onAddCategory: _addCategory,
                              onEditCategory: _editCategory,
                              onDeleteCategory: _deleteCategory,
                            ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedFloatingActionButton(
        onPressed: _addCategory,
        swipeOffset: _swipeOffset,
        isAnimating: _isAnimating,
      ),
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
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: () => Navigator.pop(context),
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

  void _addCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCategoryV2Screen(
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
        builder: (context) => AddEditCategoryV2Screen(
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
