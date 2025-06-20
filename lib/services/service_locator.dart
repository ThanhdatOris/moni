import 'package:get_it/get_it.dart';
import 'services.dart';

/// Service locator để quản lý dependency injection
final GetIt serviceLocator = GetIt.instance;

/// Khởi tạo tất cả services
void setupServiceLocator() {
  // Đăng ký các services
  serviceLocator.registerLazySingleton<AuthService>(() => AuthService());
  serviceLocator.registerLazySingleton<TransactionService>(() => TransactionService());
  serviceLocator.registerLazySingleton<CategoryService>(() => CategoryService());
  serviceLocator.registerLazySingleton<BudgetAlertService>(() => BudgetAlertService());
  serviceLocator.registerLazySingleton<ChatLogService>(() => ChatLogService());
  serviceLocator.registerLazySingleton<ReportService>(() => ReportService());
  serviceLocator.registerLazySingleton<AIProcessorService>(() => AIProcessorService());
} 