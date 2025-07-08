import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class ProviderConflictTestWidget extends ConsumerStatefulWidget {
  const ProviderConflictTestWidget({super.key});

  @override
  ConsumerState<ProviderConflictTestWidget> createState() => _ProviderConflictTestWidgetState();
}

class _ProviderConflictTestWidgetState extends ConsumerState<ProviderConflictTestWidget> {
  final _authService = AuthService();
  final _emailController = TextEditingController(text: 'test@example.com');
  final _passwordController = TextEditingController(text: '123456');
  
  bool _isLoading = false;
  String _status = '';
  UserModel? _currentUser;
  List<String> _signInMethods = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getUserData();
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(currentUser.email!);
        setState(() {
          _currentUser = user;
          _signInMethods = methods;
          _status = 'Đã đăng nhập: ${currentUser.email}';
        });
      } else {
        setState(() {
          _currentUser = null;
          _signInMethods = [];
          _status = 'Chưa đăng nhập';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Lỗi load user: $e';
      });
    }
  }

  Future<void> _signInWithEmailPassword() async {
    setState(() {
      _isLoading = true;
      _status = 'Đang đăng nhập với email/password...';
    });

    try {
      final result = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (result != null) {
        await _loadCurrentUser();
        setState(() {
          _status = 'Đăng nhập email/password thành công!';
        });
      } else {
        setState(() {
          _status = 'Đăng nhập email/password thất bại!';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Lỗi đăng nhập email/password: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _status = 'Đang đăng nhập với Google...';
    });

    try {
      final result = await _authService.signInWithGoogle();

      if (result != null) {
        await _loadCurrentUser();
        setState(() {
          _status = 'Đăng nhập Google thành công!';
        });
      } else {
        setState(() {
          _status = 'Đăng nhập Google bị hủy!';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Lỗi đăng nhập Google: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
      _status = 'Đang đăng xuất...';
    });

    try {
      await _authService.logout();
      await _loadCurrentUser();
      setState(() {
        _status = 'Đăng xuất thành công!';
      });
    } catch (e) {
      setState(() {
        _status = 'Lỗi đăng xuất: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkSignInMethods() async {
    if (_emailController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _status = 'Đang kiểm tra sign-in methods...';
    });

    try {
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(_emailController.text.trim());
      setState(() {
        _signInMethods = methods;
        _status = 'Các phương thức đăng nhập cho ${_emailController.text}: ${methods.join(', ')}';
      });
    } catch (e) {
      setState(() {
        _status = 'Lỗi kiểm tra sign-in methods: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Conflict Test'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current User Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin hiện tại',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_currentUser != null) ...[
                      Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.orange,
                            child: _currentUser!.photoUrl != null && _currentUser!.photoUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(25),
                                    child: Image.network(
                                      _currentUser!.photoUrl!,
                                      fit: BoxFit.cover,
                                      width: 50,
                                      height: 50,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Text(
                                          _currentUser!.name.isNotEmpty ? _currentUser!.name[0].toUpperCase() : 'U',
                                          style: const TextStyle(color: Colors.white, fontSize: 16),
                                        );
                                      },
                                    ),
                                  )
                                : Text(
                                    _currentUser!.name.isNotEmpty ? _currentUser!.name[0].toUpperCase() : 'U',
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Name: ${_currentUser!.name}'),
                                Text('Email: ${_currentUser!.email}'),
                                Text('Avatar: ${_currentUser!.photoUrl ?? 'Không có'}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Sign-in Methods: ${_signInMethods.join(', ')}'),
                    ] else ...[
                      const Text('Chưa đăng nhập'),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Email/Password Input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email/Password Login',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signInWithEmailPassword,
                            child: const Text('Login'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _checkSignInMethods,
                            child: const Text('Check Methods'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Google Sign-In
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Sign-In',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Sign in with Google'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Logout
            ElevatedButton(
              onPressed: _isLoading ? null : _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),

            const SizedBox(height: 20),

            // Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    if (_isLoading) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
