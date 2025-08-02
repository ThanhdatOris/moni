import 'package:flutter/material.dart';

import 'setting_tile_components.dart';

class BackupSection extends StatelessWidget {
  const BackupSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingTileComponents.buildActionTile(
          'Sao lưu ngay',
          'Sao lưu dữ liệu lên cloud',
          'Sao lưu',
          () {
            // Handle backup
          },
        ),
        SettingTileComponents.buildActionTile(
          'Khôi phục dữ liệu',
          'Khôi phục từ bản sao lưu',
          'Khôi phục',
          () {
            // Handle restore
          },
        ),
        SettingTileComponents.buildSwitchTile(
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
}
