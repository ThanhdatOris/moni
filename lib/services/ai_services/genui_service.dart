import 'package:get_it/get_it.dart';
import 'package:moni/models/assistant/chat_message_model.dart';
import 'ai_services.dart';

/// GenUI Service - Tạo dynamic UI components dựa trên AI và conversation context
class GenUIService {
  final AIProcessorService _aiService = GetIt.instance<AIProcessorService>();

  /// Generate dynamic quick actions dựa trên conversation context
  /// 
  /// Phân tích conversation history và tạo ra các quick actions phù hợp
  Future<List<String>> generateQuickActions(List<ChatMessage> messages) async {
    // Nếu chưa có messages, trả về default actions
    if (messages.isEmpty) {
      return [
        'Phân tích chi tiêu tháng này',
        'Kế hoạch tiết kiệm',
        'Đầu tư 10 triệu',
        'Tips quản lý tài chính',
      ];
    }

    // Lấy 3 messages gần nhất để phân tích context
    final recentMessages = messages.length > 3 
        ? messages.sublist(messages.length - 3)
        : messages;

    // Tạo prompt để AI generate quick actions
    final conversationContext = recentMessages
        .map((m) => '${m.isUser ? "User" : "AI"}: ${m.text}')
        .join('\n');

    final prompt = '''
Bạn là Moni AI. Phân tích cuộc trò chuyện sau và tạo ra 4 quick actions phù hợp nhất (ngắn gọn, tiếng Việt):

Conversation:
$conversationContext

Yêu cầu:
- Tạo 4 quick actions ngắn gọn (tối đa 8 từ mỗi action)
- Actions phải liên quan đến context của conversation
- Nếu conversation về chi tiêu → actions về phân tích, budget
- Nếu conversation về đầu tư → actions về đầu tư, portfolio
- Nếu conversation về tiết kiệm → actions về tiết kiệm, goals
- Trả về chỉ 4 actions, mỗi action một dòng, không đánh số

Trả về format:
Action 1
Action 2
Action 3
Action 4
''';

    try {
      final response = await _aiService.processChatInput(prompt);
      
      // Parse response thành list
      final actions = response
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .take(4)
          .map((line) => line.trim().replaceAll(RegExp(r'^\d+[\.\)]\s*'), ''))
          .where((action) => action.isNotEmpty && action.length < 50)
          .toList();

      // Nếu không đủ 4 actions, thêm default actions
      if (actions.length < 4) {
        final defaultActions = [
          'Phân tích chi tiêu tháng này',
          'Kế hoạch tiết kiệm',
          'Đầu tư 10 triệu',
          'Tips quản lý tài chính',
        ];
        final needed = 4 - actions.length;
        actions.addAll(defaultActions.take(needed));
      }

      return actions.take(4).toList();
    } catch (e) {
      // Fallback về default actions nếu có lỗi
      return [
        'Phân tích chi tiêu tháng này',
        'Kế hoạch tiết kiệm',
        'Đầu tư 10 triệu',
        'Tips quản lý tài chính',
      ];
    }
  }

  /// Generate adaptive input suggestions dựa trên conversation context
  Future<List<String>> generateInputSuggestions(List<ChatMessage> messages) async {
    if (messages.isEmpty) {
      return [
        'Chi tiêu hôm nay bao nhiêu?',
        'Tôi muốn tiết kiệm 5 triệu',
        'Đầu tư như thế nào?',
      ];
    }

    final recentMessages = messages.length > 2 
        ? messages.sublist(messages.length - 2)
        : messages;

    final conversationContext = recentMessages
        .map((m) => '${m.isUser ? "User" : "AI"}: ${m.text}')
        .join('\n');

    final prompt = '''
Bạn là Moni AI. Dựa trên conversation, tạo 3 câu hỏi/gợi ý ngắn gọn cho user tiếp tục conversation:

Conversation:
$conversationContext

Yêu cầu:
- Tạo 3 suggestions ngắn gọn (tối đa 10 từ)
- Suggestions phải tự nhiên, liên quan đến context
- Format: mỗi suggestion một dòng

Trả về format:
Suggestion 1
Suggestion 2
Suggestion 3
''';

    try {
      final response = await _aiService.processChatInput(prompt);
      
      final suggestions = response
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .take(3)
          .map((line) => line.trim().replaceAll(RegExp(r'^\d+[\.\)]\s*'), ''))
          .where((s) => s.isNotEmpty && s.length < 60)
          .toList();

      if (suggestions.length < 3) {
        final needed = 3 - suggestions.length;
        suggestions.addAll([
          'Chi tiêu hôm nay bao nhiêu?',
          'Tôi muốn tiết kiệm 5 triệu',
          'Đầu tư như thế nào?',
        ].take(needed));
      }

      return suggestions.take(3).toList();
    } catch (e) {
      return [
        'Chi tiêu hôm nay bao nhiêu?',
        'Tôi muốn tiết kiệm 5 triệu',
        'Đầu tư như thế nào?',
      ];
    }
  }

  /// Generate smart message formatting dựa trên content type
  /// Trả về widget type hoặc formatting hints
  String detectMessageType(String message) {
    final lower = message.toLowerCase();
    
    if (lower.contains('transaction') || 
        lower.contains('giao dịch') ||
        lower.contains('chi tiêu') ||
        lower.contains('thu nhập')) {
      return 'transaction';
    }
    
    if (lower.contains('budget') || 
        lower.contains('ngân sách') ||
        lower.contains('kế hoạch')) {
      return 'budget';
    }
    
    if (lower.contains('investment') || 
        lower.contains('đầu tư') ||
        lower.contains('portfolio')) {
      return 'investment';
    }
    
    if (lower.contains('analysis') || 
        lower.contains('phân tích') ||
        lower.contains('báo cáo')) {
      return 'analysis';
    }
    
    return 'general';
  }
}

