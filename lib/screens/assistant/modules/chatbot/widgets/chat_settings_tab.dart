import 'package:flutter/material.dart';

import 'package:moni/config/app_config.dart';
import '../services/conversation_service.dart';

/// Chat settings tab for chatbot configuration
class ChatSettingsTab extends StatefulWidget {
  const ChatSettingsTab({super.key});

  @override
  State<ChatSettingsTab> createState() => _ChatSettingsTabState();
}

class _ChatSettingsTabState extends State<ChatSettingsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ConversationService _conversationService = ConversationService();

  // Essential settings only
  bool _autoSave = true;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildEssentialSettings(),
          const SizedBox(height: 16),
          _buildDataManagement(),
          const SizedBox(height: 16),
          _buildAboutSection(),
          // Bottom spacing for menubar
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildEssentialSettings() {
    return _buildSettingsSection(
      title: 'Cài đặt cơ bản',
      icon: Icons.settings_outlined,
      children: [
        _buildSwitchTile(
          title: 'Tự động lưu cuộc trò chuyện',
          subtitle: 'Lưu tự động các cuộc hội thoại',
          value: _autoSave,
          onChanged: (value) => setState(() => _autoSave = value),
        ),
        _buildSwitchTile(
          title: 'Thông báo',
          subtitle: 'Nhận thông báo khi có phản hồi',
          value: _notifications,
          onChanged: (value) => setState(() => _notifications = value),
        ),
      ],
    );
  }

  Widget _buildDataManagement() {
    return _buildSettingsSection(
      title: 'Quản lý dữ liệu',
      icon: Icons.storage,
      children: [
        _buildActionTile(
          title: 'Xóa lịch sử chat',
          subtitle: 'Xóa tất cả cuộc trò chuyện đã lưu',
          icon: Icons.delete_outline,
          color: Colors.red,
          onTap: _showClearHistoryDialog,
        ),
        _buildActionTile(
          title: 'Xuất dữ liệu',
          subtitle: 'Xuất lịch sử chat ra file',
          icon: Icons.download,
          color: Colors.blue,
          onTap: _exportChatData,
        ),
        _buildActionTile(
          title: 'Đặt lại cài đặt',
          subtitle: 'Khôi phục cài đặt về mặc định',
          icon: Icons.restore,
          color: Colors.orange,
          onTap: _resetSettings,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSettingsSection(
      title: 'Thông tin',
      icon: Icons.info_outline,
      children: [
        _buildInfoTile(
          title: 'Phiên bản AI',
          value: 'Gemini 2.0 Flash',
        ),
        _buildInfoTile(
          title: 'Cập nhật cuối',
          value: '09/11/2025',
        ),
        _buildActionTile(
          title: 'Hỗ trợ',
          subtitle: 'Liên hệ đội ngũ hỗ trợ',
          icon: Icons.help_outline,
          color: AppColors.primary,
          onTap: _showSupportDialog,
        ),
      ],
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lịch sử chat'),
        content: const Text(
            'Bạn có chắc chắn muốn xóa tất cả lịch sử trò chuyện? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearChatHistory();
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _clearChatHistory() async {
    try {
      await _conversationService.clearHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa lịch sử chat'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa lịch sử: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _exportChatData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đang xuất dữ liệu chat...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _resetSettings() {
    setState(() {
      _autoSave = true;
      _notifications = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã đặt lại cài đặt về mặc định'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.support_agent, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Hỗ trợ'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn cần hỗ trợ? Liên hệ với chúng tôi:'),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, size: 16),
                SizedBox(width: 8),
                Text('support@moni.com'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 16),
                SizedBox(width: 8),
                Text('1900-123-456'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
