// =============================================================================
// SERVICES EXPORT FILE
// =============================================================================

// Core Services
export 'auth_service.dart';
export 'firebase_service.dart';
export 'environment_service.dart';
export 'logging_service.dart';
export 'error_handler.dart';

// Business Services
export 'transaction_service.dart';
export 'category_service.dart';
export 'report_service.dart';
export 'budget_alert_service.dart';
export 'chat_log_service.dart';
export 'ai_processor_service.dart';

// Offline Services
export 'offline_service.dart';
export 'offline_sync_service.dart';
export 'anonymous_conversion_service.dart';

// Other Services
export 'notification_service.dart';
export 'app_check_service.dart';

// =============================================================================
// COMMON ERROR HANDLING HELPERS
// =============================================================================

import 'error_handler.dart';

/// Shortcut để sử dụng ErrorHandler (không thể dùng const vì instance là runtime value)
ErrorHandler get errorHandler => ErrorHandler.instance;

/// Quick helper để debug errors
void logError(dynamic error, [String? context]) {
  debugError(error, context: context);
}

/// Quick helper để tạo authentication error
AppError createAuthError(String message) {
  return createAppError(
    type: ErrorType.authentication,
    code: 'auth_error',
    message: message,
    userMessage: message,
  );
}

/// Quick helper để tạo network error
AppError createNetworkError(String message) {
  return createAppError(
    type: ErrorType.network,
    code: 'network_error',
    message: message,
    userMessage: 'Lỗi kết nối mạng: $message',
  );
}

/// Quick helper để tạo validation error
AppError createValidationError(String message) {
  return createAppError(
    type: ErrorType.validation,
    code: 'validation_error',
    message: message,
    userMessage: 'Dữ liệu không hợp lệ: $message',
  );
}
