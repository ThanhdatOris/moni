import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../constants/app_colors.dart';
import '../models/transaction_model.dart';
import '../services/chart_data_service.dart';
import 'charts/components/category_list.dart';
import 'charts/components/donut_chart.dart';
import 'charts/components/filter.dart';
import 'charts/components/trend_bar_chart.dart';
import 'charts/models/chart_data_model.dart';

/// Widget cho expense chart section trong home screen - Cấu trúc mới
/// Header: Title + Chart type toggle
/// Body: Filter + Main chart + Top 5 categories + Show more
class ExpenseChartSection extends StatefulWidget {
  final VoidCallback? onCategoryTap;
  final VoidCallback? onRefresh;
  final VoidCallback? onNavigateToHistory;

  const ExpenseChartSection({
    super.key,
    this.onCategoryTap,
    this.onRefresh,
    this.onNavigateToHistory,
  });

  @override
  State<ExpenseChartSection> createState() => _ExpenseChartSectionState();
}

class _ExpenseChartSectionState extends State<ExpenseChartSection> {
  bool _showTrendChart = false;
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedTransactionType = 'expense';
  DateTime _selectedDate = DateTime.now();

  // Data
  List<ChartDataModel> _chartData = [];
  List<TrendData> _trendData = [];
  FinancialOverviewData? _financialOverviewData;

  // Services
  late final ChartDataService _chartDataService;

  @override
  void initState() {
    super.initState();
    _chartDataService = GetIt.instance<ChartDataService>();
    _loadData();
  }

  /// Load tất cả dữ liệu
  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final endDate =
          DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);

      await Future.wait([
        _loadChartData(startDate, endDate),
        _loadTrendData(),
        _loadFinancialOverviewData(startDate, endDate),
      ]);
    } catch (e) {
      debugPrint('Lỗi load data: $e');
      setState(() {
        _errorMessage = 'Không thể tải dữ liệu: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Load dữ liệu donut chart
  Future<void> _loadChartData(DateTime startDate, DateTime endDate) async {
    try {
      final data = await _chartDataService.getDonutChartData(
        startDate: startDate,
        endDate: endDate,
        transactionType: _getTransactionType(),
      );
      if (mounted) {
        setState(() {
          _chartData = data;
        });
      }
    } catch (e) {
      debugPrint('Lỗi load chart data: $e');
    }
  }

  /// Load dữ liệu trend chart
  Future<void> _loadTrendData() async {
    try {
      final data = await _chartDataService.getTrendChartData(
        months: 3,
        transactionType: _getTransactionType(),
      );
      if (mounted) {
        setState(() {
          _trendData = data;
        });
      }
    } catch (e) {
      debugPrint('Lỗi load trend data: $e');
    }
  }

  /// Load dữ liệu financial overview
  Future<void> _loadFinancialOverviewData(
      DateTime startDate, DateTime endDate) async {
    try {
      final data = await _chartDataService.getFinancialOverviewData(
        startDate: startDate,
        endDate: endDate,
        transactionType: _getTransactionType(),
      );
      if (mounted) {
        setState(() {
          _financialOverviewData = data;
        });
      }
    } catch (e) {
      debugPrint('Lỗi load financial overview data: $e');
    }
  }

  /// Helper method để convert string sang TransactionType
  TransactionType? _getTransactionType() {
    switch (_selectedTransactionType) {
      case 'expense':
        return TransactionType.expense;
      case 'income':
        return TransactionType.income;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth > 900;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.09),
                blurRadius: 10,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              // HEADER: Title + Chart Type Toggle
              _buildHeader(isCompact),

              // BODY: Filter + Main Chart + Categories
              _buildBody(isCompact, isTablet),
            ],
          ),
        );
      },
    );
  }

  /// Build header với title và chart type toggle
  Widget _buildHeader(bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          // Icon và Title
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
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.analytics_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tình hình thu chi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _buildChartTypeToggle(isCompact),
        ],
      ),
    );
  }

  /// Build chart type toggle
  Widget _buildChartTypeToggle(bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildToggleButton(
            'Phân bổ',
            Icons.pie_chart,
            !_showTrendChart,
            () => _switchChartType(false),
            isCompact,
          ),
          _buildToggleButton(
            'Xu hướng',
            Icons.bar_chart,
            _showTrendChart,
            () => _switchChartType(true),
            isCompact,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    String text,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
    bool isCompact,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : AppColors.grey600,
              size: isCompact ? 16 : 18,
            ),
            if (!isCompact) ...[
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.grey600,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build body với filter, main chart và categories
  Widget _buildBody(bool isCompact, bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ROW 1: Filter (Date + Overview/Expense-Income Filter)
          _buildFilterRow(isCompact),

          const SizedBox(height: 20),

          // ROW 2: Main Chart
          _buildMainChart(isCompact, isTablet),

          const SizedBox(height: 20),

          // ROW 3: Top 5 Categories + Show More
          _buildCategoriesRow(isCompact),
        ],
      ),
    );
  }

  /// Build filter row
  Widget _buildFilterRow(bool isCompact) {
    return ChartFilter(
      selectedDate: _selectedDate,
      selectedTransactionType: _selectedTransactionType,
      isLoading: _isLoading,
      onDateChanged: (date) {
        setState(() {
          _selectedDate = date;
        });
        _loadData();
      },
      onTransactionTypeChanged: (type) {
        setState(() {
          _selectedTransactionType = type;
        });
        _loadData();
      },
    );
  }

  /// Build main chart
  Widget _buildMainChart(bool isCompact, bool isTablet) {
    if (_errorMessage.isNotEmpty) {
      return _buildErrorState(isCompact, isTablet);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _showTrendChart
          ? TrendBarChart(
              key: const ValueKey('trend'),
              data: _trendData,
              height: isTablet ? 350 : (isCompact ? 200 : 250),
              onTap: _onTrendDetailsTap,
            )
          : DonutChart(
              key: const ValueKey('donut'),
              data: _chartData,
              size: isTablet ? 300 : (isCompact ? 200 : 250),
              onCategoryTap: _onCategoryTap,
            ),
    );
  }

  /// Build error state
  Widget _buildErrorState(bool isCompact, bool isTablet) {
    return Container(
      height: isTablet ? 400 : (isCompact ? 250 : 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withValues(alpha: 0.05),
            Colors.red.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Lỗi tải dữ liệu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build categories row
  Widget _buildCategoriesRow(bool isCompact) {
    if (_chartData.isEmpty) {
      return const SizedBox.shrink();
    }

    return CategoryList(
      data: _chartData,
      isCompact: isCompact,
      onCategoryTap: _onCategoryItemTap,
      onNavigateToHistory: widget.onNavigateToHistory,
    );
  }

  // Helper methods
  void _switchChartType(bool showTrend) {
    setState(() {
      _showTrendChart = showTrend;
    });
  }

  // Event handlers
  void _onCategoryTap() {
    widget.onCategoryTap?.call();
    debugPrint('Category tapped');
  }

  void _onCategoryItemTap(ChartDataModel item) {
    // Navigate to history with category filter
    widget.onNavigateToHistory?.call();
    debugPrint('Category item tapped: ${item.category}');
  }

  void _onTrendDetailsTap() {
    // TODO: Navigate to trend details
    debugPrint('Trend details tapped');
  }
}
