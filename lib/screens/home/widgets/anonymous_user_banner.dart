import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../core/di/injection_container.dart';
import '../../../services/anonymous_conversion_service.dart';

/// Widget hiển thị banner khuyến khích anonymous user đăng ký
class AnonymousUserBanner extends StatefulWidget {
  const AnonymousUserBanner({super.key});

  @override
  State<AnonymousUserBanner> createState() => _AnonymousUserBannerState();
}

class _AnonymousUserBannerState extends State<AnonymousUserBanner> {
  late final AnonymousConversionService _conversionService;
  bool _isDismissed = false;
  Map<String, dynamic> _userStats = {};

  @override
  void initState() {
    super.initState();
    _conversionService = getIt<AnonymousConversionService>();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    if (_conversionService.isAnonymousUser) {
      final stats = await _conversionService.getAnonymousUserStats();
      if (mounted) {
        setState(() {
          _userStats = stats;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Chỉ hiển thị cho anonymous user và chưa bị dismiss
    if (!_conversionService.isAnonymousUser || _isDismissed) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B35).withValues(alpha: 0.1), 
            const Color(0xFFFDB462).withValues(alpha: 0.1)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_circle_outlined,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tạo tài khoản để bảo vệ dữ liệu',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isDismissed = true;
                  });
                },
                icon: Icon(
                  Icons.close,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn đã tạo ${_userStats['transactionCount'] ?? 0} giao dịch. '
            'Đăng ký tài khoản để đồng bộ dữ liệu giữa các thiết bị.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showConversionDialog(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Đăng ký ngay',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isDismissed = true;
                  });
                },
                child: Text(
                  'Để sau',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showConversionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tạo tài khoản'),
          content: const Text(
            'Bạn có muốn tạo tài khoản để bảo vệ dữ liệu của mình không? '
            'Tất cả giao dịch hiện tại sẽ được giữ nguyên.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToSignUp();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Đăng ký'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToSignUp() {
    // TODO: Navigate to sign up screen with conversion mode
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => ConversionSignUpScreen(),
    //   ),
    // );
  }
}
