import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';

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

      await Firebase.initializeApp();
      _isInitialized = true;
      _logger.i('Khởi tạo Firebase thành công');
    } catch (e) {
      _logger.e('Lỗi khởi tạo Firebase: $e');
      throw Exception('Không thể khởi tạo Firebase: $e');
    }
  }

  /// Kiểm tra Firebase đã được khởi tạo chưa
  static bool get isInitialized => _isInitialized;
}
