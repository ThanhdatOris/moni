import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../core/di/injection_container.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_page_header.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _userModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Lắng nghe sự thay đổi auth state
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        _loadUserData();
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final authService = getIt<AuthService>();
      final userData = await authService.getUserData();
      
      if (mounted) {
        setState(() {
          _userModel = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Header
                  CustomPageHeader(
                    icon: Icons.person,
                    title: 'Hồ sơ',
                    subtitle: 'Quản lý thông tin cá nhân',
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildHeader(),
                          _buildSettingsMenu(context, FirebaseAuth.instance.currentUser),
                          _buildLogoutSection(),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary, // Orange
            AppColors.primaryDark, // Deep Orange
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with white border
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _buildAvatar(),
            ),
            const SizedBox(width: 12),
            // Name and Email Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Name
                  Text(
                    _userModel?.name ?? FirebaseAuth.instance.currentUser?.displayName ?? 'Người dùng',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Email
                  Text(
                    _userModel?.email ?? FirebaseAuth.instance.currentUser?.email ?? 'Chưa có email',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Membership badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Thành viên',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Edit profile button
            Container(
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Chỉnh sửa hồ sơ',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final photoURL = _userModel?.photoUrl ?? currentUser?.photoURL;
    final displayName = _userModel?.name ?? currentUser?.displayName ?? 'User';

    return CircleAvatar(
      radius: 36,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 32,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: photoURL != null && photoURL.isNotEmpty
            ? NetworkImage(photoURL)
            : null,
        child: photoURL == null || photoURL.isEmpty
            ? _buildDefaultAvatar(displayName)
            : null,
      ),
    );
  }

  // Data structure cho settings sections
  List<Map<String, dynamic>> get _settingSections => [
    {
      'icon': Icons.person_outline,
      'title': 'Thông tin cá nhân',
      'subtitle': 'Chỉnh sửa hồ sơ và thông tin',
      'widget': _buildPersonalInfoSection(),
    },
    {
      'icon': Icons.security_outlined,
      'title': 'Bảo mật',
      'subtitle': 'Mật khẩu, sinh trắc học',
      'widget': _buildSecuritySection(),
    },
    {
      'icon': Icons.notifications_outlined,
      'title': 'Thông báo',
      'subtitle': 'Cài đặt nhắc nhở và thông báo',
      'widget': _buildNotificationSection(),
    },
    {
      'icon': Icons.backup_outlined,
      'title': 'Sao lưu & Đồng bộ',
      'subtitle': 'Đồng bộ dữ liệu trên các thiết bị',
      'widget': _buildBackupSection(),
    },
    {
      'icon': Icons.palette_outlined,
      'title': 'Giao diện',
      'subtitle': 'Chủ đề, màu sắc, ngôn ngữ',
      'widget': _buildAppearanceSection(),
    },
    {
      'icon': Icons.analytics_outlined,
      'title': 'Dữ liệu',
      'subtitle': 'PDF, Excel, CSV',
      'widget': _buildDataSection(),
    },
    {
      'icon': Icons.help_outline,
      'title': 'Trợ giúp & Hỗ trợ',
      'subtitle': 'FAQ, liên hệ hỗ trợ',
      'widget': _buildHelpSection(),
    },
    {
      'icon': Icons.info_outline,
      'title': 'Về ứng dụng',
      'subtitle': 'Phiên bản 1.0.0',
      'widget': _buildAboutSection(),
    },
  ];

  Widget _buildSettingsMenu(BuildContext context, User? user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Generate setting sections
          ..._settingSections.map((section) => _buildSettingSection(
            context,
            icon: section['icon'],
            title: section['title'],
            subtitle: section['subtitle'],
            child: section['widget'],
          )),
        ],
      ),
    );
  }

  Widget _buildSettingSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFF9800).withValues(alpha: 0.8),
                  const Color(0xFFFF6F00).withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          iconColor: Colors.grey.shade500,
          collapsedIconColor: Colors.grey.shade500,
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          childrenPadding: EdgeInsets.zero,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            Container(
              width: double.infinity,
              color: Colors.grey.shade50,
              padding: const EdgeInsets.only(bottom: 12),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods để tạo các tile
  Widget _buildTile({
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF9800),
            Color(0xFFFF6F00),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return _buildTile(
      title: title,
      subtitle: subtitle,
      trailing: Transform.scale(
        scale: 0.9,
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: const Color(0xFFFF9800),
          inactiveThumbColor: Colors.grey.shade400,
          inactiveTrackColor: Colors.grey.shade200,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, String? subtitle, String buttonText, VoidCallback onPressed) {
    return _buildTile(
      title: title,
      subtitle: subtitle,
      trailing: _buildButton(buttonText, onPressed),
    );
  }

  Widget _buildDropdownTile(String title, String currentValue, List<String> options, Function(String?) onChanged) {
    return _buildTile(
      title: title,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<String>(
          value: currentValue,
          underline: Container(),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
          items: options.map((value) => DropdownMenuItem(
            value: value,
            child: Text(value),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
          const SizedBox(width: 16),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey.shade600, fontSize: 14))),
        ],
      ),
    );
  }

  // Implementation của các section
  Widget _buildPersonalInfoSection() {
    return Column(
      children: [
        _buildActionTile(
          'Chỉnh sửa hồ sơ',
          'Cập nhật thông tin cá nhân',
          'Chỉnh sửa',
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditProfileScreen(),
            ),
          ),
        ),
        _buildInfoTile('Ngày tạo', DateFormat('dd/MM/yyyy').format(DateTime.now())),
        _buildInfoTile('Loại tài khoản', 'Miễn phí'),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return Column(
      children: [
        _buildActionTile(
          'Đổi mật khẩu',
          'Cập nhật mật khẩu bảo mật',
          'Đổi',
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChangePasswordScreen(),
            ),
          ),
        ),
        _buildSwitchTile(
          'Sinh trắc học',
          'Sử dụng vân tay/Face ID',
          true,
          (value) {
            // Handle biometric toggle
          },
        ),
        _buildSwitchTile(
          'Xác thực 2 bước',
          'Tăng cường bảo mật',
          false,
          (value) {
            // Handle 2FA toggle
          },
        ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return Column(
      children: [
        _buildSwitchTile(
          'Thông báo đẩy',
          'Nhận thông báo từ ứng dụng',
          true,
          (value) {
            // Handle push notification toggle
          },
        ),
        _buildSwitchTile(
          'Nhắc nhở ngân sách',
          'Thông báo khi vượt ngân sách',
          true,
          (value) {
            // Handle budget reminder toggle
          },
        ),
        _buildSwitchTile(
          'Báo cáo hàng tháng',
          'Tóm tắt chi tiêu hàng tháng',
          false,
          (value) {
            // Handle monthly report toggle
          },
        ),
      ],
    );
  }

  Widget _buildBackupSection() {
    return Column(
      children: [
        _buildActionTile(
          'Sao lưu ngay',
          'Sao lưu dữ liệu lên cloud',
          'Sao lưu',
          () {
            // Handle backup
          },
        ),
        _buildActionTile(
          'Khôi phục dữ liệu',
          'Khôi phục từ bản sao lưu',
          'Khôi phục',
          () {
            // Handle restore
          },
        ),
        _buildSwitchTile(
          'Tự động sao lưu',
          'Sao lưu định kỳ mỗi ngày',
          true,
          (value) {
            // Handle auto backup toggle
          },
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return Column(
      children: [
        _buildDropdownTile(
          'Chủ đề',
          'Sáng',
          ['Sáng', 'Tối', 'Tự động'],
          (value) {
            // Handle theme change
          },
        ),
        _buildDropdownTile(
          'Ngôn ngữ',
          'Tiếng Việt',
          ['Tiếng Việt', 'English'],
          (value) {
            // Handle language change
          },
        ),
        _buildDropdownTile(
          'Tiền tệ',
          'VND',
          ['VND', 'USD', 'EUR'],
          (value) {
            // Handle currency change
          },
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return Column(
      children: [
        _buildActionTile(
          'Xuất PDF',
          'Xuất báo cáo dạng PDF',
          'Xuất',
          () {
            // Handle PDF export
          },
        ),
        _buildActionTile(
          'Xuất Excel',
          'Xuất dữ liệu Excel',
          'Xuất',
          () {
            // Handle Excel export
          },
        ),
        _buildActionTile(
          'Xuất CSV',
          'Xuất dữ liệu CSV',
          'Xuất',
          () {
            // Handle CSV export
          },
        ),
      ],
    );
  }

  Widget _buildHelpSection() {
    return Column(
      children: [
        _buildActionTile(
          'Câu hỏi thường gặp',
          'Tìm câu trả lời nhanh',
          'Xem',
          () {
            // Navigate to FAQ
          },
        ),
        _buildActionTile(
          'Liên hệ hỗ trợ',
          'Gửi phản hồi hoặc báo lỗi',
          'Liên hệ',
          () {
            // Navigate to contact support
          },
        ),
        _buildActionTile(
          'Đánh giá ứng dụng',
          'Đánh giá trên cửa hàng',
          'Đánh giá',
          () {
            // Open app store rating
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      children: [
        _buildInfoTile('Phiên bản', '1.0.0'),
        _buildInfoTile('Ngày phát hành', '01/01/2024'),
        _buildInfoTile('Nhà phát triển', 'Moni Team'),
        _buildActionTile(
          'Điều khoản sử dụng',
          'Xem điều khoản và chính sách',
          'Xem',
          () {
            // Navigate to terms
          },
        ),
      ],
    );
  }

  Widget _buildLogoutSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Logout button with gradient
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF5252), // Red
                  Color(0xFFD32F2F), // Deep Red
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => _showLogoutDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Đăng xuất',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất không?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await getIt<AuthService>().logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text(
              'Đăng xuất',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String userName) {
    return CircleAvatar(
      radius: 32,
      backgroundColor: const Color(0xFFFF9800),
      child: Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
