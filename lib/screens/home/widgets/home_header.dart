import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moni/services/services.dart';
import '../../../utils/formatting/currency_formatter.dart';

/// Bank card style header with financial overview
class HomeHeaderWithCards extends ConsumerStatefulWidget {
  const HomeHeaderWithCards({super.key});

  @override
  ConsumerState<HomeHeaderWithCards> createState() => _HomeHeaderWithCardsState();
}

class _HomeHeaderWithCardsState extends ConsumerState<HomeHeaderWithCards> {
  // User data
  String _userName = 'Khách';
  String? _userPhotoUrl;

  // Financial data
  double balance = 0.0;
  bool isLoadingFinancial = true;
  
  // Balance visibility
  bool _isBalanceVisible = true;

  final GetIt _getIt = GetIt.instance;

  @override
  void initState() {
    super.initState();
    _loadBalanceVisibility();
    _loadUserInfo();
    _loadFinancialData();
    
    // Lắng nghe sự thay đổi auth state
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        _loadUserInfo();
        _loadFinancialData();
      }
    });
  }

  /// Load balance visibility from SharedPreferences
  Future<void> _loadBalanceVisibility() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isVisible = prefs.getBool('balance_visibility') ?? true;
      if (mounted) {
        setState(() {
          _isBalanceVisible = isVisible;
        });
      }
    } catch (e) {
      // If error, default to visible
      debugPrint('Lỗi load balance visibility: $e');
    }
  }

  /// Save balance visibility to SharedPreferences
  Future<void> _saveBalanceVisibility(bool isVisible) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('balance_visibility', isVisible);
    } catch (e) {
      debugPrint('Lỗi save balance visibility: $e');
    }
  }

  /// Load thông tin người dùng
  Future<void> _loadUserInfo() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && mounted) {
        setState(() {
          if (currentUser.isAnonymous) {
            _userName = 'Khách';
          } else {
            _userName = currentUser.displayName ?? 
                      currentUser.email?.split('@')[0] ?? 
                      'Người dùng';
          }
          _userPhotoUrl = currentUser.photoURL;
        });
      } else {
        setState(() {
          _userName = 'Khách';
          _userPhotoUrl = null;
        });
      }
    } catch (e) {
      debugPrint('Lỗi load user info: $e');
    }
  }

  /// Load dữ liệu tài chính
  Future<void> _loadFinancialData() async {
    try {
      final transactionService = _getIt<TransactionService>();
      final currentBalance = await transactionService.getCurrentBalance();
      
      if (mounted) {
        setState(() {
          balance = currentBalance;
          isLoadingFinancial = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingFinancial = false;
        });
      }
      debugPrint('Lỗi load financial data: $e');
    }
  }

  /// Toggle balance visibility
  void _toggleBalanceVisibility() {
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
    _saveBalanceVisibility(_isBalanceVisible);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 48, 16, 16), // Top spacing for notification bar
      child: Column(
        children: [
          // Main bank card
          _buildBankCard(),
        ],
      ),
    );
  }

  /// Build main bank card với background pattern
  Widget _buildBankCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B35), // Orange
            Color(0xFFFDB462), // Yellow
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          _buildBackgroundPattern(),
          // Card content
          _buildCardContent(),
        ],
      ),
    );
  }

  /// Build background pattern giống thẻ ngân hàng
  Widget _buildBackgroundPattern() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // Geometric patterns
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Financial icons pattern
          Positioned(
            left: -20,
            top: 20,
            child: Opacity(
              opacity: 0.1,
              child: Icon(
                Icons.account_balance,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            right: 50,
            top: 30,
            child: Opacity(
              opacity: 0.08,
              child: Icon(
                Icons.trending_up,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            left: 40,
            bottom: 20,
            child: Opacity(
              opacity: 0.06,
              child: Icon(
                Icons.pie_chart,
                size: 35,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build card content
  Widget _buildCardContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // User info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: _userPhotoUrl != null
                        ? NetworkImage(_userPhotoUrl!)
                        : null,
                    child: _userPhotoUrl == null
                        ? Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Logo/Brand
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'MONI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Balance section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Số dư hiện tại',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _toggleBalanceVisibility,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        _isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              isLoadingFinancial
                  ? Container(
                      width: 120,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                  : GestureDetector(
                      onTap: _toggleBalanceVisibility,
                      child: Text(
                        _isBalanceVisible 
                            ? CurrencyFormatter.formatAmountWithCurrency(balance)
                            : '••••••••',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              // Hiển thị tip cho user mới
              if (balance == 0.0 && _isBalanceVisible) ...[
                const SizedBox(height: 4),
                Text(
                  '💡 Bắt đầu ghi chép thu chi ngay!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Card number style
          Row(
            children: [
              ...List.generate(3, (index) => 
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Text(
                    '••••',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              Text(
                DateFormat('MM/yy').format(DateTime.now()),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Get greeting based on time and user status
  String _getGreeting() {
    final hour = DateTime.now().hour;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAnonymous = currentUser?.isAnonymous ?? true;
    
    String timeGreeting;
    if (hour < 12) {
      timeGreeting = 'Chào buổi sáng';
    } else if (hour < 18) {
      timeGreeting = 'Chào buổi chiều';
    } else {
      timeGreeting = 'Chào buổi tối';
    }
    
    // Thêm emoji cho anonymous user để thân thiện hơn
    if (isAnonymous) {
      return '$timeGreeting 👋';
    }
    
    return timeGreeting;
  }
}
