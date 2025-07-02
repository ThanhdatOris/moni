import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header với thông tin cá nhân
                _buildProfileHeader(snapshot.data),

                // Khoảng trống
                const SizedBox(height: 20),

                // Menu cài đặt
                _buildSettingsMenu(context),

                const SizedBox(height: 100), // Space for bottom navigation
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(User? user) {
    final userName =
        user?.displayName ?? user?.email?.split('@')[0] ?? 'Người dùng';
    final userEmail = user?.email ?? 'user@example.com';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF7043), Color(0xFFFFD180)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Avatar và thông tin cơ bản
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFFFF9800),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Premium Member',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Edit button
              IconButton(
                onPressed: () {
                  // TODO: Navigate to edit profile
                },
                icon: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsMenu(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey300.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Cài đặt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildMenuItem(
            Icons.person_outline,
            'Thông tin cá nhân',
            'Chỉnh sửa hồ sơ và thông tin',
            onTap: () {
              // TODO: Navigate to profile edit
            },
          ),
          _buildMenuItem(
            Icons.security_outlined,
            'Bảo mật',
            'Mật khẩu, sinh trắc học',
            onTap: () {
              // TODO: Navigate to security settings
            },
          ),
          _buildMenuItem(
            Icons.notifications_outlined,
            'Thông báo',
            'Cài đặt nhắc nhở và thông báo',
            onTap: () {
              // TODO: Navigate to notification settings
            },
          ),
          _buildMenuItem(
            Icons.backup_outlined,
            'Sao lưu & Đồng bộ',
            'Đồng bộ dữ liệu trên các thiết bị',
            onTap: () {
              // TODO: Navigate to backup settings
            },
          ),
          _buildMenuItem(
            Icons.palette_outlined,
            'Giao diện',
            'Chủ đề, màu sắc, ngôn ngữ',
            onTap: () {
              // TODO: Navigate to theme settings
            },
          ),
          _buildMenuItem(
            Icons.analytics_outlined,
            'Xuất báo cáo',
            'PDF, Excel, CSV',
            onTap: () {
              // TODO: Navigate to export reports
            },
          ),
          _buildMenuItem(
            Icons.help_outline,
            'Trợ giúp & Hỗ trợ',
            'FAQ, liên hệ hỗ trợ',
            onTap: () {
              // TODO: Navigate to help
            },
          ),
          _buildMenuItem(
            Icons.info_outline,
            'Về ứng dụng',
            'Phiên bản 1.0.0',
            onTap: () {
              // TODO: Navigate to about
            },
          ),
          _buildMenuItem(
            Icons.logout,
            'Đăng xuất',
            'Thoát khỏi tài khoản',
            textColor: AppColors.error,
            showDivider: false,
            onTap: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle, {
    Color? textColor,
    bool showDivider = true,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (textColor ?? AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: textColor ?? AppColors.primary,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor ?? AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textLight,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 72,
            color: AppColors.grey200,
          ),
      ],
    );
  }
}
