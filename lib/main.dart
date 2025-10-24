import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
      statusBarIconBrightness: Brightness.dark, // Dark icons for light mode
      statusBarBrightness: Brightness.dark, // Light background
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
  if (EnvironmentService.isDevelopment && kDebugMode) {
    EnvironmentService.logConfiguration();
  }

  // Khởi tạo Firebase
  await FirebaseService.initialize();

  // Tạo tài khoản test chỉ trong production (không chạy khi debug)
  if (EnvironmentService.isProduction && !kDebugMode) {
    try {
      await AuthServiceTest.createTestAccount();
      await AuthServiceTest.createBackupTestAccount();
    } catch (e) {
      // ✅ TẮT LOG: Không cần log lỗi tạo test account
      // Chỉ là test account, không quan trọng
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
      debugShowCheckedModeBanner: false,
      
      // Localization configuration
      locale: const Locale('vi', 'VN'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'), // Vietnamese
        Locale('en', 'US'), // English
      ],
      
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        primaryColor: AppColors.primary,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark, // Dark icons for light mode
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
