import '../services/environment_service.dart';

/// Configuration công khai của ứng dụng Moni
class AppConfig {
  // App Information
  static String get appName => EnvironmentService.appName;
  static String get appVersion => EnvironmentService.appVersion;
  static String get packageName => EnvironmentService.packageName;

  // Environment
  static String get environment => EnvironmentService.environment;
  static bool get isDebug => EnvironmentService.debugMode;
  static bool get isProduction => EnvironmentService.isProduction;
  static bool get isDevelopment => EnvironmentService.isDevelopment;

  // Feature Flags
  static bool get enableChatbot => true;
  static bool get enableImageProcessing => true;
  static bool get enableAdvancedAnalytics => isProduction;
  static bool get enableOfflineMode => true;

  // API Configuration
  static String get baseApiUrl {
    switch (environment) {
      case 'production':
        return 'https://api.moni.com';
      case 'staging':
        return 'https://staging-api.moni.com';
      default:
        return 'https://dev-api.moni.com';
    }
  }

  // Default Settings
  static const String defaultCurrency = 'VND';
  static const String defaultLanguage = 'vi';
  static const int maxTransactionsPerPage = 50;
  static const int cacheExpirationHours = 24;

  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const int animationDurationMs = 300;

  // Business Logic
  static const double budgetAlertThreshold = 0.8; // 80% của ngân sách
  static const int maxCategoriesPerUser = 50;
  static const int maxReportsPerUser = 100;

  // Security
  static const int sessionTimeoutMinutes = 30;
  static const int maxLoginAttempts = 5;
  static const bool requireBiometricAuth = false;

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String transactionsCollection = 'transactions';
  static const String categoriesCollection = 'categories';
  static const String budgetAlertsCollection = 'budget_alerts';
  static const String reportsCollection = 'reports';
  static const String chatLogsCollection = 'chat_logs';

  // File Paths
  static const String imagesPath = 'assets/images/';
  static const String animationsPath = 'assets/animations/';

  /// Lấy full configuration object để debug
  static Map<String, dynamic> getAllConfig() {
    return {
      'app': {
        'name': appName,
        'version': appVersion,
        'package': packageName,
        'environment': environment,
        'isDebug': isDebug,
        'isProduction': isProduction,
      },
      'features': {
        'chatbot': enableChatbot,
        'imageProcessing': enableImageProcessing,
        'analytics': enableAdvancedAnalytics,
        'offline': enableOfflineMode,
      },
      'api': {
        'baseUrl': baseApiUrl,
      },
      'defaults': {
        'currency': defaultCurrency,
        'language': defaultLanguage,
        'maxTransactions': maxTransactionsPerPage,
        'cacheExpiration': cacheExpirationHours,
      },
      'ui': {
        'padding': defaultPadding,
        'borderRadius': defaultBorderRadius,
        'animationDuration': animationDurationMs,
      },
      'business': {
        'budgetThreshold': budgetAlertThreshold,
        'maxCategories': maxCategoriesPerUser,
        'maxReports': maxReportsPerUser,
      },
      'security': {
        'sessionTimeout': sessionTimeoutMinutes,
        'maxLoginAttempts': maxLoginAttempts,
        'requireBiometric': requireBiometricAuth,
      },
    };
  }
}
