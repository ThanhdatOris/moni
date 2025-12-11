import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moni/config/app_config.dart';
import 'package:moni/services/services.dart';
import 'package:provider/provider.dart';

import '../../../../providers/connectivity_provider.dart';
import '../../widgets/assistant_module_tab_bar.dart';
import 'widgets/report_chart_preview.dart';
import 'widgets/report_export_options.dart';
import 'widgets/report_preview_container.dart';
import 'widgets/report_template_card.dart';

/// Reports Module Screen - Generate and manage financial reports
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin {
  final AIProcessorService _aiService = GetIt.instance<AIProcessorService>();
  final TransactionService _transactionService =
      GetIt.instance<TransactionService>();
  final ChartDataService _chartDataService = GetIt.instance<ChartDataService>();
  late TabController _tabController;
  bool _isLoading = false;
  ReportTemplate? _selectedTemplate;
  double? _totalIncome;
  double? _totalExpense;
  double? _balance;
  int _transactionCount = 0;
  List<ChartPreviewData> _charts = [];

  // Sample data
  final List<ReportTemplate> _availableTemplates = [
    ReportTemplate(
      id: 'financial_summary',
      name: 'Báo cáo tài chính tổng hợp',
      description:
          'Tổng quan toàn diện về tình hình tài chính với phân tích chi tiết thu chi và xu hướng',
      category: ReportCategory.financial,
      features: [
        'Thu chi tổng hợp',
        'Phân tích xu hướng',
        'Biểu đồ trực quan',
        'Dự báo',
      ],
      estimatedTime: const Duration(minutes: 5),
      previewImage: '',
      parameters: {},
    ),
    ReportTemplate(
      id: 'spending_analysis',
      name: 'Phân tích chi tiêu chi tiết',
      description:
          'Báo cáo chi tiết về các khoản chi tiêu theo danh mục với đề xuất tối ưu hóa',
      category: ReportCategory.spending,
      features: [
        'Chi tiêu theo danh mục',
        'So sánh thời gian',
        'Gợi ý tiết kiệm',
        'Cảnh báo',
      ],
      estimatedTime: const Duration(minutes: 3),
      previewImage: '',
      parameters: {},
    ),
    ReportTemplate(
      id: 'budget_performance',
      name: 'Hiệu quả ngân sách',
      description:
          'Đánh giá hiệu quả thực hiện ngân sách với so sánh kế hoạch và thực tế',
      category: ReportCategory.budget,
      features: [
        'So sánh ngân sách',
        'Tỷ lệ thực hiện',
        'Điều chỉnh đề xuất',
        'Mục tiêu',
      ],
      estimatedTime: const Duration(minutes: 4),
      previewImage: '',
      parameters: {},
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar only (no redundant header)
        AssistantModuleTabBar(
          controller: _tabController,
          indicatorColor: Colors.purple.shade600,
          tabs: const [
            Tab(
              height: 32,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined, size: 14),
                  SizedBox(width: 4),
                  Text('Templates'),
                ],
              ),
            ),
            Tab(
              height: 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.preview, size: 14),
                  SizedBox(width: 4),
                  Text('Preview'),
                ],
              ),
            ),
            Tab(
              height: 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.file_download, size: 14),
                  SizedBox(width: 4),
                  Text('Export'),
                ],
              ),
            ),
          ],
        ),

        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTemplatesTab(),
              _buildPreviewTab(),
              _buildExportTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTemplatesTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn template báo cáo:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.grey800,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _availableTemplates.length + 1,
              itemBuilder: (context, index) {
                if (index == _availableTemplates.length) {
                  return const SizedBox(height: 120);
                }
                final template = _availableTemplates[index];
                return ReportTemplateCard(
                  template: template,
                  isSelected: _selectedTemplate?.id == template.id,
                  isLoading: _isLoading,
                  onSelect: () => _showPreview(template),
                  onPreview: () => _showPreview(template),
                  onGenerate: () => _generateReport(template),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedTemplate == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 64, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(
              'Chọn template để xem preview',
              style: TextStyle(color: AppColors.grey600, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Quay lại Templates'),
            ),
          ],
        ),
      );
    }

    // Create preview object based on loaded data
    final preview = ReportPreview(
      title: _selectedTemplate!.name,
      generatedDate: 'Hôm nay',
      period: _currentMonthLabel(),
      transactionCount: _transactionCount,
      estimatedPages: _calculateEstimatedPages(_selectedTemplate!),
      sections: _getSectionsForTemplate(_selectedTemplate!),
    );

    return ReportPreviewContainer(
      preview: preview,
      isLoading: _isLoading,
      onClose: () => _tabController.animateTo(0), // Back to templates
      onGenerate: () => _generateReport(_selectedTemplate!),
      onCustomize: () {
        // TODO: Implement customize
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tính năng tùy chỉnh đang được phát triển'),
          ),
        );
      },
      totalIncome: _totalIncome,
      totalExpense: _totalExpense,
      balance: _balance,
      charts: _charts,
    );
  }

  Widget _buildExportTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportExportOptions(
            availableFormats: ExportFormat.getDefaultFormats(),
            onExport: _exportReport,
            isLoading: _isLoading,
          ),
          // Bottom spacing for menubar
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  void _showPreview(ReportTemplate template) {
    setState(() => _selectedTemplate = template);
    _loadPreviewData(template).then((_) {
      if (!mounted) return;
      _tabController.animateTo(1); // Switch to Preview tab
    });
  }

  Future<void> _generateReport(ReportTemplate template) async {
    // ✅ CHECK OFFLINE
    final connectivity = context.read<ConnectivityProvider>();
    if (connectivity.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text('Cần kết nối internet để tạo báo cáo AI'),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Direct AI call without wrapper layers
      final prompt =
          'Tạo ${template.name} với dữ liệu thực tế của người dùng. '
          'Bao gồm phân tích chi tiết, biểu đồ và gợi ý cải thiện.';

      final response = await _aiService.generateText(prompt);

      if (mounted) {
        if (response.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Báo cáo đã được tạo thành công!')),
          );
          _tabController.animateTo(2); // Switch to export tab
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi: Không thể tạo báo cáo')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ===== Helpers for preview real data =====
  String _currentMonthLabel() {
    final now = DateTime.now();
    return 'Tháng ${now.month}/${now.year}';
  }

  ({DateTime start, DateTime end}) _currentMonthRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return (start: start, end: end);
  }

  int _calculateEstimatedPages(ReportTemplate template) {
    switch (template.id) {
      case 'financial_summary':
        return 5;
      case 'spending_analysis':
        return 8;
      case 'budget_performance':
        return 4;
      default:
        return 3;
    }
  }

  List<ReportSection> _getSectionsForTemplate(ReportTemplate template) {
    switch (template.id) {
      case 'financial_summary':
        return [
          ReportSection(
            title: 'Tổng quan tài chính',
            description: 'Tổng hợp thu chi và số dư hiện tại',
            type: ReportSectionType.summary,
          ),
          ReportSection(
            title: 'Phân bổ chi tiêu',
            description: 'Biểu đồ chi tiêu theo danh mục',
            type: ReportSectionType.chart,
          ),
          ReportSection(
            title: 'Phân tích xu hướng',
            description: 'So sánh thu nhập và chi tiêu theo thời gian',
            type: ReportSectionType.analysis,
          ),
        ];
      case 'spending_analysis':
        return [
          ReportSection(
            title: 'Chi tiết chi tiêu',
            description: 'Danh sách các khoản chi lớn nhất trong tháng',
            type: ReportSectionType.table,
          ),
          ReportSection(
            title: 'Phân bổ theo danh mục',
            description: 'Biểu đồ tròn thể hiện tỷ lệ chi tiêu',
            type: ReportSectionType.chart,
          ),
          ReportSection(
            title: 'Gợi ý tiết kiệm',
            description: 'Đề xuất cắt giảm chi tiêu dựa trên thói quen',
            type: ReportSectionType.analysis,
          ),
        ];
      case 'budget_performance':
        return [
          ReportSection(
            title: 'Tình hình ngân sách',
            description: 'So sánh thực tế với ngân sách đã đặt ra',
            type: ReportSectionType.summary,
          ),
          ReportSection(
            title: 'Tiến độ chi tiêu',
            description: 'Biểu đồ cột thể hiện mức độ sử dụng ngân sách',
            type: ReportSectionType.chart,
          ),
        ];
      default:
        return [
          ReportSection(
            title: 'Tổng quan',
            description: 'Thông tin chung',
            type: ReportSectionType.summary,
          ),
        ];
    }
  }

  Future<void> _loadPreviewData(ReportTemplate template) async {
    setState(() => _isLoading = true);
    try {
      final range = _currentMonthRange();

      // Load basic totals
      final totalIncome = await _transactionService.getTotalIncome(
        startDate: range.start,
        endDate: range.end,
      );
      final totalExpense = await _transactionService.getTotalExpense(
        startDate: range.start,
        endDate: range.end,
      );
      final balance = totalIncome - totalExpense;

      // Load transaction count
      final transactions = await _transactionService.getTransactionsByDateRange(
        range.start,
        range.end,
      );
      final transactionCount = transactions.length;

      // Load charts based on template
      List<ChartPreviewData> charts = [];

      if (template.id == 'financial_summary' ||
          template.id == 'spending_analysis') {
        // Donut chart for expense distribution
        final donutModels = await _chartDataService.getDonutChartData(
          startDate: range.start,
          endDate: range.end,
          transactionType: TransactionType.expense,
        );
        final donutTotal = donutModels.fold<double>(
          0,
          (sum, m) => sum + m.amount,
        );
        final donutData = donutModels
            .map(
              (m) => ChartDataPoint(
                label: m.category,
                value: m.amount,
                color: m.color, // Already hex string
                percentage: m.percentage,
              ),
            )
            .toList();

        if (donutData.isNotEmpty) {
          charts.add(
            ChartPreviewData(
              title: 'Phân bổ chi tiêu',
              subtitle: 'Theo danh mục (tháng này)',
              data: donutData,
              total: donutTotal,
              centerText: '',
            ),
          );
        }
      }

      if (template.id == 'financial_summary' ||
          template.id == 'budget_performance') {
        // Bar chart for income vs expense
        charts.add(
          ChartPreviewData(
            title: 'Thu nhập vs Chi tiêu',
            subtitle: 'Tháng này',
            data: [
              ChartDataPoint(
                label: 'Thu nhập',
                value: totalIncome,
                color:
                    '#${AppColors.success.toARGB32().toRadixString(16).substring(2)}',
                percentage: totalIncome > 0 ? 100 : 0,
              ),
              ChartDataPoint(
                label: 'Chi tiêu',
                value: totalExpense,
                color:
                    '#${AppColors.error.toARGB32().toRadixString(16).substring(2)}',
                percentage: totalExpense > 0
                    ? (totalExpense /
                          (totalIncome > 0 ? totalIncome : totalExpense) *
                          100)
                    : 0,
              ),
            ],
            total: totalIncome + totalExpense,
            centerText: '',
          ),
        );
      }

      setState(() {
        _totalIncome = totalIncome;
        _totalExpense = totalExpense;
        _balance = balance;
        _transactionCount = transactionCount;
        _charts = charts;
      });
    } catch (_) {
      // keep silent in UI, values remain null
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportReport(ExportSettings settings) async {
    if (_selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn template trước')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simulate export process
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã xuất báo cáo ${settings.format?.name ?? "PDF"} thành công!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi xuất file: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
