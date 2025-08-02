/// Analytics Reports Tab - Tab báo cáo của Analytics Screen
/// Được tách từ AnalyticsScreen để cải thiện maintainability

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../constants/app_colors.dart';

class AnalyticsReportsTab extends StatefulWidget {
  final String selectedPeriod;

  const AnalyticsReportsTab({
    super.key,
    required this.selectedPeriod,
  });

  @override
  State<AnalyticsReportsTab> createState() => _AnalyticsReportsTabState();
}

class _AnalyticsReportsTabState extends State<AnalyticsReportsTab> {
  bool _isLoading = false;
  bool _isExporting = false;
  String _selectedReportType = 'summary';

  final List<ReportType> _reportTypes = [
    ReportType('summary', 'Tổng quan', Icons.summarize, 'Báo cáo tổng quan tài chính'),
    ReportType('detailed', 'Chi tiết', Icons.list_alt, 'Báo cáo chi tiết giao dịch'),
    ReportType('category', 'Theo danh mục', Icons.category, 'Báo cáo phân tích theo danh mục'),
    ReportType('trends', 'Xu hướng', Icons.trending_up, 'Báo cáo xu hướng chi tiêu'),
  ];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  @override
  void didUpdateWidget(AnalyticsReportsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPeriod != widget.selectedPeriod) {
      _loadReportData();
    }
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate data loading
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportReport(String format) async {
    setState(() {
      _isExporting = true;
    });

    // Simulate export process
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _isExporting = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xuất báo cáo ${format.toUpperCase()} thành công!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Haptic feedback
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildReportTypeSelector(),
          const SizedBox(height: 24),
          _buildReportPreview(),
          const SizedBox(height: 24),
          _buildExportOptions(),
          const SizedBox(height: 24),
          _buildReportHistory(),
        ],
      ),
    );
  }

  Widget _buildReportTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Loại báo cáo',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: _reportTypes.length,
            itemBuilder: (context, index) {
              final reportType = _reportTypes[index];
              final isSelected = _selectedReportType == reportType.id;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedReportType = reportType.id;
                  });
                  _loadReportData();
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.grey200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        reportType.icon,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reportType.name,
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportPreview() {
    if (_isLoading) {
      return _buildLoadingPreview();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getSelectedReportType().icon,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Xem trước: ${_getSelectedReportType().name}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.selectedPeriod,
                  style: TextStyle(
                    color: AppColors.info,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getSelectedReportType().description,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          _buildReportContent(),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    switch (_selectedReportType) {
      case 'summary':
        return _buildSummaryReport();
      case 'detailed':
        return _buildDetailedReport();
      case 'category':
        return _buildCategoryReport();
      case 'trends':
        return _buildTrendsReport();
      default:
        return _buildSummaryReport();
    }
  }

  Widget _buildSummaryReport() {
    return Column(
      children: [
        _buildReportSummaryCard('Tổng thu', '15.000.000đ', AppColors.income, Icons.trending_up),
        const SizedBox(height: 12),
        _buildReportSummaryCard('Tổng chi', '8.500.000đ', AppColors.expense, Icons.trending_down),
        const SizedBox(height: 12),
        _buildReportSummaryCard('Số dư', '6.500.000đ', AppColors.primary, Icons.account_balance_wallet),
        const SizedBox(height: 12),
        _buildReportSummaryCard('Giao dịch', '45 giao dịch', AppColors.info, Icons.receipt),
      ],
    );
  }

  Widget _buildDetailedReport() {
    final transactions = [
      {'date': '15/12/2024', 'desc': 'Mua sắm siêu thị', 'amount': '-320.000đ', 'category': 'Ăn uống'},
      {'date': '14/12/2024', 'desc': 'Lương tháng 12', 'amount': '+15.000.000đ', 'category': 'Thu nhập'},
      {'date': '13/12/2024', 'desc': 'Xăng xe', 'amount': '-250.000đ', 'category': 'Di chuyển'},
      {'date': '12/12/2024', 'desc': 'Cafe với bạn', 'amount': '-150.000đ', 'category': 'Giải trí'},
    ];

    return Column(
      children: transactions.map((transaction) {
        final isIncome = transaction['amount']!.startsWith('+');
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isIncome ? AppColors.income : AppColors.expense).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isIncome ? Icons.add : Icons.remove,
                  color: isIncome ? AppColors.income : AppColors.expense,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction['desc']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${transaction['date']} • ${transaction['category']}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                transaction['amount']!,
                style: TextStyle(
                  color: isIncome ? AppColors.income : AppColors.expense,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryReport() {
    final categories = [
      {'name': 'Ăn uống', 'amount': '3.200.000đ', 'percentage': '40%', 'color': AppColors.food},
      {'name': 'Mua sắm', 'amount': '2.100.000đ', 'percentage': '26%', 'color': AppColors.shopping},
      {'name': 'Di chuyển', 'amount': '1.500.000đ', 'percentage': '19%', 'color': AppColors.transport},
      {'name': 'Giải trí', 'amount': '1.200.000đ', 'percentage': '15%', 'color': AppColors.entertainment},
    ];

    return Column(
      children: categories.map((category) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 8,
                decoration: BoxDecoration(
                  color: category['color'] as Color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category['name']!.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    category['amount']!.toString(),
                    style: TextStyle(
                      color: category['color'] as Color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    category['percentage']!.toString(),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrendsReport() {
    final trends = [
      {'title': 'Chi tiêu ăn uống tăng', 'change': '+15%', 'isPositive': false},
      {'title': 'Tiết kiệm cải thiện', 'change': '+25%', 'isPositive': true},
      {'title': 'Mua sắm giảm', 'change': '-10%', 'isPositive': true},
      {'title': 'Thu nhập ổn định', 'change': '+2%', 'isPositive': true},
    ];

    return Column(
      children: trends.map((trend) {
        final isPositive = trend['isPositive'] as bool;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  trend['title']!.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trend['change']!.toString(),
                  style: TextStyle(
                    color: isPositive ? AppColors.success : AppColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReportSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPreview() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Đang tạo báo cáo...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xuất báo cáo',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_isExporting) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.info),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Đang xuất báo cáo...',
                    style: TextStyle(
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildExportButton(
                    'PDF',
                    Icons.picture_as_pdf,
                    AppColors.error,
                    () => _exportReport('pdf'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildExportButton(
                    'Excel',
                    Icons.table_chart,
                    AppColors.success,
                    () => _exportReport('excel'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildExportButton(
                    'CSV',
                    Icons.description,
                    AppColors.warning,
                    () => _exportReport('csv'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildExportButton(
                    'Chia sẻ',
                    Icons.share,
                    AppColors.info,
                    () => _exportReport('share'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExportButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportHistory() {
    final history = [
      {'name': 'Báo cáo tháng 11', 'date': '01/12/2024', 'type': 'PDF'},
      {'name': 'Báo cáo quý 4', 'date': '28/11/2024', 'type': 'Excel'},
      {'name': 'Báo cáo tuần 47', 'date': '25/11/2024', 'type': 'CSV'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lịch sử báo cáo',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...history.map((report) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _getFileIcon(report['type']!),
                    color: _getFileColor(report['type']!),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report['name']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${report['date']} • ${report['type']}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.download,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getFileIcon(String type) {
    switch (type) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'Excel':
        return Icons.table_chart;
      case 'CSV':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String type) {
    switch (type) {
      case 'PDF':
        return AppColors.error;
      case 'Excel':
        return AppColors.success;
      case 'CSV':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  ReportType _getSelectedReportType() {
    return _reportTypes.firstWhere(
      (type) => type.id == _selectedReportType,
      orElse: () => _reportTypes.first,
    );
  }
}

class ReportType {
  final String id;
  final String name;
  final IconData icon;
  final String description;

  ReportType(this.id, this.name, this.icon, this.description);
} 