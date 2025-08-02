import 'package:flutter/material.dart';

import 'setting_tile_components.dart';

class DataSection extends StatelessWidget {
  const DataSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingTileComponents.buildActionTile(
          'Xuất PDF',
          'Xuất báo cáo dạng PDF',
          'Xuất',
          () {
            // Handle PDF export
          },
        ),
        SettingTileComponents.buildActionTile(
          'Xuất Excel',
          'Xuất dữ liệu Excel',
          'Xuất',
          () {
            // Handle Excel export
          },
        ),
        SettingTileComponents.buildActionTile(
          'Xuất CSV',
          'Xuất dữ liệu CSV',
          'Xuất',
          () {
            // Handle CSV export
          },
        ),
      ],
    );
  }
}
