import 'package:flutter/material.dart';

import '../change_password_screen.dart';
import 'setting_tile_components.dart';

class SecuritySection extends StatelessWidget {
  final bool isGoogleAuth;
  
  const SecuritySection({
    super.key,
    this.isGoogleAuth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Only show change password for email/password authentication
        if (!isGoogleAuth)
          SettingTileComponents.buildActionTile(
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
        SettingTileComponents.buildSwitchTile(
          'Sinh trắc học',
          'Sử dụng vân tay/Face ID',
          true,
          (value) {
            // Handle biometric toggle
          },
        ),
        SettingTileComponents.buildSwitchTile(
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
}
