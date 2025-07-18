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
  Map<String, dynamic>? _scanResults;

  final GetIt _getIt = GetIt.instance;
  late final TransactionService _transactionService;
  late final CategoryService _categoryService;

  // Stream subscriptions
  StreamSubscription<List<CategoryModel>>? _categoriesSubscription;
  StreamSubscription<User?>? _authSubscription;
  Timer? _timeoutTimer;

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
            _categoriesError = 'Người dùng chưa đăng nhập';
          });
        }
        return;
      }

      // Cancel existing subscription and timer
      await _categoriesSubscription?.cancel();
      _categoriesSubscription = null;
      _timeoutTimer?.cancel();
      _timeoutTimer = null;

      if (mounted) {
        setState(() {
          _categories = [];
          _isCategoriesLoading = true;
          _categoriesError = null;
        });
      }

      // Track if request has timed out
      bool hasTimedOut = false;

      // Create new subscription with improved error handling and retry logic
      _categoriesSubscription =
          _categoryService.getCategories(type: _selectedType).listen(
        (categories) {
          _timeoutTimer?.cancel();
          if (mounted && !hasTimedOut) {
            setState(() {
              _categories = categories;
              _isCategoriesLoading = false;
              _categoriesError = null;
            });
          }
        },
        onError: (error) {
          _timeoutTimer?.cancel();
          if (mounted && !hasTimedOut) {
            setState(() {
              _isCategoriesLoading = false;
              _categoriesError = _formatErrorMessage(error);
            });
          }
        },
        cancelOnError: false,
      );

      // Set shorter timeout for better UX
      _timeoutTimer = Timer(const Duration(seconds: 10), () {
        hasTimedOut = true;
        _categoriesSubscription?.cancel();
        if (mounted) {
          setState(() {
            _isCategoriesLoading = false;
            _categoriesError = 'Tải danh mục mất quá lâu. Vui lòng thử lại.';
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCategoriesLoading = false;
          _categoriesError = _formatErrorMessage(e);
        });
      }
    }
  }

  /// Retry loading categories
  Future<void> _retryLoadCategories() async {
    print('DEBUG: Retrying load categories'); // Debug log
    await _loadCategories();
  }

  String _formatErrorMessage(dynamic error) {
    String errorMessage = error.toString();

    if (errorMessage.contains('network') || errorMessage.contains('Network')) {
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.';
    } else if (errorMessage.contains('permission') ||
        errorMessage.contains('Permission')) {
      return 'Không có quyền truy cập dữ liệu.';
    } else if (errorMessage.contains('timeout') ||
        errorMessage.contains('Timeout')) {
      return 'Timeout: Tải danh mục mất quá nhiều thời gian.';
    } else if (errorMessage.contains('firebase') ||
        errorMessage.contains('Firestore')) {
      return 'Lỗi server. Vui lòng thử lại sau.';
    } else {
      return 'Lỗi tải danh mục: $errorMessage';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildCompactAppBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCompactManualInputTab(),
                  _buildScanReceiptTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Compact Header
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.textPrimary,
                    size: 18,
                  ),
                  onPressed: () => Navigator.pop(context),
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                  padding: const EdgeInsets.all(8),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Thêm giao dịch',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 16),

          // Compact Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
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
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              labelPadding: const EdgeInsets.symmetric(vertical: 6),
              tabs: [
                Tab(
                  height: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_outlined, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Nhập thường',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  height: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 16),
                      const SizedBox(width: 6),
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

  Widget _buildCompactManualInputTab() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TransactionTypeSelector(
              selectedType: _selectedType,
              onTypeChanged: (type) {
                if (type != _selectedType) {
                  setState(() {
                    _selectedType = type;
                    _selectedCategory = null;
                    // Reset error state when switching types
                    _categoriesError = null;
                  });
                  _loadCategories();
                }
              },
            ),
            const SizedBox(height: 16),
            TransactionAmountInput(
              controller: _amountController,
            ),
            const SizedBox(height: 16),
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
              onRetry: _retryLoadCategories,
            ),
            const SizedBox(height: 16),
            TransactionDateSelector(
              selectedDate: _selectedDate,
              onDateChanged: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
            ),
            const SizedBox(height: 16),
            TransactionNoteInput(
              controller: _noteController,
            ),
            const SizedBox(height: 16),
            TransactionQuickTemplates(
              transactionType: _selectedType,
              onTemplateSelected: _applyTemplate,
            ),
            const SizedBox(height: 20),
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
        setState(() {
          _scanResults = results;
        });
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
    if (_scanResults == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không có dữ liệu scan để lưu.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
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
      // Parse transaction type first
      final typeStr = _scanResults!['type'] ?? 'expense';
      final transactionType = typeStr.toLowerCase() == 'income'
          ? TransactionType.income
          : TransactionType.expense;

      // Find matching category based on scan result and transaction type
      String categoryId = '';
      final categoryName = _scanResults!['category_suggestion'] ?? '';

      // Filter categories by transaction type first
      final filteredCategories = _categories
          .where((cat) => cat.type == transactionType && !cat.isDeleted)
          .toList();

      print(
          'DEBUG: Looking for category "$categoryName" in ${filteredCategories.length} categories of type ${transactionType.value}');

      if (categoryName.isNotEmpty && filteredCategories.isNotEmpty) {
        // Try exact name match first
        var matchedCategory = filteredCategories.firstWhere(
          (category) =>
              category.name.toLowerCase() == categoryName.toLowerCase(),
          orElse: () => CategoryModel(
            categoryId: '',
            userId: '',
            name: '',
            type: transactionType,
            icon: '',
            color: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        if (matchedCategory.categoryId.isNotEmpty) {
          categoryId = matchedCategory.categoryId;
          print('DEBUG: Found exact match: ${matchedCategory.name}');
        } else {
          // Try partial name match
          for (final category in filteredCategories) {
            if (category.name
                    .toLowerCase()
                    .contains(categoryName.toLowerCase()) ||
                categoryName
                    .toLowerCase()
                    .contains(category.name.toLowerCase())) {
              categoryId = category.categoryId;
              print('DEBUG: Found partial match: ${category.name}');
              break;
            }
          }
        }
      }

      // If no category found, use first available category of the same type
      if (categoryId.isEmpty && filteredCategories.isNotEmpty) {
        categoryId = filteredCategories.first.categoryId;
        print(
            'DEBUG: Using default category: ${filteredCategories.first.name}');
      }

      // If still no category, check if we need to create a default one
      if (categoryId.isEmpty) {
        throw Exception(
            'Không có danh mục ${transactionType == TransactionType.income ? "thu nhập" : "chi tiêu"} khả dụng. Vui lòng tạo danh mục trước.');
      }

      // Parse date
      DateTime transactionDate;
      try {
        transactionDate = DateTime.parse(_scanResults!['date'] ?? '');
      } catch (e) {
        transactionDate = DateTime.now();
      }

      // Create transaction from scan results
      final transaction = TransactionModel(
        transactionId: '',
        userId: currentUser.uid,
        categoryId: categoryId,
        amount: (_scanResults!['amount'] ?? 0).toDouble(),
        type: transactionType,
        date: transactionDate,
        note: _scanResults!['description'] ?? 'Giao dịch từ scan AI',
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

  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    _authSubscription?.cancel();
    _tabController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _timeoutTimer?.cancel();
    super.dispose();
  }
}
