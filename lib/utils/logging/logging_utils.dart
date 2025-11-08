import 'package:flutter/foundation.dart';

import 'package:moni/services/services.dart';

/// Utility functions để dễ dàng logging trong toàn bộ app
/// Đây là wrapper around LoggingService để có syntax ngắn gọn hơn

/// Log debug message (chỉ hiển thị trong debug mode)
void logDebug(
  String message, {
  String? className,
  String? methodName,
  Map<String, dynamic>? data,
  dynamic error,
  StackTrace? stackTrace,
}) {
  if (kDebugMode) {
    LoggingService.instance.debug(
      message,
      className: className ?? 'Global',
      methodName: methodName ?? 'unknown',
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Log info message
void logInfo(
  String message, {
  String? className,
  String? methodName,
  Map<String, dynamic>? data,
}) {
  LoggingService.instance.info(
    message,
    className: className ?? 'Global',
    methodName: methodName ?? 'unknown',
    data: data,
  );
}

/// Log warning message
void logWarning(
  String message, {
  String? className,
  String? methodName,
  Map<String, dynamic>? data,
  dynamic error,
  StackTrace? stackTrace,
}) {
  LoggingService.instance.warning(
    message,
    className: className ?? 'Global',
    methodName: methodName ?? 'unknown',
    data: data,
    error: error,
    stackTrace: stackTrace,
  );
}

/// Log error message
void logError(
  String message, {
  String? className,
  String? methodName,
  Map<String, dynamic>? data,
  dynamic error,
  StackTrace? stackTrace,
}) {
  LoggingService.instance.error(
    message,
    className: className ?? 'Global',
    methodName: methodName ?? 'unknown',
    data: data,
    error: error,
    stackTrace: stackTrace,
  );
}

/// Log cho navigation events
void logNavigation(
  String destination, {
  String? from,
  Map<String, dynamic>? params,
}) {
  logInfo(
    'Navigation: $destination',
    className: 'Navigation',
    methodName: 'navigate',
    data: {
      'destination': destination,
      'from': from,
      'params': params,
    },
  );
}

/// Log cho authentication events
void logAuth(
  String event, {
  String? userId,
  String? userType,
  Map<String, dynamic>? data,
}) {
  logInfo(
    'Auth: $event',
    className: 'Authentication',
    methodName: 'authEvent',
    data: {
      'event': event,
      'userId': userId,
      'userType': userType,
      ...?data,
    },
  );
}

/// Log cho UI state changes
void logUIState(
  String component,
  String state, {
  Map<String, dynamic>? data,
}) {
  if (kDebugMode) {
    logDebug(
      'UI State: $component -> $state',
      className: 'UI',
      methodName: 'stateChange',
      data: {
        'component': component,
        'state': state,
        ...?data,
      },
    );
  }
}

/// Log cho performance metrics
void logPerformance(
  String operation,
  Duration duration, {
  Map<String, dynamic>? data,
}) {
  logInfo(
    'Performance: $operation (${duration.inMilliseconds}ms)',
    className: 'Performance',
    methodName: 'measure',
    data: {
      'operation': operation,
      'durationMs': duration.inMilliseconds,
      ...?data,
    },
  );
}

/// Helper để replace tất cả print() statements
@Deprecated('Use logDebug(), logInfo(), logWarning(), or logError() instead')
void printDebug(Object? object) {
  if (kDebugMode) {
    logDebug(object.toString());
  }
}
