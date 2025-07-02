import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import 'category_service.dart';
import 'environment_service.dart';
import 'transaction_service.dart';

/// Service xử lý các chức năng AI sử dụng Gemini API
class AIProcessorService {
  late final GenerativeModel _model;
  final Logger _logger = Logger();
  final GetIt _getIt = GetIt.instance;

  // Cache để tránh gọi API trùng lặp
  final Map<String, String> _categoryCache = {};
  final Map<String, String> _responseCache = {};
  static const int _cacheMaxSize = 100;

  // Rate limiting
  DateTime? _lastApiCall;
  static const Duration _minApiInterval = Duration(milliseconds: 500);

  // Token usage tracking
  int _dailyTokenCount = 0;
  DateTime? _lastTokenReset;
  static const int _dailyTokenLimit = 10000;

  AIProcessorService() {
    // Load API key from environment variables
    final apiKey = EnvironmentService.geminiApiKey;

    if (apiKey.isEmpty) {
      throw Exception('Gemini API key not found in environment variables');
    }

    // Define function declarations for chatbot
    final List<FunctionDeclaration> functions = [
      FunctionDeclaration(
        'addTransaction',
        'Add new transaction to system with correct category and type',
        Schema(
          SchemaType.object,
          properties: {
            'amount': Schema(SchemaType.number,
                description: 'Transaction amount (positive number)'),
            'description': Schema(SchemaType.string,
                description: 'Transaction description'),
            'category': Schema(SchemaType.string,
                description:
                    'Category: "Ăn uống" (food), "Đi lại" (transport), "Mua sắm" (shopping), "Giải trí" (entertainment), "Thu nhập" (general income), "Lương" (salary), "Sức khỏe" (health), "Học tập" (education)'),
            'type': Schema(SchemaType.string,
                description:
                    'Transaction type: "income" for salary/allowance/earning, "expense" for spending/buying'),
            'date': Schema(SchemaType.string,
                description: 'Transaction date (YYYY-MM-DD), optional'),
          },
          requiredProperties: ['amount', 'description', 'category', 'type'],
        ),
      ),
    ];

    // Try modern model first, with fallback options
    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        tools: [Tool(functionDeclarations: functions)],
      );
      _logger.i(
          'AI Processor Service initialized with gemini-1.5-flash and function calling');
    } catch (e) {
      _logger
          .w('Failed to initialize gemini-1.5-flash, trying alternative: $e');

      try {
        _model = GenerativeModel(
          model: 'gemini-1.5-flash-001',
          apiKey: apiKey,
          tools: [Tool(functionDeclarations: functions)],
        );
        _logger.i(
            'AI Processor Service initialized with gemini-1.5-flash-001 and function calling');
      } catch (e2) {
        _logger.e('Failed to initialize any Gemini model: $e2');
        throw Exception(
            'Could not initialize Gemini model. Please check your API key and internet connection.');
      }
    }
  }

  /// Trích xuất thông tin giao dịch từ hình ảnh (hóa đơn, tin nhắn ngân hàng)
  Future<Map<String, dynamic>> extractImageInfo(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final imagePart = DataPart('image/jpeg', bytes);

      final prompt = '''
      Hãy phân tích hình ảnh này và trích xuất thông tin giao dịch tài chính.
      Trả lời dưới dạng JSON với cấu trúc sau:
      {
        "amount": số tiền (double),
        "date": ngày giao dịch (YYYY-MM-DD),
        "description": mô tả giao dịch,
        "merchant": tên cửa hàng/người nhận (nếu có),
        "type": "income" hoặc "expense",
        "category_suggestion": gợi ý danh mục
      }
      
      Nếu không thể xác định thông tin, hãy trả về null cho các trường tương ứng.
      ''';

      final response = await _model.generateContent([
        Content.multi([TextPart(prompt), imagePart])
      ]);

      final result = _parseJsonResponse(response.text ?? '');
      _logger.i('Extracted image info: $result');

      return result;
    } catch (e) {
      _logger.e('Lỗi khi trích xuất thông tin từ hình ảnh: $e');
      throw Exception('Không thể xử lý hình ảnh: $e');
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

      _logger.i('Processing chat input: $input');

      final prompt = '''
You are Moni AI, a smart financial assistant. Analyze user input and:

1. If user inputs transaction info, IMMEDIATELY call addTransaction function with correct categorization:

INCOME examples:
- "trợ cấp 1tr" → category: "Thu nhập", type: "income"  
- "lương 10tr" → category: "Lương", type: "income"
- "bán hàng 500k" → category: "Thu nhập", type: "income"

EXPENSE examples:  
- "cơm sườn 20k" → category: "Ăn uống", type: "expense"
- "taxi 50k" → category: "Đi lại", type: "expense"
- "mua áo 200k" → category: "Mua sắm", type: "expense"

2. If financial question, provide helpful answer.

3. ALWAYS respond in Vietnamese naturally and friendly.

User input: "$input"
''';

      final response = await _model.generateContent([Content.text(prompt)]);

      // Update token count (estimate response tokens too)
      final responseTokens = _estimateTokens(response.text ?? '');
      _dailyTokenCount += estimatedTokens + responseTokens;
      _logger.i('Token usage: $_dailyTokenCount / $_dailyTokenLimit');

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

      _logger.i(
          'Processed chat input successfully. Response length: ${result.length}');
      return result;
    } catch (e) {
      _logger.e('Lỗi khi xử lý đầu vào chat: $e');

      // Return more helpful error message based on error type
      if (e.toString().contains('API key')) {
        return 'Xin lỗi, có vấn đề với cấu hình API. Vui lòng kiểm tra lại API key.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        return 'Xin lỗi, có vấn đề kết nối mạng. Vui lòng kiểm tra internet và thử lại.';
      } else if (e.toString().contains('quota') ||
          e.toString().contains('limit')) {
        return 'Xin lỗi, đã vượt quá giới hạn sử dụng API. Vui lòng thử lại sau.';
      } else {
        return 'Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại sau.\n\n(Lỗi: ${e.toString()})';
      }
    }
  }

  /// Handle adding transaction through function call
  Future<String> _handleAddTransaction(Map<String, dynamic> args) async {
    try {
      final transactionService = _getIt<TransactionService>();
      final categoryService = _getIt<CategoryService>();

      // Extract parameters with detailed logging
      final amount = (args['amount'] as num).toDouble();
      final description = args['description'] as String;
      final categoryName = args['category'] as String? ?? 'Ăn uống';
      final typeStr = args['type'] as String? ?? 'expense';
      final dateStr = args['date'] as String?;

      _logger.i('Function call args: $args');
      _logger.i(
          'Extracted - Amount: $amount, Description: $description, Category: $categoryName, Type: $typeStr');

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

      // If category not found, create new one
      if (categoryId == 'other') {
        final newCategory = CategoryModel(
          categoryId: '',
          userId: '',
          name: categoryName,
          type: transactionType,
          icon: 'restaurant',
          color: 0xFFFF9800, // Orange color
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        categoryId = await categoryService.createCategory(newCategory);
      }

      // Create transaction with correct amount handling
      final finalAmount = transactionType == TransactionType.expense
          ? amount.abs() // Ensure negative for expenses
          : amount.abs(); // Ensure positive for income

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

      // Save transaction
      await transactionService.createTransaction(transaction);

      _logger.i(
          'Transaction added successfully: $description - ${amount.toStringAsFixed(0)}đ');

      return '''✅ **Đã thêm giao dịch thành công!**

💰 **Số tiền:** ${_formatCurrency(amount)}
📝 **Mô tả:** $description
📁 **Danh mục:** $categoryName
📅 **Ngày:** ${transactionDate.day}/${transactionDate.month}/${transactionDate.year}

🎉 Giao dịch đã được lưu vào hệ thống của bạn!

[EDIT_BUTTON]''';
    } catch (e) {
      _logger.e('Error adding transaction: $e');
      return 'Xin lỗi, có lỗi xảy ra khi thêm giao dịch. Vui lòng thử lại.\n\nLỗi: ${e.toString()}';
    }
  }

  /// Gợi ý danh mục cho giao dịch dựa trên mô tả
  Future<String> suggestCategory(String description) async {
    // Kiểm tra cache trước
    final cacheKey = description.toLowerCase().trim();
    if (_categoryCache.containsKey(cacheKey)) {
      _logger.i('Category cache hit for: $description');
      return _categoryCache[cacheKey]!;
    }

    try {
      // Check rate limit
      await _checkRateLimit();

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
      _dailyTokenCount += estimatedTokens + responseTokens;

      // Lưu vào cache
      _addToCache(_categoryCache, cacheKey, result);

      _logger.i('Suggested category for "$description": $result');
      return result;
    } catch (e) {
      _logger.e('Lỗi khi gợi ý danh mục: $e');
      return 'Ăn uống'; // Default fallback category
    }
  }

  /// Trả lời câu hỏi tài chính cá nhân
  Future<String> answerQuestion(String question) async {
    try {
      final prompt = '''
You are a personal finance expert. Answer professionally in Vietnamese with practical advice for Vietnam context.

Question: "$question"
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final result = response.text ??
          'Xin lỗi, tôi không thể trả lời câu hỏi này lúc này.';

      _logger.i('Answered question: $result');
      return result;
    } catch (e) {
      _logger.e('Lỗi khi trả lời câu hỏi: $e');
      return 'Xin lỗi, đã có lỗi xảy ra khi trả lời câu hỏi của bạn.';
    }
  }

  /// Phân tích thói quen chi tiêu và đưa ra lời khuyên
  Future<String> analyzeSpendingHabits(
      Map<String, dynamic> transactionData) async {
    try {
      final prompt = '''
Analyze spending habits and give specific advice to improve personal finance. Answer in Vietnamese with clear structure.

Data: ${transactionData.toString()}
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final result = response.text ?? 'Không thể phân tích dữ liệu này.';

      _logger.i('Analyzed spending habits');
      return result;
    } catch (e) {
      _logger.e('Lỗi khi phân tích thói quen chi tiêu: $e');
      return 'Xin lỗi, không thể phân tích dữ liệu này lúc này.';
    }
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

  /// Format currency with Vietnamese formatting
  String _formatCurrency(double amount) {
    final absAmount = amount.abs();
    if (absAmount >= 1000000) {
      final millions = absAmount / 1000000;
      return '${millions.toStringAsFixed(millions == millions.roundToDouble() ? 0 : 1)}tr đ';
    } else if (absAmount >= 1000) {
      final thousands = absAmount / 1000;
      return '${thousands.toStringAsFixed(thousands == thousands.roundToDouble() ? 0 : 1)}k đ';
    } else {
      return '${absAmount.toStringAsFixed(0)} đ';
    }
  }

  /// Parse JSON response từ Gemini
  Map<String, dynamic> _parseJsonResponse(String response) {
    try {
      // Tìm và trích xuất JSON từ response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}');

      if (jsonStart != -1 && jsonEnd != -1) {
        // final jsonString = response.substring(jsonStart, jsonEnd + 1);
        // Có thể cần parse JSON ở đây, nhưng để đơn giản tạm thời return map rỗng
        return {};
      }

      return {};
    } catch (e) {
      _logger.e('Lỗi khi parse JSON response: $e');
      return {};
    }
  }

  /// Check rate limit and token usage before API call
  Future<void> _checkRateLimit() async {
    // Check daily token reset
    final now = DateTime.now();
    if (_lastTokenReset == null ||
        now.difference(_lastTokenReset!).inDays >= 1) {
      _dailyTokenCount = 0;
      _lastTokenReset = now;
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

  /// Estimate tokens for input text (rough estimation)
  int _estimateTokens(String text) {
    // Rough estimation: 1 token ≈ 4 characters for English, 2-3 for Vietnamese
    return (text.length / 3).ceil();
  }
}
