import 'package:get_it/get_it.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:moni/constants/enums.dart';

import '../../models/assistant/chat_message_model.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../utils/formatting/currency_formatter.dart';
import '../core/environment_service.dart';
import '../data/category_service.dart';
import '../data/transaction_service.dart';
import 'ai_helpers.dart';

/// Handles chat processing and function calls
/// - Process chat input with AI
/// - Handle function calls (addTransaction, updateTransaction, getMonthlyReport)
/// - Generate welcome messages
/// - Category and general help
class AIChatHandler {
  final GenerativeModel _model;
  final Logger _logger = Logger();
  final GetIt _getIt = GetIt.instance;

  AIChatHandler({
    required GenerativeModel model,
  }) : _model = model;

  /// Process chat input with streaming response
  /// Returns a stream of text chunks as they arrive
  Stream<String> processChatInputStream(
    String input, {
    List<ChatMessage>? history,
  }) async* {
    try {
      // Improved debug log
      if (EnvironmentService.debugMode) {
        final estimatedTokens = AIHelpers.estimateTokens(input);
        _logger.d(
          '💬 Processing chat input (streaming) (${input.length} chars, ~$estimatedTokens tokens)',
        );
      }

      final now = DateTime.now();
      final prompt =
          '''
Current Date: ${DateFormat('yyyy-MM-dd').format(now)}
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

TOOL USAGE INSTRUCTIONS:
1. When you call "addTransaction", the tool will return a JSON object with transaction details.
2. You MUST use this data to generate a formatted confirmation message exactly like this:

✅ **Đã thêm giao dịch thành công!**

💰 **Số tiền:** <amount from tool>
📝 **Mô tả:** <description from tool>
📅 **Ngày:** <date from tool>
📊 **Loại:** <type from tool>

🎉 <Add a short, relevant emoji-rich comment about the category/spending>

[EDIT_BUTTON:<transactionId from tool>]

3. When you call "getMonthlyReport", the tool returns a pre-formatted report. Just display it to the user and add a helpful comment.

4. When you call "updateTransaction", the tool returns the updated transaction. Confirm to user:

✅ **Đã cập nhật giao dịch!**

💰 **Số tiền:** <new amount>
📝 **Mô tả:** <new description>
📅 **Ngày:** <new date>
📊 **Loại:** <new type>

[EDIT_BUTTON:<transactionId>]

5. SMART CONTEXT RECOVERY:
- If user says "sửa lại", "update it", "nhầm rồi", "sửa thành...", or asks to modify the last transaction:
- AUTOMATICALLY find the transactionId from the last `[EDIT_BUTTON:<id>]` in the chat history.
- Call `updateTransaction` with that ID immediately.
- DO NOT ask for ID if it exists in recent history.

User input: "$input"
''';

      // Check if user is asking about categories or financial help
      final inputLower = input.toLowerCase();
      if (inputLower.contains('danh mục') ||
          inputLower.contains('category') ||
          inputLower.contains('emoji') ||
          inputLower.contains('icon')) {
        yield _handleCategoryHelp();
        return;
      }

      if (inputLower.contains('help') ||
          inputLower.contains('hướng dẫn') ||
          inputLower.contains('làm sao') ||
          inputLower.contains('cách')) {
        yield _handleGeneralHelp();
        return;
      }

      // 1. Prepare History
      List<Content> historyContent = [];
      if (history != null) {
        for (var msg in history) {
          if (msg.isUser) {
            historyContent.add(Content.text(msg.text));
          } else {
            historyContent.add(Content.model([TextPart(msg.text)]));
          }
        }
      }

      // 2. Start Chat Session
      final chat = _model.startChat(history: historyContent);

      // 3. Send Message & Handle Tool Loop
      var currentResponseStream = chat.sendMessageStream(Content.text(prompt));

      String fullResponse = '';
      await for (final chunk in _handleStreamResponse(
        chat,
        currentResponseStream,
      )) {
        fullResponse += chunk;
        yield chunk;
      }

      if (EnvironmentService.debugMode) {
        _logger.d(
          '✅ Chat processed successfully (streaming) (${fullResponse.length} chars)',
        );
      }
    } catch (e) {
      final errorType = AIHelpers.getErrorType(e);
      _logger.e('❌ Error in chat processing (streaming): $e');
      yield AIHelpers.getUserFriendlyErrorMessage(errorType);
    }
  }

  /// Handle stream response and potential function calls recursively
  Stream<String> _handleStreamResponse(
    ChatSession chat,
    Stream<GenerateContentResponse> stream,
  ) async* {
    List<FunctionCall> functionCalls = [];

    await for (final chunk in stream) {
      if (chunk.text != null && chunk.text!.isNotEmpty) {
        yield chunk.text!;
      }
      if (chunk.functionCalls.isNotEmpty) {
        functionCalls.addAll(chunk.functionCalls);
      }
    }

    if (functionCalls.isNotEmpty) {
      // Execute tools
      List<FunctionResponse> responses = [];

      for (final fn in functionCalls) {
        Map<String, dynamic> result = {};

        if (fn.name == 'addTransaction') {
          result = await _handleAddTransaction(fn.args);
        } else if (fn.name == 'getMonthlyReport') {
          final reportStr = await _handleGetMonthlyReport(fn.args);
          result = {'report': reportStr};
        } else if (fn.name == 'updateTransaction') {
          result = await _handleUpdateTransaction(fn.args);
        }

        responses.add(FunctionResponse(fn.name, result));
      }

      // Send tool outputs back to model
      final toolResponseContent = Content.functionResponses(responses);

      // Recursive yield for the model's response to the tool outputs
      yield* _handleStreamResponse(
        chat,
        chat.sendMessageStream(toolResponseContent),
      );
    }
  }

  /// Process chat input and return AI response (non-streaming)
  Future<String> processChatInput(String input) async {
    try {
      final responseStream = processChatInputStream(input);
      String fullResponse = "";
      await for (final chunk in responseStream) {
        fullResponse += chunk;
      }
      return fullResponse;
    } catch (e) {
      final errorType = AIHelpers.getErrorType(e);
      _logger.e('❌ Error in chat processing: $e');
      return AIHelpers.getUserFriendlyErrorMessage(errorType);
    }
  }

  /// Handle adding transaction through function call
  /// Returns Map data for AI to format
  Future<Map<String, dynamic>> _handleAddTransaction(
    Map<String, dynamic> args,
  ) async {
    try {
      final transactionService = _getIt<TransactionService>();
      final categoryService = _getIt<CategoryService>();

      // Extract parameters with robust null-safety
      final rawAmount = args['amount'];
      final double amount = AIHelpers.parseAmount(rawAmount);

      final String description = (args['description'] ?? 'Giao dịch')
          .toString();

      // Infer type if missing
      final String typeStr =
          (args['type'] ??
                  (description.toLowerCase().contains('lương')
                      ? 'income'
                      : 'expense'))
              .toString();

      // Provide category fallback based on type
      final String categoryName =
          (args['category'] ??
                  (typeStr.toLowerCase() == 'income' ? 'Lương' : 'Khác'))
              .toString();

      final String? rawDateStr = args['date']?.toString();

      // Improved log for transaction processing
      _logger.i(
        '💰 Adding transaction: $typeStr ${CurrencyFormatter.formatAmountWithCurrency(amount)} - $categoryName',
      );

      // Parse transaction type
      final transactionType = typeStr.toLowerCase() == 'income'
          ? TransactionType.income
          : TransactionType.expense;

      // Parse date or use current date
      DateTime transactionDate;
      if (rawDateStr != null) {
        try {
          transactionDate = DateTime.parse(rawDateStr);
        } catch (e) {
          transactionDate = DateTime.now();
        }
      } else {
        transactionDate = DateTime.now();
      }

      // Find or create category
      final categoriesStream = categoryService.getCategories(
        type: transactionType,
      );
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
        final iconData = AIHelpers.getSmartIconForCategory(
          categoryName,
          transactionType,
        );

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

      final transactionId = await transactionService.createTransaction(
        transaction,
      );

      final typeDisplay = transactionType == TransactionType.income
          ? 'Thu nhập'
          : 'Chi tiêu';
      final formattedDate = DateFormat('d/M/yyyy').format(transactionDate);

      // Return data for AI to format
      return {
        'success': true,
        'transactionId': transactionId,
        'amount': CurrencyFormatter.formatAmountWithCurrency(amount),
        'description': description,
        'date': formattedDate,
        'type': typeDisplay,
        'category': categoryName,
      };
    } catch (e) {
      _logger.e('❌ Error adding transaction: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Handle updating transaction through function call
  Future<Map<String, dynamic>> _handleUpdateTransaction(
    Map<String, dynamic> args,
  ) async {
    try {
      final transactionService = _getIt<TransactionService>();
      final categoryService = _getIt<CategoryService>();

      final String transactionId = args['transactionId'].toString();

      // Since we don't have getTransactionById exposed easily, we search in recent transactions
      // This is a workaround until we have a proper getById method
      final recentStream = transactionService.getRecentTransactions(limit: 50);
      final recent = await recentStream.first;
      TransactionModel? existingTransaction;
      try {
        existingTransaction = recent.firstWhere(
          (t) => t.transactionId == transactionId,
        );
      } catch (e) {
        // Not found in recent
      }

      if (existingTransaction == null) {
        return {
          'success': false,
          'error':
              'Transaction not found in recent history (last 50). Cannot update.',
        };
      }

      // Update fields
      double amount = existingTransaction.amount;
      if (args['amount'] != null) {
        amount = AIHelpers.parseAmount(args['amount']);
      }

      String description = existingTransaction.note ?? '';
      if (args['description'] != null) {
        description = args['description'].toString();
      }

      String categoryId = existingTransaction.categoryId;
      String categoryName = 'Updated Category'; // Placeholder

      // If category name changed, find/create new category
      if (args['category'] != null) {
        final newCatName = args['category'].toString();
        categoryName = newCatName;

        final categoriesStream = categoryService.getCategories(
          type: existingTransaction.type,
        );
        final categories = await categoriesStream.first;
        bool found = false;
        for (final cat in categories) {
          if (cat.name.toLowerCase() == newCatName.toLowerCase()) {
            categoryId = cat.categoryId;
            found = true;
            break;
          }
        }
        if (!found) {
          // Create new
          final iconData = AIHelpers.getSmartIconForCategory(
            newCatName,
            existingTransaction.type,
          );
          final newCategory = CategoryModel(
            categoryId: '',
            userId: '',
            name: newCatName,
            type: existingTransaction.type,
            icon: iconData['icon'],
            iconType: iconData['iconType'],
            color: iconData['color'],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          categoryId = await categoryService.createCategory(newCategory);
        }
      } else {
        // Get existing category name for display
        final category = await categoryService.getCategory(categoryId);
        categoryName = category?.name ?? 'Unknown';
      }

      DateTime date = existingTransaction.date;
      if (args['date'] != null) {
        try {
          date = DateTime.parse(args['date'].toString());
        } catch (_) {}
      }

      final updatedTransaction = TransactionModel(
        transactionId: transactionId,
        userId: existingTransaction.userId,
        categoryId: categoryId,
        amount: amount,
        date: date,
        type: existingTransaction.type,
        note: description,
        createdAt: existingTransaction.createdAt,
        updatedAt: DateTime.now(),
      );

      await transactionService.updateTransaction(updatedTransaction);

      final typeDisplay = updatedTransaction.type == TransactionType.income
          ? 'Thu nhập'
          : 'Chi tiêu';
      final formattedDate = DateFormat('d/M/yyyy').format(date);

      return {
        'success': true,
        'transactionId': transactionId,
        'amount': CurrencyFormatter.formatAmountWithCurrency(amount),
        'description': description,
        'date': formattedDate,
        'type': typeDisplay,
        'category': categoryName,
      };
    } catch (e) {
      _logger.e('❌ Error updating transaction: $e');
      return {'success': false, 'error': e.toString()};
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

  /// Handle get monthly report function call
  Future<String> _handleGetMonthlyReport(Map<String, dynamic> args) async {
    try {
      final transactionService = _getIt<TransactionService>();

      final int month =
          int.tryParse(args['month'].toString()) ?? DateTime.now().month;
      final int year =
          int.tryParse(args['year'].toString()) ?? DateTime.now().year;

      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(
        year,
        month + 1,
        0,
        23,
        59,
        59,
      ); // Last day of month

      final transactions = await transactionService.getTransactionsByDateRange(
        startDate,
        endDate,
      );

      if (transactions.isEmpty) {
        return 'Không có dữ liệu giao dịch nào được ghi nhận trong tháng $month/$year.';
      }

      double totalIncome = 0;
      double totalExpense = 0;

      for (var t in transactions) {
        if (t.type == TransactionType.income) {
          totalIncome += t.amount;
        } else {
          totalExpense += t.amount;
        }
      }

      final balance = totalIncome - totalExpense;

      final incomeStr = CurrencyFormatter.formatAmountWithCurrency(totalIncome);
      final expenseStr = CurrencyFormatter.formatAmountWithCurrency(
        totalExpense,
      );
      final balanceStr = CurrencyFormatter.formatAmountWithCurrency(balance);

      String report =
          '''📊 **Báo cáo tài chính Tháng $month/$year**

💰 **Tổng thu nhập:** $incomeStr
💸 **Tổng chi tiêu:** $expenseStr
⚖️ **Số dư:** $balanceStr

📝 **5 Giao dịch gần nhất:**
''';

      for (var t in transactions.take(5)) {
        final date = DateFormat('dd/MM').format(t.date);
        final amount = CurrencyFormatter.formatAmountWithCurrency(t.amount);
        final icon = t.type == TransactionType.income ? '➕' : '➖';
        final note = (t.note?.isEmpty ?? true) ? 'Giao dịch' : t.note!;
        report += '$icon **$date**: $note ($amount)\n';
      }

      report += '\n💡 *Bạn có thể xem chi tiết hơn trong tab Báo cáo.*';

      return report;
    } catch (e) {
      _logger.e('Error getting monthly report: $e');
      return '❌ Có lỗi xảy ra khi lấy báo cáo: $e';
    }
  }
}
