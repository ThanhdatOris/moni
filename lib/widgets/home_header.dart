import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/injection_container.dart';
import '../services/auth_service.dart';
import '../services/transaction_service.dart';

class ModernHomeHeader extends ConsumerStatefulWidget {
  const ModernHomeHeader({super.key});

  @override
  ConsumerState<ModernHomeHeader> createState() => _ModernHomeHeaderState();
}

class _ModernHomeHeaderState extends ConsumerState<ModernHomeHeader> {
  String _userName = 'Khách';
  String _greeting = 'Chào bạn!';
  int _daysSinceFirstTransaction = 0;
  String? _userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _setGreeting();
    _calculateDaysSinceFirstTransaction();
    _loadUserInfo();
    // Lắng nghe sự thay đổi auth state để cập nhật tên người dùng
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        _loadUserInfo();
      }
    });
  }

  Future<void> _loadUserInfo() async {
    final authService = getIt<AuthService>();
    final userModel = await authService.getUserData();
    
    if (userModel != null) {
      setState(() {
        _userName = userModel.name.isNotEmpty ? userModel.name : 'Người dùng';
        _userPhotoUrl = userModel.photoUrl;
      });
    } else {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        setState(() {
          _userName = currentUser.displayName ?? 
              currentUser.email?.split('@')[0] ?? 'Người dùng';
          _userPhotoUrl = currentUser.photoURL;
        });
      } else {
        setState(() {
          _userName = 'Moner';
          _userPhotoUrl = null;
        });
      }
    }
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Chào buổi sáng!';
    } else if (hour < 18) {
      greeting = 'Chào buổi chiều!';
    } else {
      greeting = 'Chào buổi tối!';
    }

    setState(() {
      _greeting = greeting;
    });
  }

  String _getUserInitials() {
    if (_userName.isNotEmpty) {
      final words = _userName.split(' ');

      if (words.length >= 2) {
        final initials = '${words[0][0]}${words[1][0]}'.toUpperCase();
        return initials;
      }
      final initial = _userName.substring(0, 1).toUpperCase();
      return initial;
    }
    return 'U';
  }

  Future<void> _calculateDaysSinceFirstTransaction() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _daysSinceFirstTransaction = 0;
          });
        }
        return;
      }

      final transactionService = getIt<TransactionService>();
      
      // Lấy tất cả giao dịch để tìm giao dịch đầu tiên
      final transactionsStream = transactionService.getTransactions();
      
      // Listen một lần để lấy dữ liệu
      transactionsStream.take(1).listen((transactions) {
        if (!mounted) return;
        
        if (transactions.isEmpty) {
          setState(() {
            _daysSinceFirstTransaction = 0;
          });
          return;
        }

        // Tìm giao dịch có ngày sớm nhất
        DateTime firstTransactionDate = transactions.first.date;
        for (final transaction in transactions) {
          if (transaction.date.isBefore(firstTransactionDate)) {
            firstTransactionDate = transaction.date;
          }
        }

        final now = DateTime.now();
        final difference = now.difference(firstTransactionDate).inDays + 1;
        
        setState(() {
          _daysSinceFirstTransaction = difference > 0 ? difference : 1;
        });
      }, onError: (error) {
        // Nếu có lỗi, set default value
        if (mounted) {
          setState(() {
            _daysSinceFirstTransaction = 1;
          });
        }
      });
    } catch (e) {
      // Nếu có lỗi, set default value
      if (mounted) {
        setState(() {
          _daysSinceFirstTransaction = 1;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 160),
      // padding: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B35),
            Color(0xFFFF8E53),
            Color(0xFFFFB56B),
            Color(0xFFFFC87C),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          // Background pattern overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.transparent,
                    const Color.fromARGB(255, 255, 0, 85)
                        .withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 10, // Giảm padding top
                24,
                20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row với greeting và avatar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Greeting với icon
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getGreetingIcon(),
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _greeting,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // User name
                          Text(
                            _userName,
                            style: TextStyle(
                              fontSize: 26, // Giảm size
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withValues(alpha: 0.9),
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: const Offset(1, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Subtitle
                          Text(
                            _daysSinceFirstTransaction > 0 
                                ? 'Quản lý chi tiêu được $_daysSinceFirstTransaction ngày'
                                : 'Hãy bắt đầu ghi chép chi tiêu của bạn!',
                            style: TextStyle(
                              fontSize: 13, // Giảm size
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Modern Avatar
                    _buildModernAvatar(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Container(
        width: 55, // Giảm size
        height: 55,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27.5),
          child: _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
              ? Stack(
                  children: [
                    // Background với gradient
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFFF9800).withValues(alpha: 0.8),
                            const Color(0xFFFF5722).withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                    ),
                    // Hình ảnh avatar
                    Image.network(
                      _userPhotoUrl!,
                      fit: BoxFit.cover,
                      width: 55,
                      height: 55,
                      errorBuilder: (context, error, stackTrace) {
                        // Nếu load ảnh thất bại, hiển thị chữ cái đầu
                        return _buildDefaultAvatar();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildDefaultAvatar();
                      },
                    ),
                  ],
                )
              : _buildDefaultAvatar(),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFF9800).withValues(alpha: 0.8),
              const Color(0xFFFF5722).withValues(alpha: 0.9),
            ],
          ),
        ),
        child: Center(
          child: Text(
            _getUserInitials(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return Icons.wb_sunny_rounded;
    } else if (hour < 18) {
      return Icons.wb_cloudy_rounded;
    } else {
      return Icons.nightlight_round;
    }
  }
}
