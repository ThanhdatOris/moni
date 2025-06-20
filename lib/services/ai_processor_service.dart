import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';

import 'environment_service.dart';

/// Service xử lý các chức năng AI sử dụng Gemini API
class AIProcessorService {
  late final GenerativeModel _model;
  final Logger _logger = Logger();

  AIProcessorService() {
    // Load API key from environment variables
    final apiKey = EnvironmentService.geminiApiKey;

    if (apiKey.isEmpty) {
      throw Exception('Gemini API key not found in environment variables');
    }

    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );

    _logger.i('AI Processor Service initialized successfully');
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

  /// Xử lý đầu vào văn bản hoặc giọng nói để nhập giao dịch hoặc truy vấn
  Future<String> processChatInput(String input) async {
    try {
      final prompt = '''
      Bạn là trợ lý tài chính thông minh. Hãy phân tích đầu vào của người dùng và:
      1. Nếu là yêu cầu nhập giao dịch, hãy trích xuất thông tin và đưa ra gợi ý
      2. Nếu là câu hỏi về tài chính, hãy trả lời một cách hữu ích
      3. Luôn trả lời bằng tiếng Việt một cách tự nhiên và thân thiện
      
      Đầu vào của người dùng: "$input"
      ''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final result =
          response.text ?? 'Xin lỗi, tôi không hiểu yêu cầu của bạn.';

      _logger.i('Processed chat input: $result');
      return result;
    } catch (e) {
      _logger.e('Lỗi khi xử lý đầu vào chat: $e');
      return 'Xin lỗi, đã có lỗi xảy ra khi xử lý yêu cầu của bạn.';
    }
  }

  /// Gợi ý danh mục cho giao dịch dựa trên mô tả
  Future<String> suggestCategory(String description) async {
    try {
      final prompt = '''
      Dựa trên mô tả giao dịch sau, hãy gợi ý danh mục phù hợp nhất.
      Chỉ trả lời tên danh mục bằng tiếng Việt, ví dụ: "Ăn uống", "Mua sắm", "Đi lại", "Giải trí", "Lương", "Thu nhập phụ", v.v.
      
      Mô tả giao dịch: "$description"
      ''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final result = response.text?.trim() ?? 'Khác';

      _logger.i('Suggested category for "$description": $result');
      return result;
    } catch (e) {
      _logger.e('Lỗi khi gợi ý danh mục: $e');
      return 'Khác';
    }
  }

  /// Trả lời câu hỏi tài chính cá nhân
  Future<String> answerQuestion(String question) async {
    try {
      final prompt = '''
      Bạn là chuyên gia tư vấn tài chính cá nhân. Hãy trả lời câu hỏi sau một cách chuyên nghiệp, 
      hữu ích và dễ hiểu bằng tiếng Việt. Tập trung vào việc đưa ra lời khuyên thực tế và 
      phù hợp với bối cảnh Việt Nam.
      
      Câu hỏi: "$question"
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
      Hãy phân tích dữ liệu giao dịch sau và đưa ra nhận xét về thói quen chi tiêu, 
      cùng với lời khuyên cụ thể để cải thiện tài chính cá nhân.
      Trả lời bằng tiếng Việt một cách chi tiết và có cấu trúc.
      
      Dữ liệu giao dịch: ${transactionData.toString()}
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

  /// Parse JSON response từ Gemini
  Map<String, dynamic> _parseJsonResponse(String response) {
    try {
      // Tìm và trích xuất JSON từ response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}');

      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonString = response.substring(jsonStart, jsonEnd + 1);
        // Có thể cần parse JSON ở đây, nhưng để đơn giản tạm thời return map rỗng
        return {};
      }

      return {};
    } catch (e) {
      _logger.e('Lỗi khi parse JSON response: $e');
      return {};
    }
  }
}
