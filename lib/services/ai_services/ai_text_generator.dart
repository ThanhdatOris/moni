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
  final GenerativeModel? _fallbackModel1;
  final GenerativeModel? _fallbackModel2;
  final Logger _logger = Logger();
  final AITokenManager _tokenManager;

  AITextGenerator({
    required GenerativeModel model,
    GenerativeModel? fallbackModel1,
    GenerativeModel? fallbackModel2,
    required AITokenManager tokenManager,
  })  : _model = model,
        _fallbackModel1 = fallbackModel1,
        _fallbackModel2 = fallbackModel2,
        _tokenManager = tokenManager;

  /// Generate text from prompt (no caching, direct API call)
  /// Tự động fallback sang model khác nếu model hiện tại không khả dụng
  Future<String> generateText(String prompt) async {
    // Check usage before API call
    await AIHelpers.checkUsageBeforeCall(_tokenManager, prompt);

    // Thử primary model trước
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final result = response.text ?? '';

      // Update token usage after API call
      await AIHelpers.updateUsageAfterCall(_tokenManager, prompt, result);

      return result;
    } catch (e) {
      // Check if it's a model not found error
      final errorStr = e.toString();
      if (errorStr.contains('not found') ||
          errorStr.contains('not supported')) {
        _logger.w('⚠️ Primary model failed, trying fallback models...');

        // Thử fallback model 1
        final fallback1 = _fallbackModel1;
        if (fallback1 != null) {
          try {
            _logger.d('🔄 Trying fallback model 1...');
            final response =
                await fallback1.generateContent([Content.text(prompt)]);
            final result = response.text ?? '';
            await AIHelpers.updateUsageAfterCall(_tokenManager, prompt, result);
            return result;
          } catch (e2) {
            _logger.w('⚠️ Fallback model 1 failed, trying fallback model 2...');

            // Thử fallback model 2
            final fallback2 = _fallbackModel2;
            if (fallback2 != null) {
              try {
                _logger.d('🔄 Trying fallback model 2...');
                final response =
                    await fallback2.generateContent([Content.text(prompt)]);
                final result = response.text ?? '';
                await AIHelpers.updateUsageAfterCall(
                    _tokenManager, prompt, result);
                return result;
              } catch (e3) {
                _logger.e('❌ All models failed: $e3');
              }
            }
          }
        }
      }

      _logger.e('Error generateText: $e');

      // Check if it's a real quota error from Google
      if (errorStr.contains('429') || errorStr.contains('quota')) {
        return 'Quota AI đã vượt giới hạn. Vui lòng thử lại sau.';
      }

      return '';
    }
  }

  /// Answer financial questions
  Future<String> answerQuestion(String question) async {
    _logger.i('💡 Processing financial question (${question.length} chars)');

    final prompt = '''
You are a personal finance expert. Answer professionally in Vietnamese with practical advice for Vietnam context.

Question: "$question"
''';

    // Sử dụng generateText để có fallback tự động
    final result = await generateText(prompt);

    if (result.isEmpty) {
      return 'Xin lỗi, đã có lỗi xảy ra khi trả lời câu hỏi của bạn.';
    }

    return result;
  }

  /// Analyze spending habits and give advice
  Future<String> analyzeSpendingHabits(
      Map<String, dynamic> transactionData) async {
    _logger.i(
        '📊 Analyzing spending habits (${transactionData.keys.length} data points)');

    final prompt = '''
Analyze spending habits and give specific advice to improve personal finance. Answer in Vietnamese with clear structure.

Data: ${transactionData.toString()}
''';

    // Sử dụng generateText để có fallback tự động
    final result = await generateText(prompt);

    if (result.isEmpty) {
      return 'Đã có lỗi xảy ra khi phân tích thói quen chi tiêu.';
    }

    return result;
  }
}
