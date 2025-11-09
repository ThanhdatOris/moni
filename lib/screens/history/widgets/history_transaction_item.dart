import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import 'package:moni/constants/app_colors.dart';
import 'package:moni/constants/enums.dart';

import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import 'package:moni/services/services.dart';
import '../../../utils/formatting/currency_formatter.dart';
import '../../../utils/helpers/category_icon_helper.dart';

class HistoryTransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel? category; // Thêm category info
  final VoidCallback onTap;
  final bool isListView;

  const HistoryTransactionItem({
    super.key,
    required this.transaction,
    this.category,
    required this.onTap,
    this.isListView = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.grey200.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Sử dụng FutureBuilder để load category nếu chưa có
            category != null 
                ? _buildIcon() 
                : _buildIconWithCategory(),
            const SizedBox(width: 12),
            Expanded(
              child: _buildContent(),
            ),
            _buildAmount(),
          ],
        ),
      ),
    );
  }

  Widget _buildIconWithCategory() {
    return FutureBuilder<CategoryModel?>(
      future: _loadCategory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIcon();
        }
        final loadedCategory = snapshot.data;
        return _buildIconWithCategoryData(loadedCategory);
      },
    );
  }

  Future<CategoryModel?> _loadCategory() async {
    try {
      final categoryService = GetIt.instance<CategoryService>();
      return await categoryService.getCategory(transaction.categoryId);
    } catch (e) {
      return null;
    }
  }

  Widget _buildLoadingIcon() {
    return Container(
      padding: EdgeInsets.all(isListView ? 10 : 8),
      decoration: BoxDecoration(
        color: AppColors.grey200.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(isListView ? 10 : 8),
      ),
      child: SizedBox(
        width: isListView ? 24 : 20,
        height: isListView ? 24 : 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildIconWithCategoryData(CategoryModel? categoryData) {
    return Container(
      padding: EdgeInsets.all(isListView ? 10 : 8),
      decoration: BoxDecoration(
        color: categoryData != null 
            ? Color(categoryData.color).withValues(alpha: isListView ? 0.15 : 0.1)
            : (transaction.type == TransactionType.income
                ? AppColors.success
                : AppColors.error).withValues(alpha: isListView ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(isListView ? 10 : 8),
      ),
      child: _buildCategoryIcon(categoryData),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: EdgeInsets.all(isListView ? 10 : 8),
      decoration: BoxDecoration(
        color: category != null 
            ? Color(category!.color).withValues(alpha: isListView ? 0.15 : 0.1)
            : (transaction.type == TransactionType.income
                ? AppColors.success
                : AppColors.error).withValues(alpha: isListView ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(isListView ? 10 : 8),
      ),
      child: _buildCategoryIcon(category),
    );
  }

  Widget _buildCategoryIcon(CategoryModel? categoryData) {
    if (categoryData != null) {
      // Sử dụng CategoryIconHelper để hiển thị icon đúng cách
      return CategoryIconHelper.buildIcon(
        categoryData,
        size: isListView ? 24 : 20,
        color: Color(categoryData.color),
      );
    } else {
      // Fallback: hiển thị icon mặc định theo loại giao dịch
      return Icon(
        transaction.type == TransactionType.income
            ? Icons.trending_up
            : Icons.trending_down,
        color: transaction.type == TransactionType.income
            ? AppColors.success
            : AppColors.error,
        size: isListView ? 24 : 20,
      );
    }
  }

  Widget _buildContent() {
    // Nếu đã có category, hiển thị trực tiếp
    if (category != null) {
      return _buildContentWithCategory(category);
    }
    
    // Nếu chưa có, load category
    return FutureBuilder<CategoryModel?>(
      future: _loadCategory(),
      builder: (context, snapshot) {
        final loadedCategory = snapshot.data;
        return _buildContentWithCategory(loadedCategory);
      },
    );
  }

  Widget _buildContentWithCategory(CategoryModel? categoryData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hiển thị note hoặc tên category
        Text(
          transaction.note?.isNotEmpty == true 
              ? transaction.note! 
              : _getCategoryDisplayName(categoryData),
          style: TextStyle(
            fontSize: isListView ? 15 : 14,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: isListView ? 6 : 4),
        // Hiển thị category name nếu có note
        if (transaction.note?.isNotEmpty == true && (categoryData?.name != null || transaction.categoryName != null))
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              categoryData?.name ?? transaction.categoryName ?? '',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (isListView)
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(transaction.date),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          )
        else
          Text(
            DateFormat('HH:mm').format(transaction.date),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  String _getCategoryDisplayName(CategoryModel? categoryData) {
    // Nếu có category data
    if (categoryData?.name != null) {
      return categoryData!.name;
    }
    
    // Nếu có categoryName từ transaction
    if (transaction.categoryName?.isNotEmpty == true) {
      return transaction.categoryName!;
    }
    
    // Fallback: hiển thị theo loại giao dịch
    return transaction.type == TransactionType.income ? 'Thu nhập' : 'Chi tiêu';
  }

  Widget _buildAmount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${transaction.type == TransactionType.income ? '+' : '-'}${CurrencyFormatter.formatAmountWithCurrency(transaction.amount)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: transaction.type == TransactionType.income
                ? AppColors.success
                : AppColors.error,
          ),
        ),
        SizedBox(height: isListView ? 6 : 4),
        if (isListView)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.arrow_forward_ios,
              size: 10,
              color: AppColors.primary,
            ),
          )
        else
          Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: AppColors.textLight,
          ),
      ],
    );
  }
}
