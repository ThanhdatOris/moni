import 'package:flutter/material.dart';

import '../../../../../constants/app_colors.dart';
import '../../../widgets/assistant_action_button.dart';
import '../../../widgets/assistant_base_card.dart';

/// Report preview container with sample data visualization
class ReportPreviewContainer extends StatelessWidget {
  final ReportPreview preview;
  final bool isLoading;
  final VoidCallback? onClose;
  final VoidCallback? onGenerate;
  final VoidCallback? onCustomize;

  const ReportPreviewContainer({
    super.key,
    required this.preview,
    this.isLoading = false,
    this.onClose,
    this.onGenerate,
    this.onCustomize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(context),
          
          // Preview content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildPreviewContent(),
            ),
          ),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preview.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Xem trước báo cáo • ${preview.estimatedPages} trang',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'PREVIEW',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Report overview
        _buildReportOverview(),
        const SizedBox(height: 20),

        // Sample sections
        ...preview.sections.map((section) => _buildSectionPreview(section)),
      ],
    );
  }

  Widget _buildReportOverview() {
    return AssistantBaseCard(
      title: 'Tổng quan báo cáo',
      titleIcon: Icons.summarize,
      gradient: LinearGradient(
        colors: [AppColors.info, AppColors.info.withValues(alpha: 0.8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewItem('Thời gian tạo', preview.generatedDate),
          _buildOverviewItem('Kỳ báo cáo', preview.period),
          _buildOverviewItem('Số lượng giao dịch', '${preview.transactionCount}'),
          _buildOverviewItem('Tổng số trang', '${preview.estimatedPages}'),
          
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đây là bản xem trước với dữ liệu mẫu. Báo cáo thực tế sẽ chứa dữ liệu của bạn.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionPreview(ReportSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AssistantBaseCard(
        title: section.title,
        titleIcon: _getSectionIcon(section.type),
        gradient: LinearGradient(
          colors: [AppColors.grey500, AppColors.grey600],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Sample content based on section type
            if (section.type == ReportSectionType.chart)
              _buildChartPreview()
            else if (section.type == ReportSectionType.table)
              _buildTablePreview()
            else if (section.type == ReportSectionType.summary)
              _buildSummaryPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildChartPreview() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              color: Colors.white.withValues(alpha: 0.6),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Biểu đồ mẫu',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablePreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        children: [
          TableRow(
            children: [
              _buildTableCell('Danh mục', isHeader: true),
              _buildTableCell('Số tiền', isHeader: true),
              _buildTableCell('Tỷ lệ', isHeader: true),
            ],
          ),
          TableRow(
            children: [
              _buildTableCell('Ăn uống'),
              _buildTableCell('8,000,000đ'),
              _buildTableCell('32%'),
            ],
          ),
          TableRow(
            children: [
              _buildTableCell('Di chuyển'),
              _buildTableCell('3,000,000đ'),
              _buildTableCell('12%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: isHeader ? 0.9 : 0.7),
          fontSize: 12,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSummaryPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• Tổng thu nhập: 25,000,000đ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '• Tổng chi tiêu: 18,500,000đ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '• Số dư còn lại: 6,500,000đ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSectionIcon(ReportSectionType type) {
    switch (type) {
      case ReportSectionType.chart:
        return Icons.bar_chart;
      case ReportSectionType.table:
        return Icons.table_chart;
      case ReportSectionType.summary:
        return Icons.summarize;
      case ReportSectionType.analysis:
        return Icons.analytics;
    }
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: AssistantActionButton(
              text: 'Tùy chỉnh',
              icon: Icons.tune,
              type: ButtonType.outline,
              backgroundColor: AppColors.primary,
              textColor: AppColors.primary,
              onPressed: onCustomize,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: AssistantActionButton(
              text: 'Tạo báo cáo hoàn chỉnh',
              icon: Icons.file_download,
              type: ButtonType.primary,
              backgroundColor: AppColors.primary,
              textColor: Colors.white,
              isLoading: isLoading,
              onPressed: onGenerate,
            ),
          ),
        ],
      ),
    );
  }
}

/// Report preview model
class ReportPreview {
  final String title;
  final String generatedDate;
  final String period;
  final int transactionCount;
  final int estimatedPages;
  final List<ReportSection> sections;

  ReportPreview({
    required this.title,
    required this.generatedDate,
    required this.period,
    required this.transactionCount,
    required this.estimatedPages,
    required this.sections,
  });
}

/// Report section model
class ReportSection {
  final String title;
  final String description;
  final ReportSectionType type;

  ReportSection({
    required this.title,
    required this.description,
    required this.type,
  });
}

/// Report section types
enum ReportSectionType {
  chart,
  table,
  summary,
  analysis,
}
