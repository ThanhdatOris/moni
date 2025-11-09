import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:moni/constants/app_colors.dart';
import 'package:moni/services/services.dart';

import '../../core/di/injection_container.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_page_header.dart';
import 'widgets/about_section.dart';
import 'widgets/appearance_section.dart';
import 'widgets/help_section.dart';
import 'widgets/logout_section.dart';
import 'widgets/notification_section.dart';
import 'widgets/personal_info_section.dart';
import 'widgets/security_section.dart';

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
                          const LogoutSection(),
                          const SizedBox(height: 80),
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
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final user = FirebaseAuth.instance.currentUser;
    final userName = _userModel?.name ?? user?.displayName ?? 'Người dùng';
    
    if (user?.photoURL != null && user!.photoURL!.isNotEmpty) {
      return CircleAvatar(
        radius: 32,
        backgroundImage: NetworkImage(user.photoURL!),
        onBackgroundImageError: (_, __) {
          // Fallback to default avatar if image fails to load
        },
        child: user.photoURL!.isEmpty ? null : null,
      );
    } else {
      return _buildDefaultAvatar(userName);
    }
  }

  bool _isGoogleAuth() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    // Check if user signed in with Google
    for (var provider in user.providerData) {
      if (provider.providerId == 'google.com') {
        return true;
      }
    }
    return false;
  }

  List<Map<String, dynamic>> get _settingSections => [
    {
      'icon': Icons.person_outline,
      'title': 'Thông tin cá nhân',
      'subtitle': 'Chỉnh sửa hồ sơ và thông tin',
      'widget': const PersonalInfoSection(),
    },
    {
      'icon': Icons.security_outlined,
      'title': 'Bảo mật',
      'subtitle': 'Mật khẩu, sinh trắc học',
      'widget': SecuritySection(isGoogleAuth: _isGoogleAuth()),
    },
    {
      'icon': Icons.notifications_outlined,
      'title': 'Thông báo',
      'subtitle': 'Cài đặt nhắc nhở và thông báo',
      'widget': const NotificationSection(),
    },
    // {
    //   'icon': Icons.backup_outlined,
    //   'title': 'Sao lưu & Đồng bộ',
    //   'subtitle': 'Đồng bộ dữ liệu trên các thiết bị',
    //   'widget': const BackupSection(),
    // },
    {
      'icon': Icons.palette_outlined,
      'title': 'Giao diện',
      'subtitle': 'Chủ đề, màu sắc, ngôn ngữ',
      'widget': const AppearanceSection(),
    },
    {
      'icon': Icons.help_outline,
      'title': 'Trợ giúp & Hỗ trợ',
      'subtitle': 'FAQ, liên hệ hỗ trợ',
      'widget': const HelpSection(),
    },
    {
      'icon': Icons.info_outline,
      'title': 'Về ứng dụng',
      'subtitle': 'Phiên bản 1.0.0',
      'widget': const AboutSection(),
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._settingSections.asMap().entries.map((entry) {
            final index = entry.key;
            final section = entry.value;
            final isFirst = index == 0;
            final isLast = index == _settingSections.length - 1;
            
            return _buildSettingSection(
              context,
              icon: section['icon'],
              title: section['title'],
              subtitle: section['subtitle'],
              child: section['widget'],
              isFirst: isFirst,
              isLast: isLast,
            );
          }),
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
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: isLast 
            ? BorderSide.none 
            : const BorderSide(color: Color(0xFFF5F5F5), width: 1)
        ),
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
                padding: const EdgeInsets.symmetric(vertical: 12),
              child: child,
            ),
          ],
        ),
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
