import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/offline/connectivity_checker.dart';

/// Provider để quản lý connectivity state toàn app
/// Sử dụng với ChangeNotifierProvider để tất cả widgets có thể listen
class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityChecker _connectivityChecker = ConnectivityChecker();
  
  bool _isOnline = true;
  bool _isChecking = false;
  Timer? _periodicCheck;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get isChecking => _isChecking;

  ConnectivityProvider() {
    _initialize();
  }

  /// Initialize connectivity checking
  Future<void> _initialize() async {
    await checkConnectivity();
    
    // Periodic check mỗi 10 giây
    _periodicCheck = Timer.periodic(
      const Duration(seconds: 10),
      (_) => checkConnectivity(),
    );
  }

  /// Check connectivity và update state
  Future<void> checkConnectivity() async {
    if (_isChecking) return; // Prevent multiple concurrent checks
    
    _isChecking = true;
    notifyListeners();

    try {
      final isOnline = await _connectivityChecker.isOnline();
      
      // Only notify if state changed
      if (_isOnline != isOnline) {
        _isOnline = isOnline;
        notifyListeners();
        
        if (kDebugMode) {
          print('📡 Connectivity changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error checking connectivity: $e');
      }
      // Assume offline on error
      if (_isOnline) {
        _isOnline = false;
        notifyListeners();
      }
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Force refresh connectivity status
  Future<void> refresh() async {
    await checkConnectivity();
  }

  @override
  void dispose() {
    _periodicCheck?.cancel();
    super.dispose();
  }
}


