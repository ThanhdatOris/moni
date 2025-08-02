import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../constants/app_colors.dart';
import '../../../../models/report_model.dart';
import '../../../../services/report_service.dart';
import '../../../../widgets/custom_page_header.dart';
import '../../../assistant/models/agent_request_model.dart';
import '../../../assistant/services/global_agent_service.dart';

/// Reports Module Screen - Generate and manage financial reports
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final GlobalAgentService _agentService = GetIt.instance<GlobalAgentService>();
  final ReportService _reportService = GetIt.instance<ReportService>();
  bool _isLoading = false;
  String? _lastReportResult;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const CustomPageHeader(
              icon: Icons.description_outlined,
              title: 'Báo cáo',
              subtitle: 'Xuất báo cáo chi tiết',
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Report Types
                    _buildReportTypes(),
                    
                    const SizedBox(height: 24),
                    
                    // Report Results
                    Expanded(
                      child: _buildReportResults(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loại báo cáo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildReportButton(
                  'Báo cáo tháng',
                  Icons.calendar_month,
                  'monthly',
                  Colors.blue,
                ),
                _buildReportButton(
                  'Báo cáo quý',
                  Icons.calendar_view_month,
                  'quarterly',
                  Colors.green,
                ),
                _buildReportButton(
                  'Báo cáo năm',
                  Icons.calendar_today,
                  'yearly',
                  Colors.orange,
                ),
                _buildReportButton(
                  'Tùy chỉnh',
                  Icons.tune,
                  'custom',
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportButton(String title, IconData icon, String type, Color color) {
    return ElevatedButton(
      onPressed: _isLoading ? null : () => _generateReport(type),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insert_chart, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Kết quả báo cáo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _lastReportResult != null
                      ? SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _lastReportResult!,
                                style: const TextStyle(fontSize: 14, height: 1.6),
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _exportReport('pdf'),
                                      icon: const Icon(Icons.picture_as_pdf),
                                      label: const Text('Xuất PDF'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade50,
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _exportReport('excel'),
                                      icon: const Icon(Icons.table_chart),
                                      label: const Text('Xuất Excel'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade50,
                                        foregroundColor: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Chọn loại báo cáo để bắt đầu',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateReport(String type) async {
    setState(() => _isLoading = true);
    
    try {
      String aiMessage;
      ReportType reportType;
      TimePeriod timePeriod;
      
      // Map string type to enum values
      switch (type) {
        case 'monthly':
          aiMessage = 'Tạo báo cáo chi tiêu tháng này với phân tích chi tiết theo danh mục';
          reportType = ReportType.byTime;
          timePeriod = TimePeriod.monthly;
          break;
        case 'quarterly':
          aiMessage = 'Tạo báo cáo chi tiêu quý này với so sánh các tháng';
          reportType = ReportType.byCategory;
          timePeriod = TimePeriod.quarterly;
          break;
        case 'yearly':
          aiMessage = 'Tạo báo cáo tổng quan chi tiêu cả năm với xu hướng và insights';
          reportType = ReportType.byTime;
          timePeriod = TimePeriod.yearly;
          break;
        case 'custom':
          aiMessage = 'Tạo báo cáo tùy chỉnh với những thông tin quan trọng nhất';
          reportType = ReportType.byCategory;
          timePeriod = TimePeriod.monthly;
          break;
        default:
          aiMessage = 'Tạo báo cáo chi tiêu tổng quát';
          reportType = ReportType.byTime;
          timePeriod = TimePeriod.monthly;
      }
      
      // Step 1: Generate real report using ReportService
      String realReportPath = '';
      String reportSummary = '';
      
      try {
        realReportPath = await _reportService.generateReport(
          type: reportType,
          timePeriod: timePeriod,
        );
        reportSummary = 'Đã tạo báo cáo thành công: $realReportPath';
      } catch (e) {
        reportSummary = 'Không thể tạo báo cáo từ ReportService: $e';
      }
      
      // Step 2: Use AI to analyze and provide insights
      final enhancedMessage = '''$aiMessage

Dữ liệu báo cáo thực tế:
$reportSummary

Hãy phân tích và đưa ra những insight quan trọng từ dữ liệu này, 
cùng với những gợi ý cải thiện tình hình tài chính.''';
      
      final request = AgentRequest.report(
        message: enhancedMessage,
        parameters: {
          'type': type,
          'report_type': reportType.name,
          'time_period': timePeriod.name,
          'has_real_report': realReportPath.isNotEmpty,
          'report_path': realReportPath,
        },
      );
      
      final response = await _agentService.processRequest(request);
      
      if (mounted) {
        if (response.isSuccess) {
          setState(() {
            _lastReportResult = '''${response.message}

---
📄 **Báo cáo được tạo:**
${realReportPath.isNotEmpty ? realReportPath : 'Chưa có file báo cáo'}''';
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${response.error ?? "Không thể tạo báo cáo"}')),
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

  Future<void> _exportReport(String format) async {
    if (_lastReportResult == null) return;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Đang xuất báo cáo...'),
          ],
        ),
      ),
    );

    try {
      final request = AgentRequest.report(
        message: 'Xuất báo cáo dưới dạng $format',
        parameters: {
          'action': 'export',
          'format': format,
          'content': _lastReportResult,
        },
      );
      
      final response = await _agentService.processRequest(request);
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        if (response.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Báo cáo $format đã được tạo thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xuất báo cáo: ${response.error}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }
}
