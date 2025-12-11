import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moni/config/app_config.dart';

import '../../../models/category_model.dart';
import '../../../models/transaction_filter_model.dart';
import '../../../services/providers/providers.dart';
import '../../../utils/helpers/category_icon_helper.dart';
import '../../category/category_management_screen.dart';
import '../../history/transaction_history_screen.dart';
import '../../transaction/add_transaction_screen.dart';

class CategoryQuickAccess extends ConsumerWidget {
  final Function(TransactionFilter)? onNavigateToHistoryWithFilter;

  const CategoryQuickAccess({
    super.key,
    this.onNavigateToHistoryWithFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch providers
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final transactionsAsync = ref.watch(allTransactionsProvider);

    if (categoriesAsync.isLoading || transactionsAsync.isLoading) {
      return _buildLoadingState();
    }

    final allCategories = categoriesAsync.value ?? [];
    final allTransactions = transactionsAsync.value ?? [];

    // Filter categories by type
    final expenseCategories = allCategories
        .where((cat) => cat.type == TransactionType.expense && !cat.isDeleted)
        .toList();
    final incomeCategories = allCategories
        .where((cat) => cat.type == TransactionType.income && !cat.isDeleted)
        .toList();

    // Calculate usage frequency từ transactions trong 60 ngày gần đây
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 60));
    
    final recentTransactions = allTransactions
        .where((t) => 
            !t.isDeleted &&
            t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(now.add(const Duration(seconds: 1))))
        .toList();

    final expCount = <String, int>{};
    final expLast = <String, DateTime>{};
    final incCount = <String, int>{};
    final incLast = <String, DateTime>{};

    for (final t in recentTransactions) {
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

    // Sort by usage
    final sortedExpenseCategories = _sortByUsage(
      expenseCategories,
      expCount,
      expLast,
    );
    final sortedIncomeCategories = _sortByUsage(
      incomeCategories,
      incCount,
      incLast,
    );

    if (sortedExpenseCategories.isEmpty && sortedIncomeCategories.isEmpty) {
      return _buildEmptyState(context);
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
          _buildHeader(context),
          const SizedBox(height: 16),
          if (sortedExpenseCategories.isNotEmpty) ...[
            _buildCategorySection(
              context,
              'Chi tiêu gần đây',
              sortedExpenseCategories,
              true,
            ),
            const SizedBox(height: 16),
          ],
          if (sortedIncomeCategories.isNotEmpty) ...[
            _buildCategorySection(
              context,
              'Thu nhập gần đây',
              sortedIncomeCategories,
              false,
            ),
          ],
        ],
      ),
    );
  }

  List<CategoryModel> _sortByUsage(
    List<CategoryModel> categories,
    Map<String, int> usageCount,
    Map<String, DateTime> lastUsed,
  ) {
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
        return AppColors.primary;
      }

      final color = Color(category.color);

      // Kiểm tra xem màu có quá tối hoặc quá sáng không
      final luminance = color.computeLuminance();
      if (luminance < 0.1 || luminance > 0.9) {
        return AppColors.primary;
      }

      return color;
    } catch (e) {
      return AppColors.primary;
    }
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
          _buildHeader(null),
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

  Widget _buildEmptyState(BuildContext context) {
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
          _buildHeader(context),
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
                _buildManageButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext? context) {
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
        if (context != null) _buildManageButtonSmall(context),
      ],
    );
  }

  Widget _buildManageButtonSmall(BuildContext context) {
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CategoryManagementScreen(),
              ),
            );
          },
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
    BuildContext context,
    String title,
    List<CategoryModel> categories,
    bool isExpense,
  ) {
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
        _buildCategoryGrid(context, categories, isExpense),
      ],
    );
  }

  Widget _buildCategoryGrid(
    BuildContext context,
    List<CategoryModel> categories,
    bool isExpense,
  ) {
    // Tạo danh sách items
    List<Widget> items = [];

    // Thêm các category items (tối đa 6)
    for (int i = 0; i < categories.length && i < 6; i++) {
      items.add(_buildCategoryCard(context, categories[i]));
    }

    // Nếu có ít hơn 6 items, thêm thẻ "..." để hiển thị thêm
    if (categories.length < 6) {
      items.add(_buildMoreCard(context));
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

  Widget _buildCategoryCard(BuildContext context, CategoryModel category) {
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
            debugPrint('🔵 Category card tapped: ${category.name}');
            debugPrint('🔵 Has callback: ${onNavigateToHistoryWithFilter != null}');
            
            // Tap: Xem transactions của category này
            if (onNavigateToHistoryWithFilter != null) {
              debugPrint('🔵 Using tab system (Option B)');
              // Use tab system (Option B)
              onNavigateToHistoryWithFilter!(
                TransactionFilter.byCategory(category.categoryId).copyWith(
                  type: category.type,
                ),
              );
            } else {
              debugPrint('🔵 Using fallback navigation');
              // Fallback: Navigate to history với filter (mở tab List)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionHistoryScreen(
                    initialFilter: TransactionFilter.byCategory(
                      category.categoryId,
                    ),
                    initialTabIndex: 1, // Mở tab List
                  ),
                ),
              );
            }
          },
          onLongPress: () {
            // Long press: Add transaction với category này
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddTransactionScreen(
                  initialType: category.type,
                  initialCategoryId: category.categoryId,
                ),
              ),
            );
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

  Widget _buildMoreCard(BuildContext context) {
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CategoryManagementScreen(),
              ),
            );
          },
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

  Widget _buildManageButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CategoryManagementScreen(),
            ),
          );
        },
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

}
