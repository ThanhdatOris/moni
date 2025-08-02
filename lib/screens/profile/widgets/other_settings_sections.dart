/// Other Settings Sections - Các sections khác của Profile
/// Được tách từ ProfileScreen để cải thiện maintainability

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../constants/app_colors.dart';
import '../../../models/user_model.dart';
import 'setting_tile_components.dart';

/// Notification Settings Section
class NotificationSection extends StatefulWidget {
  final UserModel? userModel;
  final bool isLoading;

  const NotificationSection({
    super.key,
    required this.userModel,
    this.isLoading = false,
  });

  @override
  State<NotificationSection> createState() => _NotificationSectionState();
}

class _NotificationSectionState extends State<NotificationSection> {
  bool _pushNotifications = true;
  bool _budgetReminders = true;
  bool _monthlyReports = false;
  bool _transactionAlerts = true;
  bool _promotionalEmails = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  void _loadNotificationSettings() {
    // Load from user preferences
    setState(() {
      // TODO: Implement notification settings when UserModel has these fields
      _pushNotifications = false; // widget.userModel?.pushNotificationsEnabled ?? true;
      _budgetReminders = false; // widget.userModel?.budgetRemindersEnabled ?? true;
      _monthlyReports = false; // widget.userModel?.monthlyReportsEnabled ?? false;
      _transactionAlerts = false; // widget.userModel?.transactionAlertsEnabled ?? true;
      _promotionalEmails = false; // widget.userModel?.promotionalEmailsEnabled ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingContent();
    }

    return Column(
      children: [
        SettingSwitchTile(
          title: 'Thông báo đẩy',
          subtitle: 'Nhận thông báo từ ứng dụng',
          value: _pushNotifications,
          onChanged: (value) {
            setState(() => _pushNotifications = value);
            _showMessage('Đã ${value ? 'bật' : 'tắt'} thông báo đẩy');
          },
        ),
        SettingSwitchTile(
          title: 'Nhắc nhở ngân sách',
          subtitle: 'Thông báo khi vượt ngân sách',
          value: _budgetReminders,
          onChanged: (value) {
            setState(() => _budgetReminders = value);
            _showMessage('Đã ${value ? 'bật' : 'tắt'} nhắc nhở ngân sách');
          },
        ),
        SettingSwitchTile(
          title: 'Cảnh báo giao dịch',
          subtitle: 'Thông báo khi có giao dịch mới',
          value: _transactionAlerts,
          onChanged: (value) {
            setState(() => _transactionAlerts = value);
            _showMessage('Đã ${value ? 'bật' : 'tắt'} cảnh báo giao dịch');
          },
        ),
        SettingSwitchTile(
          title: 'Báo cáo hàng tháng',
          subtitle: 'Tóm tắt chi tiêu hàng tháng',
          value: _monthlyReports,
          onChanged: (value) {
            setState(() => _monthlyReports = value);
            _showMessage('Đã ${value ? 'bật' : 'tắt'} báo cáo hàng tháng');
          },
        ),
        SettingSwitchTile(
          title: 'Email khuyến mãi',
          subtitle: 'Nhận email về ưu đãi và tính năng mới',
          value: _promotionalEmails,
          onChanged: (value) {
            setState(() => _promotionalEmails = value);
            _showMessage('Đã ${value ? 'bật' : 'tắt'} email khuyến mãi');
          },
        ),
      ],
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      children: List.generate(5, (index) => const SettingLoadingTile()),
    );
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Backup & Sync Section
class BackupSection extends StatefulWidget {
  final UserModel? userModel;
  final bool isLoading;

  const BackupSection({
    super.key,
    required this.userModel,
    this.isLoading = false,
  });

  @override
  State<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends State<BackupSection> {
  bool _autoBackup = true;
  bool _isBackingUp = false;
  bool _isRestoring = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingContent();
    }

    return Column(
      children: [
        SettingActionTile(
          title: 'Sao lưu ngay',
          subtitle: 'Sao lưu dữ liệu lên cloud',
          buttonText: _isBackingUp ? 'Đang sao lưu...' : 'Sao lưu',
          buttonIcon: Icons.cloud_upload,
          isEnabled: !_isBackingUp,
          onPressed: _handleBackup,
        ),
        SettingActionTile(
          title: 'Khôi phục dữ liệu',
          subtitle: 'Khôi phục từ bản sao lưu',
          buttonText: _isRestoring ? 'Đang khôi phục...' : 'Khôi phục',
          buttonIcon: Icons.cloud_download,
          buttonColor: AppColors.info,
          isEnabled: !_isRestoring,
          onPressed: _handleRestore,
        ),
        SettingSwitchTile(
          title: 'Tự động sao lưu',
          subtitle: 'Sao lưu định kỳ mỗi ngày',
          value: _autoBackup,
          onChanged: (value) {
            setState(() => _autoBackup = value);
            _showMessage('Đã ${value ? 'bật' : 'tắt'} tự động sao lưu');
          },
        ),
        SettingInfoTile(
          title: 'Lần sao lưu cuối',
          value: 'Hôm qua, 14:30',
          icon: Icons.schedule,
        ),
      ],
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      children: List.generate(4, (index) => const SettingLoadingTile()),
    );
  }

  Future<void> _handleBackup() async {
    setState(() => _isBackingUp = true);
    
    try {
      // Simulate backup process
      await Future.delayed(const Duration(seconds: 2));
      _showMessage('Sao lưu thành công!');
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  Future<void> _handleRestore() async {
    final confirmed = await _showRestoreConfirmDialog();
    if (!confirmed) return;

    setState(() => _isRestoring = true);
    
    try {
      // Simulate restore process
      await Future.delayed(const Duration(seconds: 3));
      _showMessage('Khôi phục thành công!');
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  Future<bool> _showRestoreConfirmDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.warning),
            const SizedBox(width: 12),
            const Text('Khôi phục dữ liệu'),
          ],
        ),
        content: const Text(
          'Dữ liệu hiện tại sẽ bị ghi đè. Bạn có chắc muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Khôi phục', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Appearance Settings Section
class AppearanceSection extends StatefulWidget {
  final UserModel? userModel;
  final bool isLoading;

  const AppearanceSection({
    super.key,
    required this.userModel,
    this.isLoading = false,
  });

  @override
  State<AppearanceSection> createState() => _AppearanceSectionState();
}

class _AppearanceSectionState extends State<AppearanceSection> {
  String _selectedTheme = 'Sáng';
  String _selectedLanguage = 'Tiếng Việt';
  String _selectedCurrency = 'VND';

  final List<String> _themes = ['Sáng', 'Tối', 'Tự động'];
  final List<String> _languages = ['Tiếng Việt', 'English'];
  final List<String> _currencies = ['VND', 'USD', 'EUR'];

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingContent();
    }

    return Column(
      children: [
        SettingDropdownTile(
          title: 'Chủ đề',
          currentValue: _selectedTheme,
          options: _themes,
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedTheme = value);
              _showMessage('Đã chuyển sang chủ đề $value');
            }
          },
        ),
        SettingDropdownTile(
          title: 'Ngôn ngữ',
          currentValue: _selectedLanguage,
          options: _languages,
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedLanguage = value);
              _showMessage('Đã chuyển sang $value');
            }
          },
        ),
        SettingDropdownTile(
          title: 'Tiền tệ',
          currentValue: _selectedCurrency,
          options: _currencies,
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedCurrency = value);
              _showMessage('Đã chuyển sang $value');
            }
          },
        ),
        SettingActionTile(
          title: 'Thiết lập lại giao diện',
          subtitle: 'Khôi phục cài đặt giao diện mặc định',
          buttonText: 'Thiết lập lại',
          buttonIcon: Icons.refresh,
          buttonColor: AppColors.warning,
          onPressed: _handleResetAppearance,
        ),
      ],
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      children: List.generate(4, (index) => const SettingLoadingTile()),
    );
  }

  void _handleResetAppearance() {
    setState(() {
      _selectedTheme = 'Sáng';
      _selectedLanguage = 'Tiếng Việt';
      _selectedCurrency = 'VND';
    });
    _showMessage('Đã khôi phục cài đặt giao diện mặc định');
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Data Export Section
class DataSection extends StatefulWidget {
  final UserModel? userModel;
  final bool isLoading;

  const DataSection({
    super.key,
    required this.userModel,
    this.isLoading = false,
  });

  @override
  State<DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends State<DataSection> {
  bool _isExporting = false;
  String? _exportingType;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingContent();
    }

    return Column(
      children: [
        SettingActionTile(
          title: 'Xuất PDF',
          subtitle: 'Xuất báo cáo dạng PDF',
          buttonText: _isExporting && _exportingType == 'PDF' ? 'Đang xuất...' : 'Xuất',
          buttonIcon: Icons.picture_as_pdf,
          buttonColor: AppColors.error,
          isEnabled: !_isExporting,
          onPressed: () => _handleExport('PDF'),
        ),
        SettingActionTile(
          title: 'Xuất Excel',
          subtitle: 'Xuất dữ liệu Excel',
          buttonText: _isExporting && _exportingType == 'Excel' ? 'Đang xuất...' : 'Xuất',
          buttonIcon: Icons.table_chart,
          buttonColor: AppColors.success,
          isEnabled: !_isExporting,
          onPressed: () => _handleExport('Excel'),
        ),
        SettingActionTile(
          title: 'Xuất CSV',
          subtitle: 'Xuất dữ liệu CSV',
          buttonText: _isExporting && _exportingType == 'CSV' ? 'Đang xuất...' : 'Xuất',
          buttonIcon: Icons.description,
          buttonColor: AppColors.warning,
          isEnabled: !_isExporting,
          onPressed: () => _handleExport('CSV'),
        ),
      ],
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      children: List.generate(3, (index) => const SettingLoadingTile()),
    );
  }

  Future<void> _handleExport(String type) async {
    setState(() {
      _isExporting = true;
      _exportingType = type;
    });

    try {
      // Simulate export process
      await Future.delayed(const Duration(seconds: 2));
      
      // Haptic feedback
      HapticFeedback.lightImpact();
      
      _showMessage('Đã xuất $type thành công!');
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportingType = null;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Help & Support Section
class HelpSection extends StatelessWidget {
  final UserModel? userModel;
  final bool isLoading;

  const HelpSection({
    super.key,
    required this.userModel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingContent();
    }

    return Column(
      children: [
        SettingNavigationTile(
          title: 'Câu hỏi thường gặp',
          subtitle: 'Tìm câu trả lời nhanh',
          onTap: () => _navigateToFAQ(context),
        ),
        SettingNavigationTile(
          title: 'Liên hệ hỗ trợ',
          subtitle: 'Gửi phản hồi hoặc báo lỗi',
          onTap: () => _navigateToSupport(context),
        ),
        SettingNavigationTile(
          title: 'Đánh giá ứng dụng',
          subtitle: 'Đánh giá trên cửa hàng',
          onTap: () => _openAppStoreRating(context),
        ),
        SettingNavigationTile(
          title: 'Chia sẻ ứng dụng',
          subtitle: 'Giới thiệu với bạn bè',
          onTap: () => _shareApp(context),
        ),
      ],
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      children: List.generate(4, (index) => const SettingLoadingTile()),
    );
  }

  void _navigateToFAQ(BuildContext context) {
    _showDevelopmentMessage(context, 'Trang FAQ');
  }

  void _navigateToSupport(BuildContext context) {
    _showDevelopmentMessage(context, 'Liên hệ hỗ trợ');
  }

  void _openAppStoreRating(BuildContext context) {
    _showDevelopmentMessage(context, 'Đánh giá ứng dụng');
  }

  void _shareApp(BuildContext context) {
    _showDevelopmentMessage(context, 'Chia sẻ ứng dụng');
  }

  void _showDevelopmentMessage(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature đang được phát triển'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// About App Section
class AboutSection extends StatelessWidget {
  final UserModel? userModel;
  final bool isLoading;

  const AboutSection({
    super.key,
    required this.userModel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingContent();
    }

    return Column(
      children: [
        SettingInfoTile(
          title: 'Phiên bản',
          value: '1.0.0',
          icon: Icons.info_outline,
        ),
        SettingInfoTile(
          title: 'Build',
          value: '2024.12.15.001',
          icon: Icons.build_circle_outlined,
        ),
        SettingInfoTile(
          title: 'Ngày phát hành',
          value: '15/12/2024',
          icon: Icons.calendar_today_outlined,
        ),
        SettingInfoTile(
          title: 'Nhà phát triển',
          value: 'Moni Team',
          icon: Icons.people_outline,
        ),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        SettingNavigationTile(
          title: 'Điều khoản sử dụng',
          subtitle: 'Xem điều khoản và chính sách',
          onTap: () => _showTerms(context),
        ),
        SettingNavigationTile(
          title: 'Chính sách bảo mật',
          subtitle: 'Cách chúng tôi bảo vệ dữ liệu của bạn',
          onTap: () => _showPrivacyPolicy(context),
        ),
        SettingNavigationTile(
          title: 'Giấy phép mã nguồn mở',
          subtitle: 'Thông tin về thư viện sử dụng',
          onTap: () => _showLicenses(context),
        ),
      ],
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      children: List.generate(7, (index) => const SettingLoadingTile()),
    );
  }

  void _showTerms(BuildContext context) {
    _showDevelopmentMessage(context, 'Điều khoản sử dụng');
  }

  void _showPrivacyPolicy(BuildContext context) {
    _showDevelopmentMessage(context, 'Chính sách bảo mật');
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'MONI',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.monetization_on,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  void _showDevelopmentMessage(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature đang được phát triển'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
} 