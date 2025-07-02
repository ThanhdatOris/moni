import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;

  @override
  void initState() {
    super.initState();
    // Điền sẵn tài khoản test với email 9588666@gmail.com
    _emailController.text = '9588666@gmail.com';
    _passwordController.text = '123456';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Thêm timeout để tránh treo vô thời hạn
      await Future.any([
        _performAuthentication(),
        Future.delayed(const Duration(seconds: 15), () {
          throw Exception(
              'Timeout: Kết nối đến Firebase bị treo. Vui lòng kiểm tra cấu hình Firebase và kết nối mạng.');
        }),
      ]);
    } on FirebaseAuthException catch (e) {
      String message = _getFirebaseErrorMessage(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      String message = _getErrorMessage(e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
            action: e.toString().contains('configuration') ||
                    e.toString().contains('.env')
                ? SnackBarAction(
                    label: 'Hướng dẫn',
                    textColor: Colors.white,
                    onPressed: () {
                      _showConfigurationDialog();
                    },
                  )
                : null,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performAuthentication() async {
    if (_isSignUp) {
      // Đăng ký tài khoản mới
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      // Đăng nhập
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này';
      case 'wrong-password':
        return 'Mật khẩu không đúng';
      case 'email-already-in-use':
        return 'Email đã được sử dụng';
      case 'weak-password':
        return 'Mật khẩu quá yếu';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng thử lại sau vài phút';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet';
      case 'invalid-credential':
        return 'Thông tin đăng nhập không đúng. Vui lòng kiểm tra lại';
      case 'configuration-not-found':
        return 'Lỗi cấu hình Firebase. Vui lòng kiểm tra file .env';
      default:
        return e.message ?? 'Đã xảy ra lỗi xác thực';
    }
  }

  String _getErrorMessage(dynamic e) {
    final errorString = e.toString().toLowerCase();

    if (errorString.contains('configuration') ||
        errorString.contains('your-project-id') ||
        errorString.contains('.env')) {
      return 'Chưa có file .env hoặc cấu hình Firebase không đúng. Nhấn "Hướng dẫn" để xem cách thiết lập.';
    }

    if (errorString.contains('timeout')) {
      return 'Kết nối bị timeout. Kiểm tra mạng và cấu hình Firebase.';
    }

    if (errorString.contains('network')) {
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.';
    }

    return 'Lỗi: $e';
  }

  void _showConfigurationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Thiết lập Firebase'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Để sử dụng ứng dụng, bạn cần tạo file .env với thông tin Firebase:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('1. Copy file "env_template.txt" thành ".env"'),
                SizedBox(height: 8),
                Text('2. Truy cập Firebase Console'),
                SizedBox(height: 8),
                Text('3. Vào Project Settings > General'),
                SizedBox(height: 8),
                Text('4. Copy các thông tin:'),
                SizedBox(height: 4),
                Text('   - Project ID'),
                Text('   - API Key'),
                Text('   - App ID'),
                Text('   - Messaging Sender ID'),
                SizedBox(height: 8),
                Text('5. Thay thế các giá trị "your-*" trong file .env'),
                SizedBox(height: 16),
                Text(
                  'Lưu ý: File .env sẽ không được commit vào git.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Đã hiểu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 80),

                // Logo hoặc tiêu đề
                Text(
                  'Chào mừng đến với Moni',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Quản lý tài chính thông minh',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!value.contains('@')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isSignUp ? 'Đăng ký' : 'Đăng nhập',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),

                const SizedBox(height: 16),

                // Toggle sign up/sign in
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                    });
                  },
                  child: Text(
                    _isSignUp
                        ? 'Đã có tài khoản? Đăng nhập'
                        : 'Chưa có tài khoản? Đăng ký',
                  ),
                ),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.grey300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'hoặc',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.grey300)),
                  ],
                ),

                const SizedBox(height: 24),

                // Anonymous sign in
                OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() {
                            _isLoading = true;
                          });

                          try {
                            await FirebaseAuth.instance.signInAnonymously();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Lỗi đăng nhập khách: $e')),
                              );
                            }
                          }

                          if (!mounted) return;
                          setState(() {
                            _isLoading = false;
                          });
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Đăng nhập khách',
                    style: TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 40),

                // Test account info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.grey300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tài khoản test:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    setState(() {
                                      _isLoading = true;
                                    });

                                    try {
                                      await FirebaseAuth.instance
                                          .signInWithEmailAndPassword(
                                        email: '9588666@gmail.com',
                                        password: '123456',
                                      );
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text('Lỗi: $e')),
                                        );
                                      }
                                    }

                                    if (!mounted) return;
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Đăng nhập test',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Email: 9588666@gmail.com',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        'Mật khẩu: 123456',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
