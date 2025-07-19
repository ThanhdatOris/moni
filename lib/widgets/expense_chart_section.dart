import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/category_service.dart';
import '../services/transaction_service.dart';
import '../widgets/charts/components/category_details_list.dart';
import '../widgets/charts/core/chart_controller.dart';
import '../widgets/charts/core/chart_theme.dart';
import '../widgets/charts/models/chart_config_models.dart';
import '../widgets/charts/models/chart_data_models.dart';
import '../widgets/charts/types/category_analysis_chart.dart';
import '../widgets/charts/utils/chart_config_factory.dart';

/// Widget cho expense chart section trong home screen
class ExpenseChartSection extends StatefulWidget {
  final VoidCallback? onCategoryTap;
  final VoidCallback? onRefresh;

  const ExpenseChartSection({
    super.key,
    this.onCategoryTap,
    this.onRefresh,
  });

  @override
  State<ExpenseChartSection> createState() => _ExpenseChartSectionState();
}

class _ExpenseChartSectionState extends State<ExpenseChartSection> {
  // Chart state
  String _selectedPeriod = 'Tháng này';
  final List<String> _periods = ['Tháng này', 'Tuần này', '30 ngày'];
  List<CategoryModel> _categories = [];
  List<CategoryAnalysisData> _categoryAnalysisData = [];
  bool _isLoadingCategories = false;
  bool _hasError = false;
  String _errorMessage = '';
  Key _chartKey = UniqueKey(); // Key để force rebuild chart

  // Services
  final GetIt _getIt = GetIt.instance;
  CategoryService? _categoryService;
  TransactionService? _transactionService;
  ChartController? _chartController;

  // Subscriptions
  StreamSubscription<List<CategoryModel>>? _categoriesSubscription;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    super.dispose();
  }

  /// Initialize services với error handling
  void _initializeServices() {
    try {
      _categoryService = _getIt<CategoryService>();
      _transactionService = _getIt<TransactionService>();
      _chartController = ChartController(
        transactionService: _transactionService!,
        categoryService: _categoryService!,
      );
      _loadCategories();
    } catch (e) {
      debugPrint('Error initializing services: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Không thể khởi tạo services: $e';
      });
    }
  }

  /// Load categories từ service
  Future<void> _loadCategories() async {
    if (!mounted || _categoryService == null) return;

    setState(() {
      _isLoadingCategories = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      await _categoriesSubscription?.cancel();

      // Load expense categories for chart
      _categoriesSubscription =
          _categoryService!.getCategories(type: TransactionType.expense).listen(
        (categories) {
          if (mounted) {
            setState(() {
              _categories = categories;
              _isLoadingCategories = false;
            });
            // Load real analysis data from ChartController
            _loadRealAnalysisData();
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isLoadingCategories = false;
              _hasError = true;
              _errorMessage = 'Lỗi tải danh mục: $error';
            });
            debugPrint('Error loading categories: $error');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
          _hasError = true;
          _errorMessage = 'Lỗi tải danh mục: $e';
        });
        debugPrint('Error loading categories: $e');
      }
    }
  }

  /// Load real category analysis data from ChartController
  Future<void> _loadRealAnalysisData() async {
    if (_categories.isEmpty || _chartController == null) {
      // Nếu không có categories, generate mock data
      _generateMockAnalysisData();
      return;
    }

    try {
      setState(() {
        _isLoadingCategories = true;
        _hasError = false;
        _errorMessage = '';
      });

      // Update chart controller filter based on selected period
      final filter = ChartFilterConfig(
        startDate: ChartConfigFactory.getStartDateFromPeriod(_selectedPeriod),
        endDate: DateTime.now(),
        includeIncome: false,
        includeExpense: true,
      );
      _chartController!.updateFilter(filter);

      // Get real analysis data
      final analysis = await _chartController!.getCategorySpendingAnalysis();

      if (mounted) {
        setState(() {
          _categoryAnalysisData = analysis.categories;
          _isLoadingCategories = false;
          _chartKey = UniqueKey(); // Tạo key mới khi data được load
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
          _hasError = true;
          _errorMessage = 'Lỗi tải dữ liệu phân tích: $e';
        });
        debugPrint('Error loading analysis data: $e');

        // Fallback to mock data if real data fails
        _generateMockAnalysisData();
      }
    }
  }

  /// Generate mock category analysis data for testing (fallback)
  void _generateMockAnalysisData() {
    if (_categories.isEmpty) {
      // Tạo mock categories nếu không có categories
      final now = DateTime.now();
      final mockCategories = [
        CategoryModel(
          categoryId: '1',
          userId: 'mock_user',
          name: 'Ăn uống',
          type: TransactionType.expense,
          color: 0xFFFF5722,
          icon: 'restaurant',
          createdAt: now,
          updatedAt: now,
        ),
        CategoryModel(
          categoryId: '2',
          userId: 'mock_user',
          name: 'Di chuyển',
          type: TransactionType.expense,
          color: 0xFF2196F3,
          icon: 'directions_car',
          createdAt: now,
          updatedAt: now,
        ),
        CategoryModel(
          categoryId: '3',
          userId: 'mock_user',
          name: 'Mua sắm',
          type: TransactionType.expense,
          color: 0xFF9C27B0,
          icon: 'shopping_cart',
          createdAt: now,
          updatedAt: now,
        ),
        CategoryModel(
          categoryId: '4',
          userId: 'mock_user',
          name: 'Giải trí',
          type: TransactionType.expense,
          color: 0xFF4CAF50,
          icon: 'movie',
          createdAt: now,
          updatedAt: now,
        ),
        CategoryModel(
          categoryId: '5',
          userId: 'mock_user',
          name: 'Sức khỏe',
          type: TransactionType.expense,
          color: 0xFFF44336,
          icon: 'local_hospital',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      setState(() {
        _categories = mockCategories;
      });
    }

    final mockData = <CategoryAnalysisData>[];
    final totalAmount = 1000000.0; // 1 triệu VND

    for (int i = 0; i < _categories.length && i < 5; i++) {
      final category = _categories[i];
      final percentage = (25 - i * 4).toDouble(); // 25%, 21%, 17%, 13%, 9%
      final amount = (totalAmount * percentage / 100);
      final transactionCount = (12 - i * 2).clamp(1, 12);
      final averageTransaction = amount / transactionCount;

      mockData.add(CategoryAnalysisData(
        categoryId: category.categoryId,
        categoryName: category.name,
        totalAmount: amount,
        percentage: percentage,
        averageTransaction: averageTransaction,
        transactionCount: transactionCount,
        budgetAmount: amount * 1.2, // Budget cao hơn 20%
        color: Color(category.color),
        trend: [], // Empty trend for now
      ));
    }

    setState(() {
      _categoryAnalysisData = mockData;
      _isLoadingCategories = false;
      _hasError = false;
      _errorMessage = '';
    });
  }

  /// Tạo chart configuration với caching
  CompleteChartConfig _createChartConfig() {
    return ChartConfigFactory.createExpenseAnalysisConfig(
      title: 'Phân tích chi tiêu',
      timePeriod: ChartConfigFactory.getTimePeriodFromString(_selectedPeriod),
      startDate: ChartConfigFactory.getStartDateFromPeriod(_selectedPeriod),
      categories: _categories,
    );
  }

  /// Xử lý thay đổi period
  void _onPeriodChanged(String? newValue) {
    if (newValue != null && newValue != _selectedPeriod) {
      setState(() {
        _selectedPeriod = newValue;
        _chartKey = UniqueKey(); // Tạo key mới để force rebuild chart
      });
      // Reload analysis data with new period
      _loadRealAnalysisData();
    }
  }

  /// Handle category tap
  void _onCategoryTap(CategoryAnalysisData category) {
    widget.onCategoryTap?.call();
    // Có thể thêm navigation hoặc action khác ở đây
    debugPrint('Category tapped: ${category.categoryName}');
  }

  /// Refresh chart data
  Future<void> _refreshChartData() async {
    setState(() {
      _chartKey = UniqueKey(); // Tạo key mới khi refresh
      _hasError = false;
      _errorMessage = '';
    });

    // Reinitialize services nếu cần
    if (_categoryService == null ||
        _transactionService == null ||
        _chartController == null) {
      _initializeServices();
    } else {
      await _loadCategories();
    }

    widget.onRefresh?.call();
  }

  /// Retry loading data
  Future<void> _retryLoading() async {
    await _refreshChartData();
  }

  @override
  Widget build(BuildContext context) {
    final chartTheme = Theme.of(context).brightness == Brightness.dark
        ? ChartTheme.dark()
        : ChartTheme.light();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartHeader(),
          const SizedBox(height: 16),
          _buildChartContent(chartTheme),
          // Category Details List - Nằm liền dưới biểu đồ với chung padding
          if (_categoryAnalysisData.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildCategoryDetailsHeader(),
            const SizedBox(height: 12),
            CategoryDetailsList(
              categories: _categoryAnalysisData,
              theme: chartTheme,
              initialDisplayCount: 5, // Hiển thị top 5
              onCategoryTap: _onCategoryTap,
            ),
          ],
        ],
      ),
    );
  }

  /// Build header với period selector và refresh button
  Widget _buildChartHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Text(
            'Phân tích chi tiêu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildPeriodSelector(),
        const SizedBox(width: 8),
        _buildRefreshButton(),
      ],
    );
  }

  /// Build refresh button
  Widget _buildRefreshButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: _isLoadingCategories ? null : _refreshChartData,
        icon: _isLoadingCategories
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(
                Icons.refresh,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
        tooltip: 'Làm mới dữ liệu',
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
      ),
    );
  }

  /// Build category details header
  Widget _buildCategoryDetailsHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.bar_chart,
            color: Color(0xFF9C27B0),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Chi tiết danh mục',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Top ${_categoryAnalysisData.length}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9C27B0),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Build period selector dropdown
  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA726).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFA726).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: DropdownButton<String>(
        value: _selectedPeriod,
        underline: const SizedBox(),
        isDense: true,
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: Color(0xFFFFA726),
          size: 20,
        ),
        style: const TextStyle(
          color: Color(0xFFFFA726),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        items: _periods.map((String period) {
          return DropdownMenuItem<String>(
            value: period,
            child: Text(period),
          );
        }).toList(),
        onChanged: _onPeriodChanged,
      ),
    );
  }

  /// Build chart content với error handling
  Widget _buildChartContent(ChartTheme chartTheme) {
    if (_isLoadingCategories) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
              const SizedBox(height: 16),
              Text(
                'Đang tải dữ liệu...',
                style: TextStyle(
                  color: chartTheme.colorScheme.onSurfaceVariant,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vui lòng chờ trong giây lát',
                style: TextStyle(
                  color: chartTheme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.shade200,
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Lỗi tải biểu đồ',
                style: TextStyle(
                  color: chartTheme.colorScheme.onSurfaceVariant,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: TextStyle(
                  color: chartTheme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _retryLoading,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA726),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_categories.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.category_outlined,
                  size: 48,
                  color: Colors.blue.shade400,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có danh mục chi tiêu',
                style: TextStyle(
                  color: chartTheme.colorScheme.onSurfaceVariant,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tạo danh mục để xem biểu đồ phân tích',
                style: TextStyle(
                  color: chartTheme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to category management
                  Navigator.pushNamed(context, '/categories');
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tạo danh mục'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 360,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ChartThemeProvider(
          theme: chartTheme,
          child: CategoryAnalysisChart(
            key: _chartKey, // Sử dụng key để force rebuild
            config: _createChartConfig(),
            showPieChart: true,
            showBarChart: false,
            showTrends: false,
            onCategoryTap: _onCategoryTap,
          ),
        ),
      ),
    );
  }
}
