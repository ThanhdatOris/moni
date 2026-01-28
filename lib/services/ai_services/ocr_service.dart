import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:logger/logger.dart';

/// Service để nhận dạng văn bản từ ảnh sử dụng Google ML Kit
class OCRService {
  late final TextRecognizer _textRecognizer;
  final Logger _logger = Logger();

  OCRService() {
    _textRecognizer = TextRecognizer();
    _logger.i('OCR Service initialized with Google ML Kit');
  }

  /// Trích xuất văn bản từ ảnh
  Future<String> extractTextFromImage(File imageFile) async {
    try {
      _logger.i('Starting text recognition for image: ${imageFile.path}');

      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final extractedText = recognizedText.text;
      _logger.i('Extracted text: $extractedText');

      return extractedText;
    } catch (e) {
      _logger.e('Error extracting text from image: $e');
      throw Exception('Không thể đọc văn bản từ ảnh: $e');
    }
  }

  /// Trích xuất văn bản có cấu trúc với thông tin vị trí
  Future<Map<String, dynamic>> extractStructuredTextFromImage(
    File imageFile,
  ) async {
    try {
      _logger.i(
        'Starting structured text recognition for image: ${imageFile.path}',
      );

      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final List<Map<String, dynamic>> textBlocks = [];
      final List<String> allLines = [];

      for (final TextBlock block in recognizedText.blocks) {
        final Map<String, dynamic> blockData = {
          'text': block.text,
          'boundingBox': {
            'left': block.boundingBox.left,
            'top': block.boundingBox.top,
            'right': block.boundingBox.right,
            'bottom': block.boundingBox.bottom,
          },
          'lines': <Map<String, dynamic>>[],
        };

        for (final TextLine line in block.lines) {
          allLines.add(line.text);
          blockData['lines'].add({
            'text': line.text,
            'boundingBox': {
              'left': line.boundingBox.left,
              'top': line.boundingBox.top,
              'right': line.boundingBox.right,
              'bottom': line.boundingBox.bottom,
            },
          });
        }

        textBlocks.add(blockData);
      }

      final result = {
        'fullText': recognizedText.text,
        'lines': allLines,
        'blocks': textBlocks,
        'confidence': _calculateConfidence(recognizedText),
      };

      _logger.i(
        'Structured text extraction completed with ${textBlocks.length} blocks',
      );
      return result;
    } catch (e) {
      _logger.e('Error extracting structured text from image: $e');
      throw Exception('Không thể đọc văn bản có cấu trúc từ ảnh: $e');
    }
  }

  /// Phân tích văn bản hóa đơn để tìm số tiền và thông tin quan trọng
  Map<String, dynamic> analyzeReceiptText(String text) {
    try {
      _logger.i('Analyzing receipt text for transaction info...');

      final lines = text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      // Tìm số tiền (các pattern phổ biến ở Việt Nam)
      final amounts = _extractAmounts(lines);

      // Tìm ngày
      final date = _extractDate(lines);

      // Tìm tên cửa hàng (thường ở đầu hóa đơn)
      final merchantName = _extractMerchantName(lines);

      // Phân loại loại giao dịch
      final transactionType = _determineTransactionType(text);

      // Gợi ý danh mục dựa trên context
      final categoryHint = _suggestCategory(text);

      final result = {
        'amounts': amounts,
        'suggestedAmount': amounts.isNotEmpty
            ? amounts.reduce((a, b) => a > b ? a : b)
            : 0.0,
        'date': date,
        'merchantName': merchantName,
        'transactionType': transactionType,
        'categoryHint': categoryHint,
        'rawText': text,
        'processedLines': lines,
      };

      _logger.i('Receipt analysis completed: $result');
      return result;
    } catch (e) {
      _logger.e('Error analyzing receipt text: $e');
      return {
        'amounts': <double>[],
        'suggestedAmount': 0.0,
        'date': null,
        'merchantName': '',
        'transactionType': 'expense',
        'categoryHint': 'Khác',
        'rawText': text,
        'processedLines': <String>[],
      };
    }
  }

  /// Tìm và trích xuất số tiền từ text
  List<double> _extractAmounts(List<String> lines) {
    final amounts = <double>[];
    final String fullText = lines.join('\n').toLowerCase();

    // Kiểm tra xem có phải thông báo ngân hàng không
    final isBankNotification = _isBankNotification(fullText);

    if (isBankNotification) {
      // Xử lý thông báo ngân hàng - chỉ lấy transaction amount, bỏ qua số dư
      return _extractBankTransactionAmount(lines);
    }

    // Xử lý hóa đơn thông thường - ưu tiên tổng tiền cuối cùng
    final priorityAmounts = _extractPriorityAmounts(lines);
    if (priorityAmounts.isNotEmpty) {
      return priorityAmounts;
    }

    // Fallback: extract tất cả số tiền
    final patterns = [
      RegExp(
        r'(\d{1,3}(?:[,\.]\d{3})*(?:[,\.]\d{2})?)\s*(?:VND|vnđ|đ|VNĐ)',
        caseSensitive: false,
      ),
      RegExp(
        r'(\d{1,3}(?:[,\.]\d{3})*)\s*(?:k|K)',
        caseSensitive: false,
      ), // 50k format
      RegExp(
        r'(\d{1,3}(?:[,\.]\d{3})*)\s*(?:tr|TR|triệu)',
        caseSensitive: false,
      ), // 1tr format
      RegExp(r'(\d{1,3}(?:[,\.]\d{3})*(?:[,\.]\d{2})?)\s*$'), // Số ở cuối dòng
    ];

    for (final line in lines) {
      for (final pattern in patterns) {
        final matches = pattern.allMatches(line);
        for (final match in matches) {
          final amountStr = match.group(1);
          if (amountStr != null) {
            double? amount = _parseVietnameseAmount(amountStr, line);
            if (amount != null && amount > 0) {
              amounts.add(amount);
            }
          }
        }
      }
    }

    // Loại bỏ duplicates và sort
    final uniqueAmounts = amounts.toSet().toList();
    uniqueAmounts.sort((a, b) => b.compareTo(a));

    return uniqueAmounts;
  }

  /// Kiểm tra xem có phải thông báo ngân hàng không
  bool _isBankNotification(String text) {
    final bankKeywords = [
      'giao dich',
      'chuyen tien',
      'nhan tien',
      'thanh toan',
      'so du',
      'balance',
      'tk ',
      'tai khoan',
      'ngan hang',
      'rut tien',
      'nap tien',
      RegExp(r'\bGD\b'),
      RegExp(r'\bSD\b'),
    ];

    for (final keyword in bankKeywords) {
      if (keyword is RegExp) {
        if (keyword.hasMatch(text)) return true;
      } else if (text.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  /// Trích xuất số tiền giao dịch từ thông báo ngân hàng (không lấy số dư)
  List<double> _extractBankTransactionAmount(List<String> lines) {
    final amounts = <double>[];

    for (final line in lines) {
      final lowerLine = line.toLowerCase();

      // Bỏ qua dòng có chứa "số dư" hoặc "balance"
      if (lowerLine.contains('so du') ||
          lowerLine.contains('balance') ||
          lowerLine.contains(RegExp(r'\bsd\b'))) {
        continue;
      }

      // Tìm số tiền có dấu +/- (transaction amount)
      final transactionPattern = RegExp(
        r'[+\-]\s*(\d{1,3}(?:[,\.]\d{3})*(?:[,\.]\d{2})?)',
        caseSensitive: false,
      );

      final match = transactionPattern.firstMatch(line);
      if (match != null) {
        final amountStr = match.group(1);
        if (amountStr != null) {
          final amount = _parseVietnameseAmount(amountStr, line);
          if (amount != null && amount > 0) {
            amounts.add(amount);
          }
        }
      }

      // Nếu không có dấu +/-, tìm số tiền có "GD" hoặc "giao dich"
      if (amounts.isEmpty &&
          (lowerLine.contains('gd') || lowerLine.contains('giao dich'))) {
        final amountPattern = RegExp(
          r'(\d{1,3}(?:[,\.]\d{3})*(?:[,\.]\d{2})?)',
          caseSensitive: false,
        );
        final matches = amountPattern.allMatches(line);

        // Lấy số tiền đầu tiên tìm được (thường là transaction amount)
        if (matches.isNotEmpty) {
          final firstMatch = matches.first;
          final amountStr = firstMatch.group(1);
          if (amountStr != null) {
            final amount = _parseVietnameseAmount(amountStr, line);
            if (amount != null && amount > 0) {
              amounts.add(amount);
              break;
            }
          }
        }
      }
    }

    return amounts.isNotEmpty ? amounts : [];
  }

  /// Trích xuất số tiền ưu tiên từ hóa đơn (Total, Tổng cộng, Thành tiền)
  List<double> _extractPriorityAmounts(List<String> lines) {
    final priorityKeywords = [
      'tong cong',
      'tổng cộng',
      'thanh tien',
      'thành tiền',
      'total',
      'grand total',
      'amount due',
      'tong thanh toan',
      'tổng thanh toán',
      'can thanh toan',
      'cần thanh toán',
    ];

    // Tìm từ cuối lên đầu (tổng tiền thường ở cuối hóa đơn)
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      final lowerLine = line.toLowerCase();

      // Kiểm tra xem dòng có chứa keyword ưu tiên không
      for (final keyword in priorityKeywords) {
        if (lowerLine.contains(keyword)) {
          // Trích xuất số tiền từ dòng này
          final amountPattern = RegExp(
            r'(\d{1,3}(?:[,\.]\d{3})*(?:[,\.]\d{2})?)',
            caseSensitive: false,
          );

          final matches = amountPattern.allMatches(line);
          if (matches.isNotEmpty) {
            // Lấy số tiền cuối cùng trong dòng (thường là số tiền chính)
            final lastMatch = matches.last;
            final amountStr = lastMatch.group(1);
            if (amountStr != null) {
              final amount = _parseVietnameseAmount(amountStr, line);
              if (amount != null && amount > 0) {
                return [amount];
              }
            }
          }
        }
      }
    }

    return [];
  }

  /// Parse số tiền theo format Việt Nam
  double? _parseVietnameseAmount(String amountStr, String fullLine) {
    try {
      // Xử lý format k, tr
      if (fullLine.toLowerCase().contains(RegExp(r'\b\d+k\b'))) {
        final number = double.tryParse(
          amountStr.replaceAll(RegExp(r'[,\.]'), ''),
        );
        return number != null ? number * 1000 : null;
      }

      if (fullLine.toLowerCase().contains(RegExp(r'\b\d+tr\b'))) {
        final number = double.tryParse(
          amountStr.replaceAll(RegExp(r'[,\.]'), ''),
        );
        return number != null ? number * 1000000 : null;
      }

      // Xử lý format thông thường
      final cleanAmount = amountStr.replaceAll(',', '').replaceAll('.', '');
      return double.tryParse(cleanAmount);
    } catch (e) {
      return null;
    }
  }

  /// Trích xuất ngày từ text
  String? _extractDate(List<String> lines) {
    final datePatterns = [
      RegExp(r'(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})'),
      RegExp(r'(\d{2,4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,2})'),
    ];

    for (final line in lines) {
      for (final pattern in datePatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          return match.group(1);
        }
      }
    }

    return null;
  }

  /// Trích xuất tên cửa hàng
  String _extractMerchantName(List<String> lines) {
    if (lines.isEmpty) return '';

    // Tên cửa hàng thường ở 1-3 dòng đầu
    for (int i = 0; i < 3 && i < lines.length; i++) {
      final line = lines[i];
      // Bỏ qua dòng chỉ có số hoặc ký tự đặc biệt
      if (line.length >= 3 &&
          RegExp(
            r'[a-zA-Zàáảãạăắằẳẵặâấầẩẫậèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵđ]',
          ).hasMatch(line)) {
        return line;
      }
    }

    return lines.isNotEmpty ? lines.first : '';
  }

  /// Xác định loại giao dịch
  String _determineTransactionType(String text) {
    final incomeKeywords = [
      'thu',
      'nhận',
      'lương',
      'thưởng',
      'income',
      'salary',
      'bonus',
    ];

    final lowerText = text.toLowerCase();

    for (final keyword in incomeKeywords) {
      if (lowerText.contains(keyword)) {
        return 'income';
      }
    }

    // Mặc định là expense vì hầu hết hóa đơn là chi tiêu
    return 'expense';
  }

  /// Gợi ý danh mục dựa trên nội dung
  String _suggestCategory(String text) {
    final lowerText = text.toLowerCase();

    // Ăn uống
    if (lowerText.contains(
      RegExp(r'(cơm|phở|bún|bánh|cafe|coffee|restaurant|food|ăn|uống|nước)'),
    )) {
      return 'Ăn uống';
    }

    // Di chuyển
    if (lowerText.contains(
      RegExp(r'(grab|taxi|uber|xăng|petrol|gas|xe|bus)'),
    )) {
      return 'Di chuyển';
    }

    // Mua sắm
    if (lowerText.contains(
      RegExp(r'(shop|mall|market|siêu thị|cửa hàng|mua|shopping)'),
    )) {
      return 'Mua sắm';
    }

    // Y tế
    if (lowerText.contains(
      RegExp(
        r'(hospital|clinic|pharmacy|nhà thuốc|bệnh viện|phòng khám|thuốc)',
      ),
    )) {
      return 'Y tế';
    }

    // Giải trí
    if (lowerText.contains(
      RegExp(r'(cinema|movie|game|entertainment|karaoke|massage)'),
    )) {
      return 'Giải trí';
    }

    return 'Khác';
  }

  /// Tính độ tin cậy của OCR
  int _calculateConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 0;

    int totalChars = 0;
    int validChars = 0;

    for (final block in recognizedText.blocks) {
      final text = block.text;
      totalChars += text.length;

      // Đếm ký tự hợp lệ (chữ, số, dấu câu phổ biến)
      validChars += text
          .split('')
          .where(
            (char) => RegExp(
              r'[a-zA-Z0-9àáảãạăắằẳẵặâấầẩẫậèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵđĐ\s\-\.,/()%]',
            ).hasMatch(char),
          )
          .length;
    }

    if (totalChars == 0) return 0;

    final confidence = ((validChars / totalChars) * 100).round();
    return confidence.clamp(0, 100);
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
    _logger.i('OCR Service disposed');
  }
}
