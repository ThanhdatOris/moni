import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

// Legacy Services - Simple architecture
import '../../services/ai_processor_service.dart';
import '../../services/auth_service.dart';
import '../../services/budget_alert_service.dart';
import '../../services/category_service.dart';
import '../../services/chat_log_service.dart';
import '../../services/environment_service.dart';
import '../../services/firebase_service.dart';
import '../../services/report_service.dart';
import '../../services/transaction_service.dart';

final getIt = GetIt.instance;

/// Simple Dependency Injection for Legacy Architecture
/// Focus: Make app run quickly without over-engineering
Future<void> init() async {
  // ==========================================================================
  // EXTERNAL DEPENDENCIES
  // ==========================================================================
  
  // Firebase
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());

  // ==========================================================================
  // CORE SERVICES 
  // ==========================================================================

  getIt.registerLazySingleton<EnvironmentService>(() => EnvironmentService());
  getIt.registerLazySingleton<FirebaseService>(() => FirebaseService());

  // ==========================================================================
  // BUSINESS SERVICES (Legacy)
  // ==========================================================================

  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<TransactionService>(() => TransactionService());
  getIt.registerLazySingleton<CategoryService>(() => CategoryService());
  getIt.registerLazySingleton<BudgetAlertService>(() => BudgetAlertService());
  getIt.registerLazySingleton<ReportService>(() => ReportService());
  getIt.registerLazySingleton<AIProcessorService>(() => AIProcessorService());
  getIt.registerLazySingleton<ChatLogService>(() => ChatLogService());
}

/// Reset dependencies (for testing)
Future<void> reset() async {
  await getIt.reset();
}

// ==========================================================================
// CONVENIENCE GETTERS
// ==========================================================================

// Firebase
FirebaseAuth get firebaseAuth => getIt<FirebaseAuth>();
FirebaseFirestore get firestore => getIt<FirebaseFirestore>();
Connectivity get connectivity => getIt<Connectivity>();

// Core Services
EnvironmentService get environmentService => getIt<EnvironmentService>();
FirebaseService get firebaseService => getIt<FirebaseService>();

// Business Services
AuthService get authService => getIt<AuthService>();
TransactionService get transactionService => getIt<TransactionService>();
CategoryService get categoryService => getIt<CategoryService>();
BudgetAlertService get budgetAlertService => getIt<BudgetAlertService>();
ReportService get reportService => getIt<ReportService>();
AIProcessorService get aiProcessorService => getIt<AIProcessorService>();
ChatLogService get chatLogService => getIt<ChatLogService>(); 