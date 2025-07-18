/// Personal Info Section Widget - Section thông tin cá nhân
/// Được tách từ ProfileScreen để cải thiện maintainability

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../edit_profile_screen.dart';
import 'setting_tile_components.dart';

class PersonalInfoSection extends StatelessWidget {
  final UserModel? userModel;
  final bool isLoading;

  const PersonalInfoSection({
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
        SettingActionTile(
          title: 'Chỉnh sửa hồ sơ',
          subtitle: 'Cập nhật thông tin cá nhân',
          buttonText: 'Chỉnh sửa',
          buttonIcon: Icons.edit,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditProfileScreen(),
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        SettingInfoTile(
          title: 'Email',
          value: _getEmail(),
          icon: Icons.email_outlined,
        ),
        SettingInfoTile(
          title: 'Điện thoại',
          value: _getPhoneNumber(),
          icon: Icons.phone_outlined,
        ),
        SettingInfoTile(
          title: 'Ngày tạo',
          value: _getCreationDate(),
          icon: Icons.calendar_today_outlined,
        ),
        SettingInfoTile(
          title: 'Loại tài khoản',
          value: _getAccountType(),
          icon: Icons.account_circle_outlined,
          valueColor: _getAccountTypeColor(),
        ),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        SettingNavigationTile(
          title: 'Xác minh danh tính',
          subtitle: _getVerificationStatus(),
          icon: Icons.verified_user_outlined,
          badge: _getVerificationBadge(),
          onTap: () => _handleVerificationTap(context),
        ),
      ],
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      children: List.generate(6, (index) => const SettingLoadingTile()),
    );
  }

  String _getEmail() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return userModel?.email ?? 
           currentUser?.email ?? 
           'Chưa có email';
  }

  String _getPhoneNumber() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser?.phoneNumber ?? 
           'Chưa có số điện thoại';
  }

  String _getCreationDate() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final creationTime = userModel?.createdAt ?? 
                        currentUser?.metadata.creationTime ?? 
                        DateTime.now();
    return DateFormat('dd/MM/yyyy').format(creationTime);
  }

  String _getAccountType() {
    // Since UserModel doesn't have isPremium, default to free
    return 'Miễn phí';
  }

  Color _getAccountTypeColor() {
    // Since UserModel doesn't have isPremium, default to free color
    return AppColors.textSecondary;
  }

  String _getVerificationStatus() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isEmailVerified = currentUser?.emailVerified ?? false;
    
    if (isEmailVerified) {
      return 'Đã xác minh email';
    }
    return 'Chưa xác minh email';
  }

  Widget? _getVerificationBadge() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isEmailVerified = currentUser?.emailVerified ?? false;
    
    if (isEmailVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              'Đã xác minh',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning,
            color: AppColors.warning,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            'Chưa xác minh',
            style: TextStyle(
              color: AppColors.warning,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _handleVerificationTap(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isEmailVerified = currentUser?.emailVerified ?? false;
    
    if (!isEmailVerified) {
      _showVerificationDialog(context);
    } else {
      _showVerifiedDialog(context);
    }
  }

  void _showVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.email, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text('Xác minh email'),
          ],
        ),
        content: const Text(
          'Chúng tôi sẽ gửi email xác minh đến địa chỉ email của bạn. Vui lòng kiểm tra hộp thư và làm theo hướng dẫn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendVerificationEmail(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Gửi email',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showVerifiedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: 12),
            const Text('Đã xác minh'),
          ],
        ),
        content: const Text(
          'Tài khoản của bạn đã được xác minh thành công. Bạn có thể sử dụng đầy đủ các tính năng của ứng dụng.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Đóng',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendVerificationEmail(BuildContext context) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && !currentUser.emailVerified) {
        await currentUser.sendEmailVerification();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Email xác minh đã được gửi!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gửi email: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// Enhanced Personal Info Section with additional features
class EnhancedPersonalInfoSection extends StatefulWidget {
  final UserModel? userModel;
  final bool isLoading;
  final VoidCallback? onProfileUpdated;

  const EnhancedPersonalInfoSection({
    super.key,
    required this.userModel,
    this.isLoading = false,
    this.onProfileUpdated,
  });

  @override
  State<EnhancedPersonalInfoSection> createState() => _EnhancedPersonalInfoSectionState();
}

class _EnhancedPersonalInfoSectionState extends State<EnhancedPersonalInfoSection> {
  @override
  Widget build(BuildContext context) {
    return PersonalInfoSection(
      userModel: widget.userModel,
      isLoading: widget.isLoading,
    );
  }
} 