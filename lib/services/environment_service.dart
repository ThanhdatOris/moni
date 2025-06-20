import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

/// Service quản lý environment variables và configuration
class EnvironmentService {
  static final Logger _logger = Logger();
  static bool _isInitialized = false;

  /// Khởi tạo environment service
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      _isInitialized = true;
      _logger.i('Environment initialized successfully');
    } catch (e) {
      _logger.e('Failed to load environment: $e');
      _isInitialized = false;
    }
  }

  /// Kiểm tra xem service đã được khởi tạo chưa
  static bool get isInitialized => _isInitialized;

  // ===================
  // FIREBASE CONFIG
  // ===================
  
  static String get firebaseProjectId => 
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  
  static String get firebaseApiKey => 
      dotenv.env['FIREBASE_API_KEY'] ?? '';
  
  static String get firebaseAuthDomain => 
      dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '';
  
  static String get firebaseStorageBucket => 
      dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
  
  static String get firebaseMessagingSenderId => 
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  
  static String get firebaseAppId => 
      dotenv.env['FIREBASE_APP_ID'] ?? '';

  // ===================
  // GEMINI AI CONFIG
  // ===================
  
  static String get geminiApiKey => 
      dotenv.env['GEMINI_API_KEY'] ?? 'AIzaSyAHBPmjkYQnqOrtz0YTryyAPYUye7Fp85A';

  // ===================
  // APP CONFIG
  // ===================
  
  static String get appName => 
      dotenv.env['APP_NAME'] ?? 'Moni';
  
  static String get appVersion => 
      dotenv.env['APP_VERSION'] ?? '1.0.0';
  
  static String get packageName => 
      dotenv.env['PACKAGE_NAME'] ?? 'com.oris.moni';

  // ===================
  // ENVIRONMENT
  // ===================
  
  static String get environment => 
      dotenv.env['ENVIRONMENT'] ?? 'development';
  
  static bool get debugMode => 
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';
  
  static bool get loggingEnabled => 
      dotenv.env['LOGGING_ENABLED']?.toLowerCase() == 'true';

  // ===================
  // SECURITY
  // ===================
  
  static String get encryptionKey => 
      dotenv.env['ENCRYPTION_KEY'] ?? '';
  
  static String get jwtSecret => 
      dotenv.env['JWT_SECRET'] ?? '';

  // ===================
  // OPTIONAL SERVICES
  // ===================
  
  static String? get sentryDsn => 
      dotenv.env['SENTRY_DSN'];
  
  static String? get analyticsId => 
      dotenv.env['ANALYTICS_ID'];
  
  static bool get crashlyticsEnabled => 
      dotenv.env['CRASHLYTICS_ENABLED']?.toLowerCase() == 'true';

  // ===================
  // UTILITY METHODS
  // ===================
  
  /// Kiểm tra xem có phải môi trường development không
  static bool get isDevelopment => environment == 'development';
  
  /// Kiểm tra xem có phải môi trường production không
  static bool get isProduction => environment == 'production';
  
  /// Kiểm tra xem có phải môi trường staging không
  static bool get isStaging => environment == 'staging';

  /// Get environment variable với fallback value
  static String getEnv(String key, {String fallback = ''}) {
    return dotenv.env[key] ?? fallback;
  }

  /// Log current environment configuration (chỉ non-sensitive data)
  static void logConfiguration() {
    if (!loggingEnabled) return;
    
    _logger.i('=== Environment Configuration ===');
    _logger.i('App Name: $appName');
    _logger.i('Version: $appVersion');
    _logger.i('Package: $packageName');
    _logger.i('Environment: $environment');
    _logger.i('Debug Mode: $debugMode');
    _logger.i('Logging Enabled: $loggingEnabled');
    _logger.i('Crashlytics: $crashlyticsEnabled');
    _logger.i('Has Firebase Config: ${firebaseProjectId.isNotEmpty}');
    _logger.i('Has Gemini API Key: ${geminiApiKey.isNotEmpty}');
    _logger.i('=================================');
  }
} 