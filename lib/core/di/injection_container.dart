import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import '../../screens/assistant/services/real_data_service.dart';
import '../../services/services.dart';
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

  // Chart Data Service
  getIt.registerLazySingleton<ChartDataService>(() => ChartDataService(
        transactionService: getIt<TransactionService>(),
        categoryService: getIt<CategoryService>(),
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
  getIt.registerLazySingleton<ConversationService>(() => ConversationService());

  // ==========================================================================
  // NEW AI SERVICES
  // ==========================================================================

  // Real Data Service for Assistant modules
  getIt.registerLazySingleton<RealDataService>(() => RealDataService());

  // Initialize AI services after registration
  await getIt<RealDataService>().initialize();

  // Validation Services
  getIt.registerLazySingleton<AdvancedValidationService>(
      () => AdvancedValidationService());
  getIt.registerLazySingleton<DuplicateDetectionService>(
      () => DuplicateDetectionService());
  getIt.registerLazySingleton<TransactionValidationService>(
      () => TransactionValidationService());
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
ChartDataService get chartDataService => getIt<ChartDataService>();
BudgetAlertService get budgetAlertService => getIt<BudgetAlertService>();
ReportService get reportService => getIt<ReportService>();
OCRService get ocrService => getIt<OCRService>();
AIProcessorService get aiProcessorService => getIt<AIProcessorService>();
ChatLogService get chatLogService => getIt<ChatLogService>();
ConversationService get conversationService => getIt<ConversationService>();

// Validation Services
AdvancedValidationService get advancedValidationService =>
    getIt<AdvancedValidationService>();
DuplicateDetectionService get duplicateDetectionService =>
    getIt<DuplicateDetectionService>();
TransactionValidationService get transactionValidationService =>
    getIt<TransactionValidationService>();
