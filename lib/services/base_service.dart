import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

/// Base service class với common functionality cho tất cả services
abstract class BaseService {
  late final FirebaseFirestore _firestore;
  late final Logger _logger;
  
  BaseService() {
    _firestore = FirebaseFirestore.instance;
    _logger = Logger();
  }

  /// Get current user ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Get Firestore instance
  FirebaseFirestore get firestore => _firestore;

  /// Logging methods
  void logInfo(String message) {
    _logger.i(message);
  }

  void logWarning(String message) {
    _logger.w(message);
  }

  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  void logDebug(String message) {
    _logger.d(message);
  }
} 