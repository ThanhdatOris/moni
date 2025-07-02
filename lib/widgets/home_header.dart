import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/transaction_service.dart';

class ModernHomeHeader extends StatefulWidget {
  const ModernHomeHeader({super.key});

  @override
  State<ModernHomeHeader> createState() => _ModernHomeHeaderState();
}

class _ModernHomeHeaderState extends State<ModernHomeHeader> {
  String _userName = 'Khách';
  String _greeting = 'Chào bạn!';
  int _daysSinceFirstTransaction = 0;

  @override
  void initState() {
    super.initState();
    _setGreeting();
    _calculateDaysSinceFirstTransaction();
    // Lắng nghe sự thay đổi auth state để cập nhật tên người dùng
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        _loadUserInfo(user);
      }
    });
  }

  void _loadUserInfo(User? user) {
    if (user != null) {
      setState(() {
        _userName =
            user.displayName ?? user.email?.split('@')[0] ?? 'Người dùng';
      });
    } else {
      setState(() {
        _userName = 'Moner';
      });
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
      final transactionService = TransactionService();

      // Lấy tất cả giao dịch và tìm giao dịch cũ nhất
      final transactionsStream = transactionService.getTransactions();
      final transactions = await transactionsStream.first;

      if (transactions.isNotEmpty) {
        // Sắp xếp theo thời gian tạo để tìm giao dịch đầu tiên
        transactions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        final firstTransactionDate = transactions.first.createdAt;
        final now = DateTime.now();
        final difference = now.difference(firstTransactionDate).inDays +
            1; // +1 để tính cả ngày hiện tại

        if (mounted) {
          setState(() {
            _daysSinceFirstTransaction = difference;
          });
        }
      } else {
        // Nếu chưa có giao dịch nào, hiển thị ngày 1
        if (mounted) {
          setState(() {
            _daysSinceFirstTransaction = 1;
          });
        }
      }
    } catch (e) {
      // Nếu có lỗi, sử dụng số ngày mặc định
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
                            'Tiết kiệm chi tiêu ngày thứ: $_daysSinceFirstTransaction',
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
          child: BackdropFilter(
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
