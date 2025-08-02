import 'package:flutter/material.dart';

import '../../../../constants/app_colors.dart';
import '../../widgets/assistant_base_card.dart';
import '../../widgets/assistant_loading_card.dart';
import 'services/analytics_module_coordinator.dart';

/// Detailed insights screen showing comprehensive analysis
class InsightsDetailScreen extends StatefulWidget {
  final String? initialInsight;
  final List<String> initialRecommendations;

  const InsightsDetailScreen({
    super.key,
    this.initialInsight,
    this.initialRecommendations = const [],
  });

  @override
  State<InsightsDetailScreen> createState() => _InsightsDetailScreenState();
}

class _InsightsDetailScreenState extends State<InsightsDetailScreen> {
  final AnalyticsModuleCoordinator _coordinator = AnalyticsModuleCoordinator();
  
  bool _isLoading = false;
  Map<String, dynamic> _detailedInsights = {};
  List<String> _priorityActions = [];

  @override
  void initState() {
    super.initState();
    _loadDetailedInsights();
  }

  Future<void> _loadDetailedInsights() async {
    setState(() => _isLoading = true);
    
    try {
      // Load trending insights
      final insights = await _coordinator.getTrendingInsights();
      final actions = await _coordinator.getPriorityActions();
      
      setState(() {
        _detailedInsights = {
          'insights': insights,
          'healthScore': 0.75, // Mock data for now
        };
        _priorityActions = actions.map((action) => action.title).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải insights: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chi tiết Insights'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading ? _buildLoadingState() : _buildInsightsContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: AssistantLoadingCard(
        showTitle: false,
      ),
    );
  }

  Widget _buildInsightsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Main insight summary
          if (widget.initialInsight != null)
            _buildMainInsightCard(),
          
          const SizedBox(height: 16),
          
          // Priority actions
          if (_priorityActions.isNotEmpty)
            _buildPriorityActionsCard(),
          
          const SizedBox(height: 16),
          
          // Detailed analysis sections
          ..._buildDetailedSections(),
        ],
      ),
    );
  }

  Widget _buildMainInsightCard() {
    return AssistantBaseCard(
      title: 'Insight Chính',
      titleIcon: Icons.lightbulb,
      gradient: LinearGradient(
        colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          widget.initialInsight!,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityActionsCard() {
    return AssistantBaseCard(
      title: 'Hành động ưu tiên',
      titleIcon: Icons.priority_high,
      gradient: LinearGradient(
        colors: [AppColors.warning, AppColors.warning.withValues(alpha: 0.8)],
      ),
      child: Column(
        children: _priorityActions.map((action) => _buildActionItem(action)).toList(),
      ),
    );
  }

  Widget _buildActionItem(String action) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.white.withValues(alpha: 0.8),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              action,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDetailedSections() {
    final sections = <Widget>[];
    
    // Financial Health
    if (_detailedInsights['healthScore'] != null) {
      sections.add(_buildHealthSection());
      sections.add(const SizedBox(height: 16));
    }
    
    // Spending Patterns
    if (_detailedInsights['spendingPatterns'] != null) {
      sections.add(_buildSpendingPatternsSection());
      sections.add(const SizedBox(height: 16));
    }
    
    // Recommendations
    if (widget.initialRecommendations.isNotEmpty) {
      sections.add(_buildRecommendationsSection());
    }
    
    return sections;
  }

  Widget _buildHealthSection() {
    final healthScore = _detailedInsights['healthScore']?.toDouble() ?? 0.0;
    final healthColor = _getHealthColor(healthScore);
    
    return AssistantBaseCard(
      title: 'Sức khỏe tài chính',
      titleIcon: Icons.favorite,
      gradient: LinearGradient(
        colors: [healthColor, healthColor.withValues(alpha: 0.8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${(healthScore * 100).toInt()}/100',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LinearProgressIndicator(
                    value: healthScore,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _getHealthDescription(healthScore),
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingPatternsSection() {
    return AssistantBaseCard(
      title: 'Mẫu chi tiêu',
      titleIcon: Icons.trending_up,
      gradient: LinearGradient(
        colors: [AppColors.info, AppColors.info.withValues(alpha: 0.8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phân tích chi tiêu trong 30 ngày qua',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 12),
            // Add spending pattern visualization here
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Biểu đồ mẫu chi tiêu',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return AssistantBaseCard(
      title: 'Gợi ý chi tiết',
      titleIcon: Icons.tips_and_updates,
      gradient: LinearGradient(
        colors: [AppColors.success, AppColors.success.withValues(alpha: 0.8)],
      ),
      child: Column(
        children: widget.initialRecommendations.map((rec) => 
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rec,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )
        ).toList(),
      ),
    );
  }

  Color _getHealthColor(double score) {
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.6) return AppColors.warning;
    return AppColors.error;
  }

  String _getHealthDescription(double score) {
    if (score >= 0.8) return 'Tình hình tài chính rất tốt';
    if (score >= 0.6) return 'Tình hình tài chính ổn định';
    if (score >= 0.4) return 'Cần cải thiện tình hình tài chính';
    return 'Tình hình tài chính cần được quan tâm đặc biệt';
  }
}
