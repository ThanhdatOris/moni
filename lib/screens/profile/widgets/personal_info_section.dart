import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../edit_profile_screen.dart';
import 'setting_tile_components.dart';

class PersonalInfoSection extends StatelessWidget {
  const PersonalInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingTileComponents.buildActionTile(
          'Chỉnh sửa hồ sơ',
          'Cập nhật thông tin cá nhân',
          'Chỉnh sửa',
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditProfileScreen(),
            ),
          ),
        ),
        SettingTileComponents.buildInfoTile(
          'Ngày tạo',
          DateFormat('dd/MM/yyyy').format(DateTime.now()),
        ),
        SettingTileComponents.buildInfoTile('Loại tài khoản', 'Miễn phí'),
      ],
    );
  }
}
