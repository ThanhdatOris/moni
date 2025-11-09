import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:moni/constants/enums.dart';

import 'logging_service.dart';

/// Model chứa thông tin lỗi
class AppError {
  final ErrorType type;
  final String code;
  final String message;
  final String? userMessage;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? data;

  AppError({
    required this.type,
    required this.code,
    required this.message,
    this.userMessage,
    this.originalError,
    this.stackTrace,
    this.data,
  });

  /// Tạo AppError từ Exception
  factory AppError.fromException(
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    if (exception is FirebaseAuthException) {
      return AppError._fromFirebaseAuthException(exception, stackTrace, data);
    } else if (exception is FirebaseException) {
      return AppError._fromFirebaseException(exception, stackTrace, data);
    } else if (exception is FormatException) {
      return AppError._fromFormatException(exception, stackTrace, data);
    } else {
      return AppError._fromGenericException(exception, stackTrace, data);
    }
  }

  /// Tạo AppError từ FirebaseAuthException
  factory AppError._fromFirebaseAuthException(
    FirebaseAuthException exception,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  ) {
    String userMessage;
    switch (exception.code) {
      case 'user-not-found':
        userMessage = 'Không tìm thấy tài khoản với email này';
        break;
      case 'wrong-password':
        userMessage = 'Mật khẩu không chính xác';
        break;
      case 'email-already-in-use':
        userMessage = 'Email này đã được sử dụng';
        break;
      case 'weak-password':
        userMessage = 'Mật khẩu quá yếu';
        break;
      case 'invalid-email':
        userMessage = 'Email không hợp lệ';
        break;
      case 'too-many-requests':
        userMessage = 'Quá nhiều lần thử. Vui lòng thử lại sau';
        break;
      case 'network-request-failed':
        userMessage = 'Lỗi kết nối mạng';
        break;
      default:
        userMessage = 'Lỗi xác thực: ${exception.message}';
    }

    return AppError(
      type: ErrorType.authentication,
      code: exception.code,
      message: exception.message ?? 'Firebase Auth Error',
      userMessage: userMessage,
      originalError: exception,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Tạo AppError từ FirebaseException
  factory AppError._fromFirebaseException(
    FirebaseException exception,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  ) {
    String userMessage;
    switch (exception.code) {
      case 'permission-denied':
        userMessage = 'Không có quyền truy cập dữ liệu';
        break;
      case 'unavailable':
        userMessage = 'Dịch vụ tạm thời không khả dụng';
        break;
      case 'deadline-exceeded':
        userMessage = 'Hết thời gian chờ kết nối';
        break;
      default:
        userMessage = 'Lỗi hệ thống: ${exception.message}';
    }

    return AppError(
      type: ErrorType.firestore,
      code: exception.code,
      message: exception.message ?? 'Firebase Error',
      userMessage: userMessage,
      originalError: exception,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Tạo AppError từ FormatException
  factory AppError._fromFormatException(
    FormatException exception,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  ) {
    return AppError(
      type: ErrorType.validation,
      code: 'format_error',
      message: exception.message,
      userMessage: 'Dữ liệu không đúng định dạng',
      originalError: exception,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Tạo AppError từ Exception chung
  factory AppError._fromGenericException(
    dynamic exception,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  ) {
    return AppError(
      type: ErrorType.unknown,
      code: 'unknown_error',
      message: exception.toString(),
      userMessage: 'Đã xảy ra lỗi không mong muốn',
      originalError: exception,
      stackTrace: stackTrace,
      data: data,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'code': code,
      'message': message,
      'userMessage': userMessage,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Service xử lý lỗi tập trung
class ErrorHandler {
  static ErrorHandler? _instance;
  static ErrorHandler get instance => _instance ??= ErrorHandler._();
  
  ErrorHandler._();

  final LoggingService _logger = LoggingService.instance;

  /// Xử lý lỗi và log
  AppError handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? data,
  }) {
    final appError = AppError.fromException(error, stackTrace: stackTrace, data: data);
    
    // Log lỗi
    _logger.error(
      appError.message,
      className: 'ErrorHandler',
      methodName: 'handleError',
      data: {
        'type': appError.type.name,
        'code': appError.code,
        'context': context,
        ...?appError.data,
      },
      error: appError.originalError,
      stackTrace: appError.stackTrace,
    );

    return appError;
  }

  /// Xử lý lỗi và hiển thị thông báo cho user
  AppError handleErrorWithUI(
    BuildContext context,
    dynamic error, {
    StackTrace? stackTrace,
    String? contextInfo,
    Map<String, dynamic>? data,
    bool showSnackBar = true,
  }) {
    final appError = handleError(
      error,
      stackTrace: stackTrace,
      context: contextInfo,
      data: data,
    );

    if (showSnackBar) {
      _showErrorSnackBar(context, appError);
    }

    return appError;
  }

  /// Hiển thị SnackBar lỗi
  void _showErrorSnackBar(BuildContext context, AppError appError) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getErrorIcon(appError.type),
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                appError.userMessage ?? appError.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _getErrorColor(appError.type),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Đóng',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Lấy icon theo loại lỗi
  IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.authentication:
        return Icons.lock;
      case ErrorType.validation:
        return Icons.warning;
      case ErrorType.permission:
        return Icons.block;
      case ErrorType.firestore:
        return Icons.cloud_off;
      case ErrorType.unknown:
        return Icons.error;
    }
  }

  /// Lấy màu theo loại lỗi
  Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.authentication:
        return Colors.red.shade700;
      case ErrorType.validation:
        return Colors.amber.shade700;
      case ErrorType.permission:
        return Colors.purple.shade700;
      case ErrorType.firestore:
        return Colors.blue.shade700;
      case ErrorType.unknown:
        return Colors.grey.shade700;
    }
  }

  /// Hiển thị dialog lỗi chi tiết
  Future<void> showErrorDialog(
    BuildContext context,
    AppError appError, {
    String? title,
    VoidCallback? onRetry,
  }) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getErrorIcon(appError.type),
              color: _getErrorColor(appError.type),
            ),
            const SizedBox(width: 8),
            Text(title ?? 'Lỗi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appError.userMessage ?? appError.message),
            if (appError.code.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Mã lỗi: ${appError.code}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Thử lại'),
            ),
        ],
      ),
    );
  }
}

/// Extension để dễ dàng sử dụng error handling
extension ErrorHandling on Object {
  ErrorHandler get _errorHandler => ErrorHandler.instance;

  /// Xử lý lỗi đơn giản
  AppError handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? data,
  }) {
    return _errorHandler.handleError(
      error,
      stackTrace: stackTrace,
      context: context,
      data: data,
    );
  }

  /// Xử lý lỗi với UI
  AppError handleErrorWithUI(
    BuildContext context,
    dynamic error, {
    StackTrace? stackTrace,
    String? contextInfo,
    Map<String, dynamic>? data,
    bool showSnackBar = true,
  }) {
    return _errorHandler.handleErrorWithUI(
      context,
      error,
      stackTrace: stackTrace,
      contextInfo: contextInfo,
      data: data,
      showSnackBar: showSnackBar,
    );
  }
}

// =============================================================================
// HELPER FUNCTIONS để dễ sử dụng hơn
// =============================================================================

/// Helper function để throw AppError thay vì Exception
Never throwAppError(
  dynamic error, {
  StackTrace? stackTrace,
  String? context,
  Map<String, dynamic>? data,
}) {
  final appError = ErrorHandler.instance.handleError(
    error,
    stackTrace: stackTrace,
    context: context,
    data: data,
  );
  throw appError;
}

/// Helper function để xử lý lỗi với try-catch pattern
T handleErrorSafely<T>(
  T Function() operation, {
  T? fallbackValue,
  String? context,
  bool logError = true,
}) {
  try {
    return operation();
  } catch (e, stackTrace) {
    if (logError) {
      ErrorHandler.instance.handleError(
        e,
        stackTrace: stackTrace,
        context: context,
      );
    }
    
    if (fallbackValue != null) {
      return fallbackValue;
    }
    
    rethrow;
  }
}

/// Helper function để xử lý Future với error handling
Future<T> handleErrorSafelyAsync<T>(
  Future<T> Function() operation, {
  T? fallbackValue,
  String? context,
  bool logError = true,
}) async {
  try {
    return await operation();
  } catch (e, stackTrace) {
    if (logError) {
      ErrorHandler.instance.handleError(
        e,
        stackTrace: stackTrace,
        context: context,
      );
    }
    
    if (fallbackValue != null) {
      return fallbackValue;
    }
    
    rethrow;
  }
}

/// Helper function để debug error trong development mode
void debugError(
  dynamic error, {
  StackTrace? stackTrace,
  String? context,
  Map<String, dynamic>? data,
}) {
  if (kDebugMode) {
    final appError = ErrorHandler.instance.handleError(
      error,
      stackTrace: stackTrace,
      context: context,
      data: data,
    );
    
    // Sử dụng LoggingService để log error với format đẹp
    LoggingService.instance.error(
      'DEBUG ERROR',
      className: 'ErrorHandler',
      methodName: 'debugError',
      data: {
        'type': appError.type.name,
        'code': appError.code,
        'message': appError.message,
        'userMessage': appError.userMessage,
        'context': context,
        'originalData': data,
        'hasStackTrace': appError.stackTrace != null,
      },
      error: appError.originalError,
      stackTrace: appError.stackTrace,
    );
  }
}

/// Helper function để tạo custom error
AppError createAppError({
  required ErrorType type,
  required String code,
  required String message,
  String? userMessage,
  Map<String, dynamic>? data,
}) {
  return AppError(
    type: type,
    code: code,
    message: message,
    userMessage: userMessage,
    data: data,
  );
}
