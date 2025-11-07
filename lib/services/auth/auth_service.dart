import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../models/user_model.dart';
import '../core/error_handler.dart';
import '../core/logging_service.dart';
import '../data/category_service.dart';
import '../offline/offline_service.dart';

/// Service xử lý xác thực người dùng
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lấy người dùng hiện tại
  User? get currentUser => _auth.currentUser;

  /// Stream theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Đăng ký người dùng mới
  Future<UserModel?> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Tạo tài khoản với Firebase Auth
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        // Tạo document người dùng trong Firestore
        final now = DateTime.now();
        final userModel = UserModel(
          userId: user.uid,
          name: name,
          email: email,
          createdAt: now,
          updatedAt: now,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());

        // Cập nhật display name
        await user.updateDisplayName(name);

        // Tạo danh mục mặc định cho user mới
        await _createDefaultCategories(user.uid);

        // Sử dụng hệ thống log mới
        logInfo('Đăng ký thành công cho user: ${user.uid}', data: {
          'email': email,
          'name': name,
        });
        return userModel;
      }
      return null;
    } catch (e, stackTrace) {
      logError('Lỗi đăng ký',
          data: {'email': email}, error: e, stackTrace: stackTrace);
      throw handleError(e, stackTrace: stackTrace);
    }
  }

  /// Đăng nhập người dùng
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        // Lấy thông tin người dùng từ Firestore
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final userModel = UserModel.fromMap(userDoc.data()!, user.uid);
          logInfo('Đăng nhập thành công cho user: ${user.uid}',
              data: {'email': email});
          return userModel;
        }
      }
      return null;
    } catch (e, stackTrace) {
      logError('Lỗi đăng nhập',
          data: {'email': email}, error: e, stackTrace: stackTrace);
      throw handleError(e, stackTrace: stackTrace);
    }
  }

  /// Đăng nhập bằng Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // GoogleSignIn v7+ API - use singleton instance
      final googleSignIn = GoogleSignIn.instance;
      
      // Initialize with clientId if needed (usually from config files)
      await googleSignIn.initialize();
      
      // Authenticate user - this shows the Google Sign-In UI and returns the account
      final GoogleSignInAccount googleUser;
      if (googleSignIn.supportsAuthenticate()) {
        googleUser = await googleSignIn.authenticate();
      } else {
        logError('Platform does not support authenticate()');
        return null;
      }

      // Get authentication tokens (idToken for Firebase)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      
      if (googleAuth.idToken == null) {
        logError('Failed to get ID token from Google authentication');
        return null;
      }

      // Get authorization for accessing Google services (to get accessToken)
      final scopes = ['email', 'profile'];
      final auth = await googleUser.authorizationClient.authorizationForScopes(scopes);

      // Create Firebase credential with ID token and optional access token
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken!,
        accessToken: auth?.accessToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Check if user document exists in Firestore
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        final now = DateTime.now();
        UserModel userModel;

        if (userDoc.exists) {
          // Update existing user
          userModel = UserModel.fromMap(userDoc.data()!, user.uid);
          
          // Update last login and photo URL if changed
          await _firestore.collection('users').doc(user.uid).update({
            'updated_at': Timestamp.fromDate(now),
            'photo_url': user.photoURL,
            'name': user.displayName ?? userModel.name,
          });
          
          userModel = userModel.copyWith(
            photoUrl: user.photoURL,
            updatedAt: now,
            name: user.displayName ?? userModel.name,
          );
        } else {
          // Create new user document
          userModel = UserModel(
            userId: user.uid,
            name: user.displayName ?? 'User',
            email: user.email ?? '',
            photoUrl: user.photoURL,
            createdAt: now,
            updatedAt: now,
          );

          await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
          
          // Create default categories for new user
          await _createDefaultCategories(user.uid);
        }

        logInfo('Đăng nhập Google thành công cho user: ${user.uid}', data: {
          'email': user.email,
          'name': user.displayName,
        });
        
        return userModel;
      }

      return null;
    } catch (e, stackTrace) {
      logError('Lỗi khi đăng nhập Google', error: e, stackTrace: stackTrace);
      throw handleError(e, stackTrace: stackTrace);
    }
  }

  /// Đăng nhập ẩn danh (Anonymous)
  Future<UserModel?> signInAnonymously() async {
    return await handleErrorSafelyAsync<UserModel?>(
      () async {
        // Kiểm tra kết nối internet
        final connectivity = await Connectivity().checkConnectivity();
        final isOnline = !connectivity.contains(ConnectivityResult.none);

        if (isOnline) {
          // Đăng nhập anonymous online
          return await _signInAnonymouslyOnline();
        } else {
          // Đăng nhập anonymous offline
          return await _signInAnonymouslyOffline();
        }
      },
      context: 'AuthService.signInAnonymously',
    );
  }

  /// Đăng nhập anonymous online
  Future<UserModel?> _signInAnonymouslyOnline() async {
    final UserCredential result = await _auth.signInAnonymously();
    final User? user = result.user;

    if (user != null) {
      // Tạo hoặc lấy thông tin user từ Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      UserModel userModel;
      if (userDoc.exists) {
        // Anonymous user đã tồn tại - lấy thông tin từ Firestore
        userModel = UserModel.fromMap(userDoc.data()!, user.uid);
        logInfo(
            'Đăng nhập anonymous thành công cho user hiện tại: ${user.uid}');
      } else {
        // Anonymous user mới - tạo document mới
        final now = DateTime.now();
        userModel = UserModel(
          userId: user.uid,
          name: 'Khách', // Tên mặc định cho anonymous user
          email: '', // Anonymous user không có email
          createdAt: now,
          updatedAt: now,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());

        // Tạo danh mục mặc định cho anonymous user mới
        await _createDefaultCategories(user.uid);

        logInfo('Tạo anonymous user mới thành công: ${user.uid}');
      }

      // Lưu session cho offline
      await _saveOfflineSession(userModel);

      return userModel;
    }
    return null;
  }

  /// Đăng nhập anonymous offline
  Future<UserModel?> _signInAnonymouslyOffline() async {
    // Tạo user ID offline tạm thời
    final userId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final userModel = UserModel(
      userId: userId,
      name: 'Khách (Offline)',
      email: '',
      createdAt: now,
      updatedAt: now,
    );

    // Lưu session offline
    await _saveOfflineSession(userModel);

    logInfo('Tạo anonymous user offline: $userId');
    return userModel;
  }

  /// Lưu session offline
  Future<void> _saveOfflineSession(UserModel user) async {
    try {
      final offlineService = OfflineService();
      await offlineService.saveOfflineUserSession(
        userId: user.userId,
        userName: user.name,
        email: user.email.isNotEmpty ? user.email : null,
      );
    } catch (e) {
      logError('Lỗi lưu session offline', error: e);
    }
  }

  /// Đăng xuất người dùng
  Future<void> logout() async {
    try {
      // Đăng xuất từ Google Sign-In v7+
      try {
        final googleSignIn = GoogleSignIn.instance;
        await googleSignIn.signOut();
      } catch (e) {
        // Ignore Google Sign-In errors (user might not be signed in with Google)
        logError('Lỗi đăng xuất Google Sign-In', error: e);
      }

      // Đăng xuất từ Firebase Auth
      await _auth.signOut();

      // Clear offline session nếu có
      try {
        final offlineService = OfflineService();
        await offlineService.clearAllOfflineData();
      } catch (e) {
        // Ignore offline service errors during logout
        logError('Lỗi xóa dữ liệu offline khi đăng xuất', error: e);
      }

      logInfo('Đăng xuất thành công');
    } catch (e, stackTrace) {
      logError('Lỗi đăng xuất', error: e, stackTrace: stackTrace);
      throw Exception('Không thể đăng xuất: $e');
    }
  }

  /// Cập nhật thông tin người dùng
  Future<void> updateProfile({
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      // Cập nhật email nếu khác với email hiện tại
      if (user.email != email) {
        await user.verifyBeforeUpdateEmail(email);
      }

      // Cập nhật display name
      await user.updateDisplayName(name);

      // Kiểm tra xem document có tồn tại không
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final now = DateTime.now();

      if (userDoc.exists) {
        // Document tồn tại - cập nhật bình thường
        final updateData = {
          'name': name,
          'email': email,
          'updated_at': Timestamp.fromDate(now),
        };

        // Thêm photo URL nếu có
        if (photoUrl != null) {
          updateData['photo_url'] = photoUrl;
        }

        await _firestore.collection('users').doc(user.uid).update(updateData);
      } else {
        // Document không tồn tại - tạo mới
        final newUserData = UserModel(
          userId: user.uid,
          name: name,
          email: email,
          photoUrl: photoUrl,
          createdAt: now,
          updatedAt: now,
        );

        await _firestore.collection('users').doc(user.uid).set(newUserData.toMap());
        
        // Tạo danh mục mặc định cho user mới
        await _createDefaultCategories(user.uid);
        
        logInfo('Tạo document user mới trong Firestore khi cập nhật profile: ${user.uid}');
      }

      logInfo('Cập nhật profile thành công cho user: ${user.uid}');
    } catch (e, stackTrace) {
      logError('Lỗi cập nhật profile', error: e, stackTrace: stackTrace);
      throw handleError(e, stackTrace: stackTrace);
    }
  }

  /// Gửi email reset mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      logInfo('Đã gửi email reset mật khẩu cho: $email');
    } catch (e, stackTrace) {
      logError('Lỗi gửi email reset mật khẩu',
          error: e, stackTrace: stackTrace);
      throw handleError(e, stackTrace: stackTrace);
    }
  }

  /// Đổi mật khẩu
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      // Xác thực lại với mật khẩu hiện tại
      final AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Cập nhật mật khẩu mới
      await user.updatePassword(newPassword);

      logInfo('Đổi mật khẩu thành công cho user: ${user.uid}');
    } catch (e, stackTrace) {
      logError('Lỗi đổi mật khẩu', error: e, stackTrace: stackTrace);
      throw handleError(e, stackTrace: stackTrace);
    }
  }

  /// Lấy thông tin người dùng từ Firestore
  Future<UserModel?> getUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        var userModel = UserModel.fromMap(userData, user.uid);

        // Kiểm tra và cập nhật avatar từ Firebase Auth nếu Firestore không có
        if ((userModel.photoUrl == null || userModel.photoUrl!.isEmpty) &&
            user.photoURL != null) {
          // Cập nhật avatar từ Firebase Auth vào Firestore
          await _firestore.collection('users').doc(user.uid).update({
            'photo_url': user.photoURL,
            'updated_at': Timestamp.fromDate(DateTime.now()),
          });

          userModel = userModel.copyWith(
            photoUrl: user.photoURL,
            updatedAt: DateTime.now(),
          );

          logInfo(
              'Cập nhật avatar từ Firebase Auth vào Firestore cho user: ${user.uid}');
        }

        return userModel;
      }
      return null;
    } catch (e, stackTrace) {
      logError('Lỗi lấy dữ liệu người dùng', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Tạo danh mục mặc định cho user mới
  Future<void> _createDefaultCategories(String userId) async {
    try {
      final categoryService = CategoryService();
      await categoryService.createDefaultCategories();
      logInfo('Tạo danh mục mặc định thành công cho user: $userId');
    } catch (e, stackTrace) {
      logError('Lỗi tạo danh mục mặc định cho user $userId',
          error: e, stackTrace: stackTrace);
      // Không throw exception vì đây không phải lỗi nghiêm trọng
    }
  }
}

/// Service quản lý authentication và tạo tài khoản test
class AuthServiceTest {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Tạo tài khoản test với email và password
  static Future<void> createTestAccount() async {
    try {
      const testEmail = 'test@example.com';
      const testPassword = '123456';

      // Use try-catch to check if account exists
      try {
        await _auth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );
        LoggingService.instance.info(
          'Đã tạo tài khoản test',
          className: 'AuthServiceTest',
          methodName: 'createTestAccount',
          data: {'email': testEmail},
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          LoggingService.instance.info(
            'Tài khoản test đã tồn tại',
            className: 'AuthServiceTest',
            methodName: 'createTestAccount',
            data: {'email': testEmail},
          );
        } else {
          LoggingService.instance.error(
            'Lỗi tạo tài khoản test',
            className: 'AuthServiceTest',
            methodName: 'createTestAccount',
            data: {'email': testEmail, 'code': e.code, 'message': e.message},
            error: e,
          );
        }
      }
    } catch (e) {
      LoggingService.instance.error(
        'Lỗi tạo tài khoản test',
        className: 'AuthServiceTest',
        methodName: 'createTestAccount',
        error: e,
      );
    }
  }

  /// Tạo tài khoản với email test@example.com (backup)
  static Future<void> createBackupTestAccount() async {
    try {
      const testEmail = 'test@example.com';
      const testPassword = '123456';

      try {
        await _auth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );
        LoggingService.instance.info(
          'Đã tạo tài khoản backup',
          className: 'AuthServiceTest',
          methodName: 'createBackupTestAccount',
          data: {'email': testEmail},
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          LoggingService.instance.info(
            'Tài khoản backup đã tồn tại',
            className: 'AuthServiceTest',
            methodName: 'createBackupTestAccount',
            data: {'email': testEmail},
          );
        } else {
          LoggingService.instance.error(
            'Lỗi tạo tài khoản backup',
            className: 'AuthServiceTest',
            methodName: 'createBackupTestAccount',
            data: {'email': testEmail, 'code': e.code, 'message': e.message},
            error: e,
          );
        }
      }
    } catch (e) {
      LoggingService.instance.error(
        'Lỗi tạo tài khoản backup',
        className: 'AuthServiceTest',
        methodName: 'createBackupTestAccount',
        error: e,
      );
    }
  }

  /// Đăng nhập với tài khoản test
  static Future<UserCredential?> signInWithTestAccount() async {
    try {
      const testEmail = 'test@example.com';
      const testPassword = '123456';

      final credential = await _auth.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );

      LoggingService.instance.info(
        'Đăng nhập thành công với tài khoản test',
        className: 'AuthServiceTest',
        methodName: 'signInWithTestAccount',
        data: {'email': testEmail},
      );
      return credential;
    } catch (e) {
      LoggingService.instance.error(
        'Lỗi đăng nhập với tài khoản test',
        className: 'AuthServiceTest',
        methodName: 'signInWithTestAccount',
        error: e,
      );
      return null;
    }
  }

  /// Đăng xuất
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      LoggingService.instance.info(
        'Đăng xuất thành công',
        className: 'AuthServiceTest',
        methodName: 'signOut',
      );
    } catch (e) {
      LoggingService.instance.error(
        'Lỗi đăng xuất',
        className: 'AuthServiceTest',
        methodName: 'signOut',
        error: e,
      );
    }
  }
}

// =============================================================================
// RIVERPOD PROVIDERS
// =============================================================================

/// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Auth State Provider - Stream theo dõi trạng thái đăng nhập
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Current User Provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});
