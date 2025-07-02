import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/category_service.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'splash_screen.dart';

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _isMinimumTimeCompleted = false;
  bool _isAuthStateLoaded = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Bắt đầu timer cho thời gian hiển thị tối thiểu
    final minimumDisplayTime =
        Future.delayed(const Duration(milliseconds: 2500));

    // Lắng nghe auth state changes
    final authCompleter = FirebaseAuth.instance.authStateChanges().first;

    // Chờ cả auth state và minimum time
    final results = await Future.wait([
      authCompleter,
      minimumDisplayTime,
    ]);

    final user = results[0] as User?;

    if (mounted) {
      setState(() {
        _isMinimumTimeCompleted = true;
        _isAuthStateLoaded = true;
        _currentUser = user;
      });

      // Nếu user đã đăng nhập, tạo danh mục mặc định
      if (user != null) {
        await _createDefaultCategories();
      }
    }
  }

  Future<void> _createDefaultCategories() async {
    try {
      final categoryService = CategoryService();
      await categoryService.createDefaultCategories();
    } catch (e) {
      // Lỗi tạo danh mục mặc định - không quan trọng lắm
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hiển thị splash screen cho đến khi hoàn thành
    if (!_isMinimumTimeCompleted || !_isAuthStateLoaded) {
      return const SplashScreen();
    }

    // Chuyển đến màn hình phù hợp
    if (_currentUser != null) {
      return const HomeScreen();
    } else {
      return const AuthScreen();
    }
  }
}
