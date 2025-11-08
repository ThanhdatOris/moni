import 'package:get_it/get_it.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';

import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../utils/formatting/currency_formatter.dart';
import '../core/environment_service.dart';
import '../data/category_service.dart';
import '../data/transaction_service.dart';
import 'ai_helpers.dart';
import 'ai_token_manager.dart';

/// Handles chat processing and function calls
/// - Process chat input with AI
/// - Handle function calls (addTransaction)
/// - Generate welcome messages
/// - Category and general help
class AIChatHandler {
  final GenerativeModel _model;
  final Logger _logger = Logger();
  final GetIt _getIt = GetIt.instance;
  final AITokenManager _tokenManager;

  AIChatHandler({
    required GenerativeModel model,
    required AITokenManager tokenManager,
  })  : _model = model,
        _tokenManager = tokenManager;

  /// Process chat input and return AI response
  Future<String> processChatInput(String input) async {
    try {
      // Rate limiting only (no quota check - let Google API handle quota)
      await _tokenManager.checkRateLimit();

      // Improved debug log
      if (EnvironmentService.debugMode) {
        final estimatedTokens = AIHelpers.estimateTokens(input);
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

      // Track token usage for statistics (non-blocking)
      final estimatedTokens = AIHelpers.estimateTokens(input);
      final responseTokens = AIHelpers.estimateTokens(response.text ?? '');
      await _tokenManager.updateTokenCount(estimatedTokens + responseTokens);

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

      // Success log only in debug mode
      if (EnvironmentService.debugMode) {
        _logger.d('✅ Chat processed successfully (${result.length} chars)');
      }

      return result;
    } catch (e) {
      final errorType = AIHelpers.getErrorType(e);
      _logger.e('❌ Error in chat processing: $e');
      return AIHelpers.getUserFriendlyErrorMessage(errorType);
    }
  }

  /// Handle adding transaction through function call
  Future<String> _handleAddTransaction(Map<String, dynamic> args) async {
    try {
      final transactionService = _getIt<TransactionService>();
      final categoryService = _getIt<CategoryService>();

      // Extract parameters with robust null-safety
      final rawAmount = args['amount'];
      final double amount = AIHelpers.parseAmount(rawAmount);

      final String description =
          (args['description'] ?? 'Giao dịch').toString();

      // Infer type if missing
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

      // Improved log for transaction processing
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
            AIHelpers.getSmartIconForCategory(categoryName, transactionType);

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

      // Create transaction
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

      await transactionService.createTransaction(transaction);

      // Return success message
      final typeText = transactionType == TransactionType.income ? 'thu' : 'chi';
      return '✅ Đã thêm giao dịch $typeText: ${CurrencyFormatter.formatAmountWithCurrency(amount)} - $categoryName ($description)';
    } catch (e) {
      _logger.e('❌ Error adding transaction: $e');
      return '❌ Lỗi khi thêm giao dịch: ${e.toString()}';
    }
  }

  /// Handle category help request
  String _handleCategoryHelp() {
    return '''
🏷️ **Hệ thống Danh mục Thông minh**

Moni AI hỗ trợ quản lý danh mục với emoji và phân cấp:

📊 **Danh mục Chi tiêu:**
🍽️ Ăn uống - Cơm, phở, cafe, nhà hàng
🚗 Di chuyển - Xăng, Grab, taxi, xe bus
🛒 Mua sắm - Quần áo, giày dép, đồ dùng
🎬 Giải trí - Phim, game, du lịch
🏥 Y tế - Thuốc, bác sĩ, khám bệnh
🏫 Học tập - Sách, khóa học, học phí
🧾 Hóa đơn - Điện, nước, internet

💰 **Danh mục Thu nhập:**
💼 Lương - Lương chính thức
🎁 Thưởng - Bonus, quà tặng
📈 Đầu tư - Cổ phiếu, lãi suất
💻 Freelance - Dự án tự do
💸 Bán hàng - Bán đồ, kinh doanh

**Tính năng:**
✨ Tự động gợi ý emoji phù hợp
🔄 Tạo danh mục mới thông minh
📱 Quản lý dễ dàng trên giao diện
🎨 Tùy chỉnh màu sắc và icon

**Ví dụ:** "ăn phở 50k" → tự động vào danh mục "Ăn uống" 🍽️
''';
  }

  /// Handle general help request
  String _handleGeneralHelp() {
    return '''
👋 **Chào mừng đến với Moni AI!**

Tôi có thể giúp bạn:

💰 **Thêm giao dịch nhanh**
- "ăn phở 45k" → thêm chi tiêu
- "lương 10tr" → thêm thu nhập
- "mua áo 300k hôm qua" → thêm với ngày cụ thể

📊 **Phân tích tài chính**
- Tổng quan chi tiêu
- Xu hướng tài chính
- Đề xuất tiết kiệm

🏷️ **Quản lý danh mục**
- Danh mục với emoji thông minh
- Tự động phân loại
- Tạo danh mục mới

📱 **Natural Chat** - Chat tự nhiên như với bạn bè

**🚀 Thử ngay:**
Hãy nói với tôi về một giao dịch bất kỳ, ví dụ: "Hôm nay ăn phở 45k"

❓ Cần hỗ trợ gì khác không?
''';
  }

  /// Generate welcome message
  String generateWelcomeMessage() {
    return _handleGeneralHelp();
  }
}
