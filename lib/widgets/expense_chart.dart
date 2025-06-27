import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

import '../constants/app_colors.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/category_service.dart';
import '../services/service_locator.dart';
import '../services/transaction_service.dart';

class ExpenseChart extends StatefulWidget {
  const ExpenseChart({super.key});

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart> {
  final TransactionService _transactionService =
      serviceLocator<TransactionService>();
  final CategoryService _categoryService = serviceLocator<CategoryService>();

  Map<String, double> _chartData = {};
  Map<String, Color> _colorMap = {};
  bool _isLoading = true;
  String _selectedPeriod = 'Tháng này';

  final List<String> _periods = ['Tháng này', 'Tuần này', '30 ngày'];

  // Màu sắc cho từng danh mục
  final List<Color> _categoryColors = [
    const Color(0xFFFF9500), // Cam - Ăn uống
    const Color(0xFF8B5CF6), // Tím - Mua sắm
    const Color(0xFF3B82F6), // Xanh dương - Di chuyển
    const Color(0xFFEC4899), // Hồng - Giải trí
    const Color(0xFF6B7280), // Xám - Hóa đơn
    const Color(0xFF10B981), // Xanh lá - Y tế
    const Color(0xFFF59E0B), // Vàng
    const Color(0xFFEF4444), // Đỏ
  ];

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Tính toán khoảng thời gian
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

      switch (_selectedPeriod) {
        case 'Tuần này':
          final weekday = now.weekday;
          startDate = now.subtract(Duration(days: weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          break;
        case '30 ngày':
          startDate = now.subtract(const Duration(days: 30));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          break;
        default: // Tháng này
          startDate = DateTime(now.year, now.month, 1);
      }

      // Lấy danh sách giao dịch chi tiêu
      final transactions = await _transactionService
          .getTransactions(
            type: TransactionType.expense,
            startDate: startDate,
            endDate: endDate,
          )
          .first;

      // Lấy danh sách danh mục
      final categories = await _categoryService
          .getCategories(
            type: TransactionType.expense,
          )
          .first;

      // Tạo map category ID -> category name
      final categoryMap = <String, CategoryModel>{};
      for (final category in categories) {
        categoryMap[category.categoryId] = category;
      }

      // Tính tổng chi tiêu theo danh mục
      final Map<String, double> categoryTotals = {};
      for (final transaction in transactions) {
        final category = categoryMap[transaction.categoryId];
        final categoryName = category?.name ?? 'Khác';

        categoryTotals[categoryName] =
            (categoryTotals[categoryName] ?? 0) + transaction.amount;
      }

      // Sắp xếp theo giá trị giảm dần và lấy top 5
      final sortedEntries = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final Map<String, double> topCategories = {};
      final Map<String, Color> colors = {};

      double otherTotal = 0;

      for (int i = 0; i < sortedEntries.length; i++) {
        if (i < 5) {
          topCategories[sortedEntries[i].key] = sortedEntries[i].value;
          colors[sortedEntries[i].key] =
              _categoryColors[i % _categoryColors.length];
        } else {
          otherTotal += sortedEntries[i].value;
        }
      }

      if (otherTotal > 0) {
        topCategories['Khác'] = otherTotal;
        colors['Khác'] = _categoryColors[5 % _categoryColors.length];
      }

      if (mounted) {
        setState(() {
          _chartData = topCategories;
          _colorMap = colors;
          _isLoading = false;
        });
      }
    } catch (e) {
      //print('Lỗi load chart data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Cancel any ongoing operations if needed
    super.dispose();
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phân tích chi tiêu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  underline: const SizedBox(),
                  isDense: true,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  items: _periods.map((String period) {
                    return DropdownMenuItem<String>(
                      value: period,
                      child: Text(period),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedPeriod = newValue;
                      });
                      _loadChartData();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_chartData.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    Icon(
                      Icons.pie_chart_outline_rounded,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Chưa có dữ liệu chi tiêu',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Thêm giao dịch để xem phân tích chi tiêu',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Row(
              children: [
                // Biểu đồ tròn
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 200,
                    child: Stack(
                      children: [
                        PieChart(
                          dataMap: _chartData,
                          colorList: _colorMap.values.toList(),
                          animationDuration: const Duration(milliseconds: 800),
                          chartLegendSpacing: 32,
                          chartRadius: MediaQuery.of(context).size.width / 3.2,
                          chartType: ChartType.ring,
                          ringStrokeWidth: 32,
                          centerText: "CHI TIÊU",
                          centerTextStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                          legendOptions: const LegendOptions(
                            showLegends: false,
                          ),
                          chartValuesOptions: ChartValuesOptions(
                            showChartValueBackground: true,
                            showChartValues: true,
                            showChartValuesInPercentage: true,
                            showChartValuesOutside: false,
                            decimalPlaces: 1,
                            chartValueStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Legend
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _chartData.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _colorMap[entry.key],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
