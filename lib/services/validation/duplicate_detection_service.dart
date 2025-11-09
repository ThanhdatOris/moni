import 'dart:math';

import 'package:moni/constants/enums.dart';

import '../../models/transaction_model.dart';

/// Service phát hiện giao dịch trùng lặp
class DuplicateDetectionService {
  static const int _timeWindowMinutes = 5; // Cửa sổ thời gian 5 phút
  static const double _amountThreshold = 0.01; // Ngưỡng chênh lệch số tiền
  static const double _duplicateScoreThreshold = 0.8; // Ngưỡng điểm trùng lặp

  /// Phát hiện giao dịch trùng lặp
  Future<DuplicateDetectionResult> detectDuplicates({
    required TransactionModel newTransaction,
    required List<TransactionModel> recentTransactions,
  }) async {
    final duplicates = <DuplicateMatch>[];
    
    for (final transaction in recentTransactions) {
      if (transaction.transactionId == newTransaction.transactionId) continue;
      
      final duplicateScore = _calculateDuplicateScore(
        newTransaction,
        transaction,
      );
      
      if (duplicateScore >= _duplicateScoreThreshold) {
        duplicates.add(DuplicateMatch(
          transaction: transaction,
          score: duplicateScore,
          reasons: _getDuplicateReasons(newTransaction, transaction),
        ));
      }
    }
    
    // Sắp xếp theo score giảm dần
    duplicates.sort((a, b) => b.score.compareTo(a.score));
    
    return DuplicateDetectionResult(
      hasDuplicates: duplicates.isNotEmpty,
      duplicates: duplicates,
      riskLevel: _calculateRiskLevel(duplicates),
    );
  }

  /// Tính điểm trùng lặp giữa 2 giao dịch
  double _calculateDuplicateScore(
    TransactionModel transaction1,
    TransactionModel transaction2,
  ) {
    double score = 0.0;
    
    // 1. Kiểm tra thời gian (40% trọng số)
    final timeScore = _calculateTimeScore(transaction1, transaction2);
    score += timeScore * 0.4;
    
    // 2. Kiểm tra số tiền (30% trọng số)
    final amountScore = _calculateAmountScore(transaction1, transaction2);
    score += amountScore * 0.3;
    
    // 3. Kiểm tra danh mục (20% trọng số)
    final categoryScore = _calculateCategoryScore(transaction1, transaction2);
    score += categoryScore * 0.2;
    
    // 4. Kiểm tra ghi chú (10% trọng số)
    final noteScore = _calculateNoteScore(transaction1, transaction2);
    score += noteScore * 0.1;
    
    return score;
  }

  /// Tính điểm thời gian
  double _calculateTimeScore(
    TransactionModel transaction1,
    TransactionModel transaction2,
  ) {
    final timeDiff = transaction1.createdAt.difference(transaction2.createdAt).abs();
    final minutes = timeDiff.inMinutes;
    
    if (minutes <= _timeWindowMinutes) {
      return 1.0;
    } else if (minutes <= 60) {
      return 0.5;
    } else if (minutes <= 24 * 60) {
      return 0.2;
    } else {
      return 0.0;
    }
  }

  /// Tính điểm số tiền
  double _calculateAmountScore(
    TransactionModel transaction1,
    TransactionModel transaction2,
  ) {
    final amountDiff = (transaction1.amount - transaction2.amount).abs();
    final maxAmount = max(transaction1.amount, transaction2.amount);
    
    if (amountDiff <= _amountThreshold) {
      return 1.0;
    } else if (amountDiff / maxAmount <= 0.05) {
      return 0.8;
    } else if (amountDiff / maxAmount <= 0.1) {
      return 0.5;
    } else {
      return 0.0;
    }
  }

  /// Tính điểm danh mục
  double _calculateCategoryScore(
    TransactionModel transaction1,
    TransactionModel transaction2,
  ) {
    if (transaction1.categoryId == transaction2.categoryId) {
      return 1.0;
    } else {
      return 0.0;
    }
  }

  /// Tính điểm ghi chú
  double _calculateNoteScore(
    TransactionModel transaction1,
    TransactionModel transaction2,
  ) {
    final note1 = transaction1.note ?? '';
    final note2 = transaction2.note ?? '';
    
    if (note1.isEmpty && note2.isEmpty) {
      return 1.0;
    }
    
    if (note1.isEmpty || note2.isEmpty) {
      return 0.3;
    }
    
    final similarity = _calculateStringSimilarity(
      note1.toLowerCase(),
      note2.toLowerCase(),
    );
    
    return similarity;
  }

  /// Tính độ tương đồng giữa 2 chuỗi
  double _calculateStringSimilarity(String str1, String str2) {
    if (str1 == str2) return 1.0;
    if (str1.isEmpty || str2.isEmpty) return 0.0;
    
    final maxLength = max(str1.length, str2.length);
    final levenshteinDistance = _calculateLevenshteinDistance(str1, str2);
    
    return 1.0 - (levenshteinDistance / maxLength);
  }

  /// Tính khoảng cách Levenshtein
  int _calculateLevenshteinDistance(String str1, String str2) {
    if (str1.isEmpty) return str2.length;
    if (str2.isEmpty) return str1.length;
    
    final matrix = List.generate(
      str1.length + 1,
      (i) => List.generate(str2.length + 1, (j) => 0),
    );
    
    for (int i = 0; i <= str1.length; i++) {
      matrix[i][0] = i;
    }
    
    for (int j = 0; j <= str2.length; j++) {
      matrix[0][j] = j;
    }
    
    for (int i = 1; i <= str1.length; i++) {
      for (int j = 1; j <= str2.length; j++) {
        final cost = str1[i - 1] == str2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce(min);
      }
    }
    
    return matrix[str1.length][str2.length];
  }

  /// Lấy lý do trùng lặp
  List<String> _getDuplicateReasons(
    TransactionModel transaction1,
    TransactionModel transaction2,
  ) {
    final reasons = <String>[];
    
    // Kiểm tra thời gian
    final timeDiff = transaction1.createdAt.difference(transaction2.createdAt).abs();
    if (timeDiff.inMinutes <= _timeWindowMinutes) {
      reasons.add('Cùng thời gian (trong vòng $_timeWindowMinutes phút)');
    }
    
    // Kiểm tra số tiền
    final amountDiff = (transaction1.amount - transaction2.amount).abs();
    if (amountDiff <= _amountThreshold) {
      reasons.add('Cùng số tiền');
    }
    
    // Kiểm tra danh mục
    if (transaction1.categoryId == transaction2.categoryId) {
      reasons.add('Cùng danh mục');
    }
    
    // Kiểm tra ghi chú
    final note1 = transaction1.note ?? '';
    final note2 = transaction2.note ?? '';
    if (note1.isNotEmpty && 
        note2.isNotEmpty &&
        note1.toLowerCase() == note2.toLowerCase()) {
      reasons.add('Cùng ghi chú');
    }
    
    return reasons;
  }

  /// Tính mức độ rủi ro
  DuplicateRiskLevel _calculateRiskLevel(List<DuplicateMatch> duplicates) {
    if (duplicates.isEmpty) return DuplicateRiskLevel.none;
    
    final highestScore = duplicates.first.score;
    
    if (highestScore >= 0.95) {
      return DuplicateRiskLevel.high;
    } else if (highestScore >= 0.85) {
      return DuplicateRiskLevel.medium;
    } else {
      return DuplicateRiskLevel.low;
    }
  }

  /// Lọc giao dịch gần đây để kiểm tra trùng lặp
  List<TransactionModel> filterRecentTransactions(
    List<TransactionModel> transactions,
    DateTime referenceTime,
  ) {
    final cutoffTime = referenceTime.subtract(const Duration(days: 1));
    
    return transactions
        .where((transaction) => transaction.createdAt.isAfter(cutoffTime))
        .toList();
  }

  /// Tạo gợi ý xử lý trùng lặp
  List<DuplicateAction> suggestActions(DuplicateDetectionResult result) {
    final actions = <DuplicateAction>[];
    
    if (!result.hasDuplicates) {
      actions.add(DuplicateAction(
        type: DuplicateActionType.proceed,
        description: 'Tiếp tục lưu giao dịch',
      ));
      return actions;
    }
    
    switch (result.riskLevel) {
      case DuplicateRiskLevel.high:
        actions.add(DuplicateAction(
          type: DuplicateActionType.block,
          description: 'Ngăn chặn lưu giao dịch (có thể trùng lặp)',
        ));
        actions.add(DuplicateAction(
          type: DuplicateActionType.review,
          description: 'Xem lại giao dịch trùng lặp',
        ));
        break;
        
      case DuplicateRiskLevel.medium:
        actions.add(DuplicateAction(
          type: DuplicateActionType.warn,
          description: 'Cảnh báo người dùng',
        ));
        actions.add(DuplicateAction(
          type: DuplicateActionType.review,
          description: 'Xem lại giao dịch trùng lặp',
        ));
        actions.add(DuplicateAction(
          type: DuplicateActionType.proceed,
          description: 'Tiếp tục lưu giao dịch',
        ));
        break;
        
      case DuplicateRiskLevel.low:
        actions.add(DuplicateAction(
          type: DuplicateActionType.proceed,
          description: 'Tiếp tục lưu giao dịch',
        ));
        actions.add(DuplicateAction(
          type: DuplicateActionType.review,
          description: 'Xem lại giao dịch tương tự',
        ));
        break;
        
      case DuplicateRiskLevel.none:
        actions.add(DuplicateAction(
          type: DuplicateActionType.proceed,
          description: 'Tiếp tục lưu giao dịch',
        ));
        break;
    }
    
    return actions;
  }
}

/// Kết quả phát hiện trùng lặp
class DuplicateDetectionResult {
  final bool hasDuplicates;
  final List<DuplicateMatch> duplicates;
  final DuplicateRiskLevel riskLevel;

  DuplicateDetectionResult({
    required this.hasDuplicates,
    required this.duplicates,
    required this.riskLevel,
  });
}

/// Giao dịch trùng lặp
class DuplicateMatch {
  final TransactionModel transaction;
  final double score;
  final List<String> reasons;

  DuplicateMatch({
    required this.transaction,
    required this.score,
    required this.reasons,
  });
}

/// Hành động xử lý trùng lặp
class DuplicateAction {
  final DuplicateActionType type;
  final String description;

  DuplicateAction({
    required this.type,
    required this.description,
  });
}
