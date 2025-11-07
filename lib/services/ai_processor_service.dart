import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../utils/formatting/currency_formatter.dart';
import 'category_service.dart';
import 'environment_service.dart';
import 'ocr_service.dart';
import 'transaction_service.dart';

/// Service xử lý các chức năng AI sử dụng Gemini API
class AIProcessorService {
  late final GenerativeModel _model;
  final Logger _logger = Logger();
  final GetIt _getIt = GetIt.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache để tránh gọi API trùng lặp
  final Map<String, String> _categoryCache = {};
  static const int _cacheMaxSize = 100;

  // Rate limiting
  DateTime? _lastApiCall;
  static const Duration _minApiInterval = Duration(milliseconds: 500);

  // Token usage tracking
  int _dailyTokenCount = 0;
  DateTime? _lastTokenReset;
  static const int _dailyTokenLimit = 10000;
  
  // SharedPreferences keys for persistent storage
  static const String _keyTokenCount = 'ai_daily_token_count';
  static const String _keyLastTokenReset = 'ai_last_token_reset';

  AIProcessorService() {
    // Load API key from environment variables
    final apiKey = EnvironmentService.geminiApiKey;

    if (apiKey.isEmpty) {
      throw Exception('Gemini API key not found in environment variables');
    }
    
    // Load saved token count from SharedPreferences
    _loadTokenUsage();

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

    // ✅ IMPROVED: Single consolidated initialization log
    _logger.i('🤖 AI Processor Service initialized successfully'
        '\n  Model: $initializedModel'
        '\n  Functions: ${functions.length} available'
        '\n  Token Limit: $_dailyTokenLimit/day'
        '\n  Cache Size: $_cacheMaxSize entries');
  }

  /// Trích xuất thông tin giao dịch từ hình ảnh sử dụng OCR + AI
  Future<Map<String, dynamic>> extractTransactionFromImageWithOCR(
      File imageFile) async {
    try {
      // ✅ IMPROVED: Single consolidated OCR processing log
      _logger
          .i('📷 Starting OCR + AI processing for transaction extraction...');

      // Bước 1: Sử dụng OCR để trích xuất text
      final ocrService = _getIt<OCRService>();
      final ocrResult =
          await ocrService.extractStructuredTextFromImage(imageFile);
      final extractedText = ocrResult['fullText'] as String;
      final ocrConfidence = ocrResult['confidence'] as int;

      if (extractedText.isEmpty) {
        _logger.w('❌ OCR failed to extract text from image');
        return {
          'success': false,
          'error':
              'Không thể đọc được văn bản từ ảnh. Vui lòng chọn ảnh rõ nét hơn.',
          'amount': 0,
          'description': 'Không đọc được',
          'type': 'expense',
          'category_suggestion': 'Khác',
          'confidence': 0,
          'raw_text': '',
        };
      }

      // Bước 2: Phân tích văn bản bằng OCR service
      final ocrAnalysis = ocrService.analyzeReceiptText(extractedText);

      // Bước 3: Sử dụng AI để cải thiện và xác thực kết quả
      final aiAnalysis = await _analyzeTextWithAI(extractedText, ocrAnalysis);

      // Bước 4: Kết hợp kết quả OCR và AI
      final finalResult = _combineOCRAndAI(ocrResult, ocrAnalysis, aiAnalysis);

      // ✅ IMPROVED: Single consolidated success log
      _logger.i('✅ OCR + AI processing completed successfully'
          '\n  Confidence: $ocrConfidence%'
          '\n  Text Length: ${extractedText.length} chars'
          '\n  Processing Method: ${finalResult['processing_method']}'
          '\n  Amount: ${finalResult['amount']}'
          '\n  Category: ${finalResult['category_suggestion']}');
      return finalResult;
    } catch (e) {
      _logger.e('❌ Error in OCR + AI processing: $e');

      String errorMessage = 'Không thể xử lý ảnh';
      if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage = 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.';
      } else if (e.toString().contains('quota') ||
          e.toString().contains('limit')) {
        errorMessage = 'Đã vượt quá giới hạn sử dụng AI hôm nay.';
      } else if (e.toString().contains('API key')) {
        errorMessage = 'Có vấn đề với cấu hình AI. Vui lòng thử lại sau.';
      }

      return {
        'success': false,
        'error': errorMessage,
        'description': 'Không thể đọc được thông tin từ ảnh',
        'amount': 0,
        'type': 'expense',
        'category_suggestion': 'Khác',
        'confidence': 0,
        'raw_text': '',
      };
    }
  }

  /// Phân tích text bằng AI để cải thiện kết quả OCR
  Future<Map<String, dynamic>> _analyzeTextWithAI(
      String text, Map<String, dynamic> ocrAnalysis) async {
    try {
      // Check rate limit and token usage
      await _checkRateLimit();

      // Estimate tokens
      final estimatedTokens = _estimateTokens(text) + 200; // Extra for prompt
      if (_dailyTokenCount + estimatedTokens > _dailyTokenLimit) {
        _logger.w('Daily token limit exceeded, using OCR results only');
        return ocrAnalysis;
      }

      final prompt = '''
Phân tích văn bản hóa đơn sau và trích xuất thông tin giao dịch. Văn bản này đã được OCR từ ảnh hóa đơn.

Văn bản hóa đơn:
"""
$text
"""

Kết quả ban đầu từ OCR:
- Số tiền gợi ý: ${ocrAnalysis['suggestedAmount']}
- Tên cửa hàng: ${ocrAnalysis['merchantName']}
- Loại giao dịch: ${ocrAnalysis['transactionType']}
- Danh mục gợi ý: ${ocrAnalysis['categoryHint']}

Hãy xác minh và cải thiện thông tin, trả về JSON với format:
{
  "verified_amount": số_tiền_chính_xác (số, không có dấu phẩy),
  "description": "mô tả ngắn gọn về giao dịch", 
  "category_suggestion": "danh mục phù hợp bằng tiếng Việt",
  "transaction_type": "expense" hoặc "income",
  "confidence_score": số từ 0-100,
  "notes": "ghi chú bổ sung nếu có"
}

Lưu ý:
- Ưu tiên số tiền lớn nhất thường là tổng tiền
- Danh mục: Ăn uống, Di chuyển, Mua sắm, Giải trí, Y tế, Học tập, Hóa đơn, v.v.
- Hầu hết hóa đơn là "expense"
- Mô tả nên bao gồm thông tin về giao dịch, không cần tách riêng tên cửa hàng
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      await _updateTokenCount(estimatedTokens);

      final responseText = response.text ?? '';
      final parsedResult = _parseAIAnalysisResponse(responseText);

      return parsedResult;
    } catch (e) {
      _logger.e('Error in AI analysis: $e');
      // Fallback to OCR results
      return ocrAnalysis;
    }
  }

  /// Parse AI analysis response (JSON)
  Map<String, dynamic> _parseAIAnalysisResponse(String response) {
    try {
      // Tìm JSON trong response (tránh prefix/suffix văn bản tự do)
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}');

      if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
        return {};
      }

      final jsonString = response.substring(jsonStart, jsonEnd + 1);

      if (EnvironmentService.debugMode) {
        _logger.d('🔍 AI Analysis JSON: ${jsonString.length} chars');
      }

      // Parse JSON thật
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return {};
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(decoded);

      // Chuẩn hoá key và kiểu dữ liệu theo spec
      final double verifiedAmount =
          _parseAmount(data['verified_amount']).toDouble();
      final String description = (data['description'] ?? '').toString();
      final String categorySuggestion =
          (data['category_suggestion'] ?? data['category'] ?? '').toString();
      final String transactionType =
          (data['transaction_type'] ?? data['type'] ?? 'expense')
              .toString()
              .toLowerCase();
      final int confidenceScore = (() {
        final raw = data['confidence_score'] ?? data['confidence'];
        if (raw is int) return raw;
        if (raw is double) return raw.round();
        if (raw is String) return int.tryParse(raw) ?? 0;
        return 0;
      })();
      final String notes = (data['notes'] ?? data['note'] ?? '').toString();

      return {
        'verified_amount': verifiedAmount,
        'description': description,
        'category_suggestion': categorySuggestion,
        'transaction_type': transactionType == 'income' ? 'income' : 'expense',
        'confidence_score': confidenceScore.clamp(0, 100),
        'notes': notes,
      };
    } catch (e) {
      _logger.e('❌ Error parsing AI analysis response: $e');
      return {};
    }
  }

  /// Kết hợp kết quả OCR và AI để có kết quả tối ưu
  Map<String, dynamic> _combineOCRAndAI(Map<String, dynamic> ocrResult,
      Map<String, dynamic> ocrAnalysis, Map<String, dynamic> aiAnalysis) {
    final useAI =
        aiAnalysis.isNotEmpty && (aiAnalysis['confidence_score'] ?? 0) > 70;

    final amount = useAI
        ? (aiAnalysis['verified_amount'] ?? ocrAnalysis['suggestedAmount'])
        : ocrAnalysis['suggestedAmount'];

    final description = useAI
        ? (aiAnalysis['description'] ?? 'Giao dịch từ hóa đơn')
        : (ocrAnalysis['merchantName'] ?? 'Giao dịch từ hóa đơn');

    final category = useAI
        ? (aiAnalysis['category_suggestion'] ?? ocrAnalysis['categoryHint'])
        : ocrAnalysis['categoryHint'];

    final type = useAI
        ? (aiAnalysis['transaction_type'] ?? ocrAnalysis['transactionType'])
        : ocrAnalysis['transactionType'];

    // Tính confidence tổng hợp
    final ocrConfidence = ocrResult['confidence'] as int;
    final aiConfidence = aiAnalysis['confidence_score'] ?? 0;
    final combinedConfidence =
        useAI ? ((ocrConfidence + aiConfidence) / 2).round() : ocrConfidence;

    return {
      'success': true,
      'amount': amount,
      'description': description,
      'type': type,
      'category_suggestion': category,
      'date': DateTime.now().toIso8601String().split('T')[0],
      'confidence': combinedConfidence,
      'raw_text': ocrResult['fullText'],
      'processing_method': useAI ? 'OCR + AI' : 'OCR only',
      // Đồng bộ với các module khác - chỉ giữ các trường cần thiết
      'note': description, // Map description thành note cho TransactionModel
      'category_name': category, // Lưu tên category để hiển thị
    };
  }

  /// Trích xuất thông tin giao dịch từ hình ảnh (legacy method with fallback to OCR)
  Future<Map<String, dynamic>> extractTransactionFromImage(
      File imageFile) async {
    // Sử dụng method mới với OCR
    return await extractTransactionFromImageWithOCR(imageFile);
  }

  /// Validate và xử lý ảnh trước khi gửi lên AI
  Future<bool> validateImageForProcessing(File imageFile) async {
    try {
      // Kiểm tra kích thước file (tối đa 4MB)
      final fileSize = await imageFile.length();
      if (fileSize > 4 * 1024 * 1024) {
        throw Exception('Ảnh quá lớn. Vui lòng chọn ảnh nhỏ hơn 4MB.');
      }

      // Kiểm tra định dạng file
      final fileName = imageFile.path.toLowerCase();
      if (!fileName.endsWith('.jpg') &&
          !fileName.endsWith('.jpeg') &&
          !fileName.endsWith('.png')) {
        throw Exception(
            'Định dạng ảnh không được hỗ trợ. Vui lòng chọn file JPG hoặc PNG.');
      }

      return true;
    } catch (e) {
      _logger.e('Image validation failed: $e');
      rethrow;
    }
  }

  /// Xử lý đầu vào chat và trả về phản hồi từ AI
  Future<String> processChatInput(String input) async {
    try {
      // Check rate limit and token usage
      await _checkRateLimit();

      // Estimate tokens
      final estimatedTokens = _estimateTokens(input);
      if (_dailyTokenCount + estimatedTokens > _dailyTokenLimit) {
        return 'Xin lỗi, bạn đã sử dụng hết quota AI hôm nay. Vui lòng thử lại vào ngày mai! 😅';
      }

      // ✅ IMPROVED: Simplified debug log for chat processing
      if (EnvironmentService.debugMode) {
        _logger.d(
            '💬 Processing chat input (${input.length} chars, ~$estimatedTokens tokens)');
      }

      final prompt = '''
You are Moni AI, a smart financial assistant with advanced category management. Analyze user input and:

1. If user inputs transaction info, IMMEDIATELY call addTransaction function with intelligent categorization:

IMPORTANT: For amount parsing, preserve the original format including k/tr suffixes:
- "18k" should be passed as "18k" not 18
- "1tr" should be passed as "1tr" not 1
- "500000" can be passed as 500000

CATEGORY SYSTEM:
- Each category now has smart emoji icons (🍽️ for food, 🚗 for transport, etc.)
- Categories support parent-child hierarchy
- Auto-create categories with appropriate emojis based on context
- Vietnamese and English names supported

INCOME examples:
- "trợ cấp 1tr" → amount: "1tr", category: "Thu nhập", type: "income"  
- "lương 10tr" → amount: "10tr", category: "Lương", type: "income"
- "bán hàng 500k" → amount: "500k", category: "Bán hàng", type: "income"
- "freelance 800k" → amount: "800k", category: "Freelance", type: "income"

EXPENSE examples:
- "ăn cơm 50k" → amount: "50k", category: "Ăn uống", type: "expense"
- "xăng xe 200k" → amount: "200k", category: "Xăng xe", type: "expense"  
- "mua áo 300k" → amount: "300k", category: "Mua sắm", type: "expense"
- "xem phim 120k" → amount: "120k", category: "Giải trí", type: "expense"
- "thuốc cảm 80k" → amount: "80k", category: "Y tế", type: "expense"
- "học phí 2tr" → amount: "2tr", category: "Học tập", type: "expense"

SMART CATEGORIZATION:
- Food/Dining: "Ăn uống" (🍽️) - cơm, phở, ăn, uống, food, eat, restaurant
- Transport: "Di chuyển" (🚗) - xe, xăng, grab, transport, taxi, bus
- Shopping: "Mua sắm" (🛒) - mua, shopping, áo, giày, đồ
- Entertainment: "Giải trí" (🎬) - phim, game, giải trí, movie, entertainment
- Health: "Y tế" (🏥) - thuốc, bác sĩ, hospital, health, doctor
- Education: "Học tập" (🏫) - học, school, course, education
- Bills: "Hóa đơn" (🧾) - điện, nước, internet, phone, utilities
- Work Income: "Lương" (💼) - lương, salary, work
- Investment: "Đầu tư" (📈) - đầu tư, stock, investment
- Bonus: "Thưởng" (🎁) - thưởng, bonus, gift

2. If asking about transactions/finances, provide helpful insights
3. If asking about categories, explain the new emoji system and management features
4. Always respond in Vietnamese, friendly and helpful

Current system features:
- ✨ Emoji-based category icons
- 🗂️ Hierarchical category organization  
- 🎨 Smart auto-categorization
- 📱 Easy category management interface
- 🔄 Real-time category updates

Guidelines:
- Be conversational and helpful
- Use emojis appropriately in responses
- Explain financial concepts simply
- Encourage good financial habits

User input: "$input"
''';

      // Update token usage
      await _updateTokenCount(estimatedTokens);

      // Check if user is asking about categories or financial help
      final inputLower = input.toLowerCase();
      if (inputLower.contains('danh mục') ||
          inputLower.contains('category') ||
          inputLower.contains('emoji') ||
          inputLower.contains('icon')) {
        return _handleCategoryHelp();
      }

      if (inputLower.contains('help') ||
          inputLower.contains('hướng dẫn') ||
          inputLower.contains('làm sao') ||
          inputLower.contains('cách')) {
        return _handleGeneralHelp();
      }

      // Process with AI model for transaction extraction or general chat
      final response = await _model.generateContent([Content.text(prompt)]);

      // Update token count (estimate response tokens too)
      final responseTokens = _estimateTokens(response.text ?? '');
      await _updateTokenCount(responseTokens);

      // Check if AI wants to call functions
      if (response.functionCalls.isNotEmpty) {
        for (final functionCall in response.functionCalls) {
          if (functionCall.name == 'addTransaction') {
            final result = await _handleAddTransaction(functionCall.args);
            return result;
          }
        }
      }

      final result =
          response.text ?? 'Xin lỗi, tôi không hiểu yêu cầu của bạn.';

      // ✅ IMPROVED: Only log successful processing in debug mode
      if (EnvironmentService.debugMode) {
        _logger.d(
            '✅ Chat processed successfully (${result.length} chars response)');
      }
      return result;
    } catch (e) {
      _logger.e('❌ Error processing chat input: $e');

      // ✅ IMPROVED: Comprehensive error handling with user-friendly messages
      return _getErrorMessageForUser(e);
    }
  }

  /// Get user-friendly error message based on exception type
  String _getErrorMessageForUser(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Server overload errors (503)
    if (errorString.contains('503') || errorString.contains('overloaded')) {
      return "🤖 AI đang quá tải hiện tại. Vui lòng thử lại sau ít phút.\n\nMôi trường AI hiện đang có nhiều người dùng, hãy kiên nhẫn một chút nhé! 😊";
    }

    // Rate limit errors (429)
    if (errorString.contains('429') || errorString.contains('rate limit')) {
      return "⏰ Bạn đã gửi quá nhiều tin nhắn trong thời gian ngắn. Vui lòng chờ một chút trước khi tiếp tục.\n\nHãy thư giãn và thử lại sau vài giây! ☕";
    }

    // Authentication errors (401, 403)
    if (errorString.contains('401') ||
        errorString.contains('403') ||
        errorString.contains('api key') ||
        errorString.contains('unauthorized')) {
      return "🔐 Có vấn đề với xác thực AI. Vui lòng khởi động lại ứng dụng.\n\nNếu vấn đề vẫn tiếp tục, hãy liên hệ hỗ trợ! 📞";
    }

    // Network connectivity errors
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('socket')) {
      return "📶 Kết nối mạng không ổn định. Vui lòng kiểm tra internet và thử lại.\n\nHãy đảm bảo bạn có kết nối mạng tốt! 🌐";
    }

    // Quota/limit exceeded errors
    if (errorString.contains('quota') ||
        errorString.contains('limit') ||
        errorString.contains('usage')) {
      return "💳 Đã vượt quá giới hạn sử dụng AI hôm nay. Vui lòng thử lại vào ngày mai.\n\nChúng tôi sẽ reset quota vào 0h mỗi ngày! 🕛";
    }

    // Model/AI specific errors
    if (errorString.contains('model') ||
        errorString.contains('unavailable') ||
        errorString.contains('service')) {
      return "🤖 Mô hình AI tạm thời không khả dụng. Vui lòng thử lại sau ít phút.\n\nChúng tôi đang khắc phục sự cố! 🔧";
    }

    // Bad request errors (400)
    if (errorString.contains('400') || errorString.contains('bad request')) {
      return "📝 Yêu cầu không hợp lệ. Vui lòng thử nhập lại tin nhắn.\n\nHãy kiểm tra định dạng tin nhắn của bạn! ✏️";
    }

    // Server errors (500, 502, 504)
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('504') ||
        errorString.contains('server error')) {
      return "🔧 Máy chủ AI đang gặp sự cố. Vui lòng thử lại sau ít phút.\n\nĐội ngũ kỹ thuật đang xử lý! 👨‍💻";
    }

    // Content policy violations
    if (errorString.contains('policy') ||
        errorString.contains('content') ||
        errorString.contains('violation')) {
      return "⚠️ Nội dung tin nhắn không phù hợp với chính sách AI. Vui lòng thử tin nhắn khác.\n\nHãy sử dụng ngôn từ lịch sự và phù hợp! 🤝";
    }

    // Generic fallback error
    return "😅 Đã có lỗi không mong muốn xảy ra. Vui lòng thử lại sau ít phút.\n\nNếu vấn đề tiếp tục, hãy khởi động lại ứng dụng! 🔄\n\n(Mã lỗi: ${_getErrorCode(error)})";
  }

  /// Extract error code from exception for debugging
  String _getErrorCode(dynamic error) {
    final errorString = error.toString();

    // Extract HTTP status code
    final statusMatch = RegExp(r'\b[45]\d{2}\b').firstMatch(errorString);
    if (statusMatch != null) {
      return statusMatch.group(0) ?? 'UNKNOWN';
    }

    // Extract error type
    if (errorString.contains('GenerativeAIException')) {
      return 'AI_ERROR';
    } else if (errorString.contains('SocketException')) {
      return 'NETWORK_ERROR';
    } else if (errorString.contains('TimeoutException')) {
      return 'TIMEOUT_ERROR';
    }

    return 'GENERIC_ERROR';
  }

  /// Handle adding transaction through function call
  Future<String> _handleAddTransaction(Map<String, dynamic> args) async {
    try {
      final transactionService = _getIt<TransactionService>();
      final categoryService = _getIt<CategoryService>();

      // Extract parameters with robust null-safety and VN-friendly defaults
      final rawAmount = args['amount'];
      final double amount = _parseAmount(rawAmount);

      // Some model calls may omit description; fallback to a sensible default
      final String description =
          (args['description'] ?? 'Giao dịch').toString();

      // Infer type if missing (e.g., input: "lương 1tr" → income)
      final String typeStr = (args['type'] ??
              (description.toLowerCase().contains('lương')
                  ? 'income'
                  : 'expense'))
          .toString();

      // Provide category fallback based on type
      final String categoryName = (args['category'] ??
              (typeStr.toLowerCase() == 'income' ? 'Lương' : 'Khác'))
          .toString();

      final String? dateStr = args['date']?.toString();

      // ✅ IMPROVED: Single comprehensive log for transaction processing
      _logger.i(
          '💰 Adding transaction: $typeStr ${CurrencyFormatter.formatAmountWithCurrency(amount)} - $categoryName');

      // Parse transaction type
      final transactionType = typeStr.toLowerCase() == 'income'
          ? TransactionType.income
          : TransactionType.expense;

      // Parse date or use current date
      DateTime transactionDate;
      if (dateStr != null) {
        try {
          transactionDate = DateTime.parse(dateStr);
        } catch (e) {
          transactionDate = DateTime.now();
        }
      } else {
        transactionDate = DateTime.now();
      }

      // Find or create category
      final categoriesStream =
          categoryService.getCategories(type: transactionType);
      final categories = await categoriesStream.first;
      String categoryId = 'other';

      for (final category in categories) {
        if (category.name.toLowerCase() == categoryName.toLowerCase()) {
          categoryId = category.categoryId;
          break;
        }
      }

      // If category not found, create new one with intelligent emoji selection
      if (categoryId == 'other') {
        final iconData =
            _getSmartIconForCategory(categoryName, transactionType);

        final newCategory = CategoryModel(
          categoryId: '',
          userId: '',
          name: categoryName,
          type: transactionType,
          icon: iconData['icon'],
          iconType: iconData['iconType'],
          color: iconData['color'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        categoryId = await categoryService.createCategory(newCategory);
      }

      // Create transaction with correct amount handling
      // Keep amount positive; type determines semantics elsewhere in app
      final double finalAmount = amount.abs();

      final transaction = TransactionModel(
        transactionId: '',
        userId: '',
        categoryId: categoryId,
        amount: finalAmount,
        date: transactionDate,
        type: transactionType,
        note: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save transaction and get transactionId
      final transactionId =
          await transactionService.createTransaction(transaction);

      // ✅ IMPROVED: Only log success in debug mode with essential info
      if (EnvironmentService.debugMode) {
        _logger.d('✅ Transaction saved successfully: ID $transactionId');
      }

      // Find category to get its emoji for display
      final category = await categoryService.getCategory(categoryId);
      final categoryDisplay =
          category != null ? '${category.icon} ${category.name}' : categoryName;

      return '''✅ **Đã thêm giao dịch thành công!**

💰 **Số tiền:** ${CurrencyFormatter.formatAmountWithCurrency(amount)}
📝 **Mô tả:** $description
📁 **Danh mục:** $categoryDisplay
📅 **Ngày:** ${transactionDate.day}/${transactionDate.month}/${transactionDate.year}
${transactionType == TransactionType.expense ? '📉' : '📈'} **Loại:** ${transactionType == TransactionType.expense ? 'Chi tiêu' : 'Thu nhập'}

🎉 Giao dịch đã được lưu với emoji phù hợp!

💡 **Mẹo:** Bạn có thể quản lý danh mục và thay đổi emoji trong phần "Quản lý danh mục" của app.

[EDIT_BUTTON:$transactionId]''';
    } catch (e) {
      _logger.e('❌ Error adding transaction: $e');
      return 'Xin lỗi, có lỗi xảy ra khi thêm giao dịch. Vui lòng thử lại.\n\nLỗi: ${e.toString()}';
    }
  }

  /// Gợi ý danh mục cho giao dịch dựa trên mô tả
  Future<String> suggestCategory(String description) async {
    // Kiểm tra cache trước
    final cacheKey = description.toLowerCase().trim();
    if (_categoryCache.containsKey(cacheKey)) {
      // ✅ IMPROVED: Only log cache hits in debug mode
      if (EnvironmentService.debugMode) {
        _logger.d('📁 Category cache hit for: $description');
      }
      return _categoryCache[cacheKey]!;
    }

    try {
      // Check rate limit
      await _checkRateLimit();

      // ✅ IMPROVED: Single log for category suggestion processing
      _logger.i('🤔 Suggesting category for: "$description"');

      final prompt = '''
Suggest best category for transaction: "$description"
Return Vietnamese category name only: "Ăn uống", "Mua sắm", "Đi lại", "Giải trí", "Lương", etc.
''';

      // Estimate tokens
      final estimatedTokens = _estimateTokens(prompt);
      if (_dailyTokenCount + estimatedTokens > _dailyTokenLimit) {
        return 'Ăn uống'; // Return default if quota exceeded
      }

      final response = await _model.generateContent([Content.text(prompt)]);
      final result = response.text?.trim() ?? 'Khác';

      // Update token count
      final responseTokens = _estimateTokens(result);
      await _updateTokenCount(estimatedTokens + responseTokens);

      // Lưu vào cache
      _addToCache(_categoryCache, cacheKey, result);

      // ✅ IMPROVED: Only log successful category suggestion in debug mode
      if (EnvironmentService.debugMode) {
        _logger.d('✅ Category suggested: "$result" for "$description"');
      }
      return result;
    } catch (e) {
      _logger.e('❌ Error suggesting category: $e');
      return 'Ăn uống'; // Default fallback category
    }
  }

  /// Trả lời câu hỏi tài chính cá nhân
  Future<String> answerQuestion(String question) async {
    try {
      // ✅ IMPROVED: Consolidated logging for financial Q&A
      _logger.i('💡 Processing financial question (${question.length} chars)');

      final prompt = '''
You are a personal finance expert. Answer professionally in Vietnamese with practical advice for Vietnam context.

Question: "$question"
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final result = response.text ??
          'Xin lỗi, tôi không thể trả lời câu hỏi này lúc này.';

      // ✅ IMPROVED: Only log successful answers in debug mode
      if (EnvironmentService.debugMode) {
        _logger.d('✅ Financial question answered (${result.length} chars)');
      }
      return result;
    } catch (e) {
      _logger.e('❌ Error answering question: $e');
      return 'Xin lỗi, đã có lỗi xảy ra khi trả lời câu hỏi của bạn.';
    }
  }

  /// Sinh văn bản thuần từ prompt đã chuẩn hoá (bỏ mọi heuristic/chat routing)
  Future<String> generateText(String prompt) async {
    try {
      await _checkRateLimit();
      final estimatedTokens = _estimateTokens(prompt);
      if (_dailyTokenCount + estimatedTokens > _dailyTokenLimit) {
        return 'Quota AI đã vượt giới hạn ngày hôm nay.';
      }

      final response = await _model.generateContent([Content.text(prompt)]);
      final result = response.text ?? '';

      // cập nhật ước lượng token tiêu thụ
      await _updateTokenCount(estimatedTokens + _estimateTokens(result));
      return result;
    } catch (e) {
      _logger.e('Error generateText: $e');
      return '';
    }
  }

  /// Phân tích thói quen chi tiêu và đưa ra lời khuyên
  Future<String> analyzeSpendingHabits(
      Map<String, dynamic> transactionData) async {
    try {
      // ✅ IMPROVED: Consolidated logging for spending analysis
      _logger.i(
          '📊 Analyzing spending habits (${transactionData.keys.length} data points)');

      final prompt = '''
Analyze spending habits and give specific advice to improve personal finance. Answer in Vietnamese with clear structure.

Data: ${transactionData.toString()}
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final result = response.text ??
          'Xin lỗi, không thể phân tích thói quen chi tiêu lúc này.';

      // ✅ IMPROVED: Only log successful analysis in debug mode
      if (EnvironmentService.debugMode) {
        _logger.d('✅ Spending analysis completed (${result.length} chars)');
      }
      return result;
    } catch (e) {
      _logger.e('❌ Error analyzing spending habits: $e');
      return 'Xin lỗi, đã có lỗi xảy ra khi phân tích thói quen chi tiêu.';
    }
  }

  /// Handle category-related questions
  String _handleCategoryHelp() {
    return '''🗂️ **Hệ thống Danh mục với Emoji**

**✨ Tính năng mới:**
📱 **Emoji Icons:** Mỗi danh mục có emoji riêng (🍽️, 🚗, 🛒...)
🗂️ **Phân cấp:** Danh mục cha-con để tổ chức tốt hơn  
🎨 **Tự động:** AI tự chọn emoji phù hợp khi tạo danh mục mới
⚡ **Real-time:** Cập nhật ngay lập tức

**📂 Danh mục phổ biến:**
🍽️ **Ăn uống** - Cơm, phở, cà phê, nhà hàng
🚗 **Di chuyển** - Xăng xe, taxi, grab, xe bus
🛒 **Mua sắm** - Áo quần, giày dép, đồ gia dụng
🎬 **Giải trí** - Xem phim, game, du lịch
🏥 **Y tế** - Thuốc, bác sĩ, bệnh viện
🏫 **Học tập** - Học phí, sách vở, khóa học
🧾 **Hóa đơn** - Điện, nước, internet, điện thoại

💼 **Thu nhập:**
💼 Lương • 🎁 Thưởng • 📈 Đầu tư • 💻 Freelance

**🔧 Quản lý danh mục:**
- Vào "Quản lý danh mục" để tạo, sửa, xóa
- Chọn emoji từ bàn phím hoặc Material Icons
- Tạo danh mục con để tổ chức chi tiết hơn
- Thay đổi màu sắc cho từng danh mục

💡 **Mẹo:** Chỉ cần nhập giao dịch, AI sẽ tự chọn danh mục và emoji phù hợp!''';
  }

  /// Handle general help questions
  String _handleGeneralHelp() {
    return '''🤖 **Moni AI - Trợ lý Tài chính Thông minh**

**💬 Cách sử dụng:**
Chỉ cần chat bình thường, tôi sẽ hiểu và thêm giao dịch cho bạn!

**📝 Ví dụ nhập giao dịch:**
• "Ăn cơm 50k" 
• "Xăng xe 200k"
• "Lương tháng 10tr"
• "Mua áo 300k"
• "Freelance 800k"

**🎯 Tôi có thể:**
✅ Thêm giao dịch tự động với emoji
✅ Phân loại danh mục thông minh  
✅ Tư vấn tài chính cá nhân
✅ Giải thích các tính năng app
✅ Phân tích chi tiêu theo danh mục

**💡 Tính năng đặc biệt:**
🎨 **Smart Categorization** - Tự động chọn danh mục và emoji
📊 **Financial Insights** - Phân tích thói quen chi tiêu
🗂️ **Category Management** - Quản lý danh mục với emoji
📱 **Natural Chat** - Chat tự nhiên như với bạn bè

**🚀 Thử ngay:**
Hãy nói với tôi về một giao dịch bất kỳ, ví dụ: "Hôm nay ăn phở 45k"

❓ Cần hỗ trợ gì khác không?''';
  }

  /// Add item to cache with size limit
  void _addToCache(Map<String, String> cache, String key, String value) {
    if (cache.length >= _cacheMaxSize) {
      // Remove oldest entry (first in map)
      final firstKey = cache.keys.first;
      cache.remove(firstKey);
    }
    cache[key] = value;
  }

  /// Parse amount from various formats (18k, 1tr, 18000, etc.)
  double _parseAmount(dynamic rawAmount) {
    // Null-safe fallback
    if (rawAmount == null) return 0;

    if (rawAmount is num) {
      return rawAmount.toDouble();
    }

    if (rawAmount is String) {
      // Normalize common Vietnamese money formats
      String cleanAmount = rawAmount.trim().toLowerCase();

      // Map synonyms to standard suffixes
      cleanAmount = cleanAmount
          .replaceAll(' triệu', 'tr')
          .replaceAll('trieu', 'tr')
          .replaceAll(' ', '');

      // Remove currency symbols (đ, vnd, đồng) and thousand separators
      cleanAmount = cleanAmount.replaceAll(RegExp(r'[₫đvndđồng,\.]'), '');

      // Handle Vietnamese shorthand: k = 1,000; tr = 1,000,000; tỷ = 1,000,000,000
      if (cleanAmount.endsWith('k')) {
        final number =
            double.tryParse(cleanAmount.substring(0, cleanAmount.length - 1)) ??
                0;
        return number * 1000;
      }

      if (cleanAmount.endsWith('tr')) {
        final number =
            double.tryParse(cleanAmount.substring(0, cleanAmount.length - 2)) ??
                0;
        return number * 1000000;
      }

      if (cleanAmount.endsWith('tỷ') || cleanAmount.endsWith('ty')) {
        final base = cleanAmount.endsWith('tỷ')
            ? cleanAmount.substring(0, cleanAmount.length - 2)
            : cleanAmount.substring(0, cleanAmount.length - 2);
        final number = double.tryParse(base) ?? 0;
        return number * 1000000000;
      }

      // Try plain numeric
      return double.tryParse(cleanAmount) ?? 0;
    }

    return 0;
  }

  // Unused for now, but may be useful for future JSON parsing
  // /// Parse JSON response từ Gemini
  // Map<String, dynamic> _parseJsonResponse(String response) {
  //   try {
  //     // Tìm và trích xuất JSON từ response
  //     final jsonStart = response.indexOf('{');
  //     final jsonEnd = response.lastIndexOf('}');

  //     if (jsonStart != -1 && jsonEnd != -1) {
  //       // final jsonString = response.substring(jsonStart, jsonEnd + 1);
  //       // Có thể cần parse JSON ở đây, nhưng để đơn giản tạm thời return map rỗng
  //       return {};
  //     }

  //     return {};
  //   } catch (e) {
  //     _logger.e('Lỗi khi parse JSON response: $e');
  //     return {};
  //   }
  // }

  /// Check rate limit and token usage before API call
  Future<void> _checkRateLimit() async {
    // Check daily token reset
    final now = DateTime.now();
    
    // Reset token nếu đã qua ngày mới (so sánh date, không phải duration)
    if (_lastTokenReset == null) {
      _dailyTokenCount = 0;
      _lastTokenReset = now;
      await _saveTokenUsage();
    } else {
      // So sánh ngày (year, month, day) để reset đúng vào 0h mỗi ngày
      final lastResetDate = DateTime(
        _lastTokenReset!.year,
        _lastTokenReset!.month,
        _lastTokenReset!.day,
      );
      final currentDate = DateTime(now.year, now.month, now.day);
      
      if (currentDate.isAfter(lastResetDate)) {
        _dailyTokenCount = 0;
        _lastTokenReset = now;
        await _saveTokenUsage();
        _logger.i('🔄 Daily token limit reset: 0 / $_dailyTokenLimit');
      }
    }

    // Check daily token limit
    if (_dailyTokenCount >= _dailyTokenLimit) {
      throw Exception('Daily token limit exceeded. Please try again tomorrow.');
    }

    // Check minimum interval between API calls
    if (_lastApiCall != null) {
      final timeSinceLastCall = now.difference(_lastApiCall!);
      if (timeSinceLastCall < _minApiInterval) {
        final waitTime = _minApiInterval - timeSinceLastCall;
        await Future.delayed(waitTime);
      }
    }

    _lastApiCall = DateTime.now();
  }

  /// Load token usage from SharedPreferences and Firestore
  Future<void> _loadTokenUsage() async {
    try {
      final user = _auth.currentUser;
      
      // Ưu tiên đọc từ Firestore nếu user đã login
      if (user != null) {
        try {
          final docSnapshot = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('ai_usage')
              .doc('token_tracking')
              .get();

          if (docSnapshot.exists) {
            final data = docSnapshot.data()!;
            _dailyTokenCount = data['dailyTokenCount'] ?? 0;
            
            if (data['lastTokenReset'] != null) {
              _lastTokenReset = (data['lastTokenReset'] as Timestamp).toDate();
            }
            
            // Check if need to reset (crossed to new day)
            final now = DateTime.now();
            if (_lastTokenReset != null) {
              final lastResetDate = DateTime(
                _lastTokenReset!.year,
                _lastTokenReset!.month,
                _lastTokenReset!.day,
              );
              final currentDate = DateTime(now.year, now.month, now.day);
              
              if (currentDate.isAfter(lastResetDate)) {
                // Reset token count for new day
                _dailyTokenCount = 0;
                _lastTokenReset = now;
                await _saveTokenUsage(); // Save reset to Firestore
                _logger.i('🔄 Token usage reset for new day (Firestore)');
              } else {
                _logger.i('📊 Token usage loaded from Firestore: $_dailyTokenCount / $_dailyTokenLimit');
              }
            }
            
            // Cache local backup
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt(_keyTokenCount, _dailyTokenCount);
            if (_lastTokenReset != null) {
              await prefs.setInt(_keyLastTokenReset, _lastTokenReset!.millisecondsSinceEpoch);
            }
            
            return;
          }
        } catch (e) {
          _logger.w('Error loading from Firestore, fallback to local: $e');
        }
      }
      
      // Fallback: Load from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      // Load saved token count
      _dailyTokenCount = prefs.getInt(_keyTokenCount) ?? 0;
      
      // Load last reset time
      final lastResetMillis = prefs.getInt(_keyLastTokenReset);
      if (lastResetMillis != null) {
        _lastTokenReset = DateTime.fromMillisecondsSinceEpoch(lastResetMillis);
        
        // Check if need to reset (crossed to new day)
        final now = DateTime.now();
        final lastResetDate = DateTime(
          _lastTokenReset!.year,
          _lastTokenReset!.month,
          _lastTokenReset!.day,
        );
        final currentDate = DateTime(now.year, now.month, now.day);
        
        if (currentDate.isAfter(lastResetDate)) {
          // Reset token count for new day
          _dailyTokenCount = 0;
          _lastTokenReset = now;
          await _saveTokenUsage();
          _logger.i('🔄 Token usage reset for new day (local)');
        } else {
          _logger.i('📊 Token usage loaded from local: $_dailyTokenCount / $_dailyTokenLimit');
        }
      }
    } catch (e) {
      _logger.e('Error loading token usage: $e');
      // Initialize with default values on error
      _dailyTokenCount = 0;
      _lastTokenReset = DateTime.now();
    }
  }

  /// Save token usage to both Firestore and SharedPreferences
  Future<void> _saveTokenUsage() async {
    try {
      // Save to Firestore first (if user logged in)
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('ai_usage')
            .doc('token_tracking')
            .set({
          'dailyTokenCount': _dailyTokenCount,
          'lastTokenReset': _lastTokenReset != null 
              ? Timestamp.fromDate(_lastTokenReset!) 
              : null,
          'dailyLimit': _dailyTokenLimit,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      
      // Always save to local as backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyTokenCount, _dailyTokenCount);
      if (_lastTokenReset != null) {
        await prefs.setInt(_keyLastTokenReset, _lastTokenReset!.millisecondsSinceEpoch);
      }
    } catch (e) {
      _logger.e('Error saving token usage: $e');
    }
  }

  /// Update token count and save to persistent storage
  Future<void> _updateTokenCount(int tokens) async {
    _dailyTokenCount += tokens;
    await _saveTokenUsage();
    
    // Log warning if approaching limit
    if (_dailyTokenCount > _dailyTokenLimit * 0.8) {
      _logger.w(
        '⚠️ High token usage: $_dailyTokenCount / $_dailyTokenLimit '
        '(${(_dailyTokenCount / _dailyTokenLimit * 100).toStringAsFixed(1)}%)'
      );
    }
  }

  /// Estimate tokens for input text (rough estimation)
  int _estimateTokens(String text) {
    // Rough estimation: 1 token ≈ 4 characters for English, 2-3 for Vietnamese
    return (text.length / 3).ceil();
  }

  /// Get smart icon for category based on name and type
  Map<String, dynamic> _getSmartIconForCategory(
      String categoryName, TransactionType type) {
    final name = categoryName.toLowerCase();

    // Expense categories with specific emojis
    if (type == TransactionType.expense) {
      if (name.contains('ăn') ||
          name.contains('uống') ||
          name.contains('food') ||
          name.contains('eat')) {
        return {
          'icon': '🍽️',
          'iconType': CategoryIconType.emoji,
          'color': 0xFFFF6B35
        };
      } else if (name.contains('di chuyển') ||
          name.contains('xe') ||
          name.contains('transport') ||
          name.contains('travel')) {
        return {
          'icon': '🚗',
          'iconType': CategoryIconType.emoji,
          'color': 0xFF2196F3
        };
      } else if (name.contains('mua sắm') ||
          name.contains('shopping') ||
          name.contains('shop')) {
        return {
          'icon': '🛒',
          'iconType': CategoryIconType.emoji,
          'color': 0xFF9C27B0
        };
      } else if (name.contains('giải trí') ||
          name.contains('phim') ||
          name.contains('entertainment') ||
          name.contains('movie')) {
        return {
          'icon': '🎬',
          'iconType': CategoryIconType.emoji,
          'color': 0xFFFF9800
        };
      } else if (name.contains('hóa đơn') ||
          name.contains('bill') ||
          name.contains('utilities')) {
        return {
          'icon': '🧾',
          'iconType': CategoryIconType.emoji,
          'color': 0xFFF44336
        };
      } else if (name.contains('y tế') ||
          name.contains('health') ||
          name.contains('hospital') ||
          name.contains('doctor')) {
        return {
          'icon': '🏥',
          'iconType': CategoryIconType.emoji,
          'color': 0xFF4CAF50
        };
      } else if (name.contains('học') ||
          name.contains('education') ||
          name.contains('school')) {
        return {
          'icon': '🏫',
          'iconType': CategoryIconType.emoji,
          'color': 0xFF673AB7
        };
      } else if (name.contains('thể thao') ||
          name.contains('gym') ||
          name.contains('sport')) {
        return {
          'icon': '⚽',
          'iconType': CategoryIconType.emoji,
          'color': 0xFF009688
        };
      } else if (name.contains('nhà') ||
          name.contains('home') ||
          name.contains('house')) {
        return {
          'icon': '🏠',
          'iconType': CategoryIconType.emoji,
          'color': 0xFF795548
        };
      } else if (name.contains('xăng') ||
          name.contains('gas') ||
          name.contains('fuel')) {
        return {
          'icon': '⛽',
          'iconType': CategoryIconType.emoji,
          'color': 0xFF607D8B
        };
      } else if (name.contains('bay') ||
          name.contains('flight') ||
          name.contains('plane')) {
        return {
          'icon': '✈️',
          'iconType': CategoryIconType.emoji,
          'color': 0xFF00BCD4
        };
      } else if (name.contains('khách sạn') || name.contains('hotel')) {
        return {
          'icon': '🏨',
          'iconType': CategoryIconType.emoji,
          'color': 0xFFFF5722
        };
      } else if (name.contains('thú cưng') || name.contains('pet')) {
        return {
          'icon': '🐕',
          'iconType': CategoryIconType.emoji,
          'color': 0xFFFFB74D
        };
      } else if (name.contains('con') ||
          name.contains('child') ||
          name.contains('baby')) {
        return {
          'icon': '👶',
          'iconType': CategoryIconType.emoji,
          'color': 0xFFE91E63
        };
      } else if (name.contains('cà phê') ||
          name.contains('coffee') ||
          name.contains('cafe')) {
        return {
          'icon': '☕',
          'iconType': CategoryIconType.emoji,
          'color': 0xFF8D6E63
        };
      } else {
        // Default expense emoji
        return {
          'icon': '💸',
          'iconType': CategoryIconType.emoji,
          'color': 0xFFFF6B35
        };
      }
    } else {
      // Income categories with specific emojis
      if (name.contains('lương') ||
          name.contains('salary') ||
          name.contains('work')) {
        return {
          'icon': '💼',
          'iconType': CategoryIconType.emoji,
          'color': 0xFF4CAF50
        };
      } else if (name.contains('thưởng') ||
          name.contains('bonus') ||
          name.contains('gift')) {
        return {
          'icon': '🎁',
          'iconType': CategoryIconType.emoji,
          'color': 0xFFFFD700
        };
      } else if (name.contains('đầu tư') ||
          name.contains('investment') ||
          name.contains('stock')) {
        return {
          'icon': '📈',
          'iconType': CategoryIconType.emoji,
          'color': 0xFF00BCD4
        };
      } else if (name.contains('bán') ||
          name.contains('sell') ||
          name.contains('sale')) {
        return {
          'icon': '💸',
          'iconType': CategoryIconType.emoji,
          'color': 0xFF9C27B0
        };
      } else if (name.contains('tiết kiệm') ||
          name.contains('saving') ||
          name.contains('bank')) {
        return {
          'icon': '🏦',
          'iconType': CategoryIconType.emoji,
          'color': 0xFF2196F3
        };
      } else if (name.contains('freelance') || name.contains('tự do')) {
        return {
          'icon': '💻',
          'iconType': CategoryIconType.emoji,
          'color': 0xFF673AB7
        };
      } else if (name.contains('cho thuê') ||
          name.contains('rent') ||
          name.contains('rental')) {
        return {
          'icon': '🏢',
          'iconType': CategoryIconType.emoji,
          'color': 0xFF795548
        };
      } else {
        // Default income emoji
        return {
          'icon': '💰',
          'iconType': CategoryIconType.emoji,
          'color': 0xFF4CAF50
        };
      }
    }
  }

  /// Map scan result thành TransactionModel
  Future<TransactionModel> mapScanResultToTransaction(
      Map<String, dynamic> scanResult, String userId) async {
    try {
      // Parse transaction type
      final transactionType = scanResult['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense;

      // Parse amount
      final amount = (scanResult['amount'] ?? 0).toDouble();

      // Parse date
      DateTime transactionDate;
      try {
        transactionDate = DateTime.parse(scanResult['date'] ?? '');
      } catch (e) {
        transactionDate = DateTime.now();
      }

      // Tìm category ID
      String categoryId = 'other';
      String categoryName = scanResult['category_name'] ??
          scanResult['category_suggestion'] ??
          '';

      if (categoryName.isNotEmpty) {
        final categoryService = _getIt<CategoryService>();
        final categoriesStream =
            categoryService.getCategories(type: transactionType);
        final categories = await categoriesStream.first;
        final filteredCategories =
            categories.where((cat) => !cat.isDeleted).toList();

        // Tìm category chính xác
        for (final category in filteredCategories) {
          if (category.name.toLowerCase() == categoryName.toLowerCase()) {
            categoryId = category.categoryId;
            categoryName = category.name;
            break;
          }
        }

        // Nếu không tìm thấy, tìm partial match
        if (categoryId == 'other') {
          for (final category in filteredCategories) {
            if (category.name
                    .toLowerCase()
                    .contains(categoryName.toLowerCase()) ||
                categoryName
                    .toLowerCase()
                    .contains(category.name.toLowerCase())) {
              categoryId = category.categoryId;
              categoryName = category.name;
              break;
            }
          }
        }

        // Sử dụng category đầu tiên nếu vẫn không tìm thấy
        if (categoryId == 'other' && filteredCategories.isNotEmpty) {
          categoryId = filteredCategories.first.categoryId;
          categoryName = filteredCategories.first.name;
        }
      }

      // Tạo note từ description
      String note = scanResult['note'] ??
          scanResult['description'] ??
          'Giao dịch từ scan AI';

      return TransactionModel(
        transactionId: '',
        userId: userId,
        categoryId: categoryId,
        categoryName: categoryName,
        amount: amount,
        type: transactionType,
        date: transactionDate,
        note: note,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDeleted: false,
      );
    } catch (e) {
      _logger.e('Error mapping scan result to transaction: $e');
      rethrow;
    }
  }

  /// Validate scan result trước khi lưu
  Map<String, dynamic> validateScanResult(Map<String, dynamic> scanResult) {
    final errors = <String>[];

    // Kiểm tra amount
    final amount = scanResult['amount'];
    if (amount == null || amount <= 0) {
      errors.add('Số tiền không hợp lệ');
    }

    // Kiểm tra type
    final type = scanResult['type'];
    if (type != 'income' && type != 'expense') {
      errors.add('Loại giao dịch không hợp lệ');
    }

    // Kiểm tra date
    try {
      if (scanResult['date'] != null) {
        DateTime.parse(scanResult['date']);
      }
    } catch (e) {
      errors.add('Ngày giao dịch không hợp lệ');
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
    };
  }
}
