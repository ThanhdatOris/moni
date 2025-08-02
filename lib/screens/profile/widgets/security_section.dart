/// Security Section Widget - Section bảo mật
/// Được tách từ ProfileScreen để cải thiện maintainability

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../change_password_screen.dart';
import 'setting_tile_components.dart';

class SecuritySection extends StatefulWidget {
  final UserModel? userModel;
  final bool isLoading;

  const SecuritySection({
    super.key,
    required this.userModel,
    this.isLoading = false,
  });

  @override
  State<SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends State<SecuritySection> {
  bool _biometricEnabled = false;
  bool _twoFactorEnabled = false;
  bool _sessionTimeout = true;
  bool _isCheckingBiometrics = false;
  // final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    // Load from preferences or user model
    setState(() {
      _biometricEnabled = false; // widget.userModel?.biometricEnabled ?? false;
      _twoFactorEnabled = false; // widget.userModel?.twoFactorEnabled ?? false;
      _sessionTimeout = true; // widget.userModel?.sessionTimeoutEnabled ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingContent();
    }

    return Column(
      children: [
        SettingActionTile(
          title: 'Đổi mật khẩu',
          subtitle: 'Cập nhật mật khẩu bảo mật',
          buttonText: 'Đổi',
          buttonIcon: Icons.lock_outline,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChangePasswordScreen(),
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        SettingSwitchTile(
          title: 'Sinh trắc học',
          subtitle: 'Sử dụng vân tay/Face ID để đăng nhập',
          value: _biometricEnabled,
          isEnabled: !_isCheckingBiometrics,
          onChanged: _handleBiometricToggle,
        ),
        SettingSwitchTile(
          title: 'Xác thực 2 bước',
          subtitle: 'Tăng cường bảo mật với mã OTP',
          value: _twoFactorEnabled,
          onChanged: _handleTwoFactorToggle,
        ),
        SettingSwitchTile(
          title: 'Tự động đăng xuất',
          subtitle: 'Đăng xuất khi không sử dụng 15 phút',
          value: _sessionTimeout,
          onChanged: _handleSessionTimeoutToggle,
        ),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        SettingNavigationTile(
          title: 'Thiết bị đã đăng nhập',
          subtitle: 'Quản lý các thiết bị có quyền truy cập',
          onTap: () => _showDeviceManagement(context),
        ),
        SettingNavigationTile(
          title: 'Lịch sử đăng nhập',
          subtitle: 'Xem lịch sử hoạt động đăng nhập',
          onTap: () => _showLoginHistory(context),
        ),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        SettingActionTile(
          title: 'Khóa tài khoản tạm thời',
          subtitle: 'Vô hiệu hóa tài khoản trong 24h',
          buttonText: 'Khóa',
          buttonIcon: Icons.lock_clock,
          buttonColor: AppColors.warning,
          onPressed: () => _showTemporaryLockDialog(context),
        ),
      ],
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      children: List.generate(7, (index) => const SettingLoadingTile()),
    );
  }

  Future<void> _handleBiometricToggle(bool enabled) async {
    if (enabled) {
      setState(() {
        _isCheckingBiometrics = true;
      });

      // TODO: Implement biometric authentication when local_auth package is available
      // For now, just show a message that biometric is not supported
      _showBiometricNotSupportedDialog();
      setState(() {
        _isCheckingBiometrics = false;
      });
      return;

      /*
      try {
        // Check if device supports biometrics
        final bool isAvailable = await _localAuth.canCheckBiometrics;
        final bool isDeviceSupported = await _localAuth.isDeviceSupported();

        if (!isAvailable || !isDeviceSupported) {
          _showBiometricNotSupportedDialog();
          setState(() {
            _isCheckingBiometrics = false;
          });
          return;
        }

        // Get available biometrics
        final List<BiometricType> availableBiometrics = 
            await _localAuth.getAvailableBiometrics();

        if (availableBiometrics.isEmpty) {
          _showNoBiometricsDialog();
          setState(() {
            _isCheckingBiometrics = false;
          });
          return;
        }

        // Authenticate user
        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Xác minh danh tính để bật tính năng sinh trắc học',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );

        if (didAuthenticate) {
          setState(() {
            _biometricEnabled = true;
          });
          _saveBiometricSetting(true);
          _showSuccessMessage('Đã bật sinh trắc học thành công');
        } else {
          setState(() {
            _isCheckingBiometrics = false;
          });
        }
      } on PlatformException catch (e) {
        setState(() {
          _isCheckingBiometrics = false;
        });
        _showErrorMessage('Lỗi xác thực sinh trắc học: ${e.message}');
      }
      */
    } else {
      // TODO: Implement biometric disable functionality
      // For now, just show a message
      _showSuccessMessage('Tính năng sinh trắc học chưa được hỗ trợ');
    }
  }

  void _handleTwoFactorToggle(bool enabled) {
    if (enabled) {
      _showTwoFactorSetupDialog();
    } else {
      _showTwoFactorDisableDialog();
    }
  }

  void _handleSessionTimeoutToggle(bool enabled) {
    setState(() {
      // TODO: Implement session timeout when UserModel has this field
      // _sessionTimeout = enabled;
    });
    _saveSessionTimeoutSetting(enabled);
    
    final message = enabled 
        ? 'Đã bật tự động đăng xuất' 
        : 'Đã tắt tự động đăng xuất';
    _showSuccessMessage(message);
  }

  void _showBiometricNotSupportedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error, color: AppColors.error),
            const SizedBox(width: 12),
            const Text('Không hỗ trợ'),
          ],
        ),
        content: const Text(
          'Thiết bị của bạn không hỗ trợ xác thực sinh trắc học hoặc chưa được cài đặt.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Đóng', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showNoBiometricsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.fingerprint, color: AppColors.warning),
            const SizedBox(width: 12),
            const Text('Chưa thiết lập'),
          ],
        ),
        content: const Text(
          'Bạn chưa thiết lập vân tay hoặc Face ID trên thiết bị. Vui lòng thiết lập trong Cài đặt hệ thống trước.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Đóng', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTwoFactorSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.security, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text('Xác thực 2 bước'),
          ],
        ),
        content: const Text(
          'Thiết lập xác thực 2 bước để tăng cường bảo mật tài khoản. Bạn sẽ nhận mã OTP qua SMS khi đăng nhập.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to 2FA setup screen
              setState(() {
                _twoFactorEnabled = true;
              });
              _showSuccessMessage('Đã bật xác thực 2 bước');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Thiết lập', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTwoFactorDisableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.warning),
            const SizedBox(width: 12),
            const Text('Tắt xác thực 2 bước'),
          ],
        ),
        content: const Text(
          'Bạn có chắc muốn tắt xác thực 2 bước? Điều này sẽ làm giảm mức độ bảo mật của tài khoản.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _twoFactorEnabled = false;
              });
              _showSuccessMessage('Đã tắt xác thực 2 bước');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Tắt', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTemporaryLockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock_clock, color: AppColors.error),
            const SizedBox(width: 12),
            const Text('Khóa tài khoản'),
          ],
        ),
        content: const Text(
          'Tài khoản sẽ bị khóa trong 24 giờ. Bạn sẽ không thể đăng nhập trong thời gian này. Chắc chắn muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessMessage('Tài khoản sẽ bị khóa sau 5 phút');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Khóa tài khoản', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeviceManagement(BuildContext context) {
    // TODO: Navigate to device management screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tính năng đang phát triển'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLoginHistory(BuildContext context) {
    // TODO: Navigate to login history screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tính năng đang phát triển'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveBiometricSetting(bool enabled) {
    // TODO: Save to preferences
  }

  void _saveSessionTimeoutSetting(bool enabled) {
    // TODO: Save to preferences
  }

  void _showSuccessMessage(String message) {
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

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
} 