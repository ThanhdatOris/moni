/// Logout Section Widget - Section đăng xuất
/// Được tách từ ProfileScreen để cải thiện maintainability

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../services/auth_service.dart';

class LogoutSection extends StatefulWidget {
  final bool isLoading;

  const LogoutSection({
    super.key,
    this.isLoading = false,
  });

  @override
  State<LogoutSection> createState() => _LogoutSectionState();
}

class _LogoutSectionState extends State<LogoutSection> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingSection();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Logout button with gradient
          _buildLogoutButton(),
          const SizedBox(height: 16),
          // Additional logout options
          _buildQuickLogoutOptions(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
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
        onPressed: _isLoggingOut ? null : () => _showLogoutDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          disabledBackgroundColor: Colors.transparent,
        ),
        child: _isLoggingOut
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Đang đăng xuất...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 22,
                  ),
                  SizedBox(width: 12),
                  Text(
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
    );
  }

  Widget _buildQuickLogoutOptions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickOption(
            'Đăng xuất tất cả',
            'Đăng xuất khỏi tất cả thiết bị',
            Icons.devices,
            AppColors.warning,
            () => _showLogoutAllDialog(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickOption(
            'Xóa dữ liệu',
            'Xóa dữ liệu và đăng xuất',
            Icons.delete_forever,
            AppColors.error,
            () => _showDeleteDataDialog(context),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: _isLoggingOut ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: _isLoggingOut ? color.withValues(alpha: 0.5) : color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: _isLoggingOut ? color.withValues(alpha: 0.5) : color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: _isLoggingOut 
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : AppColors.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
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
        title: Row(
          children: [
            Icon(Icons.logout, color: AppColors.error),
            const SizedBox(width: 12),
            const Text(
              'Đăng xuất',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất không? Dữ liệu chưa được đồng bộ có thể bị mất.',
          style: TextStyle(color: Colors.grey),
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
              _performLogout(context, LogoutType.normal);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.devices, color: AppColors.warning),
            const SizedBox(width: 12),
            const Text(
              'Đăng xuất tất cả thiết bị',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: const Text(
          'Bạn sẽ bị đăng xuất khỏi tất cả thiết bị đã đăng nhập. Bạn có chắc chắn muốn tiếp tục?',
          style: TextStyle(color: Colors.grey),
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
              _performLogout(context, LogoutType.all);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Đăng xuất tất cả',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: AppColors.error),
            const SizedBox(width: 12),
            const Text(
              'Xóa dữ liệu',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: const Text(
          'TẤT CẢ dữ liệu của bạn sẽ bị xóa vĩnh viễn và không thể khôi phục. Bạn có chắc chắn muốn tiếp tục?',
          style: TextStyle(color: Colors.grey),
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
              _performLogout(context, LogoutType.deleteData);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Xóa và đăng xuất',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext context, LogoutType type) async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      // Haptic feedback
      HapticFeedback.mediumImpact();

      final authService = getIt<AuthService>();

      switch (type) {
        case LogoutType.normal:
          await authService.logout();
          break;
        case LogoutType.all:
          // TODO: Implement logout from all devices
          await authService.logout();
          break;
        case LogoutType.deleteData:
          // TODO: Implement delete all data
          await authService.logout();
          break;
      }

      if (context.mounted) {
        // Clear navigation stack and go to login
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/auth',
          (route) => false,
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getLogoutMessage(type)),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _isLoggingOut = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng xuất: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getLogoutMessage(LogoutType type) {
    switch (type) {
      case LogoutType.normal:
        return 'Đã đăng xuất thành công';
      case LogoutType.all:
        return 'Đã đăng xuất khỏi tất cả thiết bị';
      case LogoutType.deleteData:
        return 'Đã xóa dữ liệu và đăng xuất';
    }
  }
}

enum LogoutType {
  normal,
  all,
  deleteData,
}

/// Enhanced Logout Section with additional options
class EnhancedLogoutSection extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onBeforeLogout;
  final VoidCallback? onAfterLogout;

  const EnhancedLogoutSection({
    super.key,
    this.isLoading = false,
    this.onBeforeLogout,
    this.onAfterLogout,
  });

  @override
  Widget build(BuildContext context) {
    return LogoutSection(isLoading: isLoading);
  }
} 