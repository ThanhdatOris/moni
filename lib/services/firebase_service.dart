import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';

import '../firebase_options.dart';
import 'app_check_service.dart';
import 'environment_service.dart';

/// Service khởi tạo và cấu hình Firebase
class FirebaseService {
  static final Logger _logger = Logger();
  static bool _isInitialized = false;

  /// Khởi tạo Firebase
  static Future<void> initialize() async {
    try {
      if (_isInitialized) {
        _logger.i('Firebase đã được khởi tạo');
        return;
      }

      // Khởi tạo Environment Service trước
      await EnvironmentService.initialize();

      if (!EnvironmentService.isInitialized) {
        _logger.w(
            'Environment Service không thể khởi tạo, sử dụng fallback config');
      } else {
        _logger.i('Environment Service khởi tạo thành công');

        // Log configuration (chỉ non-sensitive info)
        if (EnvironmentService.loggingEnabled) {
          EnvironmentService.logConfiguration();
        }
      }

      // Kiểm tra xem Firebase đã được khởi tạo chưa
      if (Firebase.apps.isNotEmpty) {
        _logger.i('Firebase app đã tồn tại, bỏ qua khởi tạo');
        _isInitialized = true;
        return;
      }

      // Kiểm tra Firebase configuration
      if (EnvironmentService.firebaseProjectId.isEmpty ||
          EnvironmentService.firebaseProjectId == 'your-project-id') {
        throw Exception(
            'Firebase configuration chưa được thiết lập. Vui lòng tạo file .env với thông tin Firebase đúng.');
      }

      // Khởi tạo Firebase Core
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Khởi tạo Firebase App Check
      await AppCheckService.initialize();

      _isInitialized = true;
      _logger.i('Khởi tạo Firebase thành công');
    } catch (e) {
      _logger.e('Lỗi khởi tạo Firebase: $e');

      // Nếu lỗi là duplicate app, vẫn coi như đã khởi tạo thành công
      if (e.toString().contains('duplicate-app')) {
        _logger.i('Firebase app đã tồn tại, tiếp tục sử dụng');
        _isInitialized = true;
        return;
      }

      // Nếu lỗi configuration, ném exception cụ thể
      if (e.toString().contains('configuration') ||
          e.toString().contains('your-project-id')) {
        throw Exception(
            'Firebase configuration không hợp lệ. Vui lòng kiểm tra file .env');
      }

      throw Exception('Không thể khởi tạo Firebase: $e');
    }
  }

  /// Kiểm tra Firebase đã được khởi tạo chưa
  static bool get isInitialized => _isInitialized;
}
