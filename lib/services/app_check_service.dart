import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:logger/logger.dart';

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

      // Khởi tạo Firebase App Check với debug provider cho development
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
        webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
      );

      _isInitialized = true;
      _logger.i('Khởi tạo App Check thành công');
    } on Exception catch (e) {
      // Xử lý lỗi đặc biệt cho Firebase App Check API chưa được kích hoạt
      final errorMessage = e.toString().toLowerCase();
      
      if (errorMessage.contains('firebaseappcheck.googleapis.com') ||
          errorMessage.contains('api has not been used') ||
          errorMessage.contains('disabled')) {
        _logger.w('Firebase App Check API chưa được kích hoạt. Ứng dụng sẽ chạy mà không có App Check.');
        _logger.w('Để kích hoạt, truy cập: https://console.developers.google.com/apis/api/firebaseappcheck.googleapis.com/overview?project=YOUR_PROJECT_ID');
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
}
