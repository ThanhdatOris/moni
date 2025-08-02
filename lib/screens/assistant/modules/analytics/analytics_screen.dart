import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../constants/app_colors.dart';
import '../../../../services/analytics/analytics_coordinator.dart';
import '../../../../widgets/custom_page_header.dart';
import '../../../assistant/models/agent_request_model.dart';
import '../../../assistant/services/global_agent_service.dart';

/// Analytics Module Screen - Advanced spending analysis and insights
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final GlobalAgentService _agentService = GetIt.instance<GlobalAgentService>();
  final AnalyticsCoordinator _analyticsCoordinator = AnalyticsCoordinator();
  bool _isLoading = false;
  String? _analysisResult;
  
  @override
  void initState() {
    super.initState();
    _loadInitialAnalysis();
  }

  Future<void> _loadInitialAnalysis() async {
    setState(() => _isLoading = true);
    
    try {
      final request = AgentRequest.analytics(
        message: 'Phân tích chi tiêu tháng này và đưa ra những insight quan trọng',
        parameters: {
          'period': 'month',
          'analysis_type': 'comprehensive',
        },
      );
      
      final response = await _agentService.processRequest(request);
      
      if (mounted && response.isSuccess) {
        setState(() {
          _analysisResult = response.message;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải phân tích: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const CustomPageHeader(
              icon: Icons.analytics_outlined,
              title: 'Phân tích thông minh',
              subtitle: 'AI-powered spending insights',
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Actions
                    _buildQuickActions(),
                    
                    const SizedBox(height: 24),
                    
                    // Analysis Results
                    Expanded(
                      child: _buildAnalysisSection(),
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

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phân tích nhanh',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionChip('Tháng này', 'month'),
                _buildActionChip('Quý này', 'quarter'),
                _buildActionChip('Năm này', 'year'),
                _buildActionChip('So sánh', 'compare'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(String label, String period) {
    return ActionChip(
      label: Text(label),
      onPressed: _isLoading ? null : () => _requestAnalysis(period),
      backgroundColor: AppColors.primary.withOpacity(0.1),
    );
  }

  Widget _buildAnalysisSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Kết quả phân tích',
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
                  : _analysisResult != null
                      ? SingleChildScrollView(
                          child: Text(
                            _analysisResult!,
                            style: const TextStyle(fontSize: 14, height: 1.6),
                          ),
                        )
                      : const Center(
                          child: Text(
                            'Chưa có dữ liệu phân tích.\nNhấn vào các nút phía trên để bắt đầu.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestAnalysis(String period) async {
    setState(() => _isLoading = true);
    
    try {
      String message;
      String analyticsData = '';
      
      // Lấy dữ liệu thực từ analytics service
      try {
        final realAnalytics = await _analyticsCoordinator.performComprehensiveAnalysis();
        analyticsData = '''
        
Dữ liệu phân tích thực tế:
- Confidence Score: ${realAnalytics.spendingPatterns.confidenceScore}/100
- Anomalies: ${realAnalytics.anomalies.length} bất thường phát hiện
- Budget Recommendations: ${realAnalytics.budgetRecommendations.length} gợi ý
- Financial Health: ${realAnalytics.financialHealth.overallScore}/100
- Overall Score: ${realAnalytics.overallScore}/100
- Category Patterns: ${realAnalytics.spendingPatterns.categoryDistribution.length} danh mục
''';
      } catch (e) {
        analyticsData = '\nKhông thể lấy dữ liệu analytics thực tế: $e';
      }
      
      switch (period) {
        case 'month':
          message = '''Phân tích chi tiêu tháng này và đưa ra insights quan trọng.
          
Hãy dựa vào dữ liệu sau đây:$analyticsData

Đưa ra những nhận xét và gợi ý cụ thể để cải thiện tình hình tài chính.''';
          break;
        case 'quarter':
          message = '''Phân tích chi tiêu quý này so với các quý trước.
          
Dữ liệu hiện tại:$analyticsData

Đánh giá xu hướng và đề xuất điều chỉnh cho quý tới.''';
          break;
        case 'year':
          message = '''Phân tích tổng quan chi tiêu cả năm và xu hướng.
          
Dữ liệu tóm tắt:$analyticsData

Đưa ra đánh giá tổng thể và kế hoạch cho năm tới.''';
          break;
        case 'compare':
          message = '''So sánh chi tiêu hiện tại với các khoảng thời gian trước đó.
          
Dữ liệu so sánh:$analyticsData

Phân tích sự thay đổi và xu hướng phát triển.''';
          break;
        default:
          message = '''Phân tích chi tiêu tổng quát.
          
Dữ liệu hiện có:$analyticsData

Đưa ra những insight hữu ích nhất.''';
      }
      
      final request = AgentRequest.analytics(
        message: message,
        parameters: {
          'period': period,
          'analysis_type': 'hybrid_real_ai',
          'has_real_data': analyticsData.isNotEmpty,
        },
      );
      
      final response = await _agentService.processRequest(request);
      
      if (mounted) {
        if (response.isSuccess) {
          setState(() {
            _analysisResult = response.message;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${response.error ?? "Không thể phân tích"}')),
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
}
