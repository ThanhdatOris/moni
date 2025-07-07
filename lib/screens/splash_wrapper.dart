import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
    await Future.wait([
      authCompleter,
      minimumDisplayTime,
    ]);

    if (mounted) {
      setState(() {
        _isMinimumTimeCompleted = true;
        _isAuthStateLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hiển thị splash screen cho đến khi hoàn thành
    if (!_isMinimumTimeCompleted || !_isAuthStateLoaded) {
      return const SplashScreen();
    }

    // Sử dụng StreamBuilder để lắng nghe auth state changes trong thời gian thực
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // Chuyển đến màn hình phù hợp
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}
