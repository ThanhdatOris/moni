import 'dart:math';

import 'package:moni/constants/enums.dart';

import '../../models/category_model.dart';
import '../../models/transaction_model.dart';

/// Service validation nâng cao
class AdvancedValidationService {
  static const double _unusualAmountThreshold = 500000; // 500k VND
  static const int _maxTransactionsPerMinute = 5;
  static const int _maxSimilarTransactionsPerDay = 3;

  /// Kiểm tra pattern chi tiêu bất thường
  static Future<ValidationResult> validateSpendingPattern({
    required TransactionModel newTransaction,
    required List<TransactionModel> recentTransactions,
    required List<CategoryModel> categories,
  }) async {
    final warnings = <String, String>{};
    final errors = <String, String>{};

    // 1. Kiểm tra số tiền bất thường
    final unusualAmountResult = _checkUnusualAmount(
      newTransaction,
      recentTransactions,
    );
    if (unusualAmountResult.hasWarnings) {
      warnings.addAll(unusualAmountResult.warnings);
    }

    // 2. Kiểm tra tần suất giao dịch
    final frequencyResult = _checkTransactionFrequency(
      newTransaction,
      recentTransactions,
    );
    if (frequencyResult.hasWarnings) {
      warnings.addAll(frequencyResult.warnings);
    }

    // 3. Kiểm tra pattern thời gian
    final timePatternResult = _checkTimePattern(
      newTransaction,
      recentTransactions,
    );
    if (timePatternResult.hasWarnings) {
      warnings.addAll(timePatternResult.warnings);
    }

    // 4. Kiểm tra consistency với category
    final categoryResult = _checkCategoryConsistency(
      newTransaction,
      recentTransactions,
      categories,
    );
    if (categoryResult.hasWarnings) {
      warnings.addAll(categoryResult.warnings);
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      warnings: warnings,
      errors: errors,
    );
  }

  /// Kiểm tra số tiền bất thường
  static ValidationResult _checkUnusualAmount(
    TransactionModel newTransaction,
    List<TransactionModel> recentTransactions,
  ) {
    final warnings = <String, String>{};

    // Lấy transactions cùng category trong 30 ngày gần đây
    final categoryTransactions = recentTransactions
        .where(
          (t) =>
              t.categoryId == newTransaction.categoryId &&
              t.type == newTransaction.type &&
              t.createdAt.isAfter(
                DateTime.now().subtract(const Duration(days: 30)),
              ),
        )
        .toList();

    if (categoryTransactions.isNotEmpty) {
      // Tính trung bình và độ lệch chuẩn
      final amounts = categoryTransactions.map((t) => t.amount).toList();
      final average = amounts.reduce((a, b) => a + b) / amounts.length;
      final variance =
          amounts.map((a) => pow(a - average, 2)).reduce((a, b) => a + b) /
          amounts.length;
      final standardDeviation = sqrt(variance);

      // Kiểm tra nếu số tiền mới lệch quá nhiều
      final zScore = (newTransaction.amount - average) / standardDeviation;

      if (zScore.abs() > 2.0) {
        warnings['unusual_amount'] =
            'Số tiền này khác biệt ${zScore > 0 ? 'lớn' : 'nhỏ'} hơn so với thói quen chi tiêu của bạn trong danh mục này';
      }
    }

    // Kiểm tra số tiền quá lớn
    if (newTransaction.amount > _unusualAmountThreshold) {
      warnings['large_amount'] =
          'Số tiền khá lớn (${(newTransaction.amount / 1000000).toStringAsFixed(1)}M VND). Vui lòng kiểm tra lại';
    }

    return ValidationResult(isValid: true, warnings: warnings, errors: {});
  }

  /// Kiểm tra tần suất giao dịch
  static ValidationResult _checkTransactionFrequency(
    TransactionModel newTransaction,
    List<TransactionModel> recentTransactions,
  ) {
    final warnings = <String, String>{};

    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
    final oneDayAgo = now.subtract(const Duration(days: 1));

    // Kiểm tra quá nhiều giao dịch trong 1 phút
    final recentMinuteTransactions = recentTransactions
        .where((t) => t.createdAt.isAfter(oneMinuteAgo))
        .length;

    if (recentMinuteTransactions >= _maxTransactionsPerMinute) {
      warnings['high_frequency'] =
          'Bạn đã tạo $recentMinuteTransactions giao dịch trong 1 phút qua. Có thể bạn đang nhập trùng lặp?';
    }

    // Kiểm tra quá nhiều giao dịch tương tự trong 1 ngày
    final similarTransactions = recentTransactions
        .where(
          (t) =>
              t.createdAt.isAfter(oneDayAgo) &&
              t.categoryId == newTransaction.categoryId &&
              (t.amount - newTransaction.amount).abs() < 1000,
        )
        .length;

    if (similarTransactions >= _maxSimilarTransactionsPerDay) {
      warnings['similar_transactions'] =
          'Bạn đã có $similarTransactions giao dịch tương tự trong ngày hôm nay';
    }

    return ValidationResult(isValid: true, warnings: warnings, errors: {});
  }

  /// Kiểm tra pattern thời gian
  static ValidationResult _checkTimePattern(
    TransactionModel newTransaction,
    List<TransactionModel> recentTransactions,
  ) {
    final warnings = <String, String>{};

    final hour = newTransaction.createdAt.hour;

    // Cảnh báo giao dịch vào giờ bất thường
    if (hour < 6 || hour > 23) {
      warnings['unusual_time'] =
          'Giao dịch vào ${hour}h có thể không phù hợp. Bạn có chắc chắn về thời gian này?';
    }

    // Kiểm tra ngày trong tuần
    final weekday = newTransaction.createdAt.weekday;
    final categoryTransactions = recentTransactions
        .where((t) => t.categoryId == newTransaction.categoryId)
        .toList();

    if (categoryTransactions.isNotEmpty) {
      final weekdayStats = <int, int>{};
      for (final transaction in categoryTransactions) {
        weekdayStats[transaction.createdAt.weekday] =
            (weekdayStats[transaction.createdAt.weekday] ?? 0) + 1;
      }

      final totalTransactions = categoryTransactions.length;
      final currentWeekdayCount = weekdayStats[weekday] ?? 0;
      final weekdayPercentage = (currentWeekdayCount / totalTransactions) * 100;

      if (weekdayPercentage < 5 && totalTransactions > 10) {
        final weekdayName = _getWeekdayName(weekday);
        warnings['unusual_weekday'] =
            'Bạn hiếm khi có giao dịch loại này vào $weekdayName';
      }
    }

    return ValidationResult(isValid: true, warnings: warnings, errors: {});
  }

  /// Kiểm tra tính nhất quán với category
  static ValidationResult _checkCategoryConsistency(
    TransactionModel newTransaction,
    List<TransactionModel> recentTransactions,
    List<CategoryModel> categories,
  ) {
    final warnings = <String, String>{};

    final category = categories.firstWhere(
      (c) => c.categoryId == newTransaction.categoryId,
      orElse: () => CategoryModel(
        categoryId: '',
        userId: '',
        name: '',
        type: TransactionType.expense,
        icon: '',
        iconType: CategoryIconType.material,
        color: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDefault: false,
        isSuggested: false,
        isDeleted: false,
      ),
    );

    // Kiểm tra type consistency
    if (category.type != newTransaction.type) {
      warnings['type_mismatch'] =
          'Danh mục "${category.name}" thường dùng cho ${category.type == TransactionType.income ? 'thu nhập' : 'chi tiêu'}';
    }

    // Kiểm tra note patterns
    if (newTransaction.note != null && newTransaction.note!.isNotEmpty) {
      final categoryNotes = recentTransactions
          .where(
            (t) =>
                t.categoryId == newTransaction.categoryId &&
                t.note != null &&
                t.note!.isNotEmpty,
          )
          .map((t) => t.note!)
          .toList();

      if (categoryNotes.isNotEmpty) {
        final commonWords = _findCommonWords(categoryNotes);
        final newWords = newTransaction.note!.toLowerCase().split(' ');
        final hasCommonWords = newWords.any(
          (word) => commonWords.contains(word),
        );

        if (!hasCommonWords && categoryNotes.length > 5) {
          warnings['unusual_note'] =
              'Ghi chú này khác với các ghi chú thường gặp trong danh mục "${category.name}"';
        }
      }
    }

    return ValidationResult(isValid: true, warnings: warnings, errors: {});
  }

  /// Tìm từ khóa phổ biến trong notes
  static Set<String> _findCommonWords(List<String> notes) {
    final wordCounts = <String, int>{};

    for (final note in notes) {
      final words = note.toLowerCase().split(' ');
      for (final word in words) {
        if (word.length > 2) {
          // Ignore short words
          wordCounts[word] = (wordCounts[word] ?? 0) + 1;
        }
      }
    }

    final threshold = (notes.length * 0.3).round();
    return wordCounts.entries
        .where((entry) => entry.value >= threshold)
        .map((entry) => entry.key)
        .toSet();
  }

  /// Lấy tên ngày trong tuần
  static String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Thứ 2';
      case 2:
        return 'Thứ 3';
      case 3:
        return 'Thứ 4';
      case 4:
        return 'Thứ 5';
      case 5:
        return 'Thứ 6';
      case 6:
        return 'Thứ 7';
      case 7:
        return 'Chủ nhật';
      default:
        return 'Không xác định';
    }
  }
}

/// Kết quả validation
class ValidationResult {
  final bool isValid;
  final Map<String, String> warnings;
  final Map<String, String> errors;

  ValidationResult({
    required this.isValid,
    required this.warnings,
    required this.errors,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
}
