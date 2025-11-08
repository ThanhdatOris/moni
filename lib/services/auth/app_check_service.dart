import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../core/environment_service.dart';

/// Service quản lý Firebase App Check
class AppCheckService {
  static final Logger _logger = Logger();
  static bool _isInitialized = false;

  /// Khởi tạo Firebase App Check
  static Future<void> initialize() async {
    try {
      if (_isInitialized) {
        _logger.i('App Check đã được khởi tạo');
        return;
      }

      // Set debug token nếu có trong environment (development mode)
      final debugToken = EnvironmentService.firebaseAppCheckDebugToken;
      if (kDebugMode) {
        if (debugToken.isNotEmpty) {
          _logger.i('🔓 App Check Debug Token configured: ${debugToken.substring(0, 8)}...');
          _logger.i('Make sure this token is added to Firebase Console > App Check > Manage debug tokens');
        } else {
          _logger.w('⚠️  No debug token found. Add FIREBASE_APPCHECK_DEBUG_TOKEN to .env');
        }
      }

      // Khởi tạo Firebase App Check với debug provider cho development
      // Debug token sẽ được tự động sinh ra bởi AndroidProvider.debug/AppleProvider.debug
      // và có thể được override bằng token trong .env file
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
        webProvider:
            ReCaptchaV3Provider('6LcXXXXXXXXXXXXXXXXXXXXX'), // Placeholder key
      );

      _isInitialized = true;
      _logger.i('✅ App Check initialized successfully ${kDebugMode ? "(Debug Mode)" : ""}');
    } on Exception catch (e) {
      // Xử lý lỗi đặc biệt cho Firebase App Check API chưa được kích hoạt
      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('firebaseappcheck.googleapis.com') ||
          errorMessage.contains('api has not been used') ||
          errorMessage.contains('disabled')) {
        _logger.w(
            'Firebase App Check API chưa được kích hoạt. Ứng dụng sẽ chạy mà không có App Check.');
        _logger.w(
            'Để kích hoạt, truy cập: https://console.developers.google.com/apis/api/firebaseappcheck.googleapis.com/overview?project=YOUR_PROJECT_ID');
      } else {
        _logger.e('Lỗi khởi tạo App Check: $e');
      }

      // Không throw exception để app vẫn có thể chạy
      _logger.w('App sẽ chạy mà không có App Check');
    } catch (e) {
      _logger.e('Lỗi khởi tạo App Check: $e');
      // Không throw exception để app vẫn có thể chạy
      _logger.w('App sẽ chạy mà không có App Check');
    }
  }

  /// Kiểm tra App Check đã được khởi tạo chưa
  static bool get isInitialized => _isInitialized;

  /// Lấy debug token hiện tại từ environment
  static String? getDebugToken() {
    final token = EnvironmentService.firebaseAppCheckDebugToken;
    return token.isNotEmpty ? token : null;
  }

  /// Log instructions để setup debug token
  static void logDebugTokenInstructions() {
    if (!kDebugMode) return;
    
    final token = getDebugToken();
    if (token == null) {
      _logger.w('⚠️  No App Check Debug Token found in .env file');
      _logger.w('Add FIREBASE_APPCHECK_DEBUG_TOKEN to .env');
      return;
    }
    
    _logger.i('📋 App Check Debug Token Setup Instructions:');
    _logger.i('1. Go to Firebase Console > App Check');
    _logger.i('2. Select your app');
    _logger.i('3. Click "Manage debug tokens"');
    _logger.i('4. Add this token: $token');
    _logger.i('5. Token is already configured in .env file ✅');
  }
}

