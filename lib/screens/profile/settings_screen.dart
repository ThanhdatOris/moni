import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _twoFactorAuth = false;
  bool _transactionNotifications = true;
  bool _weeklyReports = false;
  String _theme = 'light';
  String _language = 'vi';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _twoFactorAuth = prefs.getBool('two_factor_auth') ?? false;
      _transactionNotifications = prefs.getBool('transaction_notifications') ?? true;
      _weeklyReports = prefs.getBool('weekly_reports') ?? false;
      _theme = prefs.getString('theme') ?? 'light';
      _language = prefs.getString('language') ?? 'vi';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _performBackup() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Simulate backup process
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sao lưu dữ liệu thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _exportReport() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Simulate export process
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xuất báo cáo thành công! File đã được lưu vào thư mục Downloads.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Security Section
          _buildSectionCard(
            'Bảo mật',
            Icons.security,
            [
              SwitchListTile(
                title: const Text('Xác thực 2 lớp'),
                subtitle: const Text('Tăng cường bảo mật tài khoản'),
                value: _twoFactorAuth,
                onChanged: (value) async {
                  setState(() {
                    _twoFactorAuth = value;
                  });
                  await _saveSetting('two_factor_auth', value);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value 
                          ? 'Đã bật xác thực 2 lớp' 
                          : 'Đã tắt xác thực 2 lớp'
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Notifications Section
          _buildSectionCard(
            'Thông báo',
            Icons.notifications,
            [
              SwitchListTile(
                title: const Text('Thông báo giao dịch'),
                subtitle: const Text('Nhận thông báo khi có giao dịch mới'),
                value: _transactionNotifications,
                onChanged: (value) async {
                  setState(() {
                    _transactionNotifications = value;
                  });
                  await _saveSetting('transaction_notifications', value);
                },
              ),
              SwitchListTile(
                title: const Text('Báo cáo hàng tuần'),
                subtitle: const Text('Nhận báo cáo tài chính hàng tuần'),
                value: _weeklyReports,
                onChanged: (value) async {
                  setState(() {
                    _weeklyReports = value;
                  });
                  await _saveSetting('weekly_reports', value);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Appearance Section
          _buildSectionCard(
            'Giao diện',
            Icons.palette,
            [
              ListTile(
                title: const Text('Chủ đề'),
                subtitle: Text(_theme == 'light' ? 'Sáng' : 'Tối'),
                trailing: DropdownButton<String>(
                  value: _theme,
                  items: const [
                    DropdownMenuItem(value: 'light', child: Text('Sáng')),
                    DropdownMenuItem(value: 'dark', child: Text('Tối')),
                  ],
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() {
                        _theme = value;
                      });
                      await _saveSetting('theme', value);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã chuyển sang chủ đề ${value == 'light' ? 'sáng' : 'tối'}'),
                        ),
                      );
                    }
                  },
                ),
              ),
              ListTile(
                title: const Text('Ngôn ngữ'),
                subtitle: Text(_language == 'vi' ? 'Tiếng Việt' : 'English'),
                trailing: DropdownButton<String>(
                  value: _language,
                  items: const [
                    DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() {
                        _language = value;
                      });
                      await _saveSetting('language', value);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã chuyển sang ${value == 'vi' ? 'Tiếng Việt' : 'English'}'),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Data Section
          _buildSectionCard(
            'Dữ liệu',
            Icons.storage,
            [
              ListTile(
                title: const Text('Sao lưu dữ liệu'),
                subtitle: const Text('Tạo bản sao lưu dữ liệu của bạn'),
                trailing: ElevatedButton(
                  onPressed: _performBackup,
                  child: const Text('Sao lưu'),
                ),
              ),
              ListTile(
                title: const Text('Xuất báo cáo'),
                subtitle: const Text('Xuất báo cáo tài chính dưới dạng PDF'),
                trailing: ElevatedButton(
                  onPressed: _exportReport,
                  child: const Text('Xuất'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
