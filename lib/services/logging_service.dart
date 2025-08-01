import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Enum định nghĩa mức độ log
enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

/// Model chứa thông tin context cho log
class LogContext {
  final String? userId;
  final String? deviceId;
  final String? appVersion;
  final String? platform;
  final DateTime timestamp;
  final String className;
  final String methodName;

  LogContext({
    this.userId,
    this.deviceId,
    this.appVersion,
    this.platform,
    required this.timestamp,
    required this.className,
    required this.methodName,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'deviceId': deviceId,
      'appVersion': appVersion,
      'platform': platform,
      'timestamp': timestamp.toIso8601String(),
      'className': className,
      'methodName': methodName,
    };
  }
}

/// Service quản lý log tập trung cho toàn bộ ứng dụng
class LoggingService {
  static LoggingService? _instance;
  static LoggingService get instance => _instance ??= LoggingService._();

  LoggingService._() {
    _initializeLogger();
    _loadDeviceInfo();
  }

  late Logger _logger;
  String? _deviceId;
  String? _appVersion;
  String? _platform;
  LogLevel _currentLogLevel = LogLevel.debug;
  final List<String> _logBuffer = [];
  static const int _maxBufferSize = 1000;

  /// Khởi tạo logger với cấu hình tối ưu
  void _initializeLogger() {
    _logger = Logger(
      level: kDebugMode ? Level.debug : Level.info,
      printer: PrettyPrinter(
        methodCount: 1, // ✅ GIẢM: Từ 2 → 1 để giảm noise
        errorMethodCount: 3, // ✅ GIẢM: Từ 5 → 3 để giảm noise
        lineLength: 120, // ✅ TĂNG: Từ 80 → 120 để message không bị cắt
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTime, // ✅ ĐƠN GIẢN HÓA: Chỉ hiện giờ
        noBoxingByDefault: true, // ✅ TẮT BOXING: Giảm visual noise
      ),
      output: MultiOutput([
        ConsoleOutput(),
        if (!kDebugMode) FileOutput(),
      ]),
    );
  }

  /// Tải thông tin thiết bị
  Future<void> _loadDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      _appVersion = packageInfo.version;
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _platform = 'Android ${androidInfo.version.release}';
        _deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _platform = 'iOS ${iosInfo.systemVersion}';
        _deviceId = iosInfo.identifierForVendor;
      } else {
        _platform = Platform.operatingSystem;
        _deviceId = 'unknown';
      }
      
      // ✅ CHỈ LOG KHI DEBUG: Tránh spam logs trong production
      if (kDebugMode) {
        _logger.d('📱 Device Info loaded: $_platform | App: $_appVersion');
      }
    } catch (e) {
      _platform = Platform.operatingSystem;
      _deviceId = 'unknown';
      _appVersion = 'unknown';
      // ✅ CHỈ LOG LỖI THẬT SỰ CẦN THIẾT
      if (kDebugMode) {
        _logger.w('⚠️ Không thể tải thông tin thiết bị: $e');
      }
    }
  }

  /// Tạo context cho log
  LogContext _createContext(String className, String methodName) {
    return LogContext(
      userId: FirebaseAuth.instance.currentUser?.uid,
      deviceId: _deviceId,
      appVersion: _appVersion,
      platform: _platform,
      timestamp: DateTime.now(),
      className: className,
      methodName: methodName,
    );
  }

  /// Thêm log vào buffer để có thể upload sau
  void _addToBuffer(String logEntry) {
    _logBuffer.add(logEntry);
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0);
    }
  }

  /// Log DEBUG
  void debug(
    String message, {
    required String className,
    required String methodName,
    Map<String, dynamic>? data,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    if (_currentLogLevel.index > LogLevel.debug.index) return;
    
    // ✅ ĐƠN GIẢN HÓA: Chỉ log message gốc, tránh double formatting
    _logger.d(message);
    
    // Buffer cho export (format đầy đủ)
    final context = _createContext(className, methodName);
    final logEntry = _formatLogEntry(LogLevel.debug, message, context, data, error, stackTrace);
    _addToBuffer(logEntry);
  }

  /// Log INFO
  void info(
    String message, {
    required String className,
    required String methodName,
    Map<String, dynamic>? data,
  }) {
    if (_currentLogLevel.index > LogLevel.info.index) return;
    
    // ✅ ĐƠN GIẢN HÓA: Chỉ log message gốc
    _logger.i(message);
    
    // Buffer cho export (format đầy đủ)
    final context = _createContext(className, methodName);
    final logEntry = _formatLogEntry(LogLevel.info, message, context, data);
    _addToBuffer(logEntry);
  }

  /// Log WARNING
  void warning(
    String message, {
    required String className,
    required String methodName,
    Map<String, dynamic>? data,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    if (_currentLogLevel.index > LogLevel.warning.index) return;
    
    // ✅ ĐƠN GIẢN HÓA: Chỉ log message gốc
    _logger.w(message);
    
    // Buffer cho export (format đầy đủ)
    final context = _createContext(className, methodName);
    final logEntry = _formatLogEntry(LogLevel.warning, message, context, data, error, stackTrace);
    _addToBuffer(logEntry);
  }

  /// Log ERROR
  void error(
    String message, {
    required String className,
    required String methodName,
    Map<String, dynamic>? data,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    // ✅ ĐƠN GIẢN HÓA: Chỉ log message gốc với error
    if (error != null) {
      _logger.e('$message: $error');
    } else {
      _logger.e(message);
    }
    
    // Buffer cho export và crash reporting (format đầy đủ)
    final context = _createContext(className, methodName);
    final logEntry = _formatLogEntry(LogLevel.error, message, context, data, error, stackTrace);
    _addToBuffer(logEntry);
    
    // Gửi lên crash reporting service
    _reportCrash(message, error, stackTrace, context);
  }

  /// Log FATAL
  void fatal(
    String message, {
    required String className,
    required String methodName,
    Map<String, dynamic>? data,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    // ✅ ĐƠN GIẢN HÓA: Chỉ log message gốc với error
    if (error != null) {
      _logger.f('$message: $error');
    } else {
      _logger.f(message);
    }
    
    // Buffer cho export và crash reporting (format đầy đủ)
    final context = _createContext(className, methodName);
    final logEntry = _formatLogEntry(LogLevel.fatal, message, context, data, error, stackTrace);
    _addToBuffer(logEntry);
    
    // Luôn gửi lên crash reporting service
    _reportCrash(message, error, stackTrace, context);
  }

  /// Format entry log để lưu vào buffer
  String _formatLogEntry(
    LogLevel level,
    String message,
    LogContext context,
    Map<String, dynamic>? data, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    final buffer = StringBuffer();
    
    buffer.write('[${level.name.toUpperCase()}] ');
    buffer.write('${context.className}.${context.methodName}() - ');
    buffer.write(message);
    
    if (context.userId != null) {
      buffer.write(' | Người dùng: ${context.userId}');
    }
    
    if (data != null && data.isNotEmpty) {
      buffer.write(' | Dữ liệu: $data');
    }
    
    if (error != null) {
      buffer.write(' | Lỗi: $error');
    }
    
    if (stackTrace != null) {
      buffer.write(' | Stack: ${stackTrace.toString()}');
    }
    
    return buffer.toString();
  }

  /// Gửi báo cáo lỗi (có thể tích hợp với Firebase Crashlytics)
  void _reportCrash(
    String message,
    dynamic error,
    StackTrace? stackTrace,
    LogContext context,
  ) {
    // TODO: Tích hợp với Firebase Crashlytics
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  /// Thiết lập mức độ log
  void setLogLevel(LogLevel level) {
    _currentLogLevel = level;
  }

  /// Lấy tất cả log trong buffer
  List<String> getLogBuffer() {
    return List.from(_logBuffer);
  }

  /// Xóa buffer log
  void clearLogBuffer() {
    _logBuffer.clear();
  }

  /// Xuất log ra file
  Future<String?> exportLogsToFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/moni_logs_${DateTime.now().millisecondsSinceEpoch}.txt');
      
      await file.writeAsString(_logBuffer.join('\n'));
      
      return file.path;
    } catch (e) {
      _logger.e('❌ Lỗi xuất log: $e');
      return null;
    }
  }
}

/// Output log ra file
class FileOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    // TODO: Implement file output
  }
}

/// Extension để dễ dàng sử dụng logging với tối ưu hóa
extension AppLogger on Object {
  LoggingService get _log => LoggingService.instance;
  
  void logDebug(
    String message, {
    Map<String, dynamic>? data,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    // ✅ CHỈ LOG DEBUG KHI CẦN THIẾT
    if (!kDebugMode) return;
    
    _log.debug(
      message,
      className: runtimeType.toString(),
      methodName: _getSimpleMethodName(),
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void logInfo(
    String message, {
    Map<String, dynamic>? data,
  }) {
    _log.info(
      message,
      className: runtimeType.toString(),
      methodName: _getSimpleMethodName(),
      data: data,
    );
  }

  void logWarning(
    String message, {
    Map<String, dynamic>? data,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _log.warning(
      message,
      className: runtimeType.toString(),
      methodName: _getSimpleMethodName(),
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void logError(
    String message, {
    Map<String, dynamic>? data,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _log.error(
      message,
      className: runtimeType.toString(),
      methodName: _getSimpleMethodName(),
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void logFatal(
    String message, {
    Map<String, dynamic>? data,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _log.fatal(
      message,
      className: runtimeType.toString(),
      methodName: _getSimpleMethodName(),
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// ✅ ĐƠN GIẢN HÓA: Method name detection đơn giản hơn, ít gây lỗi
  String _getSimpleMethodName() {
    try {
      final trace = StackTrace.current;
      final frames = trace.toString().split('\n');
      // Tìm frame có method name, bỏ qua các frame của extension
      for (int i = 1; i < frames.length && i < 5; i++) {
        final frame = frames[i];
        if (frame.contains(runtimeType.toString())) {
          final match = RegExp(r'\.(\w+)\s*\(').firstMatch(frame);
          if (match != null) {
            return match.group(1) ?? 'unknown';
          }
        }
      }
    } catch (e) {
      // Bỏ qua lỗi, không log để tránh infinite loop
    }
    return 'unknown';
  }
}
