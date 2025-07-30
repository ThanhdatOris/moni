import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Widget đơn giản hiển thị trạng thái offline/online
class SimpleOfflineStatusBanner extends StatefulWidget {
  const SimpleOfflineStatusBanner({super.key});

  @override
  State<SimpleOfflineStatusBanner> createState() => _SimpleOfflineStatusBannerState();
}

class _SimpleOfflineStatusBannerState extends State<SimpleOfflineStatusBanner> {
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _startConnectivityListener();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = !connectivity.contains(ConnectivityResult.none);
    if (mounted) {
      setState(() {
        _isOnline = isOnline;
      });
    }
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = !results.contains(ConnectivityResult.none);
      if (mounted && _isOnline != isOnline) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Chỉ hiển thị khi offline
    if (_isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withValues(alpha: 0.1),
            Colors.orange.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.4),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              color: Colors.orange[700],
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chế độ offline',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Dữ liệu sẽ đồng bộ khi có kết nối',
                  style: TextStyle(
                    color: Colors.orange[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
