import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../constants/app_colors.dart';
import '../../../../models/transaction_model.dart';
import '../../../../services/services.dart';
import '../../../assistant/models/agent_request_model.dart';
import '../../../assistant/services/global_agent_service.dart';
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
  final GlobalAgentService _agentService = GetIt.instance<GlobalAgentService>();
  final TransactionService _transactionService =
      GetIt.instance<TransactionService>();
  final ChartDataService _chartDataService = GetIt.instance<ChartDataService>();
  late TabController _tabController;
  bool _isLoading = false;
  ReportTemplate? _selectedTemplate;
  double? _totalIncome;
  double? _totalExpense;
  double? _balance;
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
        'Dự báo'
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
        'Cảnh báo'
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
        'Mục tiêu'
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
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(11), // Giảm từ 12 xuống 11
              color:
                  Colors.purple.shade600, // Solid tím thay vì gradient primary
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.shade600
                      .withValues(alpha: 0.3), // Đổi màu shadow
                  blurRadius: 4, // Giảm từ 6 xuống 4
                  offset: const Offset(0, 1), // Giảm từ 2 xuống 1
                ),
              ],
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600), // Giảm từ 12 xuống 10
            unselectedLabelStyle:
                const TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
            dividerColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
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
      padding: const EdgeInsets.all(20),
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
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _availableTemplates.length,
                    itemBuilder: (context, index) {
                      final template = _availableTemplates[index];
                      return ReportTemplateCard(
                        template: template,
                        isSelected: _selectedTemplate?.id == template.id,
                        isLoading: _isLoading,
                        onSelect: () =>
                            setState(() => _selectedTemplate = template),
                        onPreview: () => _showPreview(template),
                        onGenerate: () => _generateReport(template),
                      );
                    },
                  ),
                ),
                // Bottom spacing for menubar
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
    if (_selectedTemplate == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description,
              size: 64,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              'Chọn template để xem preview',
              style: TextStyle(
                color: AppColors.grey600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          // Chart previews
          Expanded(
            flex: 2,
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                ReportChartPreview(
                  chartData: ChartPreviewData.createSampleData(ChartType.donut),
                  chartType: ChartType.donut,
                  height: 180,
                ),
                ReportChartPreview(
                  chartData: ChartPreviewData.createSampleData(ChartType.bar),
                  chartType: ChartType.bar,
                  height: 180,
                ),
                ReportChartPreview(
                  chartData: ChartPreviewData.createSampleData(ChartType.line),
                  chartType: ChartType.line,
                  height: 180,
                ),
                ReportChartPreview(
                  chartData:
                      ChartPreviewData.createSampleData(ChartType.combined),
                  chartType: ChartType.combined,
                  height: 180,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Preview button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showFullPreview(_selectedTemplate!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Xem preview đầy đủ',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          // Bottom spacing for menubar
          const SizedBox(height: 120),
        ],
      ),
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
    _loadPreviewData(template).then((_) {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ReportPreviewContainer(
          preview: ReportPreview(
            title: template.name,
            generatedDate: 'Hôm nay',
            period: _currentMonthLabel(),
            transactionCount: 0,
            estimatedPages: 8,
            sections: [
              ReportSection(
                title: 'Tổng quan tài chính',
                description: 'Tổng hợp thu chi và số dư hiện tại',
                type: ReportSectionType.summary,
              ),
              ReportSection(
                title: 'Phân tích chi tiêu',
                description: 'Biểu đồ chi tiêu theo danh mục',
                type: ReportSectionType.chart,
              ),
            ],
          ),
          onClose: () => Navigator.pop(context),
          onGenerate: () {
            Navigator.pop(context);
            _generateReport(template);
          },
          totalIncome: _totalIncome,
          totalExpense: _totalExpense,
          balance: _balance,
          charts: _charts,
        ),
      );
    });
  }

  void _showFullPreview(ReportTemplate template) {
    _showPreview(template);
  }

  Future<void> _generateReport(ReportTemplate template) async {
    setState(() => _isLoading = true);

    try {
      final request = AgentRequest.budget(
        message: 'Tạo ${template.name} với dữ liệu thực tế của người dùng. '
            'Bao gồm phân tích chi tiết, biểu đồ và gợi ý cải thiện.',
        parameters: {
          'template_id': template.id,
          'category': template.category.name,
          'features': template.features,
        },
      );

      final response = await _agentService.processRequest(request);

      if (mounted) {
        if (response.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Báo cáo đã được tạo thành công!')),
          );
          _tabController.animateTo(2); // Switch to export tab
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Lỗi: ${response.error ?? "Không thể tạo báo cáo"}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
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

  Future<void> _loadPreviewData(ReportTemplate template) async {
    setState(() => _isLoading = true);
    try {
      final range = _currentMonthRange();
      // Totals
      final totalIncome = await _transactionService.getTotalIncome(
        startDate: range.start,
        endDate: range.end,
      );
      final totalExpense = await _transactionService.getTotalExpense(
        startDate: range.start,
        endDate: range.end,
      );
      final balance = totalIncome - totalExpense;

      // Donut chart for expense distribution
      final donutModels = await _chartDataService.getDonutChartData(
        startDate: range.start,
        endDate: range.end,
        transactionType: TransactionType.expense,
      );
      final donutTotal =
          donutModels.fold<double>(0, (sum, m) => sum + m.amount);
      final donutData = donutModels
          .map((m) => ChartDataPoint(
                label: m.category,
                value: m.amount,
                color: m.color,
                percentage: m.percentage,
              ))
          .toList();
      final donutChart = ChartPreviewData(
        title: 'Phân bổ chi tiêu',
        subtitle: 'Theo danh mục (tháng này)',
        data: donutData,
        total: donutTotal,
        centerText: '',
      );

      setState(() {
        _totalIncome = totalIncome;
        _totalExpense = totalExpense;
        _balance = balance;
        _charts = [donutChart];
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
                'Đã xuất báo cáo ${settings.format?.name ?? "PDF"} thành công!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xuất file: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
