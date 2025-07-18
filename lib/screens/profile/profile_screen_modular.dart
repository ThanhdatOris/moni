/// Profile Screen Modular - Phiên bản đã tách components
/// Được tái cấu trúc từ ProfileScreen để cải thiện maintainability

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../core/di/injection_container.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_page_header.dart';
import 'widgets/profile_widgets.dart';

class ProfileScreenModular extends StatefulWidget {
  const ProfileScreenModular({super.key});

  @override
  State<ProfileScreenModular> createState() => _ProfileScreenModularState();
}

class _ProfileScreenModularState extends State<ProfileScreenModular> {
  UserModel? _userModel;
  bool _isLoading = true;

  // Data structure cho settings sections
  late List<ProfileSettingSection> _settingSections;

  @override
  void initState() {
    super.initState();
    _initializeSettingSections();
    _loadUserData();
    
    // Lắng nghe sự thay đổi auth state
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        _loadUserData();
      }
    });
  }

  void _initializeSettingSections() {
    _settingSections = [
      ProfileSettingSection(
        icon: Icons.person_outline,
        title: 'Thông tin cá nhân',
        subtitle: 'Chỉnh sửa hồ sơ và thông tin',
        widgetBuilder: () => PersonalInfoSection(
          userModel: _userModel,
          isLoading: _isLoading,
        ),
      ),
      ProfileSettingSection(
        icon: Icons.security_outlined,
        title: 'Bảo mật',
        subtitle: 'Mật khẩu, sinh trắc học',
        widgetBuilder: () => SecuritySection(
          userModel: _userModel,
          isLoading: _isLoading,
        ),
      ),
      ProfileSettingSection(
        icon: Icons.notifications_outlined,
        title: 'Thông báo',
        subtitle: 'Cài đặt nhắc nhở và thông báo',
        widgetBuilder: () => NotificationSection(
          userModel: _userModel,
          isLoading: _isLoading,
        ),
      ),
      ProfileSettingSection(
        icon: Icons.backup_outlined,
        title: 'Sao lưu & Đồng bộ',
        subtitle: 'Đồng bộ dữ liệu trên các thiết bị',
        widgetBuilder: () => BackupSection(
          userModel: _userModel,
          isLoading: _isLoading,
        ),
      ),
      ProfileSettingSection(
        icon: Icons.palette_outlined,
        title: 'Giao diện',
        subtitle: 'Chủ đề, màu sắc, ngôn ngữ',
        widgetBuilder: () => AppearanceSection(
          userModel: _userModel,
          isLoading: _isLoading,
        ),
      ),
      ProfileSettingSection(
        icon: Icons.analytics_outlined,
        title: 'Dữ liệu',
        subtitle: 'PDF, Excel, CSV',
        widgetBuilder: () => DataSection(
          userModel: _userModel,
          isLoading: _isLoading,
        ),
      ),
      ProfileSettingSection(
        icon: Icons.help_outline,
        title: 'Trợ giúp & Hỗ trợ',
        subtitle: 'FAQ, liên hệ hỗ trợ',
        widgetBuilder: () => HelpSection(
          userModel: _userModel,
          isLoading: _isLoading,
        ),
      ),
      ProfileSettingSection(
        icon: Icons.info_outline,
        title: 'Về ứng dụng',
        subtitle: 'Phiên bản 1.0.0',
        widgetBuilder: () => AboutSection(
          userModel: _userModel,
          isLoading: _isLoading,
        ),
      ),
    ];
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
        child: Column(
          children: [
            // Header
            CustomPageHeader(
              icon: Icons.person,
              title: 'Hồ sơ',
              subtitle: 'Quản lý thông tin cá nhân',
            ),
            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadUserData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Profile Header with Stats
                      ProfileHeaderWidget(
                        userModel: _userModel,
                        isLoading: _isLoading,
                      ),
                      // User Statistics
                      ProfileStatsWidget(
                        totalTransactions: 156,
                        totalSavings: 6500000,
                        daysActive: 45,
                        isLoading: _isLoading,
                      ),
                      // Settings Menu
                      _buildSettingsMenu(),
                      // Logout Section
                      LogoutSection(isLoading: _isLoading),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsMenu() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
        children: _settingSections.asMap().entries.map((entry) {
          final index = entry.key;
          final section = entry.value;
          final isFirst = index == 0;
          final isLast = index == _settingSections.length - 1;
          
          return SettingSection(
            icon: section.icon,
            title: section.title,
            subtitle: section.subtitle,
            child: section.widgetBuilder(),
            isFirst: isFirst,
            isLast: isLast,
          );
        }).toList(),
      ),
    );
  }
}

class ProfileSettingSection {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget Function() widgetBuilder;

  ProfileSettingSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.widgetBuilder,
  });
}

/// Demo version for testing the modular structure
class ProfileScreenDemo extends StatelessWidget {
  const ProfileScreenDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Demo'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
      ),
      body: const ProfileScreenModular(),
    );
  }
}

/// Widget for comparing old vs new profile screen
class ProfileComparison extends StatefulWidget {
  const ProfileComparison({super.key});

  @override
  State<ProfileComparison> createState() => _ProfileComparisonState();
}

class _ProfileComparisonState extends State<ProfileComparison> {
  bool _showModular = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showModular ? 'Profile (Modular)' : 'Profile (Original)'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        actions: [
          Switch(
            value: _showModular,
            onChanged: (value) {
              setState(() {
                _showModular = value;
              });
            },
            activeColor: AppColors.textWhite,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _showModular
          ? const ProfileScreenModular()
          : const Center(
              child: Text(
                'Original ProfileScreen\n(902 lines)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.backgroundLight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _showModular
                  ? '✅ Modular: 15 files, ~250 lines each'
                  : '❌ Monolithic: 1 file, 902 lines',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _showModular ? AppColors.success : AppColors.warning,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showModular
                  ? 'Enhanced features: Biometric auth, advanced settings, better UX'
                  : 'Limited features, difficult to maintain and extend',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced Profile Screen with additional features
class EnhancedProfileScreen extends StatefulWidget {
  const EnhancedProfileScreen({super.key});

  @override
  State<EnhancedProfileScreen> createState() => _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends State<EnhancedProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: const ProfileScreenModular(),
    );
  }
} 