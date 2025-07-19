import 'package:flutter/material.dart';

import '../core/chart_theme.dart';

/// Error handling utility cho chart system
/// Cung cấp consistent error handling và user-friendly error messages
class ChartErrorHandler {
  /// Hiển thị error state cho chart
  static Widget buildErrorState({
    required String error,
    required ChartTheme theme,
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              customMessage ?? 'Có lỗi xảy ra',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Hiển thị loading state cho chart
  static Widget buildLoadingState({
    required ChartTheme theme,
    String? message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Hiển thị empty state cho chart
  static Widget buildEmptyState({
    required ChartTheme theme,
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 16),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Xử lý exception và trả về user-friendly message
  static String getErrorMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();

      // Xử lý các loại lỗi cụ thể
      if (message.contains('network')) {
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet.';
      } else if (message.contains('permission')) {
        return 'Không có quyền truy cập dữ liệu.';
      } else if (message.contains('not_found')) {
        return 'Không tìm thấy dữ liệu.';
      } else if (message.contains('timeout')) {
        return 'Yêu cầu hết thời gian chờ. Vui lòng thử lại.';
      } else if (message.contains('authentication')) {
        return 'Lỗi xác thực. Vui lòng đăng nhập lại.';
      }

      return 'Có lỗi xảy ra: ${message.split(':').last.trim()}';
    }

    return 'Có lỗi không xác định xảy ra.';
  }

  /// Log error với context
  static void logError(String context, dynamic error,
      [StackTrace? stackTrace]) {
    // Trong production, có thể sử dụng logging service
    debugPrint('Chart Error [$context]: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Kiểm tra xem có nên retry hay không
  static bool shouldRetry(dynamic error, int retryCount) {
    if (retryCount >= 3) return false;

    final message = error.toString().toLowerCase();

    // Retry cho network errors
    if (message.contains('network') ||
        message.contains('timeout') ||
        message.contains('connection')) {
      return true;
    }

    // Không retry cho permission/authentication errors
    if (message.contains('permission') ||
        message.contains('authentication') ||
        message.contains('unauthorized')) {
      return false;
    }

    return true;
  }
}
