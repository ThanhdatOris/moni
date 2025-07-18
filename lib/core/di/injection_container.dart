import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

// Legacy Services - Simple architecture
import '../../services/ai_processor_service.dart';
import '../../services/anonymous_conversion_service.dart';
import '../../services/auth_service.dart';
import '../../services/budget_alert_service.dart';
import '../../services/category_service.dart';
import '../../services/chat_log_service.dart';
import '../../services/environment_service.dart';
import '../../services/firebase_service.dart';
import '../../services/ocr_service.dart';
import '../../services/offline_service.dart';
import '../../services/offline_sync_service.dart';
import '../../services/report_service.dart';
import '../../services/transaction_service.dart';

// New AI Services
import '../../services/ai_analytics_service.dart';
import '../../services/ai_budget_agent_service.dart';
import '../../services/advanced_validation_service.dart';
import '../../services/duplicate_detection_service.dart';
import '../../services/transaction_validation_service.dart';

final getIt = GetIt.instance;

/// Simple Dependency Injection for Legacy Architecture
/// Focus: Make app run quickly without over-engineering
Future<void> init() async {
  // ==========================================================================
  // EXTERNAL DEPENDENCIES
  // ==========================================================================

  // Firebase
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance);
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());

  // ==========================================================================
  // CORE SERVICES
  // ==========================================================================

  getIt.registerLazySingleton<EnvironmentService>(() => EnvironmentService());
  getIt.registerLazySingleton<FirebaseService>(() => FirebaseService());

  // ==========================================================================
  // BUSINESS SERVICES (Legacy)
  // ==========================================================================

  // Core services first
  getIt.registerLazySingleton<OfflineService>(() => OfflineService());
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<CategoryService>(() => CategoryService());

  // Transaction service with offline support
  getIt.registerLazySingleton<TransactionService>(() => TransactionService(
        offlineService: getIt<OfflineService>(),
      ));

  // Services that depend on TransactionService
  getIt.registerLazySingleton<BudgetAlertService>(() => BudgetAlertService(
        transactionService: getIt<TransactionService>(),
      ));
  getIt.registerLazySingleton<ReportService>(() => ReportService(
        transactionService: getIt<TransactionService>(),
      ));

  // Sync service
  getIt.registerLazySingleton<OfflineSyncService>(() => OfflineSyncService(
        offlineService: getIt<OfflineService>(),
        transactionService: getIt<TransactionService>(),
        categoryService: getIt<CategoryService>(),
      ));

  // Anonymous conversion service
  getIt.registerLazySingleton<AnonymousConversionService>(
      () => AnonymousConversionService(
            offlineService: getIt<OfflineService>(),
            syncService: getIt<OfflineSyncService>(),
          ));

  // Other services
  getIt.registerLazySingleton<OCRService>(() => OCRService());
  getIt.registerLazySingleton<AIProcessorService>(() => AIProcessorService());
  getIt.registerLazySingleton<ChatLogService>(() => ChatLogService());

  // ==========================================================================
  // NEW AI SERVICES
  // ==========================================================================
  
  // AI Analytics Service
  getIt.registerLazySingleton<AIAnalyticsService>(() => AIAnalyticsService());
  
  // AI Budget Agent Service
  getIt.registerLazySingleton<AIBudgetAgentService>(() => AIBudgetAgentService());
  
  // Validation Services
  getIt.registerLazySingleton<AdvancedValidationService>(() => AdvancedValidationService());
  getIt.registerLazySingleton<DuplicateDetectionService>(() => DuplicateDetectionService());
  getIt.registerLazySingleton<TransactionValidationService>(() => TransactionValidationService());
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
OCRService get ocrService => getIt<OCRService>();
AIProcessorService get aiProcessorService => getIt<AIProcessorService>();
ChatLogService get chatLogService => getIt<ChatLogService>();

// AI Services
AIAnalyticsService get aiAnalyticsService => getIt<AIAnalyticsService>();
AIBudgetAgentService get aiBudgetAgentService => getIt<AIBudgetAgentService>();
AdvancedValidationService get advancedValidationService => getIt<AdvancedValidationService>();
DuplicateDetectionService get duplicateDetectionService => getIt<DuplicateDetectionService>();
TransactionValidationService get transactionValidationService => getIt<TransactionValidationService>();
