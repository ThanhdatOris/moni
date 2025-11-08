import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';

import '../../constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../services/services.dart';
import '../../utils/formatting/currency_formatter.dart';
import 'widgets/detail_app_bar.dart';
import 'widgets/detail_details_tab.dart';
import 'widgets/detail_edit_form.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;
  final int? initialTabIndex;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    this.initialTabIndex,
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
  late TransactionModel _currentTransaction; // Track current transaction state
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
    
    // Set initial tab index if provided
    if (widget.initialTabIndex != null && widget.initialTabIndex! >= 0 && widget.initialTabIndex! < 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tabController.animateTo(widget.initialTabIndex!);
        }
      });
    }
    
    try {
      _transactionService = _getIt<TransactionService>();
      _categoryService = _getIt<CategoryService>();
    } catch (e) {
      // Handle service initialization error
    }

    // Initialize with transaction data
    _currentTransaction = widget.transaction;
    _selectedType = widget.transaction.type;
    _selectedDate = widget.transaction.date;
    _amountController.text = CurrencyFormatter.formatDisplay(widget.transaction.amount.toInt());
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

      // Chỉ set loading state nếu chưa được set
      if (!_isCategoriesLoading && mounted) {
        setState(() {
          _isCategoriesLoading = true;
          _categoriesError = null;
        });
      }

      _categoriesSubscription =
          _categoryService.getCategories(type: _selectedType).listen(
        (categories) {
          // Defer setState để tránh layout cycle
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _categories = categories;
                _isCategoriesLoading = false;

                // Find and set current category
                _selectedCategory = categories.firstWhere(
                  (cat) => cat.categoryId == _currentTransaction.categoryId,
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
          });
        },
        onError: (error) {
          // Defer setState để tránh layout cycle
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isCategoriesLoading = false;
                _categoriesError = error.toString();
              });
            }
          });
        },
      );
    } catch (e) {
      // Defer setState để tránh layout cycle
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isCategoriesLoading = false;
            _categoriesError = e.toString();
          });
        }
      });
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
      final amount = CurrencyFormatter.parseFormattedAmount(_amountController.text);

      final updatedTransaction = _currentTransaction.copyWith(
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
        // Cập nhật local transaction data
        setState(() {
          _currentTransaction = updatedTransaction; // Update current transaction
        });
        
        // Nếu được gọi từ chatbot (có initialTabIndex), return updated transaction
        if (widget.initialTabIndex != null) {
          Navigator.pop(context, updatedTransaction);
          return;
        }
        
        // Chuyển về tab "Chi tiết" để hiển thị thông tin đã cập nhật
        _tabController.animateTo(0);
        
        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cập nhật giao dịch thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
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
          .deleteTransaction(_currentTransaction.transactionId); // Use current transaction

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
            DetailAppBar(
              transaction: _currentTransaction, // Use current transaction
              tabController: _tabController,
              onBack: () => Navigator.pop(context),
              onDelete: _deleteTransaction,
              isDeleting: _isDeleting,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  DetailDetailsTab(
                    transaction: _currentTransaction, // Use current transaction
                    selectedCategory: _selectedCategory,
                  ),
                  _buildEditTab(),
                ],
              ),
            ),
          ],
        ),
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

    return DetailEditForm(
      formKey: _formKey,
      amountController: _amountController,
      noteController: _noteController,
      selectedType: _selectedType,
      selectedCategory: _selectedCategory,
      selectedDate: _selectedDate,
      categories: _categories,
      isCategoriesLoading: _isCategoriesLoading,
      isLoading: _isLoading,
      onTypeChanged: (type) {
        // Update UI ngay lập tức cho responsive UX
        if (mounted) {
          setState(() {
            _selectedType = type;
            _selectedCategory = null;
            _categories = []; // Clear old categories immediately
            _isCategoriesLoading = true; // Show loading state immediately
            _categoriesError = null;
          });
          // Load categories sau khi state đã update
          Future.microtask(() => _loadCategories());
        }
      },
      onCategoryChanged: (category) {
        // Defer setState để tránh layout cycle
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedCategory = category;
            });
          }
        });
      },
      onDateChanged: (date) {
        // Defer setState để tránh layout cycle
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedDate = date;
            });
          }
        });
      },
      onRetry: _loadCategories,
      onSave: _updateTransaction,
    );
  }
}
