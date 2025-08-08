import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../assistant/models/agent_request_model.dart';
import '../../assistant/services/universal_ai_processor.dart';
import 'assistant_action_button.dart';
import 'assistant_base_card.dart';

/// GlobalInsightPanel: Một panel AI insight dùng chung cho mọi module
/// - Multifunction qua tham số moduleId, query, context bổ sung
/// - Dùng universal pipeline để gom ngữ cảnh chéo module
class GlobalInsightPanel extends StatefulWidget {
  final String moduleId; // ví dụ: 'home', 'budget', 'reports'
  final String title;
  final String defaultQuery; // câu hỏi mặc định để tạo insight
  final Map<String, dynamic>? additionalContext;
  final VoidCallback? onViewDetails; // hook cho từng trang nếu cần

  const GlobalInsightPanel({
    super.key,
    required this.moduleId,
    this.title = 'AI Insights',
    this.defaultQuery =
        'Tổng hợp các insight quan trọng giúp tôi quản lý tài chính tốt hơn.',
    this.additionalContext,
    this.onViewDetails,
  });

  @override
  State<GlobalInsightPanel> createState() => _GlobalInsightPanelState();
}

class _GlobalInsightPanelState extends State<GlobalInsightPanel> {
  final UniversalAIProcessor _processor = UniversalAIProcessor();

  bool _isLoading = false;
  String? _error;
  String? _insightText;
  Map<String, dynamic> _insightMeta = {};

  @override
  void initState() {
    super.initState();
    _runInsight();
  }

  Future<void> _runInsight() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _processor.processRequest(
        moduleId: widget.moduleId,
        requestType: AgentRequestType.analytics,
        query: widget.defaultQuery,
        additionalContext: widget.additionalContext,
      );

      if (!mounted) return;
      if (result.isError) {
        setState(() {
          _error = result.errorMessage ?? 'Không thể tạo insight';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _insightText = result.response;
        _insightMeta = result.insights;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AssistantBaseCard(
      title: widget.title,
      titleIcon: Icons.psychology,
      isLoading: _isLoading,
      hasError: _error != null,
      onTap: null,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary,
          AppColors.primary.withValues(alpha: 0.85),
        ],
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Không thể tải Insight',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AssistantActionButton(
                text: 'Thử lại',
                icon: Icons.refresh,
                onPressed: _runInsight,
              ),
            ],
          )
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_insightText != null) ...[
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Text(
              _insightText!,
              style: const TextStyle(color: Colors.white, height: 1.35),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildMetaChips(),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: AssistantActionButton(
                text: 'Tạo lại Insight',
                icon: Icons.auto_fix_high,
                onPressed: _runInsight,
              ),
            ),
            const SizedBox(width: 12),
            AssistantActionButton(
              text: 'Chi tiết',
              icon: Icons.arrow_forward,
              type: ButtonType.secondary,
              backgroundColor: Colors.white,
              textColor: AppColors.textPrimary,
              onPressed: widget.onViewDetails,
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildMetaChips() {
    final List<Widget> chips = [];
    if (_insightMeta['has_recommendations'] == true) {
      chips.add(_buildChip(Icons.check_circle, 'Có khuyến nghị'));
    }
    if (_insightMeta['has_warnings'] == true) {
      chips.add(_buildChip(Icons.warning_amber_outlined, 'Có cảnh báo'));
    }
    if (_insightMeta['trend_detected'] == true) {
      chips.add(_buildChip(Icons.trending_up, 'Nhận diện xu hướng'));
    }
    final length = _insightMeta['response_length'];
    if (length is int) {
      chips.add(_buildChip(Icons.notes, 'Độ dài: $length'));
    }
    return chips;
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
