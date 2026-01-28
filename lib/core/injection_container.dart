import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:moni/services/services.dart';

import '../screens/assistant/services/real_data_service.dart';

final getIt = GetIt.instance;

/// Simple Dependency Injection for Legacy Architecture
/// Focus: Make app run quickly without over-engineering
Future<void> init() async {
  // ==========================================================================
  // EXTERNAL DEPENDENCIES
  // ==========================================================================

  // Firebase - Persistence đã được enable trong FirebaseService
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );
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

  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<CategoryService>(() => CategoryService());

  // Transaction service - Offline-First với Firestore Persistence
  getIt.registerLazySingleton<TransactionService>(() => TransactionService());

  // Budget service - use TransactionService (V1 for now, V2 later)
  getIt.registerLazySingleton<BudgetService>(() {
    final budgetService = BudgetService();
    budgetService.setTransactionService(getIt<TransactionService>());
    budgetService.setCategoryService(getIt<CategoryService>());
    return budgetService;
  });

  // Chart Data Service
  getIt.registerLazySingleton<ChartDataService>(
    () => ChartDataService(
      transactionService: getIt<TransactionService>(),
      categoryService: getIt<CategoryService>(),
    ),
  );

  // Services that depend on TransactionService
  getIt.registerLazySingleton<BudgetAlertService>(
    () => BudgetAlertService(transactionService: getIt<TransactionService>()),
  );
  getIt.registerLazySingleton<ReportService>(
    () => ReportService(transactionService: getIt<TransactionService>()),
  );

  // Sync service V2 - Simple cleanup service

  // Anonymous conversion service
  getIt.registerLazySingleton<AnonymousConversionService>(
    () => AnonymousConversionService(),
  );

  // ==========================================================================
  // FACTORY SERVICES (Need disposal after use)
  // ==========================================================================

  // ✅ OCR Service - Factory pattern để dispose sau mỗi lần dùng
  // Fix memory leak: ML Kit TextRecognizer (~30-50 MB native memory)
  // Must call dispose() after each use to free native resources
  getIt.registerFactory<OCRService>(() => OCRService());

  // ==========================================================================
  // SINGLETON SERVICES (Persistent throughout app lifecycle)
  // ==========================================================================

  // Other services
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
    () => AdvancedValidationService(),
  );
  getIt.registerLazySingleton<DuplicateDetectionService>(
    () => DuplicateDetectionService(),
  );
  getIt.registerLazySingleton<TransactionValidationService>(
    () => TransactionValidationService(),
  );
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
