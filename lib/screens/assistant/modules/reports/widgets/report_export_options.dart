import 'package:flutter/material.dart';
import 'package:moni/constants/app_colors.dart';
import 'package:moni/constants/enums.dart';

import '../../../widgets/assistant_action_button.dart';
import '../../../widgets/assistant_base_card.dart';

/// Report export options with format selection and customization
class ReportExportOptions extends StatefulWidget {
  final List<ExportFormat> availableFormats;
  final ExportSettings? defaultSettings;
  final Function(ExportSettings) onExport;
  final bool isLoading;

  const ReportExportOptions({
    super.key,
    required this.availableFormats,
    this.defaultSettings,
    required this.onExport,
    this.isLoading = false,
  });

  @override
  State<ReportExportOptions> createState() => _ReportExportOptionsState();
}

class _ReportExportOptionsState extends State<ReportExportOptions> {
  late ExportFormat _selectedFormat;
  late ExportSettings _settings;

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.availableFormats.first;
    _settings = widget.defaultSettings ?? ExportSettings.defaultSettings();
  }

  @override
  Widget build(BuildContext context) {
    return AssistantBaseCard(
      title: 'Tùy chọn xuất báo cáo',
      titleIcon: Icons.settings,
      gradient: AppColors.purpleGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Format selection
          _buildFormatSelection(),
          const SizedBox(height: 20),

          // Export settings
          _buildExportSettings(),
          const SizedBox(height: 20),

          // Quality settings
          _buildQualitySettings(),
          const SizedBox(height: 20),

          // Export button
          _buildExportButton(),
        ],
      ),
    );
  }

  Widget _buildFormatSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Định dạng xuất file:',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.2,
          ),
          itemCount: widget.availableFormats.length,
          itemBuilder: (context, index) {
            final format = widget.availableFormats[index];
            final isSelected = format == _selectedFormat;
            return GestureDetector(
              onTap: () => setState(() => _selectedFormat = format),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getFormatIcon(format),
                      color: Colors.white.withValues(alpha: 0.95),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            format.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            format.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExportSettings() {
    final settings = [
      (
        title: 'Bao gồm biểu đồ',
        desc: 'Thêm các biểu đồ phân tích vào báo cáo',
        value: _settings.includeCharts,
        onChanged: (bool v) =>
            setState(() => _settings = _settings.copyWith(includeCharts: v)),
      ),
      (
        title: 'Bao gồm bảng dữ liệu',
        desc: 'Thêm bảng chi tiết các giao dịch',
        value: _settings.includeTables,
        onChanged: (bool v) =>
            setState(() => _settings = _settings.copyWith(includeTables: v)),
      ),
      (
        title: 'Phân tích AI',
        desc: 'Thêm nhận xét và gợi ý từ AI',
        value: _settings.includeAnalysis,
        onChanged: (bool v) =>
            setState(() => _settings = _settings.copyWith(includeAnalysis: v)),
      ),
      (
        title: 'Watermark',
        desc: 'Thêm logo và thông tin ứng dụng',
        value: _settings.includeWatermark,
        onChanged: (bool v) =>
            setState(() => _settings = _settings.copyWith(includeWatermark: v)),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tùy chọn nội dung:',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.4,
          ),
          itemCount: settings.length,
          itemBuilder: (context, index) {
            final item = settings[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.desc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: item.value,
                    onChanged: item.onChanged,
                    activeTrackColor: Colors.white.withValues(alpha: 0.3),
                    inactiveThumbColor: Colors.white.withValues(alpha: 0.6),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // (unused legacy toggle builder removed)

  Widget _buildQualitySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chất lượng xuất file:',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chất lượng ảnh:',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    _getQualityLabel(_settings.imageQuality),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: _settings.imageQuality,
                  min: 0.5,
                  max: 1.0,
                  divisions: 2,
                  onChanged: (value) => setState(() =>
                      _settings = _settings.copyWith(imageQuality: value)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      child: AssistantActionButton(
        text: 'Xuất báo cáo ${_selectedFormat.name}',
        icon: Icons.file_download,
        type: ButtonType.secondary,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        textColor: Colors.white,
        isLoading: widget.isLoading,
        onPressed: () => widget.onExport(
          _settings.copyWith(format: _selectedFormat),
        ),
      ),
    );
  }

  IconData _getFormatIcon(ExportFormat format) {
    switch (format.type) {
      case ExportType.pdf:
        return Icons.picture_as_pdf;
      case ExportType.excel:
        return Icons.table_view;
      case ExportType.word:
        return Icons.description;
      case ExportType.csv:
        return Icons.grid_on;
      case ExportType.image:
        return Icons.image;
    }
  }

  String _getQualityLabel(double quality) {
    if (quality <= 0.6) return 'Thấp';
    if (quality <= 0.8) return 'Trung bình';
    return 'Cao';
  }
}

/// Export format model
class ExportFormat {
  final String id;
  final String name;
  final String description;
  final ExportType type;
  final String extension;
  final int maxSizeMB;

  ExportFormat({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.extension,
    required this.maxSizeMB,
  });

  static List<ExportFormat> getDefaultFormats() {
    return [
      ExportFormat(
        id: 'pdf',
        name: 'PDF',
        description: 'Portable Document Format',
        type: ExportType.pdf,
        extension: '.pdf',
        maxSizeMB: 10,
      ),
      ExportFormat(
        id: 'excel',
        name: 'Excel',
        description: 'Microsoft Excel Spreadsheet',
        type: ExportType.excel,
        extension: '.xlsx',
        maxSizeMB: 5,
      ),
      ExportFormat(
        id: 'word',
        name: 'Word',
        description: 'Microsoft Word Document',
        type: ExportType.word,
        extension: '.docx',
        maxSizeMB: 8,
      ),
      // Mock CSV option
      ExportFormat(
        id: 'csv',
        name: 'CSV',
        description: 'Comma-Separated Values',
        type: ExportType.csv,
        extension: '.csv',
        maxSizeMB: 3,
      ),
    ];
  }
}

/// Export settings model
class ExportSettings {
  final ExportFormat? format;
  final bool includeCharts;
  final bool includeTables;
  final bool includeAnalysis;
  final bool includeWatermark;
  final double imageQuality;
  final String? password;

  ExportSettings({
    this.format,
    required this.includeCharts,
    required this.includeTables,
    required this.includeAnalysis,
    required this.includeWatermark,
    required this.imageQuality,
    this.password,
  });

  static ExportSettings defaultSettings() {
    return ExportSettings(
      includeCharts: true,
      includeTables: true,
      includeAnalysis: true,
      includeWatermark: false,
      imageQuality: 0.8,
    );
  }

  ExportSettings copyWith({
    ExportFormat? format,
    bool? includeCharts,
    bool? includeTables,
    bool? includeAnalysis,
    bool? includeWatermark,
    double? imageQuality,
    String? password,
  }) {
    return ExportSettings(
      format: format ?? this.format,
      includeCharts: includeCharts ?? this.includeCharts,
      includeTables: includeTables ?? this.includeTables,
      includeAnalysis: includeAnalysis ?? this.includeAnalysis,
      includeWatermark: includeWatermark ?? this.includeWatermark,
      imageQuality: imageQuality ?? this.imageQuality,
      password: password ?? this.password,
    );
  }
}