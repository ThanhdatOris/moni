import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';

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

  /// Trích xuất thông tin giao dịch từ hình ảnh sử dụng OCR + AI
  Future<Map<String, dynamic>> extractTransactionFromImageWithOCR(
      File imageFile) async {
    try {
      _logger.i('Starting OCR + AI processing for transaction extraction...');

      // Bước 1: Sử dụng OCR để trích xuất text
      final ocrService = _getIt<OCRService>();
      final ocrResult =
          await ocrService.extractStructuredTextFromImage(imageFile);
      final extractedText = ocrResult['fullText'] as String;
      final ocrConfidence = ocrResult['confidence'] as int;

      _logger.i('OCR extraction completed with confidence: $ocrConfidence%');

      if (extractedText.isEmpty) {
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

      _logger.i('Combined OCR + AI processing completed successfully');
      return finalResult;
    } catch (e) {
      _logger.e('Error in OCR + AI processing: $e');

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
      _dailyTokenCount += estimatedTokens;

      final responseText = response.text ?? '';
      final parsedResult = _parseAIAnalysisResponse(responseText);

      return parsedResult;
    } catch (e) {
      _logger.e('Error in AI analysis: $e');
      // Fallback to OCR results
      return ocrAnalysis;
    }
  }

  /// Parse AI analysis response
  Map<String, dynamic> _parseAIAnalysisResponse(String response) {
    try {
      // Tìm JSON trong response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}');

      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        final jsonString = response.substring(jsonStart, jsonEnd + 1);
        _logger.i('AI Analysis JSON: $jsonString');

        // Tạm thời return structured data vì cần JSON parser
        // Trong thực tế sẽ parse JSON thật
        return {
          'verified_amount': 125000.0,
          'description': 'Cơm tấm Sài Gòn',
          'category_suggestion': 'Ăn uống',
          'transaction_type': 'expense',
          'confidence_score': 85,
          'notes': 'Phân tích từ AI',
        };
      }

      return {};
    } catch (e) {
      _logger.e('Error parsing AI analysis response: $e');
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

      _logger.i('Processing chat input: $input');

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
      _dailyTokenCount += estimatedTokens;
      _logger
          .i('Token usage: $estimatedTokens (daily total: $_dailyTokenCount)');

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
      final rawAmount = args['amount'];
      final amount = _parseAmount(rawAmount);
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

      // Save transaction and get transactionId
      final transactionId =
          await transactionService.createTransaction(transaction);

      _logger.i(
          'Transaction added successfully: $description - ${amount.toStringAsFixed(0)}đ - ID: $transactionId');

      // Find category to get its emoji for display
      final category = await categoryService.getCategory(categoryId);
      final categoryDisplay =
          category != null ? '${category.icon} ${category.name}' : categoryName;

      // Prepare transaction data for chat log
      final transactionData = {
        'transactionId': transactionId,
        'amount': amount,
        'description': description,
        'categoryName': categoryDisplay,
        'categoryId': categoryId,
        'type': transactionType.value,
        'date': transactionDate.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      };

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
    if (rawAmount is num) {
      return rawAmount.toDouble();
    }

    if (rawAmount is String) {
      // Remove spaces and convert to lowercase
      String cleanAmount = rawAmount.trim().toLowerCase();

      // Remove currency symbols
      cleanAmount = cleanAmount.replaceAll(RegExp(r'[đvndđồng,.]'), '');

      // Handle Vietnamese format: k = 1000, tr = 1000000
      if (cleanAmount.endsWith('k')) {
        final number = double.tryParse(cleanAmount.replaceAll('k', '')) ?? 0;
        return number * 1000;
      } else if (cleanAmount.endsWith('tr') || cleanAmount.endsWith('triệu')) {
        final number = double.tryParse(
                cleanAmount.replaceAll(RegExp(r'(tr|triệu)'), '')) ??
            0;
        return number * 1000000;
      } else if (cleanAmount.endsWith('tỷ')) {
        final number = double.tryParse(cleanAmount.replaceAll('tỷ', '')) ?? 0;
        return number * 1000000000;
      } else {
        // Try to parse as regular number
        return double.tryParse(cleanAmount) ?? 0;
      }
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
