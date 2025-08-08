import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import '../../../services/category_service.dart';
import '../../../services/transaction_service.dart';
import '../../../utils/formatting/currency_formatter.dart';
import '../../../utils/helpers/category_icon_helper.dart';
import '../../history/transaction_detail_screen.dart';
import '../../history/transaction_history_screen.dart';
import '../../transaction/add_transaction_screen.dart';

class HomeRecentTransactions extends StatefulWidget {
  final VoidCallback? onNavigateToHistory;

  const HomeRecentTransactions({
    super.key,
    this.onNavigateToHistory,
  });

  @override
  State<HomeRecentTransactions> createState() => _HomeRecentTransactionsState();
}

class _HomeRecentTransactionsState extends State<HomeRecentTransactions>
    with TickerProviderStateMixin {
  late final TransactionService _transactionService;
  late final CategoryService _categoryService;
  late final AnimationController _animationController;
  late final AnimationController _pullRefreshController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  List<TransactionModel> _transactions = [];
  Map<String, CategoryModel> _categoryMap = {};
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _transactionService = getIt<TransactionService>();
    _categoryService = getIt<CategoryService>();

    // Animation controllers
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pullRefreshController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

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
          .getRecentTransactions(
            limit: 5,
          )
          .first;

      // Lấy danh sách tất cả danh mục (tối ưu: 1 call thay vì 2)
      final allCategories = await _categoryService
          .getCategories() // Không filter type, lấy tất cả
          .first;

      // Tạo map category ID -> category
      final categoryMap = <String, CategoryModel>{};
      for (final category in allCategories) {
        categoryMap[category.categoryId] = category;
      }

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _categoryMap = categoryMap;
          _isLoading = false;
        });

        // Start animation when data loaded
        _animationController.forward();
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

  Future<void> _refreshTransactions() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    _pullRefreshController.forward();

    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Smooth UX
      await _loadRecentTransactions();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        _pullRefreshController.reverse();
      }
    }
  }

  void _navigateToTransactionDetail(TransactionModel transaction) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TransactionDetailScreen(transaction: transaction),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );

    // Refresh data khi quay về nếu có thay đổi
    if (result != null) {
      // result có thể là:
      // - true nếu transaction bị xóa
      // - TransactionModel nếu transaction được update
      await _loadRecentTransactions();
    }
  }

  void _navigateToAllTransactions() {
    // Sử dụng callback để chuyển tab thay vì navigate sang màn hình mới
    if (widget.onNavigateToHistory != null) {
      widget.onNavigateToHistory!();
    } else {
      // Fallback: navigate như cũ nếu không có callback
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const TransactionHistoryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pullRefreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: _refreshTransactions,
        backgroundColor: Colors.white,
        color: AppColors.primary,
        displacement: 40.0,
        child: Column(
          children: [
            // Header với gradient subtil
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
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
                    child: Icon(
                      Icons.history,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Giao dịch gần đây',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _pullRefreshController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _pullRefreshController.value * 2 * 3.14159,
                        child: GestureDetector(
                          onTap: _navigateToAllTransactions,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                width: 1,
                              ),
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
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Content
            if (_isLoading)
              _buildLoadingState()
            else if (_transactions.isEmpty)
              _buildEmptyState()
            else
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // Transaction items với padding chung
                      for (int index = 0;
                          index < _transactions.length;
                          index++) ...[
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            final delay = index * 0.1;
                            final animationValue =
                                Curves.easeOutCubic.transform(
                              (_animationController.value - delay)
                                  .clamp(0.0, 1.0),
                            );

                            return Transform.translate(
                              offset: Offset(0, 50 * (1 - animationValue)),
                              child: Opacity(
                                opacity: animationValue,
                                child:
                                    _buildTransactionItem(_transactions[index]),
                              ),
                            );
                          },
                        ),
                        // Divider giữa các items (trừ item cuối)
                        if (index < _transactions.length - 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Divider(
                              height: 1,
                              thickness: 0.5,
                              color: Colors.grey[100],
                              indent:
                                  48, // 24px padding + 12px spacing + 12px để căn với text
                            ),
                          ),
                      ],
                      const SizedBox(height: 24), // Bottom spacing
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Đang tải giao dịch...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chưa có giao dịch nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bắt đầu ghi chép chi tiêu của bạn ngay hôm nay',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to add transaction
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddTransactionScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Thêm giao dịch đầu tiên',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final category = _categoryMap[transaction.categoryId];
    final isExpense = transaction.type == TransactionType.expense;

    // Sử dụng màu từ category nếu có, fallback về màu mặc định
    final categoryColor = category != null
        ? Color(category.color)
        : (isExpense ? Colors.red[600]! : Colors.green[600]!);

    final backgroundColorLight = category != null
        ? Color(category.color).withValues(alpha: 0.1)
        : (isExpense ? Colors.red[50]! : Colors.green[50]!);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToTransactionDetail(transaction),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              // Icon danh mục với màu đúng từ category
              Hero(
                tag: 'transaction-${transaction.transactionId}',
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: backgroundColorLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: category != null
                        ? CategoryIconHelper.buildIcon(
                            category,
                            size: 18,
                            color: categoryColor,
                            showBackground: false,
                          )
                        : Icon(
                            Icons.category_rounded,
                            color: categoryColor,
                            size: 18,
                          ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Thông tin giao dịch - tận dụng tối đa không gian
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hàng 1: Tên category + Số tiền trên cùng 1 hàng
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category?.name ?? 'Không rõ',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          CurrencyFormatter.formatAmountWithCurrency(
                              transaction.amount),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: categoryColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    // Hàng 2: Note/Date + Type indicator
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            transaction.note?.isNotEmpty == true
                                ? transaction.note!
                                : DateFormat('dd/MM/yyyy')
                                    .format(transaction.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: backgroundColorLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isExpense ? 'Chi' : 'Thu',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: categoryColor,
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
        ),
      ),
    );
  }
}
