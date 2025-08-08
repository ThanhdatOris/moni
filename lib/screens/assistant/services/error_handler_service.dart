import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/// Centralized error handling for Assistant modules
class AssistantErrorHandler {
  static final Logger _logger = Logger();

  /// Handle errors with proper categorization and user feedback
  static AssistantError handleError(dynamic error, {String? context}) {
    _logger.e('Assistant Error in $context: $error');

    final assistantError = _categorizeError(error);

    // Log detailed error for debugging
    _logDetailedError(assistantError, context);

    return assistantError;
  }

  /// Categorize error based on type and content
  static AssistantError _categorizeError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return AssistantError(
        type: ErrorType.network,
        code: 'NETWORK_ERROR',
        message: error.toString(),
        userMessage: 'Mất kết nối mạng. Vui lòng kiểm tra và thử lại.',
        canRetry: true,
        severity: ErrorSeverity.medium,
        retryDelay: const Duration(seconds: 2),
      );
    }

    if (errorString.contains('unauthorized') ||
        errorString.contains('authentication')) {
      return AssistantError(
        type: ErrorType.auth,
        code: 'AUTH_ERROR',
        message: error.toString(),
        userMessage: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        canRetry: false,
        severity: ErrorSeverity.high,
      );
    }

    if (errorString.contains('ai') ||
        errorString.contains('model') ||
        errorString.contains('api')) {
      return AssistantError(
        type: ErrorType.ai,
        code: 'AI_ERROR',
        message: error.toString(),
        userMessage: 'AI đang bận. Vui lòng thử lại sau ít phút.',
        canRetry: true,
        severity: ErrorSeverity.medium,
        retryDelay: const Duration(seconds: 5),
      );
    }

    if (errorString.contains('data') ||
        errorString.contains('parse') ||
        errorString.contains('format')) {
      return AssistantError(
        type: ErrorType.data,
        code: 'DATA_ERROR',
        message: error.toString(),
        userMessage: 'Dữ liệu không hợp lệ. Vui lòng thử tải lại.',
        canRetry: true,
        severity: ErrorSeverity.medium,
        retryDelay: const Duration(seconds: 1),
      );
    }

    // Default unknown error
    return AssistantError(
      type: ErrorType.unknown,
      code: 'UNKNOWN_ERROR',
      message: error.toString(),
      userMessage: 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.',
      canRetry: true,
      severity: ErrorSeverity.low,
      retryDelay: const Duration(seconds: 3),
    );
  }

  /// Log detailed error information
  static void _logDetailedError(AssistantError error, String? context) {
    final logData = {
      'context': context,
      'error_type': error.type.name,
      'error_code': error.code,
      'severity': error.severity.name,
      'can_retry': error.canRetry,
      'timestamp': DateTime.now().toIso8601String(),
    };

    switch (error.severity) {
      case ErrorSeverity.high:
        _logger.e('Critical Assistant Error', error: logData);
        break;
      case ErrorSeverity.medium:
        _logger.w('Medium Assistant Error', error: logData);
        break;
      case ErrorSeverity.low:
        _logger.i('Minor Assistant Error', error: logData);
        break;
    }
  }

  /// Show error to user with appropriate action
  static void showErrorToUser(BuildContext context, AssistantError error,
      {VoidCallback? onRetry}) {
    final shouldShowRetry = error.canRetry && onRetry != null;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getErrorIcon(error.type),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error.userMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _getErrorColor(error.severity),
        duration:
            Duration(seconds: error.severity == ErrorSeverity.high ? 6 : 4),
        action: shouldShowRetry
            ? SnackBarAction(
                label: 'Thử lại',
                textColor: Colors.white,
                onPressed: () async {
                  if (error.retryDelay != null) {
                    await Future.delayed(error.retryDelay!);
                  }
                  onRetry();
                },
              )
            : null,
      ),
    );
  }

  static IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.auth:
        return Icons.lock_outline;
      case ErrorType.ai:
        return Icons.psychology_outlined;
      case ErrorType.data:
        return Icons.data_usage_outlined;
      case ErrorType.unknown:
        return Icons.error_outline;
    }
  }

  static Color _getErrorColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.high:
        return Colors.red.shade700;
      case ErrorSeverity.medium:
        return Colors.orange.shade700;
      case ErrorSeverity.low:
        return Colors.blue.shade700;
    }
  }
}

/// Error types for Assistant modules
enum ErrorType { network, auth, ai, data, unknown }

/// Error severity levels
enum ErrorSeverity { high, medium, low }

/// Structured error model for Assistant modules
class AssistantError {
  final ErrorType type;
  final String code;
  final String message;
  final String userMessage;
  final bool canRetry;
  final ErrorSeverity severity;
  final Duration? retryDelay;
  final Map<String, dynamic>? metadata;

  const AssistantError({
    required this.type,
    required this.code,
    required this.message,
    required this.userMessage,
    required this.canRetry,
    required this.severity,
    this.retryDelay,
    this.metadata,
  });

  /// Create a copy with modified fields
  AssistantError copyWith({
    ErrorType? type,
    String? code,
    String? message,
    String? userMessage,
    bool? canRetry,
    ErrorSeverity? severity,
    Duration? retryDelay,
    Map<String, dynamic>? metadata,
  }) {
    return AssistantError(
      type: type ?? this.type,
      code: code ?? this.code,
      message: message ?? this.message,
      userMessage: userMessage ?? this.userMessage,
      canRetry: canRetry ?? this.canRetry,
      severity: severity ?? this.severity,
      retryDelay: retryDelay ?? this.retryDelay,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() => 'AssistantError(${type.name}): $userMessage';
}
