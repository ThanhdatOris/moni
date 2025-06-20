import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

import '../models/user_model.dart';

/// Service xử lý xác thực người dùng
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

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

        _logger.i('Đăng ký thành công cho user: ${user.uid}');
        return userModel;
      }
      return null;
    } catch (e) {
      _logger.e('Lỗi đăng ký: $e');
      throw _handleAuthException(e);
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
          _logger.i('Đăng nhập thành công cho user: ${user.uid}');
          return userModel;
        }
      }
      return null;
    } catch (e) {
      _logger.e('Lỗi đăng nhập: $e');
      throw _handleAuthException(e);
    }
  }

  /// Đăng xuất người dùng
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _logger.i('Đăng xuất thành công');
    } catch (e) {
      _logger.e('Lỗi đăng xuất: $e');
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
        await user.updateEmail(email);
      }

      // Cập nhật display name
      await user.updateDisplayName(name);

      // Cập nhật thông tin trong Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'name': name,
        'email': email,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });

      _logger.i('Cập nhật profile thành công cho user: ${user.uid}');
    } catch (e) {
      _logger.e('Lỗi cập nhật profile: $e');
      throw _handleAuthException(e);
    }
  }

  /// Gửi email reset mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _logger.i('Đã gửi email reset mật khẩu cho: $email');
    } catch (e) {
      _logger.e('Lỗi gửi email reset mật khẩu: $e');
      throw _handleAuthException(e);
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

      _logger.i('Đổi mật khẩu thành công cho user: ${user.uid}');
    } catch (e) {
      _logger.e('Lỗi đổi mật khẩu: $e');
      throw _handleAuthException(e);
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
    } catch (e) {
      _logger.e('Lỗi lấy dữ liệu người dùng: $e');
      return null;
    }
  }

  /// Xử lý exception từ Firebase Auth
  Exception _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return Exception('Không tìm thấy tài khoản với email này');
        case 'wrong-password':
          return Exception('Mật khẩu không chính xác');
        case 'email-already-in-use':
          return Exception('Email này đã được sử dụng');
        case 'weak-password':
          return Exception('Mật khẩu quá yếu');
        case 'invalid-email':
          return Exception('Email không hợp lệ');
        case 'operation-not-allowed':
          return Exception('Thao tác này không được phép');
        case 'too-many-requests':
          return Exception('Quá nhiều yêu cầu, vui lòng thử lại sau');
        default:
          return Exception('Lỗi xác thực: ${e.message}');
      }
    }
    return Exception('Đã xảy ra lỗi: $e');
  }
}
