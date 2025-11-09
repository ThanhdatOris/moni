import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';

import '../../firebase_options.dart';
import '../auth/app_check_service.dart';
import 'environment_service.dart';

/// Service khởi tạo và cấu hình Firebase
class FirebaseService {
  static final Logger _logger = Logger();
  static bool _isInitialized = false;

  /// Khởi tạo Firebase
  static Future<void> initialize() async {
    try {
      // Kiểm tra đã khởi tạo
      if (_isInitialized) {
        if (EnvironmentService.debugMode) {
          _logger.d('🔥 Firebase đã được khởi tạo');
        }
        return;
      }

      // Kiểm tra Firebase app đã tồn tại (check trước khi init)
      if (Firebase.apps.isNotEmpty) {
        _isInitialized = true;
        _logger.i('🔥 Firebase: Sử dụng instance có sẵn');
        // Vẫn cần init App Check
        await AppCheckService.initialize();
        return;
      }

      // Khởi tạo Environment Service nếu cần
      if (!EnvironmentService.isInitialized) {
        await EnvironmentService.initialize();
      }

      if (!EnvironmentService.isInitialized) {
        _logger.w('⚠️ Environment Service không khởi tạo được, sử dụng fallback');
      }

      // Kiểm tra Firebase configuration
      if (EnvironmentService.firebaseProjectId.isEmpty ||
          EnvironmentService.firebaseProjectId == 'your-project-id') {
        throw Exception(
            'Firebase configuration chưa được thiết lập. Vui lòng tạo file .env với thông tin Firebase đúng.');
      }

      // Khởi tạo Firebase Core với xử lý duplicate-app
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _logger.i('🔥 Khởi tạo Firebase Core thành công');
      } catch (e) {
        // Xử lý duplicate app error riêng biệt
        if (e.toString().contains('duplicate-app')) {
          _logger.i('🔥 Firebase: App đã tồn tại, sử dụng instance hiện có');
        } else {
          rethrow; // Throw lại nếu là lỗi khác
        }
      }

      // Khởi tạo Firebase App Check
      await AppCheckService.initialize();

      _isInitialized = true;
      _logger.i('✅ Firebase Service initialized successfully');
    } catch (e) {
      _logger.e('❌ Lỗi khởi tạo Firebase: $e');

      // Xử lý configuration error
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
