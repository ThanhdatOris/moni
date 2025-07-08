import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../services/category_service.dart';
import '../../services/transaction_service.dart';
import '../../widgets/transaction_ai_scan_tab.dart';
import '../../widgets/transaction_amount_input.dart';
import '../../widgets/transaction_category_selector.dart';
import '../../widgets/transaction_date_selector.dart';
import '../../widgets/transaction_note_input.dart';
import '../../widgets/transaction_quick_templates.dart';
import '../../widgets/transaction_save_button.dart';
import '../../widgets/transaction_type_selector.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  // Transaction data
  TransactionType _selectedType = TransactionType.expense;
  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  bool _isCategoriesLoading = false;
  String? _categoriesError;

  final GetIt _getIt = GetIt.instance;
  late final TransactionService _transactionService;
  late final CategoryService _categoryService;

  // Stream subscriptions
  StreamSubscription<List<CategoryModel>>? _categoriesSubscription;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _transactionService = _getIt<TransactionService>();
    _categoryService = _getIt<CategoryService>();

    // Add listener for auth state changes
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

  Future<void> _loadCategories() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _categories = [];
            _isCategoriesLoading = false;
          });
        }
        return;
      }

      await _categoriesSubscription?.cancel();

      setState(() {
        _categories = [];
        _isCategoriesLoading = true;
        _categoriesError = null;
      });

      _categoriesSubscription =
          _categoryService.getCategories(type: _selectedType).timeout(
        const Duration(seconds: 15),
        onTimeout: (sink) {
          sink.add([]);
        },
      ).listen(
        (categories) {
          if (mounted) {
            setState(() {
              _categories = categories;
              _isCategoriesLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildModernAppBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildManualInputTab(),
                  _buildScanReceiptTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
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
          // Header
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Thêm giao dịch',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 20),

          // Modern Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(24),
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
                borderRadius: BorderRadius.circular(20),
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
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              labelPadding: const EdgeInsets.symmetric(vertical: 8),
              tabs: [
                Tab(
                  height: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Nhập thông thường',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  height: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 20),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Scan hóa đơn',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualInputTab() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            TransactionAmountInput(
              controller: _amountController,
            ),
            const SizedBox(height: 24),
            TransactionCategorySelector(
              selectedCategory: _selectedCategory,
              categories: _categories,
              isLoading: _isCategoriesLoading,
              errorMessage: _categoriesError,
              onCategoryChanged: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              onRetry: _loadCategories,
            ),
            const SizedBox(height: 24),
            TransactionDateSelector(
              selectedDate: _selectedDate,
              onDateChanged: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
            ),
            const SizedBox(height: 24),
            TransactionNoteInput(
              controller: _noteController,
            ),
            const SizedBox(height: 24),
            TransactionQuickTemplates(
              transactionType: _selectedType,
              onTemplateSelected: _applyTemplate,
            ),
            const SizedBox(height: 32),
            TransactionSaveButton(
              isLoading: _isLoading,
              onSave: _saveTransaction,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanReceiptTab() {
    return TransactionAiScanTab(
      onScanComplete: (results) {
        // Handle scan completion if needed
      },
      onScanSaved: _saveScannedTransaction,
    );
  }

  void _applyTemplate(Map<String, dynamic> template) {
    setState(() {
      _amountController.text = template['amount'] ?? '';
      _noteController.text = template['note'] ?? template['name'] ?? '';
    });
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedCategory == null) {
        throw Exception('Vui lòng chọn danh mục');
      }

      final amount = double.parse(_amountController.text);
      final transaction = TransactionModel(
        transactionId: '',
        userId: currentUser.uid,
        categoryId: _selectedCategory!.categoryId,
        amount: amount,
        type: _selectedType,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDeleted: false,
      );

      await Future.any([
        _transactionService.createTransaction(transaction),
        Future.delayed(const Duration(seconds: 30), () {
          throw Exception('Timeout: Lưu giao dịch mất quá nhiều thời gian.');
        }),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu giao dịch thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, transaction);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Lỗi lưu giao dịch: $e';

        if (e.toString().contains('Timeout')) {
          errorMessage =
              'Kết nối bị timeout. Vui lòng kiểm tra mạng và thử lại.';
        } else if (e.toString().contains('permission-denied')) {
          errorMessage = 'Không có quyền thực hiện thao tác này.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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

  Future<void> _saveScannedTransaction() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_categories.isEmpty) {
        throw Exception(
            'Không có danh mục khả dụng. Vui lòng tạo danh mục trước.');
      }

      // Mock data từ AI scan
      final transaction = TransactionModel(
        transactionId: '',
        userId: currentUser.uid,
        categoryId: _categories.first.categoryId,
        amount: 125000,
        type: TransactionType.expense,
        date: DateTime.now(),
        note: 'Cơm tấm Sài Gòn (Scan AI)',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDeleted: false,
      );

      await Future.any([
        _transactionService.createTransaction(transaction),
        Future.delayed(const Duration(seconds: 30), () {
          throw Exception('Timeout: Lưu giao dịch mất quá nhiều thời gian.');
        }),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu giao dịch từ scan thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, transaction);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Lỗi lưu giao dịch: $e';

        if (e.toString().contains('Timeout')) {
          errorMessage =
              'Kết nối bị timeout. Vui lòng kiểm tra mạng và thử lại.';
        } else if (e.toString().contains('permission-denied')) {
          errorMessage = 'Không có quyền thực hiện thao tác này.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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

  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    _authSubscription?.cancel();
    _tabController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
