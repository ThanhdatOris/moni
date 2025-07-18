import '../models/category_model.dart';
import '../models/transaction_model.dart';

/// Service validation nâng cao cho transaction form
class TransactionValidationService {
  // Giới hạn số tiền
  static const double maxAmount = 1000000000; // 1 tỷ
  static const double minAmount = 0.01;
  static const double suspiciousAmount = 10000000; // 10 triệu

  // Giới hạn ghi chú
  static const int maxNoteLength = 500;
  static const int minNoteLength = 3;

  /// Kết quả validation
  static ValidationResult validateTransaction({
    required String? amountText,
    required CategoryModel? category,
    required DateTime date,
    required TransactionType type,
    String? note,
  }) {
    final errors = <String, String>{};
    final warnings = <String, String>{};

    // Validate amount
    final amountValidation = _validateAmount(amountText);
    if (amountValidation.hasError) {
      errors['amount'] = amountValidation.error!;
    }
    if (amountValidation.hasWarning) {
      warnings['amount'] = amountValidation.warning!;
    }

    // Validate category
    final categoryValidation = _validateCategory(category, type);
    if (categoryValidation.hasError) {
      errors['category'] = categoryValidation.error!;
    }

    // Validate date
    final dateValidation = _validateDate(date);
    if (dateValidation.hasError) {
      errors['date'] = dateValidation.error!;
    }
    if (dateValidation.hasWarning) {
      warnings['date'] = dateValidation.warning!;
    }

    // Validate note
    if (note != null && note.isNotEmpty) {
      final noteValidation = _validateNote(note);
      if (noteValidation.hasError) {
        errors['note'] = noteValidation.error!;
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      amount: amountValidation.amount,
    );
  }

  /// Validate amount với business rules
  static _AmountValidation _validateAmount(String? amountText) {
    if (amountText == null || amountText.isEmpty) {
      return _AmountValidation(error: 'Vui lòng nhập số tiền');
    }

    final amount = double.tryParse(amountText.replaceAll(',', ''));
    if (amount == null) {
      return _AmountValidation(error: 'Số tiền không hợp lệ');
    }

    if (amount <= 0) {
      return _AmountValidation(error: 'Số tiền phải lớn hơn 0');
    }

    if (amount < minAmount) {
      return _AmountValidation(
        error: 'Số tiền phải lớn hơn ${_formatCurrency(minAmount)}',
      );
    }

    if (amount > maxAmount) {
      return _AmountValidation(
        error: 'Số tiền không được vượt quá ${_formatCurrency(maxAmount)}',
      );
    }

    // Warning cho số tiền lớn
    String? warning;
    if (amount > suspiciousAmount) {
      warning = 'Số tiền khá lớn (${_formatCurrency(amount)}). Vui lòng kiểm tra lại.';
    }

    return _AmountValidation(amount: amount, warning: warning);
  }

  /// Validate category
  static _FieldValidation _validateCategory(CategoryModel? category, TransactionType type) {
    if (category == null) {
      return _FieldValidation(error: 'Vui lòng chọn danh mục');
    }

    if (category.isDeleted) {
      return _FieldValidation(error: 'Danh mục này đã bị xóa');
    }

    if (category.type != type) {
      return _FieldValidation(
        error: 'Danh mục không phù hợp với loại giao dịch',
      );
    }

    return _FieldValidation();
  }

  /// Validate date
  static _FieldValidation _validateDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(date.year, date.month, date.day);

    // Không được chọn ngày tương lai
    if (selectedDate.isAfter(today)) {
      return _FieldValidation(error: 'Không thể chọn ngày tương lai');
    }

    // Warning cho ngày quá xa trong quá khứ
    final daysDifference = today.difference(selectedDate).inDays;
    if (daysDifference > 90) {
      return _FieldValidation(
        warning: 'Giao dịch này cách đây $daysDifference ngày. Có chắc chắn không?',
      );
    }

    return _FieldValidation();
  }

  /// Validate note
  static _FieldValidation _validateNote(String note) {
    if (note.length < minNoteLength && note.isNotEmpty) {
      return _FieldValidation(
        error: 'Ghi chú phải có ít nhất $minNoteLength ký tự',
      );
    }

    if (note.length > maxNoteLength) {
      return _FieldValidation(
        error: 'Ghi chú không được vượt quá $maxNoteLength ký tự',
      );
    }

    // Check for suspicious patterns
    if (_containsSuspiciousContent(note)) {
      return _FieldValidation(
        warning: 'Ghi chú có thể chứa nội dung nhạy cảm',
      );
    }

    return _FieldValidation();
  }

  /// Kiểm tra nội dung nghi ngờ trong ghi chú
  static bool _containsSuspiciousContent(String note) {
    final suspiciousWords = ['password', 'pin', 'otp', 'hack', 'fraud'];
    final lowerNote = note.toLowerCase();
    
    return suspiciousWords.any((word) => lowerNote.contains(word));
  }

  /// Format currency cho error messages (public method)
  static String formatCurrency(double amount) {
    return _formatCurrency(amount);
  }

  /// Format currency cho error messages
  static String _formatCurrency(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)} tỷ VNĐ';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} triệu VNĐ';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} nghìn VNĐ';
    } else {
      return '${amount.toStringAsFixed(0)} VNĐ';
    }
  }

  /// Kiểm tra duplicate transaction
  static bool isDuplicateTransaction({
    required double amount,
    required String categoryId,
    required DateTime date,
    required List<TransactionModel> recentTransactions,
  }) {
    final sameDay = DateTime(date.year, date.month, date.day);
    
    return recentTransactions.any((transaction) {
      final transactionDay = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      
      return transaction.amount == amount &&
          transaction.categoryId == categoryId &&
          transactionDay == sameDay;
    });
  }
}

/// Kết quả validation
class ValidationResult {
  final bool isValid;
  final Map<String, String> errors;
  final Map<String, String> warnings;
  final double? amount;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    this.amount,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
}

/// Validation cho amount field
class _AmountValidation extends _FieldValidation {
  final double? amount;

  _AmountValidation({
    this.amount,
    super.error,
    super.warning,
  });
}

/// Validation cho từng field
class _FieldValidation {
  final String? error;
  final String? warning;

  _FieldValidation({this.error, this.warning});

  bool get hasError => error != null;
  bool get hasWarning => warning != null;
}
