import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../constants/app_colors.dart';
import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import '../../../services/category_service.dart';
import '../../../services/transaction_service.dart';
import '../../../utils/helpers/category_icon_helper.dart';
import '../../../utils/logging/logging_utils.dart';
import '../../category/category_management_screen.dart';
import '../../transaction/add_transaction_screen.dart';

class CategoryQuickAccess extends StatefulWidget {
  const CategoryQuickAccess({super.key});

  @override
  State<CategoryQuickAccess> createState() => _CategoryQuickAccessState();
}

class _CategoryQuickAccessState extends State<CategoryQuickAccess> {
  final GetIt _getIt = GetIt.instance;
  late final CategoryService _categoryService;

  List<CategoryModel> _expenseCategories = [];
  List<CategoryModel> _incomeCategories = [];
  bool _isLoading = false;

  // Usage ranking maps
  Map<String, int> _expenseUsageCount = {};
  Map<String, DateTime> _expenseLastUsed = {};
  Map<String, int> _incomeUsageCount = {};
  Map<String, DateTime> _incomeLastUsed = {};

  StreamSubscription<List<CategoryModel>>? _expenseSubscription;
  StreamSubscription<List<CategoryModel>>? _incomeSubscription;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<TransactionModel>>? _recentTxSub;

  @override
  void initState() {
    super.initState();
    _categoryService = _getIt<CategoryService>();

    // Listen to auth changes
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        if (user != null) {
          _loadCategories();
          _listenRecentTransactions();
        } else {
          setState(() {
            _expenseCategories = [];
            _incomeCategories = [];
            _expenseUsageCount = {};
            _expenseLastUsed = {};
            _incomeUsageCount = {};
            _incomeLastUsed = {};
          });
        }
      }
    });

    _loadCategories();
    _listenRecentTransactions();
  }

  @override
  void dispose() {
    _expenseSubscription?.cancel();
    _incomeSubscription?.cancel();
    _authSubscription?.cancel();
    _recentTxSub?.cancel();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _expenseSubscription?.cancel();
      await _incomeSubscription?.cancel();

      // Load expense categories
      _expenseSubscription =
          _categoryService.getCategories(type: TransactionType.expense).listen(
        (categories) {
          if (mounted) {
            setState(() {
              _expenseCategories = _sortByUsage(categories, true);
            });
            // Debug: Log category colors
            for (var category in categories.take(3)) {
              logDebug(
                'Expense category color',
                className: 'CategoryQuickAccess',
                methodName: '_loadCategories',
                data: {
                  'name': category.name,
                  'color': category.color,
                  'hex': '0x${category.color.toRadixString(16).toUpperCase()}',
                },
              );
            }
          }
        },
      );

      // Load income categories
      _incomeSubscription =
          _categoryService.getCategories(type: TransactionType.income).listen(
        (categories) {
          if (mounted) {
            setState(() {
              _incomeCategories = _sortByUsage(categories, false);
              _isLoading = false;
            });
            // Debug: Log income category colors
            for (var category in categories.take(3)) {
              logDebug(
                'Income category color',
                className: 'CategoryQuickAccess',
                methodName: '_loadCategories',
                data: {
                  'name': category.name,
                  'color': category.color,
                  'hex': '0x${category.color.toRadixString(16).toUpperCase()}',
                },
              );
            }
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Listen recent transactions to compute usage frequency per category
  void _listenRecentTransactions() {
    final transactionService = _getIt<TransactionService>();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 60));
    _recentTxSub = transactionService
        .getTransactions(startDate: start, endDate: now)
        .listen((txs) {
      final expCount = <String, int>{};
      final expLast = <String, DateTime>{};
      final incCount = <String, int>{};
      final incLast = <String, DateTime>{};

      for (final t in txs) {
        if (t.categoryId.isEmpty) continue;
        if (t.type == TransactionType.expense) {
          expCount[t.categoryId] = (expCount[t.categoryId] ?? 0) + 1;
          final prev = expLast[t.categoryId];
          if (prev == null || t.date.isAfter(prev)) {
            expLast[t.categoryId] = t.date;
          }
        } else if (t.type == TransactionType.income) {
          incCount[t.categoryId] = (incCount[t.categoryId] ?? 0) + 1;
          final prev = incLast[t.categoryId];
          if (prev == null || t.date.isAfter(prev)) {
            incLast[t.categoryId] = t.date;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _expenseUsageCount = expCount;
        _expenseLastUsed = expLast;
        _incomeUsageCount = incCount;
        _incomeLastUsed = incLast;
        // Re-sort lists when usage stats updated
        _expenseCategories = _sortByUsage(_expenseCategories, true);
        _incomeCategories = _sortByUsage(_incomeCategories, false);
      });
    });
  }

  List<CategoryModel> _sortByUsage(
      List<CategoryModel> categories, bool isExpense) {
    final usageCount = isExpense ? _expenseUsageCount : _incomeUsageCount;
    final lastUsed = isExpense ? _expenseLastUsed : _incomeLastUsed;
    final sorted = [...categories];
    sorted.sort((a, b) {
      final ca = usageCount[a.categoryId] ?? 0;
      final cb = usageCount[b.categoryId] ?? 0;
      if (cb != ca) return cb.compareTo(ca); // higher count first
      final la = lastUsed[a.categoryId];
      final lb = lastUsed[b.categoryId];
      if (la == null && lb == null) return 0;
      if (la == null) return 1;
      if (lb == null) return -1;
      return lb.compareTo(la); // latest first
    });
    return sorted.take(6).toList();
  }

  /// Helper method để xử lý màu category một cách an toàn
  Color _getCategoryColor(CategoryModel category) {
    try {
      // Kiểm tra xem màu có hợp lệ không
      if (category.color <= 0) {
        logWarning(
          'Invalid color for category',
          className: 'CategoryQuickAccess',
          methodName: '_getCategoryColor',
          data: {
            'categoryName': category.name,
            'color': category.color,
          },
        );
        return AppColors.primary;
      }

      final color = Color(category.color);

      // Kiểm tra xem màu có quá tối hoặc quá sáng không
      final luminance = color.computeLuminance();
      if (luminance < 0.1 || luminance > 0.9) {
        logWarning(
          'Color too dark/bright for category',
          className: 'CategoryQuickAccess',
          methodName: '_getCategoryColor',
          data: {
            'categoryName': category.name,
            'color': category.color,
            'luminance': luminance,
          },
        );
        return AppColors.primary;
      }

      return color;
    } catch (e) {
      logError(
        'Error parsing color for category',
        className: 'CategoryQuickAccess',
        methodName: '_getCategoryColor',
        data: {
          'categoryName': category.name,
          'color': category.color,
        },
        error: e,
      );
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_expenseCategories.isEmpty && _incomeCategories.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          if (_expenseCategories.isNotEmpty) ...[
            _buildCategorySection('Chi tiêu gần đây', _expenseCategories, true),
            const SizedBox(height: 16),
          ],
          if (_incomeCategories.isNotEmpty) ...[
            _buildCategorySection('Thu nhập gần đây', _incomeCategories, false),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 48,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chưa có danh mục nào',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildManageButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.category_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Danh mục',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _buildManageButtonSmall(),
      ],
    );
  }

  Widget _buildManageButtonSmall() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _navigateToCategoryManagement,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Đã xoá icon bánh răng, chỉ còn chữ
              Text(
                'Quản lý',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(
      String title, List<CategoryModel> categories, bool isExpense) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _buildCategoryGrid(categories, isExpense),
      ],
    );
  }

  Widget _buildCategoryGrid(List<CategoryModel> categories, bool isExpense) {
    // Tạo danh sách items
    List<Widget> items = [];

    // Thêm các category items (tối đa 6)
    for (int i = 0; i < categories.length && i < 6; i++) {
      items.add(_buildCategoryCard(categories[i]));
    }

    // Nếu có ít hơn 6 items, thêm thẻ "..." để hiển thị thêm
    if (categories.length < 6) {
      items.add(_buildMoreCard());
    }

    return Column(
      children: [
        // Hàng 1
        if (items.isNotEmpty)
          Row(
            children: [
              for (int i = 0; i < 3 && i < items.length; i++) ...[
                Expanded(child: items[i]),
                if (i < 2 && i < items.length - 1) const SizedBox(width: 12),
              ],
            ],
          ),
        // Hàng 2
        if (items.length > 3) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              for (int i = 3; i < 6 && i < items.length; i++) ...[
                Expanded(child: items[i]),
                if (i < 5 && i < items.length - 1) const SizedBox(width: 12),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    final categoryColor = _getCategoryColor(category);

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            _navigateToAddTransaction(category);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                CategoryIconHelper.buildIcon(
                  category,
                  size: 16,
                  color: categoryColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: categoryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreCard() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _navigateToCategoryManagement,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Icon(
                  Icons.more_horiz,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Thêm',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManageButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _navigateToCategoryManagement,
        icon: Icon(
          Icons.settings,
          size: 18,
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
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _navigateToCategoryManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryManagementScreen(),
      ),
    );
  }

  void _navigateToAddTransaction(CategoryModel category) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          initialType: category.type,
          initialCategoryId: category.categoryId,
        ),
      ),
    );
  }
}
