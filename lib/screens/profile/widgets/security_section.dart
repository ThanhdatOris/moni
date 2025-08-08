import 'package:flutter/material.dart';

import '../change_password_screen.dart';
import 'setting_tile_components.dart';

class SecuritySection extends StatelessWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
