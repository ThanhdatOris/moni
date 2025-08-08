import 'package:flutter/material.dart';

import 'setting_tile_components.dart';

class NotificationSection extends StatelessWidget {
  const NotificationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingTileComponents.buildSwitchTile(
          'Thông báo đẩy',
          'Nhận thông báo từ ứng dụng',
          true,
          (value) {
            // Handle push notification toggle
          },
        ),
        SettingTileComponents.buildSwitchTile(
          'Nhắc nhở ngân sách',
          'Thông báo khi vượt ngân sách',
          true,
          (value) {
            // Handle budget reminder toggle
          },
        ),
        SettingTileComponents.buildSwitchTile(
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
}
