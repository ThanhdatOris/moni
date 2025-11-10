import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/injection_container.dart' as di;
import '../auth/auth_service.dart';

/// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return di.getIt<AuthService>();
});

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

/// Is Authenticated Provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

