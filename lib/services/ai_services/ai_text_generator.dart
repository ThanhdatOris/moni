import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';

import 'ai_helpers.dart';
import 'ai_token_manager.dart';

/// Handles generic text generation and analysis
/// - Answer financial questions
/// - Generate text from prompts
/// - Analyze spending habits
class AITextGenerator {
  final GenerativeModel _model;
  final Logger _logger = Logger();
  final AITokenManager _tokenManager;

  AITextGenerator({
    required GenerativeModel model,
    required AITokenManager tokenManager,
  })  : _model = model,
        _tokenManager = tokenManager;

  /// Generate text from prompt (no caching, direct API call)
  Future<String> generateText(String prompt) async {
    try {
      await _tokenManager.checkRateLimit();
      
      final estimatedTokens = AIHelpers.estimateTokens(prompt);
      if (_tokenManager.hasExceededQuota(estimatedTokens)) {
        return 'Quota AI đã vượt giới hạn ngày hôm nay.';
      }

      final response = await _model.generateContent([Content.text(prompt)]);
      final result = response.text ?? '';

      // Update token count
      await _tokenManager.updateTokenCount(
          estimatedTokens + AIHelpers.estimateTokens(result));
      return result;
    } catch (e) {
      _logger.e('Error generateText: $e');
      return '';
    }
  }

  /// Answer financial questions
  Future<String> answerQuestion(String question) async {
    try {
      _logger.i('💡 Processing financial question (${question.length} chars)');

      final prompt = '''
You are a personal finance expert. Answer professionally in Vietnamese with practical advice for Vietnam context.

Question: "$question"
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final result = response.text ??
          'Xin lỗi, tôi không thể trả lời câu hỏi này lúc này.';

      return result;
    } catch (e) {
      _logger.e('❌ Error answering question: $e');
      return 'Xin lỗi, đã có lỗi xảy ra khi trả lời câu hỏi của bạn.';
    }
  }

  /// Analyze spending habits and give advice
  Future<String> analyzeSpendingHabits(
      Map<String, dynamic> transactionData) async {
    try {
      _logger.i(
          '📊 Analyzing spending habits (${transactionData.keys.length} data points)');

      final prompt = '''
Analyze spending habits and give specific advice to improve personal finance. Answer in Vietnamese with clear structure.

Data: ${transactionData.toString()}
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Không thể phân tích dữ liệu lúc này.';
    } catch (e) {
      _logger.e('❌ Error analyzing spending habits: $e');
      return 'Đã có lỗi xảy ra khi phân tích thói quen chi tiêu.';
    }
  }
}
