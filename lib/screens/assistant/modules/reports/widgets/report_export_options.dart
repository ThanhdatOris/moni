import 'package:flutter/material.dart';

import '../../../../../constants/app_colors.dart';
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
      gradient: LinearGradient(
        colors: [AppColors.primary, AppColors.primaryDark],
      ),
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.availableFormats.map((format) {
            final isSelected = format == _selectedFormat;
            return GestureDetector(
              onTap: () => setState(() => _selectedFormat = format),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getFormatIcon(format),
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          format.name,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          format.description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExportSettings() {
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
        _buildSettingToggle(
          'Bao gồm biểu đồ',
          'Thêm các biểu đồ phân tích vào báo cáo',
          _settings.includeCharts,
          (value) => setState(() => _settings = _settings.copyWith(includeCharts: value)),
        ),
        _buildSettingToggle(
          'Bao gồm bảng dữ liệu',
          'Thêm bảng chi tiết các giao dịch',
          _settings.includeTables,
          (value) => setState(() => _settings = _settings.copyWith(includeTables: value)),
        ),
        _buildSettingToggle(
          'Phân tích AI',
          'Thêm nhận xét và gợi ý từ AI',
          _settings.includeAnalysis,
          (value) => setState(() => _settings = _settings.copyWith(includeAnalysis: value)),
        ),
        _buildSettingToggle(
          'Watermark',
          'Thêm logo và thông tin ứng dụng',
          _settings.includeWatermark,
          (value) => setState(() => _settings = _settings.copyWith(includeWatermark: value)),
        ),
      ],
    );
  }

  Widget _buildSettingToggle(
    String title,
    String description,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withValues(alpha: 0.3),
            inactiveThumbColor: Colors.white.withValues(alpha: 0.6),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }

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
                    _settings = _settings.copyWith(imageQuality: value)
                  ),
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

/// Export types
enum ExportType {
  pdf,
  excel,
  word,
  image,
}
