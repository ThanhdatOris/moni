import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../services/category_service.dart';
import '../../services/transaction_service.dart';
import '../../utils/category_icon_helper.dart';
import '../../utils/currency_formatter.dart';
import '../transaction/widgets/transaction_amount_input.dart';
import '../transaction/widgets/transaction_category_selector.dart';
import '../transaction/widgets/transaction_date_selector.dart';
import '../transaction/widgets/transaction_note_input.dart';
import '../transaction/widgets/transaction_type_selector.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Services
  final GetIt _getIt = GetIt.instance;
  late final TransactionService _transactionService;
  late final CategoryService _categoryService;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  // Transaction data
  late TransactionType _selectedType;
  CategoryModel? _selectedCategory;
  late DateTime _selectedDate;
  List<CategoryModel> _categories = [];

  // UI state
  bool _isLoading = false;
  bool _isCategoriesLoading = false;
  bool _isDeleting = false;
  String? _categoriesError;

  // Stream subscriptions
  StreamSubscription<List<CategoryModel>>? _categoriesSubscription;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _transactionService = _getIt<TransactionService>();
    _categoryService = _getIt<CategoryService>();

    // Initialize with transaction data
    _selectedType = widget.transaction.type;
    _selectedDate = widget.transaction.date;
    _amountController.text = widget.transaction.amount.toString();
    _noteController.text = widget.transaction.note ?? '';

    // Auth listener
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted && user == null) {
        Navigator.of(context).pop();
      }
    });

    _loadCategories();
  }

  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    _authSubscription?.cancel();
    _tabController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      await _categoriesSubscription?.cancel();

      setState(() {
        _isCategoriesLoading = true;
        _categoriesError = null;
      });

      _categoriesSubscription =
          _categoryService.getCategories(type: _selectedType).listen(
        (categories) {
          if (mounted) {
            setState(() {
              _categories = categories;
              _isCategoriesLoading = false;

              // Find and set current category
              _selectedCategory = categories.firstWhere(
                (cat) => cat.categoryId == widget.transaction.categoryId,
                orElse: () => categories.isNotEmpty
                    ? categories.first
                    : CategoryModel(
                        categoryId: 'other',
                        userId: '',
                        name: 'Khác',
                        type: _selectedType,
                        icon: '📝',
                        iconType: CategoryIconType.emoji,
                        color: 0xFF9E9E9E,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
              );
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isCategoriesLoading = false;
              _categoriesError = error.toString();
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCategoriesLoading = false;
          _categoriesError = e.toString();
        });
      }
    }
  }

  Future<void> _updateTransaction() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.tryParse(_amountController.text) ?? 0.0;

      final updatedTransaction = widget.transaction.copyWith(
        amount: amount,
        type: _selectedType,
        categoryId: _selectedCategory!.categoryId,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await _transactionService.updateTransaction(updatedTransaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cập nhật giao dịch thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(
            context, true); // Return true to indicate successful update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi cập nhật giao dịch: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteTransaction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa giao dịch này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _transactionService
          .deleteTransaction(widget.transaction.transactionId);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate deletion
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã xóa giao dịch thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi xóa giao dịch: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDetailsTab(),
                  _buildEditTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
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
                    Text(
                      'Chi tiết giao dịch',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm')
                          .format(widget.transaction.date),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              IconButton(
                onPressed: _isDeleting ? null : _deleteTransaction,
                icon: _isDeleting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      )
                    : const Icon(Icons.delete_outline),
                style: IconButton.styleFrom(
                  foregroundColor: Colors.red,
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Tab bar
          Container(
            height: 45,
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Chi tiết'),
                Tab(text: 'Chỉnh sửa'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.transaction.type == TransactionType.income
                    ? [
                        AppColors.success,
                        AppColors.success.withValues(alpha: 0.8)
                      ]
                    : [AppColors.error, AppColors.error.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (widget.transaction.type == TransactionType.income
                          ? AppColors.success
                          : AppColors.error)
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  widget.transaction.type == TransactionType.income
                      ? 'Thu nhập'
                      : 'Chi tiêu',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.transaction.type == TransactionType.income ? '+' : '-'}${CurrencyFormatter.formatAmountWithCurrency(widget.transaction.amount)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Details Cards
          _buildDetailCard(
            icon: Icons.category_outlined,
            title: 'Danh mục',
            value: _selectedCategory?.name ?? 'Đang tải...',
            categoryIcon: _selectedCategory,
          ),

          const SizedBox(height: 16),

          _buildDetailCard(
            icon: Icons.calendar_today_outlined,
            title: 'Ngày',
            value: DateFormat('EEEE, dd/MM/yyyy', 'vi_VN')
                .format(widget.transaction.date),
          ),

          const SizedBox(height: 16),

          _buildDetailCard(
            icon: Icons.access_time_outlined,
            title: 'Thời gian',
            value: DateFormat('HH:mm').format(widget.transaction.date),
          ),

          if (widget.transaction.note?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            _buildDetailCard(
              icon: Icons.note_outlined,
              title: 'Ghi chú',
              value: widget.transaction.note!,
              isMultiline: true,
            ),
          ],

          const SizedBox(height: 16),

          _buildDetailCard(
            icon: Icons.update_outlined,
            title: 'Cập nhật lần cuối',
            value: DateFormat('dd/MM/yyyy HH:mm')
                .format(widget.transaction.updatedAt),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    CategoryModel? categoryIcon,
    bool isMultiline = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (categoryIcon != null) ...[
                      CategoryIconHelper.buildIcon(
                        categoryIcon,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditTab() {
    if (_isCategoriesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_categoriesError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Lỗi tải dữ liệu: $_categoriesError'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCategories,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Type Selector
            TransactionTypeSelector(
              selectedType: _selectedType,
              onTypeChanged: (type) {
                setState(() {
                  _selectedType = type;
                  _selectedCategory = null;
                });
                _loadCategories();
              },
            ),

            const SizedBox(height: 24),

            // Amount Input
            TransactionAmountInput(
              controller: _amountController,
            ),

            const SizedBox(height: 24),

            // Category Selector
            TransactionCategorySelector(
              selectedCategory: _selectedCategory,
              categories: _categories,
              isLoading: _isCategoriesLoading,
              onCategoryChanged: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              onRetry: _loadCategories,
            ),

            const SizedBox(height: 24),

            // Date Selector
            TransactionDateSelector(
              selectedDate: _selectedDate,
              onDateChanged: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
            ),

            const SizedBox(height: 24),

            // Note Input
            TransactionNoteInput(
              controller: _noteController,
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Cập nhật giao dịch',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
