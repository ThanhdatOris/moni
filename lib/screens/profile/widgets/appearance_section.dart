import 'package:flutter/material.dart';

import 'setting_tile_components.dart';

class AppearanceSection extends StatelessWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingTileComponents.buildDropdownTile(
          'Chủ đề',
          'Sáng',
          ['Sáng', 'Tối', 'Tự động'],
          (value) {
            // Handle theme change
          },
        ),
        SettingTileComponents.buildDropdownTile(
          'Ngôn ngữ',
          'Tiếng Việt',
          ['Tiếng Việt', 'English'],
          (value) {
            // Handle language change
          },
        ),
        SettingTileComponents.buildDropdownTile(
          'Tiền tệ',
          'VND',
          ['VND', 'USD', 'EUR'],
          (value) {
            // Handle currency change
          },
        ),
      ],
    );
  }
}
