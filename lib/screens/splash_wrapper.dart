import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../services/environment_service.dart';
import '../services/offline_service.dart';
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
    _loadAuthState();
    _waitMinimumTime();
  }

  Future<void> _loadAuthState() async {
    // Lắng nghe auth state changes
    final authCompleter = FirebaseAuth.instance.authStateChanges().first;

    // Chờ auth state
    await authCompleter;

    if (mounted) {
      setState(() {
        _isAuthStateLoaded = true;
      });
    }
  }

  Future<void> _waitMinimumTime() async {
    // Bắt đầu timer cho thời gian hiển thị tối thiểu
    final minimumDisplayTime =
        Future.delayed(const Duration(milliseconds: 2500));

    // Chờ minimum time
    await minimumDisplayTime;

    if (mounted) {
      setState(() {
        _isMinimumTimeCompleted = true;
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

        // Debug logging để track auth state
        if (kDebugMode && EnvironmentService.isDevelopment) {
          print('🔍 DEBUG AUTH STATE:');
          print('  - Has data: ${snapshot.hasData}');
          print('  - User: ${snapshot.data?.uid}');
          print('  - Is Anonymous: ${snapshot.data?.isAnonymous}');
          print('  - Email: ${snapshot.data?.email}');
          print('  - Display Name: ${snapshot.data?.displayName}');
        }

        // Chuyển đến màn hình phù hợp
        final user = snapshot.data;

        if (user != null) {
          // Có Firebase user (cả anonymous và registered) -> vào HomeScreen
          // HomeScreen sẽ tự xử lý hiển thị UI phù hợp cho từng loại user
          if (kDebugMode && EnvironmentService.isDevelopment) {
            print(
                '✅ Navigating to HomeScreen - User type: ${user.isAnonymous ? "Anonymous" : "Registered"}');
          }
          return const HomeScreen();
        } else {
          // Không có Firebase user - kiểm tra offline sessions
          return FutureBuilder<bool>(
            future: GetIt.instance<OfflineService>().hasOfflineSession(),
            builder: (context, offlineSnapshot) {
              if (offlineSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }

              final hasOfflineSession = offlineSnapshot.data ?? false;

              if (hasOfflineSession) {
                // Có offline session -> vào HomeScreen
                if (kDebugMode && EnvironmentService.isDevelopment) {
                  print('✅ Navigating to HomeScreen - Offline anonymous user');
                }
                return const HomeScreen();
              } else {
                // Không có user nào (cả Firebase và offline) -> vào AuthScreen
                if (kDebugMode && EnvironmentService.isDevelopment) {
                  print('➡️ Navigating to AuthScreen - No user found');
                }
                return const AuthScreen();
              }
            },
          );
        }
      },
    );
  }
}
