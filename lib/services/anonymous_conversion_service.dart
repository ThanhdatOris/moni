import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'logging_service.dart';
import 'offline_service.dart';
import 'offline_sync_service.dart';

/// Service xử lý chuyển đổi anonymous user thành registered user
class AnonymousConversionService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OfflineService _offlineService;
  final OfflineSyncService? _syncService;

  AnonymousConversionService({
    required OfflineService offlineService,
    OfflineSyncService? syncService,
  }) : _offlineService = offlineService,
       _syncService = syncService;

  /// Kiểm tra xem user hiện tại có phải anonymous không
  bool get isAnonymousUser {
    final user = _auth.currentUser;
    return user?.isAnonymous ?? false;
  }

  /// Kiểm tra xem có phải offline anonymous user không
  Future<bool> get isOfflineAnonymousUser async {
    if (!await _offlineService.hasOfflineSession()) return false;

    final session = await _offlineService.getOfflineUserSession();
    final userId = session['userId'];

    return userId != null && _offlineService.isOfflineUserId(userId);
  }

  /// Lấy thông tin anonymous user hiện tại
  User? get currentAnonymousUser {
    final user = _auth.currentUser;
    return (user?.isAnonymous ?? false) ? user : null;
  }

  /// Chuyển đổi anonymous user thành registered user với email/password
  Future<UserModel?> convertToEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Kiểm tra kết nối internet
      if (!await _offlineService.isOnline) {
        throw Exception('Cần kết nối internet để chuyển đổi tài khoản');
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Không có user để chuyển đổi');
      }

      if (!user.isAnonymous) {
        throw Exception('User hiện tại không phải anonymous user');
      }

      logInfo('Bắt đầu chuyển đổi anonymous user: ${user.uid}');

      // Sync dữ liệu offline trước khi convert (nếu có)
      if (_syncService != null && await _syncService.hasOfflineDataToSync()) {
        logInfo('Đồng bộ dữ liệu offline trước khi convert');
        final result = await _syncService.syncAllOfflineData();
        
        if (result.hasError) {
          logWarning('Một số dữ liệu offline không sync được', data: {
            'errors': result.errors,
            'failedCount': result.failedCount,
          });
        } else {
          logInfo('Đồng bộ dữ liệu offline thành công');
        }
      }

      // Tạo credential cho email/password
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      // Link anonymous account với email/password
      final userCredential = await user.linkWithCredential(credential);
      final linkedUser = userCredential.user;

      if (linkedUser != null) {
        // Cập nhật display name
        await linkedUser.updateDisplayName(name);

        // Tạo hoặc cập nhật user document trong Firestore
        final now = DateTime.now();
        final userModel = UserModel(
          userId: linkedUser.uid,
          name: name,
          email: email,
          createdAt: now,
          updatedAt: now,
        );

        // Kiểm tra xem user document đã tồn tại chưa
        final userDoc = await _firestore
            .collection('users')
            .doc(linkedUser.uid)
            .get();

        if (userDoc.exists) {
          // Cập nhật thông tin user
          await _firestore
              .collection('users')
              .doc(linkedUser.uid)
              .update({
            'name': name,
            'email': email,
            'updated_at': Timestamp.fromDate(now),
            'is_anonymous': false, // Đánh dấu không còn anonymous
          });
        } else {
          // Tạo user document mới
          await _firestore
              .collection('users')
              .doc(linkedUser.uid)
              .set(userModel.toMap());
        }

        logInfo('Chuyển đổi anonymous user thành công: ${linkedUser.uid}', data: {
          'email': email,
          'name': name,
          'preservedData': 'Tất cả dữ liệu anonymous được giữ nguyên',
        });

        return userModel;
      }

      return null;
    } catch (e, stackTrace) {
      logError('Lỗi chuyển đổi anonymous user', error: e, stackTrace: stackTrace);

      // Xử lý các lỗi specific
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            throw Exception('Email đã được sử dụng bởi tài khoản khác');
          case 'invalid-email':
            throw Exception('Email không hợp lệ');
          case 'weak-password':
            throw Exception('Mật khẩu quá yếu');
          case 'credential-already-in-use':
            throw Exception('Thông tin đăng nhập đã được sử dụng');
          default:
            throw Exception('Lỗi Firebase: ${e.message}');
        }
      }

      throw Exception('Không thể chuyển đổi tài khoản: $e');
    }
  }

  /// Chuyển đổi anonymous user thành Google user
  Future<UserModel?> convertToGoogle() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Không có user để chuyển đổi');
      }

      if (!user.isAnonymous) {
        throw Exception('User hiện tại không phải anonymous user');
      }

      logInfo('Bắt đầu chuyển đổi anonymous user sang Google: ${user.uid}');

      // Import Google Sign-In (cần thêm vào pubspec.yaml nếu chưa có)
      // final GoogleSignIn googleSignIn = GoogleSignIn();
      //
      // // Kích hoạt flow đăng nhập Google
      // final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      // if (googleUser == null) {
      //   throw Exception('Đăng nhập Google bị hủy');
      // }
      //
      // // Lấy thông tin xác thực từ Google
      // final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      //
      // // Tạo credential cho Google
      // final credential = GoogleAuthProvider.credential(
      //   accessToken: googleAuth.accessToken,
      //   idToken: googleAuth.idToken,
      // );
      //
      // // Link anonymous account với Google
      // final userCredential = await user.linkWithCredential(credential);
      // final linkedUser = userCredential.user;
      //
      // // Xử lý tương tự như email/password...

      throw UnimplementedError('Google conversion chưa được implement');
    } catch (e, stackTrace) {
      logError('Lỗi chuyển đổi anonymous user sang Google', error: e, stackTrace: stackTrace);
      throw Exception('Không thể chuyển đổi tài khoản Google: $e');
    }
  }

  /// Lấy thống kê dữ liệu của anonymous user
  Future<Map<String, dynamic>> getAnonymousUserStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null || !user.isAnonymous) {
        return {};
      }

      // Đếm số giao dịch
      final transactionsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .where('is_deleted', isEqualTo: false)
          .get();

      // Đếm số danh mục
      final categoriesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .where('is_deleted', isEqualTo: false)
          .get();

      return {
        'transactionCount': transactionsSnapshot.docs.length,
        'categoryCount': categoriesSnapshot.docs.length,
        'userId': user.uid,
        'createdAt': user.metadata.creationTime,
        'lastSignIn': user.metadata.lastSignInTime,
      };
    } catch (e) {
      logError('Lỗi lấy thống kê anonymous user', error: e);
      return {};
    }
  }

  /// Hiển thị prompt khuyến khích user đăng ký
  bool shouldShowConversionPrompt() {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) {
      return false;
    }

    // Logic để quyết định khi nào hiển thị prompt
    // Ví dụ: sau khi user tạo >= 5 giao dịch
    // hoặc sử dụng app > 3 ngày

    return true; // Simplified for now
  }
}
