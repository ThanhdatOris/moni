import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';

import '../core/environment_service.dart';
import 'ocr_service.dart';
import 'ai_category_service.dart';
import 'ai_chat_handler.dart';
import 'ai_response_cache.dart';
import 'ai_text_generator.dart';
import 'ai_token_manager.dart';
import 'ai_transaction_processor.dart';

/// AI Processor Service - Facade Pattern
/// 
/// This is the main entry point for all AI operations.
/// Delegates to specialized modules for specific tasks.
/// 
/// Modules:
/// - AITokenManager: Token quota & rate limiting
/// - AIResponseCache: Smart persistent caching
/// - AICategoryService: Category suggestions
/// - AITextGenerator: Text generation & analysis
/// - AIChatHandler: Chat processing & function calls
/// - AITransactionProcessor: OCR & image processing
class AIProcessorService {
  final Logger _logger = Logger();
  final GetIt _getIt = GetIt.instance;
  
  // Specialized modules
  late final AITokenManager _tokenManager;
  late final AIResponseCache _cache;
  late final AICategoryService _categoryService;
  late final AITextGenerator _textGenerator;
  late final AIChatHandler _chatHandler;
  late final AITransactionProcessor _transactionProcessor;
  
  // Gemini model
  late final GenerativeModel _model;

  AIProcessorService() {
    // Initialize Gemini model
    final apiKey = EnvironmentService.geminiApiKey;

    if (apiKey.isEmpty) {
      throw Exception('Gemini API key not found in environment variables');
    }

    // Define function declarations for chatbot
    final List<FunctionDeclaration> functions = [
      FunctionDeclaration(
        'addTransaction',
        'Add new transaction with intelligent emoji-based categorization',
        Schema(
          SchemaType.object,
          properties: {
            'amount': Schema(SchemaType.string,
                description:
                    'Transaction amount (preserve k/tr format: "18k", "1tr", or plain number)'),
            'description': Schema(SchemaType.string,
                description: 'Transaction description'),
            'category': Schema(SchemaType.string,
                description:
                    'Smart category with auto-emoji assignment: "Ăn uống" (🍽️), "Di chuyển" (🚗), "Mua sắm" (🛒), "Giải trí" (🎬), "Y tế" (🏥), "Học tập" (🏫), "Hóa đơn" (🧾), "Lương" (💼), "Đầu tư" (📈), "Thưởng" (🎁), "Freelance" (💻), "Bán hàng" (💸), or create new category with appropriate name'),
            'type': Schema(SchemaType.string,
                description:
                    'Transaction type: "income" for salary/bonus/earning/selling, "expense" for spending/buying/payments'),
            'date': Schema(SchemaType.string,
                description: 'Transaction date (YYYY-MM-DD), optional'),
          },
          requiredProperties: ['amount', 'description', 'category', 'type'],
        ),
      ),
    ];

    // Try modern model first, with fallback options
    String initializedModel = '';
    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        tools: [Tool(functionDeclarations: functions)],
      );
      initializedModel = 'gemini-1.5-flash';
    } catch (e) {
      try {
        _model = GenerativeModel(
          model: 'gemini-1.5-flash-001',
          apiKey: apiKey,
          tools: [Tool(functionDeclarations: functions)],
        );
        initializedModel = 'gemini-1.5-flash-001';
      } catch (e2) {
        _logger.e('❌ Failed to initialize Gemini models: $e2');
        throw Exception(
            'Could not initialize Gemini model. Please check your API key and internet connection.');
      }
    }

    // Initialize specialized modules
    _tokenManager = AITokenManager();
    _cache = AIResponseCache();
    _cache.loadFromDisk();
    
    _categoryService = AICategoryService(
      model: _model,
      cache: _cache,
      tokenManager: _tokenManager,
    );
    
    _textGenerator = AITextGenerator(
      model: _model,
      tokenManager: _tokenManager,
    );
    
    _chatHandler = AIChatHandler(
      model: _model,
      tokenManager: _tokenManager,
    );
    
    final ocrService = _getIt<OCRService>();
    _transactionProcessor = AITransactionProcessor(
      model: _model,
      ocrService: ocrService,
      tokenManager: _tokenManager,
    );

    _logger.i('🤖 AI Processor Service initialized successfully'
        '\n  Model: $initializedModel'
        '\n  Functions: ${functions.length} available'
        '\n  Modules: 6 specialized services'
        '\n  Token Limit: ${_tokenManager.dailyTokenLimit}/day'
        '\n  Smart Cache: Enabled with tiered priorities');
  }

  // ============================================================================
  // PUBLIC API - Category Suggestions
  // ============================================================================

  /// Suggest category for a single transaction description
  Future<String> suggestCategory(String description) async {
    return await _categoryService.suggestCategory(description);
  }

  /// Batch category suggestions for multiple transactions
  /// Returns Map<description, category>
  Future<Map<String, String>> suggestCategoriesBatch(
      List<String> descriptions) async {
    return await _categoryService.suggestCategoriesBatch(descriptions);
  }

  // ============================================================================
  // PUBLIC API - Text Generation
  // ============================================================================

  /// Generate text from prompt (no caching, direct API call)
  Future<String> generateText(String prompt) async {
    return await _textGenerator.generateText(prompt);
  }

  /// Answer financial questions
  Future<String> answerQuestion(String question) async {
    return await _textGenerator.answerQuestion(question);
  }

  /// Analyze spending habits and give advice
  Future<String> analyzeSpendingHabits(
      Map<String, dynamic> transactionData) async {
    return await _textGenerator.analyzeSpendingHabits(transactionData);
  }

  // ============================================================================
  // PUBLIC API - Chat Processing
  // ============================================================================

  /// Process chat input and return AI response
  Future<String> processChatInput(String input) async {
    return await _chatHandler.processChatInput(input);
  }

  /// Generate welcome message
  String generateWelcomeMessage() {
    return _chatHandler.generateWelcomeMessage();
  }

  // ============================================================================
  // PUBLIC API - Transaction Extraction
  // ============================================================================

  /// Extract transaction from image using OCR + AI
  Future<Map<String, dynamic>> extractTransactionFromImageWithOCR(
      File imageFile) async {
    return await _transactionProcessor.extractTransactionFromImage(imageFile);
  }

  /// Legacy method - delegates to OCR version
  Future<Map<String, dynamic>> extractTransactionFromImage(
      File imageFile) async {
    return await extractTransactionFromImageWithOCR(imageFile);
  }

  /// Validate image before processing
  Future<bool> validateImageForProcessing(File imageFile) async {
    return await _transactionProcessor.validateImageForProcessing(imageFile);
  }

  // ============================================================================
  // PUBLIC API - Token Management
  // ============================================================================

  /// Get token usage statistics
  Future<Map<String, dynamic>> getTokenUsageStats() async {
    return await _tokenManager.getTokenUsageStats();
  }

  /// Force reset token quota (admin tool)
  Future<void> forceResetTokenQuota() async {
    await _tokenManager.forceResetTokenQuota();
  }

  /// Get current daily token count
  int get dailyTokenCount => _tokenManager.dailyTokenCount;

  /// Get daily token limit
  int get dailyTokenLimit => _tokenManager.dailyTokenLimit;

  // ============================================================================
  // PUBLIC API - Cache Management
  // ============================================================================

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return _cache.getStats();
  }

  /// Clear all caches
  void clearAllCaches() {
    _cache.clearAll();
  }

  /// Clear expired cache entries
  void clearExpiredCaches() {
    _cache.clearExpired();
  }
}
