import 'package:flutter/material.dart';

import 'setting_tile_components.dart';

class HelpSection extends StatelessWidget {
  const HelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingTileComponents.buildActionTile(
          'Câu hỏi thường gặp',
          'Tìm câu trả lời nhanh',
          'Xem',
          () {
            // Navigate to FAQ
          },
        ),
        SettingTileComponents.buildActionTile(
          'Liên hệ hỗ trợ',
          'Gửi phản hồi hoặc báo lỗi',
          'Liên hệ',
          () {
            // Navigate to contact support
          },
        ),
        SettingTileComponents.buildActionTile(
          'Đánh giá ứng dụng',
          'Đánh giá trên cửa hàng',
          'Đánh giá',
          () {
            // Open app store rating
          },
        ),
      ],
    );
  }
}
