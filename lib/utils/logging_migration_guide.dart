// Migration Guide: Cách cập nhật từ hệ thống log cũ sang mới
// ===============================================================

// TRƯỚC (Cũ):
// class SomeService {
//   final Logger _logger = Logger();
//   
//   void someMethod() {
//     try {
//       // business logic
//       _logger.i('Success message');
//     } catch (e) {
//       _logger.e('Error: $e');
//       throw Exception('User friendly message');
//     }
//   }
// }

// SAU (Mới):
// class SomeService {
//   // Bỏ Logger _logger
//   
//   void someMethod() {
//     try {
//       // business logic
//       this.logInfo('Success message', data: {'key': 'value'});
//     } catch (e, stackTrace) {
//       this.logError('Error occurred', error: e, stackTrace: stackTrace);
//       
//       // Sử dụng ErrorHandler để xử lý lỗi
//       final appError = this.handleError(e, stackTrace: stackTrace);
//       throw appError;
//     }
//   }
// }

// TRONG UI WIDGET (Cũ):
// ScaffoldMessenger.of(context).showSnackBar(
//   SnackBar(content: Text('Some message')),
// );

// TRONG UI WIDGET (Mới):
// context.showSuccessMessage('Success message');
// context.showErrorMessage('Error message');
// context.showWarningMessage('Warning message');
// context.showInfoMessage('Info message');

// HOẶC:
// this.handleErrorWithUI(context, error, showSnackBar: true);

import '../services/logging_service.dart';
import '../services/error_handler.dart';
import '../services/notification_service.dart';

/// Class demo việc sử dụng hệ thống log mới
class DemoService {
  /// Ví dụ method sử dụng hệ thống log mới
  Future<String> createSomething(String name) async {
    try {
      // Log debug info
      this.logDebug('Starting createSomething', data: {'name': name});
      
      // Business logic here
      await Future.delayed(const Duration(seconds: 1));
      
      if (name.isEmpty) {
        throw const FormatException('Name cannot be empty');
      }
      
      // Log success
      this.logInfo('Successfully created something', data: {
        'name': name,
        'id': 'generated-id',
      });
      
      return 'generated-id';
    } catch (e, stackTrace) {
      // Log error với đầy đủ context
      this.logError(
        'Failed to create something',
        data: {'name': name},
        error: e,
        stackTrace: stackTrace,
      );
      
      // Xử lý lỗi và throw AppError thay vì Exception
      final appError = this.handleError(e, stackTrace: stackTrace);
      throw appError;
    }
  }
  
  /// Ví dụ method có UI interaction
  Future<void> createSomethingWithUI(context, String name) async {
    try {
      // Hiển thị loading
      await context.showLoadingDialog('Đang tạo...');
      
      final id = await createSomething(name);
      
      // Ẩn loading
      context.hideLoadingDialog();
      
      // Hiển thị thành công
      context.showSuccessMessage('Tạo thành công với ID: $id');
      
    } catch (e, stackTrace) {
      // Ẩn loading nếu có lỗi
      context.hideLoadingDialog();
      
      // Xử lý lỗi và hiển thị UI
      this.handleErrorWithUI(
        context,
        e,
        stackTrace: stackTrace,
        contextInfo: 'createSomethingWithUI',
        showSnackBar: true,
      );
    }
  }
}

/// Ví dụ migration cho AuthService method register
class AuthServiceMigrationExample {
  Future<String> registerUser(String email, String password, String name) async {
    try {
      // Log bắt đầu process
      this.logInfo('Starting user registration', data: {
        'email': email,
        'name': name,
      });
      
      // Business logic...
      // final result = await _auth.createUserWithEmailAndPassword(...);
      
      // Log thành công với đầy đủ context
      this.logInfo('User registration successful', data: {
        'email': email,
        'userId': 'user-id',
        'name': name,
      });
      
      return 'user-id';
      
    } catch (e, stackTrace) {
      // Log lỗi với context
      this.logError(
        'User registration failed',
        data: {
          'email': email,
          'name': name,
        },
        error: e,
        stackTrace: stackTrace,
      );
      
      // Xử lý lỗi thống nhất
      final appError = this.handleError(e, stackTrace: stackTrace);
      throw appError;
    }
  }
}

/// Pattern để update tất cả service:
/// 
/// 1. Bỏ: final Logger _logger = Logger();
/// 2. Thay: _logger.i('message') => this.logInfo('message')
/// 3. Thay: _logger.e('error: $e') => this.logError('error', error: e)
/// 4. Thay: throw Exception('msg') => throw this.handleError(e)
/// 5. Thay: ScaffoldMessenger => context.showXxxMessage()
/// 
/// Script tự động (có thể chạy bằng regex):
/// Find: _logger\.i\('([^']+)'\);
/// Replace: this.logInfo('$1');
/// 
/// Find: _logger\.e\('([^']+): \$([^']+)'\);
/// Replace: this.logError('$1', error: $2);
/// 
/// Find: throw Exception\('([^']+)'\);
/// Replace: throw this.handleError(Exception('$1'));
/// 
/// Etc...
