import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/connectivity_provider.dart';

/// Wrapper widget cho các AI features
/// - Tự động disable UI khi offline
/// - Hiển thị overlay "Cần kết nối internet"
/// - Block user interactions khi offline
class AIFeatureWrapper extends StatelessWidget {
  final Widget child;
  final String? offlineMessage;
  final bool showOverlay;
  final VoidCallback? onOfflineTap;

  const AIFeatureWrapper({
    super.key,
    required this.child,
    this.offlineMessage,
    this.showOverlay = true,
    this.onOfflineTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        final isOffline = connectivity.isOffline;

        return Stack(
          children: [
            // Original content (grayed out when offline)
            IgnorePointer(
              ignoring: isOffline,
              child: Opacity(
                opacity: isOffline ? 0.4 : 1.0,
                child: child,
              ),
            ),

            // Offline overlay
            if (isOffline && showOverlay)
              Positioned.fill(
                child: GestureDetector(
                  onTap: onOfflineTap ?? () => _showOfflineDialog(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _buildOfflineIndicator(context),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOfflineIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              offlineMessage ?? 'Cần kết nối internet',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showOfflineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.cloud_off_rounded,
          size: 48,
          color: Colors.orange.shade600,
        ),
        title: const Text('Tính năng AI không khả dụng'),
        content: Text(
          offlineMessage ??
              'Tính năng này cần kết nối internet để sử dụng AI.\n\n'
                  'Vui lòng kiểm tra kết nối mạng và thử lại.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}

/// Compact version - Chỉ hiển thị icon nhỏ, không có overlay
class AIFeatureIndicator extends StatelessWidget {
  final bool compact;

  const AIFeatureIndicator({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        if (connectivity.isOnline) return const SizedBox.shrink();

        if (compact) {
          return Icon(
            Icons.wifi_off_rounded,
            size: 16,
            color: Colors.orange.shade600,
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 14,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                'Offline',
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


