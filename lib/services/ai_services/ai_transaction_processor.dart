import 'dart:convert';
import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';

import '../core/environment_service.dart';
import 'ai_helpers.dart';
import 'ocr_service.dart';

/// Handles transaction extraction from images
/// - OCR processing
/// - Image validation
/// - AI verification of OCR results
/// - Combine OCR + AI for best results
///
/// ⚠️ OCRService is created per-request and disposed after use
/// to prevent memory leak (ML Kit TextRecognizer ~30-50 MB native memory)
class AITransactionProcessor {
  final GenerativeModel _model;
  final Logger _logger = Logger();
  final GetIt _getIt; // ✅ Use GetIt to create OCRService per-request

  AITransactionProcessor({required GenerativeModel model, required GetIt getIt})
    : _model = model,
      _getIt = getIt;

  /// Extract transaction from image using OCR + AI verification
  Future<Map<String, dynamic>> extractTransactionFromImage(
    File imageFile,
  ) async {
    // ✅ Create OCRService instance for this request
    OCRService? ocrService;

    try {
      _logger.i('📸 Processing image for transaction extraction');

      // Create new OCRService instance (Factory pattern)
      ocrService = _getIt<OCRService>();

      // Step 1: Run OCR to extract text from image
      final String extractedText = await ocrService.extractTextFromImage(
        imageFile,
      );

      if (extractedText.isEmpty) {
        return {'success': false, 'error': 'Could not extract text from image'};
      }

      _logger.d('📝 OCR extracted ${extractedText.length} characters');

      // Step 2: Analyze extracted text with OCR service
      final ocrAnalysis = ocrService.analyzeReceiptText(extractedText);
      final int ocrConfidence = 75; // OCR base confidence

      // Step 3: If OCR analysis is confident, use it directly
      if (ocrConfidence >= 80) {
        _logger.i('✅ OCR confidence high ($ocrConfidence%), using OCR results');
        return _buildResult(
          extractedText,
          ocrAnalysis,
          {},
          ocrConfidence,
          useAI: false,
        );
      }

      // Step 4: Use AI to verify and improve OCR results
      _logger.i('🤖 OCR confidence low ($ocrConfidence%), verifying with AI');
      final aiAnalysis = await _analyzeTextWithAI(extractedText, ocrAnalysis);

      // Step 5: Combine OCR and AI results
      return _buildResult(
        extractedText,
        ocrAnalysis,
        aiAnalysis,
        ocrConfidence,
        useAI: true,
      );
    } catch (e) {
      _logger.e('❌ Error extracting transaction from image: $e');
      return {'success': false, 'error': e.toString()};
    } finally {
      // ✅ CRITICAL: Always dispose OCRService to free native memory
      // This prevents memory leak of ~30-50 MB from ML Kit TextRecognizer
      ocrService?.dispose();
      _logger.d('🧹 OCRService disposed (freed native memory)');
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
          'Định dạng ảnh không được hỗ trợ. Vui lòng chọn file JPG hoặc PNG.',
        );
      }

      return true;
    } catch (e) {
      _logger.e('Image validation failed: $e');
      rethrow;
    }
  }

  /// Analyze text with AI to verify OCR results
  Future<Map<String, dynamic>> _analyzeTextWithAI(
    String text,
    Map<String, dynamic> ocrAnalysis,
  ) async {
    try {
      final prompt =
          '''
Phân tích văn bản sau và trích xuất thông tin giao dịch. Văn bản này đã được OCR từ ảnh (có thể là hóa đơn hoặc thông báo ngân hàng).

Văn bản:
"""
$text
"""

Kết quả ban đầu từ OCR:
- Số tiền gợi ý: ${ocrAnalysis['suggestedAmount']}
- Tên cửa hàng: ${ocrAnalysis['merchantName']}
- Loại giao dịch: ${ocrAnalysis['transactionType']}
- Danh mục gợi ý: ${ocrAnalysis['categoryHint']}

QUAN TRỌNG - Xác định loại văn bản và xử lý phù hợp:

📱 NẾU LÀ THÔNG BÁO NGÂN HÀNG (SMS/App notification):
- Tìm các từ khóa: "GD", "Giao dich", "Chuyen tien", "Nhan tien", "Thanh toan", "Rut tien", "Nap tien"
- LẤY SỐ TIỀN GIAO DỊCH (transaction amount), KHÔNG LẤY SỐ DƯ (balance/so du)
- Ví dụ: "GD: -50,000 VND. So du: 1,500,000 VND" → Lấy 50000, không lấy 1500000
- Số tiền thường có dấu +/- phía trước
- Số dư thường có từ "so du", "balance", "SD" kèm theo

🧾 NẾU LÀ HÓA ĐƠN MUA BÁN (Receipt/Invoice):
- Ưu tiên tìm THEO THỨ TỰ (từ quan trọng nhất → ít quan trọng):
  1. "Tổng cộng", "Thành tiền", "Total", "Grand Total", "Amount Due", "Tổng thanh toán"
  2. Nếu có nhiều mục, tìm số tiền cuối cùng SAU KHI đã:
     - Cộng thuế (VAT, Tax, Thuế)
     - Trừ giảm giá (Discount, Giảm giá, Khuyến mại)
     - Cộng phí dịch vụ (Service charge)
  3. TRÁNH lấy: "Tạm tính", "Subtotal", số tiền từng món riêng lẻ

QUY TẮC CHUNG:
- Nếu có cả "Tạm tính: 100k" và "Tổng cộng: 110k" → Lấy 110k
- Nếu có cả "Subtotal: 100k", "Tax: 10k", "Total: 110k" → Lấy 110k
- Với nhiều số tiền, ưu tiên số có nhãn "Total", "Tổng", "Thành tiền"
- Số tiền thường ở cuối hóa đơn, sau các dòng chi tiết

Trả về JSON với format:
{
  "verified_amount": số_tiền_chính_xác (số nguyên, không dấu phẩy),
  "description": "mô tả ngắn gọn về giao dịch",
  "category_suggestion": "danh mục phù hợp bằng tiếng Việt",
  "transaction_type": "expense" hoặc "income",
  "confidence_score": số từ 0-100,
  "notes": "ghi chú bổ sung (ví dụ: đã tính thuế 10%, giảm giá 5k)",
  "document_type": "bank_notification" hoặc "receipt"
}

Danh mục gợi ý: Ăn uống, Di chuyển, Mua sắm, Giải trí, Y tế, Học tập, Hóa đơn, Chuyển tiền, Thu nhập, Lương, Khác

VÍ DỤ PHÂN TÍCH:

Ví dụ 1 - Thông báo ngân hàng:
"TK 9704229304857264 GD -18,000 VND luc 11:30 20/01. So du 2,456,789 VND"
→ verified_amount: 18000 (không lấy 2456789)
→ document_type: "bank_notification"

Ví dụ 2 - Hóa đơn nhiều mục:
"Com tam: 35,000
Nuoc ngot: 15,000
Tam tinh: 50,000
Thue VAT 10%: 5,000
Tong cong: 55,000"
→ verified_amount: 55000 (không lấy 50000 tạm tính)
→ document_type: "receipt"
''';

      final response = await _model.generateContent([Content.text(prompt)]);

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
      final double verifiedAmount = AIHelpers.parseAmount(
        data['verified_amount'],
      );
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
      final String documentType = (data['document_type'] ?? 'receipt')
          .toString();

      return {
        'verified_amount': verifiedAmount,
        'description': description,
        'category_suggestion': categorySuggestion,
        'transaction_type': transactionType == 'income' ? 'income' : 'expense',
        'confidence_score': confidenceScore.clamp(0, 100),
        'notes': notes,
        'document_type': documentType,
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
    int ocrConfidence, {
    required bool useAI,
  }) {
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
    final combinedConfidence = useAI
        ? ((ocrConfidence + aiConfidence) / 2).round()
        : ocrConfidence;

    final notes = useAI && aiAnalysis.isNotEmpty
        ? (aiAnalysis['notes'] ?? '')
        : '';

    final documentType = useAI && aiAnalysis.isNotEmpty
        ? (aiAnalysis['document_type'] ?? 'receipt')
        : 'receipt';

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
      'note': notes.isNotEmpty ? notes : description,
      'category_name': category,
      'document_type': documentType,
    };
  }
}
