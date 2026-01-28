// =============================================================================
// SERVICES EXPORT FILE
// =============================================================================
// This file exports all services through module-level barrel files.
// Each module (core, auth, data, etc.) has its own export file for better organization.

// =============================================================================
// COMMON ERROR HANDLING HELPERS
// =============================================================================

import 'package:moni/constants/enums.dart';

import 'core/error_handler.dart';

// AI-Powered Services
export 'ai_services/ai_services.dart';
// Analytics & Reporting Services
export 'analytics/analytics_services.dart';
// Authentication & Security Services
export 'auth/auth_services.dart';
// Core Infrastructure Services
export 'core/core_services.dart';
// Data Management Services
export 'data/data_services.dart';
// Notification Services
export 'notification/notification_services.dart';
// Offline & Sync Services

// Validation & Quality Services
export 'validation/validation_services.dart';

/// Shortcut để sử dụng ErrorHandler (không thể dùng const vì instance là runtime value)
ErrorHandler get errorHandler => ErrorHandler.instance;

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
