import 'package:flutter/material.dart';

import 'setting_tile_components.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingTileComponents.buildInfoTile('Phiên bản', '1.0.0'),
        SettingTileComponents.buildInfoTile('Ngày phát hành', '01/01/2024'),
        SettingTileComponents.buildInfoTile('Nhà phát triển', 'Moni Team'),
        SettingTileComponents.buildActionTile(
          'Điều khoản sử dụng',
          'Xem điều khoản và chính sách',
          'Xem',
          () {
            // Navigate to terms
          },
        ),
      ],
    );
  }
}
