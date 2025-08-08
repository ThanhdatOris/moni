import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../assistant/models/agent_request_model.dart';
import '../../assistant/services/real_data_service.dart';
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
  final RealDataService _realDataService = RealDataService();

  bool _isLoading = false;
  String? _error;
  String? _insightText;
  Map<String, dynamic> _insightMeta = {};
  Map<String, dynamic>? _structuredInsight;
  List<String> _localTips = [];

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
      // Bổ sung ngữ cảnh thực tế từ dữ liệu transaction + analytics
      final analytics = await _realDataService.getAnalyticsData();
      final spendingSummary = await _realDataService.getSpendingSummary();

      // Mẹo cục bộ dựa trên dữ liệu thực
      _localTips = _computeLocalTips(analytics);

      // Chuẩn hóa context và prompt để tạo nội dung súc tích, có số liệu
      final contextPayload = {
        'totals': {
          'income': analytics.totalIncome,
          'expense': analytics.totalExpense,
          'balance': analytics.balance,
          'transaction_count': analytics.transactionCount,
        },
        'period': analytics.period,
        'top_categories': analytics.categoryData
            .take(5)
            .map((c) => {
                  'name': c.category,
                  'amount': c.amount,
                  'percentage': c.percentage,
                  'type': c.type,
                })
            .toList(),
        'summary': spendingSummary,
      };

      final prompt = '''
Bạn là trợ lý tài chính. Dựa trên JSON dưới đây, tạo nội dung Markdown NGẮN với đúng 3 phần:

### Cảnh báo
- 2-3 dòng cảnh báo cụ thể, có % hoặc số tiền

### Đề xuất hành động
- 2-3 hành động khả thi ngay, ưu tiên tác động lớn

### Mẹo nhanh
- 2-3 mẹo tiết kiệm/thói quen dễ áp dụng

Yêu cầu:
- Không viết phần giới thiệu chung
- Mỗi dòng 8-20 từ, emoji ở đầu dòng
- Dùng số liệu trong context
- Trả lời tiếng Việt

DỮ LIỆU:
${jsonEncode(contextPayload)}
''';

      final enrichedContext = {
        'source': 'global_insight_panel',
        'spending_summary': spendingSummary,
        'analytics_totals': contextPayload['totals'],
        if (widget.additionalContext != null) ...widget.additionalContext!,
      };

      final result = await _processor.processRequest(
        moduleId: widget.moduleId,
        requestType: AgentRequestType.analytics,
        query: prompt,
        additionalContext: enrichedContext,
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
        // Nếu response có data.insight (được đi qua Universal → GlobalAgentService), lấy để render
        // AgentResponse từ GlobalAgentService sẽ chứa data.insight.
        final responseData = result.context['response_data'];
        if (responseData is Map && responseData['insight'] != null) {
          _structuredInsight =
              Map<String, dynamic>.from(responseData['insight']);
        }
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
        if (_structuredInsight != null) ...[
          _buildStructuredInsight(_structuredInsight!),
          const SizedBox(height: 12),
        ] else if (_insightText != null) ...[
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: _buildMarkdownOrText(_insightText!),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildMetaChips(),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox.shrink(),
        if (_localTips.isNotEmpty) ...[
          Text(
            'Gợi ý nhanh (từ dữ liệu hiện tại):',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ..._localTips.map(
            (t) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Colors.white)),
                Expanded(
                  child: Text(
                    t,
                    style: const TextStyle(color: Colors.white, height: 1.35),
                  ),
                ),
              ],
            ),
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

  /// Render markdown nếu có, fallback Text nếu không
  Widget _buildMarkdownOrText(String content) {
    // Hiện tại chưa có Markdown widget trong dự án, tạm thời xử lý đơn giản:
    // - Thay các tiêu đề **bold** → TextStyle đậm
    // - Giữ nguyên gạch đầu dòng '-'
    // Có thể thay thế bằng markdown package sau nếu muốn render phong phú.
    final lines = content.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: _buildMarkdownLine(line),
          ),
      ],
    );
  }

  Widget _buildMarkdownLine(String line) {
    // xử lý bold **text** đơn giản
    final boldRegex = RegExp(r"\*\*(.*?)\*\*");
    if (boldRegex.hasMatch(line)) {
      final spans = <TextSpan>[];
      int start = 0;
      for (final match in boldRegex.allMatches(line)) {
        if (match.start > start) {
          spans.add(TextSpan(text: line.substring(start, match.start)));
        }
        spans.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ));
        start = match.end;
      }
      if (start < line.length) {
        spans.add(TextSpan(text: line.substring(start)));
      }
      return RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white, height: 1.35),
          children: spans,
        ),
      );
    }

    // Bullet line
    if (line.trimLeft().startsWith('- ')) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white)),
          Expanded(
            child: Text(
              line.trimLeft().substring(2),
              style: const TextStyle(color: Colors.white, height: 1.35),
            ),
          ),
        ],
      );
    }

    return Text(line,
        style: const TextStyle(color: Colors.white, height: 1.35));
  }

  Widget _buildStructuredInsight(Map<String, dynamic> data) {
    final warnings =
        (data['warnings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final actions =
        (data['actions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final tips = (data['tips'] as List?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (warnings.isNotEmpty) ...[
          _sectionHeader('Cảnh báo'),
          const SizedBox(height: 6),
          ...warnings.map((w) => _bullet('${w['title']}: ${w['detail']}')),
          const SizedBox(height: 12),
        ],
        if (actions.isNotEmpty) ...[
          _sectionHeader('Đề xuất hành động'),
          const SizedBox(height: 6),
          ...actions.map((a) => _bullet('${a['title']} → ${a['nextStep']}')),
          const SizedBox(height: 12),
        ],
        if (tips.isNotEmpty) ...[
          _sectionHeader('Mẹo nhanh'),
          const SizedBox(height: 6),
          ...tips.map(_bullet),
        ],
      ],
    );
  }

  Widget _sectionHeader(String text) => Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.95),
          fontWeight: FontWeight.w700,
        ),
      );

  Widget _bullet(String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white)),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white, height: 1.35)),
          ),
        ],
      );

  List<String> _computeLocalTips(AnalyticsData analytics) {
    final tips = <String>[];
    final income = analytics.totalIncome;
    final expense = analytics.totalExpense;
    final savingsRate = income > 0 ? ((income - expense) / income) * 100 : -100;

    if (income <= 0 && expense <= 0) {
      tips.add(
          'Chưa có dữ liệu giao dịch. Hãy thêm vài giao dịch để AI phân tích.');
      return tips;
    }

    if (expense > income) {
      tips.add('Chi tiêu vượt thu nhập. Cắt 10-15% ở danh mục chi nhiều nhất.');
    }

    if (savingsRate < 10) {
      tips.add(
          'Tỷ lệ tiết kiệm thấp (${savingsRate.toStringAsFixed(1)}%). Đặt mục tiêu ≥ 15%.');
    }

    if (analytics.categoryData.isNotEmpty) {
      final top = analytics.categoryData.first;
      if (top.percentage > 30) {
        tips.add(
            'Danh mục cao nhất: ${top.category} ${top.percentage.toStringAsFixed(1)}%. Thiết lập hạn mức.');
      }
    }

    return tips;
  }
}
