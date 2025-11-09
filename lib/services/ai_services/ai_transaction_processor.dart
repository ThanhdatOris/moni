import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';

import '../core/environment_service.dart';
import 'ai_helpers.dart';
import 'ai_token_manager.dart';
import 'ocr_service.dart';

/// Handles transaction extraction from images
/// - OCR processing
/// - Image validation
/// - AI verification of OCR results
/// - Combine OCR + AI for best results
class AITransactionProcessor {
  final GenerativeModel _model;
  final Logger _logger = Logger();
  final OCRService _ocrService;
  final AITokenManager _tokenManager;

  AITransactionProcessor({
    required GenerativeModel model,
    required OCRService ocrService,
    required AITokenManager tokenManager,
  })  : _model = model,
        _ocrService = ocrService,
        _tokenManager = tokenManager;

  /// Extract transaction from image using OCR + AI verification
  Future<Map<String, dynamic>> extractTransactionFromImage(
      File imageFile) async {
    try {
      _logger.i('📸 Processing image for transaction extraction');

      // Step 1: Run OCR to extract text from image
      final String extractedText =
          await _ocrService.extractTextFromImage(imageFile);

      if (extractedText.isEmpty) {
        return {
          'success': false,
          'error': 'Could not extract text from image',
        };
      }

      _logger.d('📝 OCR extracted ${extractedText.length} characters');

      // Step 2: Analyze extracted text with OCR service
      final ocrAnalysis = _ocrService.analyzeReceiptText(extractedText);
      final int ocrConfidence = 75; // OCR base confidence

      // Step 3: If OCR analysis is confident, use it directly
      if (ocrConfidence >= 80) {
        _logger.i('✅ OCR confidence high ($ocrConfidence%), using OCR results');
        return _buildResult(
            extractedText, ocrAnalysis, {}, ocrConfidence,
            useAI: false);
      }

      // Step 4: Use AI to verify and improve OCR results
      _logger.i('🤖 OCR confidence low ($ocrConfidence%), verifying with AI');
      final aiAnalysis = await _analyzeTextWithAI(extractedText, ocrAnalysis);

      // Step 5: Combine OCR and AI results
      return _buildResult(
          extractedText, ocrAnalysis, aiAnalysis, ocrConfidence,
          useAI: true);
    } catch (e) {
      _logger.e('❌ Error extracting transaction from image: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Validate image before processing
  Future<bool> validateImageForProcessing(File imageFile) async {
    try {
      // Check file size (max 4MB)
      final fileSize = await imageFile.length();
      if (fileSize > 4 * 1024 * 1024) {
        throw Exception('Ảnh quá lớn. Vui lòng chọn ảnh nhỏ hơn 4MB.');
      }

      // Check file format
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

  /// Analyze text with AI to verify OCR results
  Future<Map<String, dynamic>> _analyzeTextWithAI(
      String text, Map<String, dynamic> ocrAnalysis) async {
    try {
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

      // Check usage before API call
      await AIHelpers.checkUsageBeforeCall(_tokenManager, prompt);

      final response = await _model.generateContent([Content.text(prompt)]);
      
      // Update token usage after API call
      await AIHelpers.updateUsageAfterCall(_tokenManager, prompt, response.text ?? '');

      final responseText = response.text ?? '';
      final parsedResult = _parseAIAnalysisResponse(responseText);

      return parsedResult;
    } catch (e) {
      _logger.e('Error in AI analysis: $e');
      return {};
    }
  }

  /// Parse AI analysis response (JSON)
  Map<String, dynamic> _parseAIAnalysisResponse(String response) {
    try {
      // Find JSON in response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}');

      if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
        return {};
      }

      final jsonString = response.substring(jsonStart, jsonEnd + 1);

      if (EnvironmentService.debugMode) {
        _logger.d('🔍 AI Analysis JSON: ${jsonString.length} chars');
      }

      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return {};
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(decoded);

      // Normalize keys and data types
      final double verifiedAmount =
          AIHelpers.parseAmount(data['verified_amount']);
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

  /// Build final result combining OCR and AI
  Map<String, dynamic> _buildResult(
      String extractedText,
      Map<String, dynamic> ocrAnalysis,
      Map<String, dynamic> aiAnalysis,
      int ocrConfidence,
      {required bool useAI}) {
    final amount = useAI && aiAnalysis.isNotEmpty
        ? (aiAnalysis['verified_amount'] ?? ocrAnalysis['suggestedAmount'])
        : ocrAnalysis['suggestedAmount'];

    final description = useAI && aiAnalysis.isNotEmpty
        ? (aiAnalysis['description'] ?? 'Giao dịch từ hóa đơn')
        : (ocrAnalysis['merchantName'] ?? 'Giao dịch từ hóa đơn');

    final category = useAI && aiAnalysis.isNotEmpty
        ? (aiAnalysis['category_suggestion'] ?? ocrAnalysis['categoryHint'])
        : ocrAnalysis['categoryHint'];

    final type = useAI && aiAnalysis.isNotEmpty
        ? (aiAnalysis['transaction_type'] ?? ocrAnalysis['transactionType'])
        : ocrAnalysis['transactionType'];

    // Calculate combined confidence
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
      'raw_text': extractedText,
      'processing_method': useAI ? 'OCR + AI' : 'OCR only',
      'note': description,
      'category_name': category,
    };
  }
}
