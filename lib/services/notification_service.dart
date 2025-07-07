import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Enum định nghĩa loại thông báo
enum NotificationType {
  success,
  info,
  warning,
  error,
}

/// Service quản lý thông báo UI
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  
  NotificationService._();

  /// Hiển thị SnackBar thành công
  void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message,
      NotificationType.success,
      duration: duration,
      action: action,
    );
  }

  /// Hiển thị SnackBar thông tin
  void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message,
      NotificationType.info,
      duration: duration,
      action: action,
    );
  }

  /// Hiển thị SnackBar cảnh báo
  void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message,
      NotificationType.warning,
      duration: duration,
      action: action,
    );
  }

  /// Hiển thị SnackBar lỗi
  void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 5),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message,
      NotificationType.error,
      duration: duration,
      action: action,
    );
  }

  /// Hiển thị SnackBar tổng quát
  void _showSnackBar(
    BuildContext context,
    String message,
    NotificationType type, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getIcon(type),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _getColor(type),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: duration,
        action: action ?? SnackBarAction(
          label: 'Đóng',
          textColor: Colors.white70,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        elevation: 6,
      ),
    );
  }

  /// Lấy icon theo loại thông báo
  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.info:
        return Icons.info;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.error:
        return Icons.error;
    }
  }

  /// Lấy màu theo loại thông báo
  Color _getColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Colors.green.shade600;
      case NotificationType.info:
        return AppColors.primary;
      case NotificationType.warning:
        return Colors.orange.shade600;
      case NotificationType.error:
        return Colors.red.shade600;
    }
  }

  /// Hiển thị dialog thông báo
  Future<void> showNotificationDialog(
    BuildContext context, {
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) async {
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getColor(type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIcon(type),
                color: _getColor(type),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          if (cancelText != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onCancel?.call();
              },
              child: Text(cancelText),
            ),
          if (confirmText != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getColor(type),
                foregroundColor: Colors.white,
              ),
              child: Text(confirmText),
            ),
        ],
      ),
    );
  }

  /// Hiển thị loading dialog
  Future<void> showLoadingDialog(
    BuildContext context,
    String message, {
    bool barrierDismissible = false,
  }) async {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Ẩn loading dialog
  void hideLoadingDialog(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Extension để dễ dàng sử dụng notification
extension NotificationExtension on BuildContext {
  NotificationService get _notification => NotificationService.instance;

  void showSuccessMessage(String message) {
    _notification.showSuccess(this, message);
  }

  void showInfoMessage(String message) {
    _notification.showInfo(this, message);
  }

  void showWarningMessage(String message) {
    _notification.showWarning(this, message);
  }

  void showErrorMessage(String message) {
    _notification.showError(this, message);
  }

  Future<void> showLoadingDialog(String message) async {
    await _notification.showLoadingDialog(this, message);
  }

  void hideLoadingDialog() {
    _notification.hideLoadingDialog(this);
  }
}
