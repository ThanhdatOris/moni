import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../../constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../services/services.dart';
import '../../utils/formatting/currency_formatter.dart';
import '../../widgets/advanced_validation_widgets.dart';
import '../../widgets/duplicate_warning_dialog.dart';
import '../../widgets/spending_limit_widgets.dart';
import 'widgets/transaction_ai_scan_tab.dart';
import 'widgets/transaction_app_bar.dart';
import 'widgets/transaction_manual_form.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionType? initialType;
  final String? initialCategoryId;

  const AddTransactionScreen({
    super.key,
    this.initialType,
    this.initialCategoryId,
  });

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
  TransactionType _currentTransactionType =
      TransactionType.expense; // Track current type for AI workflow
  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  bool _isCategoriesLoading = false;
  String? _categoriesError;

  // AI auto-fill tracking for UI enhancement
  final Set<String> _aiFilledFields = {};
  bool _showAiFilledHint = false;

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

    // Initialize from initial parameters if provided
    _selectedType = widget.initialType ?? TransactionType.expense;
    _currentTransactionType = _selectedType;

    // Add controller listeners to track manual edits
    _noteController.addListener(() {
      if (_noteController.text.isNotEmpty) {
        _aiFilledFields.remove('note');
        if (_aiFilledFields.isEmpty && _showAiFilledHint) {
          setState(() => _showAiFilledHint = false);
        }
      }
    });

    // Add listener for auth state changes
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        if (user == null) {
          Navigator.of(context).pop();
        } else {
          _loadCategories();
          // Debug all categories
          _debugAllCategories();
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
      _logger.d('🔍 Starting category subscription for type: $_selectedType');
      _categoriesSubscription =
          _categoryService.getCategories(type: _selectedType).listen(
        (categories) async {
          _timeoutTimer?.cancel();
          if (mounted && !hasTimedOut) {
            _logger.d(
                '📦 Received ${categories.length} categories for type: $_selectedType');

            // If no categories found, try to create default categories
            if (categories.isEmpty) {
              _logger
                  .d('🔧 No categories found, creating default categories...');
              try {
                await _categoryService.createDefaultCategories();
                _logger.d('✅ Default categories created successfully');
                // The stream will automatically emit new data after creation
              } catch (e) {
                _logger.e('❌ Failed to create default categories: $e');
              }
            } else {
              // Debug: log category names
              for (var cat in categories) {
                _logger.d('   - ${cat.name} (${cat.type.value})');
              }
            }

            setState(() {
              _categories = categories;
              _isCategoriesLoading = false;
              _categoriesError = null;
              // Preselect category if provided
              if (widget.initialCategoryId != null &&
                  _selectedCategory == null) {
                try {
                  _selectedCategory = categories.firstWhere(
                    (c) => c.categoryId == widget.initialCategoryId,
                    orElse: () =>
                        _selectedCategory ??
                        (categories.isNotEmpty ? categories.first : null)!,
                  );
                } catch (_) {
                  // ignore if not found
                }
              }
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

  /// Debug method to check all categories without type filter
  Future<void> _debugAllCategories() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _logger.d('🔍 Debug: Checking all categories without type filter...');
      _categoryService.getCategories().listen((allCategories) {
        _logger.d('📊 Total categories in DB: ${allCategories.length}');
        final expenseCount = allCategories
            .where((c) => c.type == TransactionType.expense)
            .length;
        final incomeCount =
            allCategories.where((c) => c.type == TransactionType.income).length;
        _logger.d('   - Expense categories: $expenseCount');
        _logger.d('   - Income categories: $incomeCount');

        for (var cat in allCategories) {
          _logger.d('   - ${cat.name} (${cat.type.value})');
        }
      });

      // Also test optimized version
      _logger.d('🔍 Debug: Testing getCategoriesOptimized for current type...');
      _categoryService
          .getCategoriesOptimized(type: _selectedType)
          .listen((categories) {
        _logger.d(
            '📦 Optimized method returned: ${categories.length} categories for type: $_selectedType');
        for (var cat in categories) {
          _logger.d('   - ${cat.name} (${cat.type})');
        }
      });
    } catch (e) {
      _logger.e('❌ Debug all categories failed: $e');
    }
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
            TransactionAppBar(
              tabController: _tabController,
              onBackPressed: () => Navigator.pop(context),
            ),
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

  Widget _buildCompactManualInputTab() {
    return TransactionManualForm(
      formKey: _formKey,
      logger: _logger,
      amountController: _amountController,
      noteController: _noteController,
      selectedType: _selectedType,
      selectedCategory: _selectedCategory,
      selectedDate: _selectedDate,
      categories: _categories,
      isCategoriesLoading: _isCategoriesLoading,
      categoriesError: _categoriesError,
      isLoading: _isLoading,
      aiFilledFields: _aiFilledFields,
      showAiFilledHint: _showAiFilledHint,
      categoryService: _categoryService,
      currentTransactionType: _currentTransactionType,
      onTypeChanged: (type) {
        setState(() {
          _selectedType = type;
          _currentTransactionType = type;
          _selectedCategory = null;
          _categoriesError = null;
          _aiFilledFields.remove('type');
          if (_aiFilledFields.isEmpty) _showAiFilledHint = false;
        });
        _logger.d('📋 Loading categories for type: $type');
        _loadCategories();
      },
      onAmountChanged: (value) {
        _validateAmountRealTime(value);
        _aiFilledFields.remove('amount');
        if (_aiFilledFields.isEmpty) {
          setState(() => _showAiFilledHint = false);
        }
      },
      onCategoryChanged: (category) {
        setState(() {
          _selectedCategory = category;
          _aiFilledFields.remove('category');
          if (_aiFilledFields.isEmpty) _showAiFilledHint = false;
        });
      },
      onRetryLoadCategories: _retryLoadCategories,
      onDateChanged: (date) {
        setState(() {
          _selectedDate = date;
          _aiFilledFields.remove('date');
          if (_aiFilledFields.isEmpty) _showAiFilledHint = false;
        });
      },
      onSaveTransaction: _saveTransaction,
      onDebugAllCategories: _debugAllCategories,
      onDismissAiBanner: () {
        setState(() {
          _showAiFilledHint = false;
          _aiFilledFields.clear();
        });
      },
    );
  }

  Widget _buildScanReceiptTab() {
    return TransactionAiScanTab(
      onScanComplete: (results) async {
        // Tự động điền dữ liệu vào form thủ công
        await _applyScanResults(results);

        // Chuyển sang tab thủ công để user có thể chỉnh sửa
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _tabController.index == 1) {
            _tabController.animateTo(0); // Chuyển về tab manual input

            // Hiển thị thông báo
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Đã điền tự động! Bạn có thể kiểm tra và chỉnh sửa thông tin.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        });
      },
    );
  }

  Future<void> _applyScanResults(Map<String, dynamic> scanResults) async {
    // Debug log để kiểm tra dữ liệu AI trả về
    _logger.d('📊 AI Scan Results: $scanResults');

    _aiFilledFields.clear(); // Reset tracking

    // Điền amount với xử lý nhiều format
    final amount = scanResults['amount'];
    if (amount != null) {
      if (amount is String) {
        // Xử lý format như "125,000" hoặc "125k"
        final cleanAmount = amount.replaceAll(',', '').replaceAll(' ', '');
        final parsedAmount = double.tryParse(cleanAmount) ?? 0;
        _amountController.text =
            CurrencyFormatter.formatDisplay(parsedAmount.toInt());
        _aiFilledFields.add('amount');
      } else if (amount is num) {
        _amountController.text =
            CurrencyFormatter.formatDisplay(amount.toInt());
        _aiFilledFields.add('amount');
      }
    }

    // FIXED: Điền note/description một cách cẩn thận, tránh điền thời gian
    String noteText = '';

    // Ưu tiên note từ AI
    if (scanResults['note'] != null &&
        scanResults['note'].toString().isNotEmpty) {
      noteText = scanResults['note'].toString();
    }
    // Sau đó description
    else if (scanResults['description'] != null &&
        scanResults['description'].toString().isNotEmpty) {
      noteText = scanResults['description'].toString();
    }
    // Cuối cùng merchant name
    else if (scanResults['merchantName'] != null &&
        scanResults['merchantName'].toString().isNotEmpty) {
      noteText = scanResults['merchantName'].toString();
    }

    // Kiểm tra xem có phải là thời gian không (tránh điền thời gian vào note)
    if (noteText.isNotEmpty && !_isTimeString(noteText)) {
      _noteController.text = noteText;
      _aiFilledFields.add('note');
    }

    // FIXED: Điền type và đảm bảo reload categories đúng
    final typeString =
        scanResults['type']?.toString().toLowerCase() ?? 'expense';
    final newType = typeString == 'income'
        ? TransactionType.income
        : TransactionType.expense;

    _logger.d('🔄 AI detected type: $typeString -> $newType');

    if (newType != _selectedType) {
      _logger.d('⚡ Switching transaction type from $_selectedType to $newType');
      setState(() {
        _selectedType = newType;
        _currentTransactionType =
            newType; // Keep current type in sync for category selector
        _selectedCategory = null; // Reset category khi đổi type
      });
      _aiFilledFields.add('type');

      // CRITICAL: Reload categories cho type mới và đợi hoàn thành
      _logger.d('⏳ Loading categories for $newType...');
      await _loadCategoriesForType(newType);
      _logger.d('✅ Categories loaded for $newType');
    }

    // Điền date với fallback an toàn
    final dateValue = scanResults['date'];
    if (dateValue != null) {
      try {
        DateTime? parsedDate;

        if (dateValue is String) {
          // Thử parse các format date khác nhau
          parsedDate = _parseDate(dateValue);
        } else if (dateValue is DateTime) {
          parsedDate = dateValue;
        }

        if (parsedDate != null) {
          setState(() {
            _selectedDate = parsedDate!; // Force unwrap vì đã check null
          });
          _aiFilledFields.add('date');
        }
      } catch (e) {
        _logger.w('⚠️ Error parsing date: $e');
        setState(() {
          _selectedDate = DateTime.now();
        });
      }
    }

    // Show hint if any fields were auto-filled
    setState(() {
      _showAiFilledHint = _aiFilledFields.isNotEmpty;
    });

    // FIXED: Điền category sau khi categories đã được load (với delay longer cho income)
    final isIncomeType = _selectedType == TransactionType.income;
    final delayMs =
        isIncomeType ? 1200 : 800; // More time for income category loading

    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        _logger
            .d('🔍 Attempting to auto-select category for $_selectedType...');
        final categoryName = scanResults['category_name'] ??
            scanResults['category_suggestion'] ??
            scanResults['categoryHint'];
        if (categoryName != null && categoryName.toString().isNotEmpty) {
          _logger.d('🎯 Looking for category: ${categoryName.toString()}');
          final foundCategory = _findCategoryByName(categoryName.toString());
          if (foundCategory != null) {
            _logger.d('✅ Found and selecting category: ${foundCategory.name}');
            setState(() {
              _selectedCategory = foundCategory;
              _aiFilledFields.add('category');
              _showAiFilledHint = _aiFilledFields.isNotEmpty;
            });
          } else {
            _logger.w('❌ Category not found: ${categoryName.toString()}');
            _logger.d(
                '📋 Available categories: ${_categories.map((c) => c.name).join(', ')}');
          }
        }
      }
    });
  }

  CategoryModel? _findCategoryByName(String categoryName) {
    if (_categories.isEmpty) return null;

    try {
      // Chỉ tìm trong categories của type hiện tại
      final currentTypeCategories = _categories
          .where((cat) => cat.type == _currentTransactionType)
          .toList();
      _logger.d(
          '🔍 Searching in ${currentTypeCategories.length} categories of type $_currentTransactionType');

      if (currentTypeCategories.isEmpty) return null;

      // Tìm exact match trước
      var exactMatch = currentTypeCategories
          .where((category) =>
              category.name.toLowerCase() == categoryName.toLowerCase())
          .firstOrNull;
      if (exactMatch != null) {
        _logger.d('✅ Found exact match: ${exactMatch.name}');
        return exactMatch;
      }

      // Tìm partial match
      var partialMatch = currentTypeCategories
          .where((category) =>
              category.name
                  .toLowerCase()
                  .contains(categoryName.toLowerCase()) ||
              categoryName.toLowerCase().contains(category.name.toLowerCase()))
          .firstOrNull;
      if (partialMatch != null) {
        _logger.d('✅ Found partial match: ${partialMatch.name}');
        return partialMatch;
      }

      // Fallback: return first category of current type
      _logger.w(
          '⚠️ No match found, returning first category of type $_currentTransactionType');
      return currentTypeCategories.firstOrNull;
    } catch (e) {
      _logger.e('❌ Error in _findCategoryByName: $e');
      return null;
    }
  }

  Future<void> _saveTransaction() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn danh mục'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để lưu giao dịch'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Parse amount từ formatted text
    final rawAmount = CurrencyFormatter.getRawValue(_amountController.text);
    if (rawAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số tiền phải lớn hơn 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate với TransactionValidationService
    final validationResult = TransactionValidationService.validateTransaction(
      amountText: rawAmount.toString(),
      category: _selectedCategory,
      date: _selectedDate,
      type: _selectedType,
      note: _noteController.text.trim(),
    );

    if (!validationResult.isValid) {
      final errorMessages = validationResult.errors.values.toList();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessages.first),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Kiểm tra trùng lặp
    final duplicateService = DuplicateDetectionService();
    final recentTransactions = await _getRecentTransactions();

    final newTransaction = TransactionModel(
      transactionId: '',
      userId: currentUser.uid,
      categoryId: _selectedCategory!.categoryId,
      amount: rawAmount.toDouble(), // Sử dụng raw amount
      type: _selectedType,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDeleted: false,
    );

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

      // Lấy 30 ngày gần nhất, limit 200 giao dịch để phục vụ validations
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));

      final transactions = await _getIt<TransactionService>()
          .getTransactions(startDate: start, endDate: now, limit: 200)
          .first;

      return transactions;
    } catch (e) {
      _logger.e('Error getting recent transactions: $e');
      return [];
    }
  }

  /// Check if text is a time string (to avoid filling time into note field)
  bool _isTimeString(String text) {
    // Check for common time patterns
    final timePatterns = [
      RegExp(r'^\d{1,2}:\d{2}$'), // HH:MM
      RegExp(r'^\d{1,2}:\d{2}:\d{2}$'), // HH:MM:SS
      RegExp(r'^\d{4}-\d{2}-\d{2}$'), // YYYY-MM-DD
      RegExp(r'^\d{2}/\d{2}/\d{4}$'), // DD/MM/YYYY
      RegExp(r'^\d{1,2}h\d{2}$'), // 14h30
    ];

    return timePatterns.any((pattern) => pattern.hasMatch(text.trim()));
  }

  /// Parse date from various formats
  DateTime? _parseDate(String dateString) {
    try {
      final cleanDate = dateString.trim();

      // Try ISO format first
      if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(cleanDate)) {
        return DateTime.parse(cleanDate);
      }

      // Try DD/MM/YYYY format
      if (RegExp(r'^\d{1,2}/\d{1,2}/\d{4}$').hasMatch(cleanDate)) {
        final parts = cleanDate.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]), // year
            int.parse(parts[1]), // month
            int.parse(parts[0]), // day
          );
        }
      }

      // Try other common formats...
      return DateTime.tryParse(cleanDate);
    } catch (e) {
      _logger.w('⚠️ Failed to parse date: $dateString');
      return null;
    }
  }

  /// Load categories for specific transaction type
  Future<void> _loadCategoriesForType(TransactionType type) async {
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

      // Cancel existing subscription
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

      _logger.d('🔄 Loading categories for type: $type');

      // Create new subscription for specific type
      _categoriesSubscription =
          _categoryService.getCategoriesOptimized(type: type).listen(
        (categories) {
          _timeoutTimer?.cancel();
          if (mounted) {
            _logger.d('✅ Loaded ${categories.length} categories for $type');
            setState(() {
              _categories = categories;
              _isCategoriesLoading = false;
              _categoriesError = null;
            });
          }
        },
        onError: (error) {
          _timeoutTimer?.cancel();
          if (mounted) {
            _logger.e('❌ Error loading categories: $error');
            setState(() {
              _isCategoriesLoading = false;
              _categoriesError = _formatErrorMessage(error);
            });
          }
        },
        cancelOnError: false,
      );

      // Set timeout
      _timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (mounted && _isCategoriesLoading) {
          setState(() {
            _isCategoriesLoading = false;
            _categoriesError = 'Timeout khi tải danh mục';
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
