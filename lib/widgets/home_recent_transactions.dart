import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../core/di/injection_container.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/category_service.dart';
import '../services/transaction_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/category_icon_helper.dart';

class HomeRecentTransactions extends StatefulWidget {
  const HomeRecentTransactions({super.key});

  @override
  State<HomeRecentTransactions> createState() => _HomeRecentTransactionsState();
}

class _HomeRecentTransactionsState extends State<HomeRecentTransactions> {
  late final TransactionService _transactionService;
  late final CategoryService _categoryService;

  List<TransactionModel> _transactions = [];
  Map<String, CategoryModel> _categoryMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _transactionService = getIt<TransactionService>();
    _categoryService = getIt<CategoryService>();
    _loadRecentTransactions();
  }

  Future<void> _loadRecentTransactions() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Lấy danh sách giao dịch gần đây (5 giao dịch)
      final transactions = await _transactionService
          .getTransactions(
            limit: 5,
          )
          .first;

      // Lấy danh sách tất cả danh mục
      final expenseCategories = await _categoryService
          .getCategories(
            type: TransactionType.expense,
          )
          .first;

      final incomeCategories = await _categoryService
          .getCategories(
            type: TransactionType.income,
          )
          .first;

      // Tạo map category ID -> category
      final categoryMap = <String, CategoryModel>{};
      for (final category in [...expenseCategories, ...incomeCategories]) {
        categoryMap[category.categoryId] = category;
      }

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _categoryMap = categoryMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Error loading recent transactions: $e
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Cancel any ongoing operations if needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Giao dịch gần đây',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to transaction list
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_transactions.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: _transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildTransactionItem(_transactions[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa có giao dịch nào',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nhấn nút + để thêm giao dịch đầu tiên',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final category = _categoryMap[transaction.categoryId];
    final isExpense = transaction.type == TransactionType.expense;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Icon danh mục với CategoryIconHelper
          if (category != null)
            CategoryIconHelper.buildIcon(
              category,
              size: 20,
              color: isExpense ? Colors.red[600] : Colors.green[600],
              showBackground: true,
              backgroundColor: isExpense ? Colors.red[50] : Colors.green[50],
            )
          else
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.category,
                color: Colors.grey[600],
                size: 20,
              ),
            ),

          const SizedBox(width: 12),

          // Thông tin giao dịch
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category?.name ?? 'Không rõ',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.note?.isNotEmpty == true
                      ? transaction.note!
                      : DateFormat('dd/MM/yyyy').format(transaction.date),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Số tiền
          Text(
            CurrencyFormatter.formatAmountWithCurrency(transaction.amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isExpense ? Colors.red[600] : Colors.green[600],
            ),
          ),
        ],
      ),
    );
  }
}
