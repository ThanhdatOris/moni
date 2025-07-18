import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../../constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../services/advanced_validation_service.dart';
import '../../services/category_service.dart';
import '../../services/duplicate_detection_service.dart';
import '../../services/spending_limit_service.dart';
import '../../services/transaction_service.dart';
import '../../services/transaction_template_service.dart';
import '../../services/transaction_validation_service.dart';
import '../../widgets/advanced_validation_widgets.dart';
import '../../widgets/duplicate_warning_dialog.dart';
import '../../widgets/enhanced_category_selector.dart';
import '../../widgets/enhanced_save_button.dart';
import '../../widgets/spending_limit_widgets.dart';
import '../../widgets/transaction_ai_scan_tab.dart';
import '../../widgets/transaction_amount_input.dart';
import '../../widgets/transaction_date_selector.dart';
import '../../widgets/transaction_note_input.dart';
import '../../widgets/transaction_template_widget.dart';
import '../../widgets/transaction_type_selector.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Logger _logger = Logger();

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
          _categoryService.getCategoriesOptimized(type: _selectedType).listen(
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

      // Set optimized timeout for better UX
      _timeoutTimer = Timer(const Duration(seconds: 5), () {
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
    _logger.d('Retrying load categories');
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
              onChanged: (value) => _validateAmountRealTime(value),
            ),
            const SizedBox(height: 16),
            EnhancedCategorySelector(
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
              transactionType: _tabController.index == 0
                  ? TransactionType.expense
                  : TransactionType.income,
              transactionNote:
                  _noteController.text.isNotEmpty ? _noteController.text : null,
              transactionTime: _selectedDate,
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
            BudgetTransactionTemplateWidget(
              transactionType: _selectedType,
              onTemplateSelected: _applyTransactionTemplate,
            ),
            const SizedBox(height: 20),
            EnhancedSaveButton(
              isLoading: _isLoading,
              onSave: _saveTransaction,
              icon: Icons.save,
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

  void _applyTransactionTemplate(TransactionTemplate template) {
    setState(() {
      _amountController.text = template.amount.toString();
      _noteController.text = template.note;
      _selectedType = template.type;

      // Tìm category từ template
      final category = _categories.firstWhere(
        (cat) => cat.categoryId == template.categoryId,
        orElse: () => CategoryModel(
          categoryId: template.categoryId,
          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
          name: template.categoryName,
          type: template.type,
          icon: 'category',
          iconType: CategoryIconType.material,
          color: 0xFF2196F3,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isDefault: false,
          isSuggested: false,
          isDeleted: false,
        ),
      );
      _selectedCategory = category;
    });
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Enhanced validation using validation service
    final validationResult = TransactionValidationService.validateTransaction(
      amountText: _amountController.text,
      category: _selectedCategory,
      date: _selectedDate,
      type: _selectedType,
      note: _noteController.text,
    );

    if (!validationResult.isValid) {
      // Show first error
      final firstError = validationResult.errors.values.first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(firstError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show warnings if any
    if (validationResult.hasWarnings) {
      final hasUserConfirmed =
          await _showWarningDialog(validationResult.warnings);
      if (!hasUserConfirmed) return;
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

    // Tạo transaction model để kiểm tra trùng lặp
    final newTransaction = TransactionModel(
      transactionId: '',
      userId: currentUser.uid,
      amount: double.parse(_amountController.text),
      categoryId: _selectedCategory!.categoryId,
      type: _selectedType,
      note: _noteController.text,
      date: _selectedDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDeleted: false,
    );

    // Kiểm tra trùng lặp
    final duplicateService = DuplicateDetectionService();
    final recentTransactions = await _getRecentTransactions();
    final duplicateResult = await duplicateService.detectDuplicates(
      newTransaction: newTransaction,
      recentTransactions: recentTransactions,
    );

    // Hiển thị cảnh báo trùng lặp nếu cần
    if (duplicateResult.hasDuplicates) {
      if (!mounted) return;
      final shouldProceed = await BudgetDuplicateWarningDialog.show(
        context,
        duplicateResult,
      );
      if (!shouldProceed) return;
    }

    // Kiểm tra giới hạn chi tiêu (chỉ cho giao dịch chi tiêu)
    if (_selectedType == TransactionType.expense) {
      final limitService = SpendingLimitService();
      final limitResult = await limitService.checkSpendingLimit(
        amount: newTransaction.amount,
        categoryId: _selectedCategory?.id ?? '',
        transactionDate: _selectedDate,
        recentTransactions: recentTransactions,
      );

      if (limitResult.hasWarnings) {
        if (limitResult.shouldBlock) {
          // Hiển thị cảnh báo và block
          if (!mounted) return;
          final shouldContinue = await BudgetLimitWarningDialog.show(
            context,
            limitResult,
          );
          if (!shouldContinue) return;
        } else {
          // Hiển thị cảnh báo nhưng cho phép tiếp tục
          if (!mounted) return;
          await BudgetLimitWarningDialog.show(
            context,
            limitResult,
          );
        }
      }
    }

    // Advanced validation
    final advancedValidationResult =
        await AdvancedValidationService.validateSpendingPattern(
      newTransaction: newTransaction,
      recentTransactions: recentTransactions,
      categories: _categories,
    );

    // Kiểm tra template suggestions
    final templateService = TransactionTemplateService();
    final templateSuggestions =
        await templateService.suggestTemplatesFromFrequentTransactions(
      recentTransactions,
    );

    // Hiển thị advanced validation nếu có warnings
    if (advancedValidationResult.hasWarnings) {
      if (!mounted) return;
      final advancedResult = await BudgetAdvancedValidationDialog.show(
        context,
        validationResult: advancedValidationResult,
      );

      // TODO: Handle template suggestions separately
      // Template suggestions: ${templateSuggestions.length} found

      switch (advancedResult) {
        case AdvancedValidationResult.cancel:
          return;
        case AdvancedValidationResult.setupRecurring:
          // TODO: Implement recurring transaction setup
          break;
        case AdvancedValidationResult.proceed:
          break;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedCategory == null) {
        throw Exception('Vui lòng chọn danh mục');
      }

      final amount = validationResult.amount ?? 0.0;
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

      _logger.d(
          'Looking for category "$categoryName" in ${filteredCategories.length} categories of type ${transactionType.value}');

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
          _logger.d('Found exact match: ${matchedCategory.name}');
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
              _logger.d('Found partial match: ${category.name}');
              break;
            }
          }
        }
      }

      // If no category found, use first available category of the same type
      if (categoryId.isEmpty && filteredCategories.isNotEmpty) {
        categoryId = filteredCategories.first.categoryId;
        _logger.d('Using default category: ${filteredCategories.first.name}');
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

  /// Real-time validation cho amount input
  void _validateAmountRealTime(String value) {
    // Chỉ validate nếu có input
    if (value.isNotEmpty) {
      // Remove formatting to get raw number
      final cleanValue = value.replaceAll(',', '');
      final amount = double.tryParse(cleanValue);

      if (amount != null &&
          amount > TransactionValidationService.suspiciousAmount) {
        // Show subtle warning cho số tiền lớn
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Số tiền khá lớn (${TransactionValidationService.formatCurrency(amount)})'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Lấy danh sách giao dịch gần đây để kiểm tra trùng lặp
  Future<List<TransactionModel>> _getRecentTransactions() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];

      // Lấy giao dịch gần đây (tạm thời trả về danh sách rỗng)
      // TODO: Implement actual recent transactions retrieval
      return [];
    } catch (e) {
      _logger.e('Error getting recent transactions: $e');
      return [];
    }
  }

  /// Show warning dialog cho user confirmation
  Future<bool> _showWarningDialog(Map<String, String> warnings) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange),
                const SizedBox(width: 8),
                Text('Cảnh báo'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: warnings.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: Colors.orange)),
                      Expanded(child: Text(entry.value)),
                    ],
                  ),
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Tiếp tục'),
              ),
            ],
          ),
        ) ??
        false;
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
