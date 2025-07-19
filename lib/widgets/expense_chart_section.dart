import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../constants/app_colors.dart';
import '../models/transaction_model.dart';
import '../services/chart_data_service.dart';
import 'charts/index.dart';

/// Widget cho expense chart section trong home screen - Phiên bản mới với real data
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
  bool _showTrendChart = false;
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedTransactionType = 'all'; // 'all', 'expense', 'income'

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
      // Lấy khoảng thời gian hiện tại (tháng này)
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Load dữ liệu song song
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
        return null; // 'all'
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Financial Overview Cards
          FinancialOverviewCards(
            data: _financialOverviewData,
            isLoading: _isLoading,
            selectedType: _selectedTransactionType,
            onAllocationTap: _onAllocationTap,
            onTrendTap: _onTrendTap,
            onComparisonTap: _onComparisonTap,
            onExpenseTap: _onExpenseTap,
            onIncomeTap: _onIncomeTap,
          ),
          const SizedBox(height: 16),
          _buildChartContent(),
          const SizedBox(height: 16),
          _buildDetailsLink(),
        ],
      ),
    );
  }

  /// Build header với title và toggle buttons
  Widget _buildChartHeader() {
    return Row(
      children: [
        const Text(
          'Tình hình thu chi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        // Toggle buttons container
        Container(
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Phân bổ button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showTrendChart = false;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: !_showTrendChart ? 16 : 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: !_showTrendChart
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pie_chart,
                        color:
                            !_showTrendChart ? Colors.white : AppColors.grey600,
                        size: 16,
                      ),
                      if (!_showTrendChart) ...[
                        const SizedBox(width: 4),
                        const Text(
                          'Phân bổ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Biểu đồ cột button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showTrendChart = true;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _showTrendChart ? 16 : 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _showTrendChart
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bar_chart,
                        color:
                            _showTrendChart ? Colors.white : AppColors.grey600,
                        size: 16,
                      ),
                      if (_showTrendChart) ...[
                        const SizedBox(width: 4),
                        const Text(
                          'Biểu đồ cột',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Refresh button
        if (_isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          )
        else
          GestureDetector(
            onTap: _loadData,
            child: Icon(
              Icons.refresh,
              color: AppColors.grey600,
              size: 20,
            ),
          ),
      ],
    );
  }

  /// Build chart content
  Widget _buildChartContent() {
    if (_isLoading) {
      return Container(
        height: 300,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              SizedBox(height: 16),
              Text('Đang tải dữ liệu...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Container(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
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
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return _showTrendChart
        ? TrendBarChart(
            data: _trendData,
            height: 200,
            onTap: _onTrendDetailsTap,
          )
        : DonutChart(
            data: _chartData,
            size: 250,
            onCategoryTap: _onCategoryTap,
          );
  }

  /// Build details link
  Widget _buildDetailsLink() {
    return GestureDetector(
      onTap: _onDetailsTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Chi tiết từng danh mục (${_chartData.length})',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Event handlers
  void _onAllocationTap() {
    // TODO: Navigate to allocation screen
    debugPrint('Allocation tapped');
  }

  void _onTrendTap() {
    setState(() {
      _showTrendChart = !_showTrendChart;
    });
  }

  void _onCategoryTap() {
    widget.onCategoryTap?.call();
    debugPrint('Category tapped');
  }

  void _onTrendDetailsTap() {
    // TODO: Navigate to trend details
    debugPrint('Trend details tapped');
  }

  void _onDetailsTap() {
    // TODO: Navigate to detailed categories
    debugPrint('Details tapped');
  }

  void _onComparisonTap() {
    // TODO: Navigate to comparison screen
    debugPrint('Comparison tapped');
  }

  void _onExpenseTap() {
    setState(() {
      _selectedTransactionType =
          _selectedTransactionType == 'expense' ? 'all' : 'expense';
    });
    _loadData(); // Reload data với filter mới
    debugPrint('Expense tapped: $_selectedTransactionType');
  }

  void _onIncomeTap() {
    setState(() {
      _selectedTransactionType =
          _selectedTransactionType == 'income' ? 'all' : 'income';
    });
    _loadData(); // Reload data với filter mới
    debugPrint('Income tapped: $_selectedTransactionType');
  }
}
