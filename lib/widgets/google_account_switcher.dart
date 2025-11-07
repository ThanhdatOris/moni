import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../core/di/injection_container.dart';
import '../../../services/services.dart';

/// Widget hiển thị thông tin user và nút chuyển đổi tài khoản
class GoogleAccountSwitcher extends StatefulWidget {
  const GoogleAccountSwitcher({super.key});

  @override
  State<GoogleAccountSwitcher> createState() => _GoogleAccountSwitcherState();
}

class _GoogleAccountSwitcherState extends State<GoogleAccountSwitcher> {
  late final AuthService _authService;
  User? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = getIt<AuthService>();
    _currentUser = _authService.currentUser;
    
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.account_circle, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Tài khoản hiện tại',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // User info
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundImage: _currentUser!.photoURL != null
                      ? NetworkImage(_currentUser!.photoURL!)
                      : null,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: _currentUser!.photoURL == null
                      ? Icon(Icons.person, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 12),
                
                // User details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentUser!.displayName ?? 'Không có tên',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentUser!.email ?? 'Không có email',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getProviderColor(),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getProviderText(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Actions
            Row(
              children: [
                // Switch account button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleSwitchAccount,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.swap_horiz),
                    label: Text(_isLoading ? 'Đang chuyển...' : 'Chuyển tài khoản'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Logout button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Đăng xuất'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getProviderColor() {
    if (_currentUser!.isAnonymous) {
      return Colors.orange;
    }
    
    final providers = _currentUser!.providerData;
    if (providers.any((p) => p.providerId == 'google.com')) {
      return Colors.red;
    }
    if (providers.any((p) => p.providerId == 'password')) {
      return Colors.blue;
    }
    
    return Colors.grey;
  }

  String _getProviderText() {
    if (_currentUser!.isAnonymous) {
      return 'Khách';
    }
    
    final providers = _currentUser!.providerData;
    if (providers.any((p) => p.providerId == 'google.com')) {
      return 'Google';
    }
    if (providers.any((p) => p.providerId == 'password')) {
      return 'Email';
    }
    
    return 'Khác';
  }

  void _handleSwitchAccount() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.switchGoogleAccount();
      
      if (mounted) {
        if (user != null) {
          _showSnackBar('Đã chuyển tài khoản thành công', Colors.green);
        } else {
          _showSnackBar('Người dùng đã hủy chuyển tài khoản', Colors.orange);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Lỗi chuyển tài khoản: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _authService.logout();
        if (mounted) {
          _showSnackBar('Đã đăng xuất thành công', Colors.green);
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Lỗi đăng xuất: $e', Colors.red);
        }
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
    }
  }
}
