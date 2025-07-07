import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

import '../models/user_model.dart';
import 'category_service.dart';
import 'error_handler.dart';
import 'logging_service.dart';

/// Service xử lý xác thực người dùng
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
      logError('Lỗi đăng ký', data: {'email': email}, error: e, stackTrace: stackTrace);
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
          logInfo('Đăng nhập thành công cho user: ${user.uid}', data: {'email': email});
          return userModel;
        }
      }
      return null;
    } catch (e, stackTrace) {
      logError('Lỗi đăng nhập', data: {'email': email}, error: e, stackTrace: stackTrace);
      throw handleError(e, stackTrace: stackTrace);
    }
  }

  /// Đăng nhập bằng Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Kích hoạt flow đăng nhập Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User đã hủy đăng nhập
        return null;
      }

      // Lấy thông tin xác thực từ Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Tạo credential cho Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Đăng nhập với Firebase
      final UserCredential result = await _auth.signInWithCredential(credential);
      final User? user = result.user;

      if (user != null) {
        // Kiểm tra xem user đã tồn tại trong Firestore chưa
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        UserModel userModel;
        if (userDoc.exists) {
          // User đã tồn tại - lấy thông tin từ Firestore
          userModel = UserModel.fromMap(userDoc.data()!, user.uid);
          logInfo('Đăng nhập Google thành công cho user hiện tại: ${user.uid}');
        } else {
          // User mới - tạo document mới
          final now = DateTime.now();
          userModel = UserModel(
            userId: user.uid,
            name: user.displayName ?? 'User',
            email: user.email ?? '',
            photoUrl: user.photoURL,
            createdAt: now,
            updatedAt: now,
          );

          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(userModel.toMap());

          // Tạo danh mục mặc định cho user mới
          await _createDefaultCategories(user.uid);
          
          logInfo('Đăng nhập Google thành công cho user mới: ${user.uid}');
        }

        return userModel;
      }
      return null;
    } catch (e, stackTrace) {
      logError('Lỗi đăng nhập Google', error: e, stackTrace: stackTrace);
      throw handleError(e, stackTrace: stackTrace);
    }
  }

  /// Đăng xuất người dùng
  Future<void> logout() async {
    try {
      // Đăng xuất từ Google Sign-In
      await _googleSignIn.signOut();
      // Đăng xuất từ Firebase Auth
      await _auth.signOut();
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

      // Cập nhật thông tin trong Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'name': name,
        'email': email,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });

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
      logError('Lỗi gửi email reset mật khẩu', error: e, stackTrace: stackTrace);
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
        return UserModel.fromMap(userDoc.data()!, user.uid);
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
      logError('Lỗi tạo danh mục mặc định cho user $userId', error: e, stackTrace: stackTrace);
      // Không throw exception vì đây không phải lỗi nghiêm trọng
    }
  }
}

/// Service quản lý authentication và tạo tài khoản test
class AuthServiceTest {
  static final Logger _logger = Logger();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Tạo tài khoản test với email và password
  static Future<void> createTestAccount() async {
    try {
      const testEmail = '9588666@gmail.com';
      const testPassword = '123456';

      // Kiểm tra xem tài khoản đã tồn tại chưa
      final methods = await _auth.fetchSignInMethodsForEmail(testEmail);

      if (methods.isEmpty) {
        // Tài khoản chưa tồn tại, tạo mới
        await _auth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );

        _logger.i('Đã tạo tài khoản test: $testEmail');
      } else {
        _logger.i('Tài khoản test đã tồn tại: $testEmail ✅');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _logger.i('Tài khoản test đã tồn tại: 9588666@gmail.com ✅');
      } else {
        _logger.w('Lỗi kiểm tra tài khoản test: ${e.code} - ${e.message}');
      }
    } catch (e) {
      _logger.w('Lỗi tạo tài khoản test: $e');
    }
  }

  /// Tạo tài khoản với email test@example.com (backup)
  static Future<void> createBackupTestAccount() async {
    try {
      const testEmail = 'test@example.com';
      const testPassword = '123456';

      // Kiểm tra xem tài khoản đã tồn tại chưa
      final methods = await _auth.fetchSignInMethodsForEmail(testEmail);

      if (methods.isEmpty) {
        // Tài khoản chưa tồn tại, tạo mới
        await _auth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );

        _logger.i('Đã tạo tài khoản backup: $testEmail');
      } else {
        _logger.i('Tài khoản backup đã tồn tại: $testEmail ✅');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _logger.i('Tài khoản backup đã tồn tại: test@example.com ✅');
      } else {
        _logger.w('Lỗi kiểm tra tài khoản backup: ${e.code} - ${e.message}');
      }
    } catch (e) {
      _logger.w('Lỗi tạo tài khoản backup: $e');
    }
  }

  /// Đăng nhập với tài khoản test
  static Future<UserCredential?> signInWithTestAccount() async {
    try {
      const testEmail = '9588666@gmail.com';
      const testPassword = '123456';

      final credential = await _auth.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );

      _logger.i('Đăng nhập thành công với tài khoản test');
      return credential;
    } catch (e) {
      _logger.e('Lỗi đăng nhập với tài khoản test: $e');
      return null;
    }
  }

  /// Đăng xuất
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      _logger.i('Đăng xuất thành công');
    } catch (e) {
      _logger.e('Lỗi đăng xuất: $e');
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
