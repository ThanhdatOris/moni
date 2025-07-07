import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'constants/app_colors.dart';
import 'constants/app_strings.dart';
import 'core/di/injection_container.dart' as di;
import 'screens/splash_wrapper.dart';
import 'services/auth_service.dart';
import 'services/environment_service.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cấu hình màu thanh trạng thái
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Khởi tạo locale data cho date formatting
  await initializeDateFormatting('vi_VN', null);
  await initializeDateFormatting('en_US', null);

  // Khởi tạo Environment Service trước
  await EnvironmentService.initialize();

  // Log configuration nếu ở development mode
  if (EnvironmentService.isDevelopment) {
    EnvironmentService.logConfiguration();
  }

  // Khởi tạo Firebase
  await FirebaseService.initialize();

  // Tạo tài khoản test chỉ trong production (không chạy khi debug)
  if (EnvironmentService.isProduction) {
    try {
      await AuthServiceTest.createTestAccount();
      await AuthServiceTest.createBackupTestAccount();
    } catch (e) {
      //print('Lỗi tạo tài khoản test: $e');
    }
  }

  // Setup dependency injection
  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        primaryColor: AppColors.primary,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const SplashWrapper(),
    );
  }
}
