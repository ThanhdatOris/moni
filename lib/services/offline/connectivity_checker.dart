import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Utility class để kiểm tra kết nối mạng
/// Consolidates duplicate connectivity check logic (DRY principle)
class ConnectivityChecker {
  static final ConnectivityChecker _instance = ConnectivityChecker._internal();
  factory ConnectivityChecker() => _instance;
  ConnectivityChecker._internal();

  final Connectivity _connectivity = Connectivity();

  /// Kiểm tra thiết bị có online không
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Stream theo dõi trạng thái kết nối
  Stream<bool> get connectivityStream => _connectivity.onConnectivityChanged
      .map((results) => !results.contains(ConnectivityResult.none));

  /// Execute action với offline fallback
  /// Pattern: Online thì gọi onlineAction, offline thì gọi offlineAction
  Future<T> executeWithOfflineFallback<T>({
    required Future<T> Function() onlineAction,
    required Future<T> Function() offlineAction,
  }) async {
    if (await isOnline()) {
      return await onlineAction();
    }
    return await offlineAction();
  }

  /// Execute action chỉ khi online, throw exception nếu offline
  Future<T> executeOnlineOnly<T>({
    required Future<T> Function() action,
    String? errorMessage,
  }) async {
    if (!await isOnline()) {
      throw OfflineException(
        errorMessage ?? 'Không có kết nối internet để thực hiện thao tác này',
      );
    }
    return await action();
  }
}

/// Exception khi thiết bị offline
class OfflineException implements Exception {
  final String message;
  OfflineException(this.message);

  @override
  String toString() => 'OfflineException: $message';
}
