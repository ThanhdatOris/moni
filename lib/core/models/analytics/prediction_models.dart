/// Dự đoán cash flow tổng quan
class CashFlowPrediction {
  final List<MonthlyPrediction> predictions;
  final double totalPredictedIncome;
  final double totalPredictedExpenses;
  final double confidence; // 0.0 - 1.0
  final List<String> factors; // Factors affecting the prediction

  const CashFlowPrediction({
    required this.predictions,
    required this.totalPredictedIncome,
    required this.totalPredictedExpenses,
    required this.confidence,
    required this.factors,
  });

  /// Convert to JSON for API/Firebase
  Map<String, dynamic> toJson() {
    return {
      'predictions': predictions.map((e) => e.toJson()).toList(),
      'totalPredictedIncome': totalPredictedIncome,
      'totalPredictedExpenses': totalPredictedExpenses,
      'confidence': confidence,
      'factors': factors,
    };
  }

  /// Create from JSON
  factory CashFlowPrediction.fromJson(Map<String, dynamic> json) {
    return CashFlowPrediction(
      predictions: (json['predictions'] as List)
          .map((e) => MonthlyPrediction.fromJson(e))
          .toList(),
      totalPredictedIncome: json['totalPredictedIncome'].toDouble(),
      totalPredictedExpenses: json['totalPredictedExpenses'].toDouble(),
      confidence: json['confidence'].toDouble(),
      factors: List<String>.from(json['factors']),
    );
  }

  /// Get predicted net cash flow
  double get predictedNetFlow => totalPredictedIncome - totalPredictedExpenses;

  /// Get prediction accuracy level
  String get accuracyLevel {
    if (confidence >= 0.8) return 'Rất chính xác';
    if (confidence >= 0.6) return 'Chính xác';
    if (confidence >= 0.4) return 'Khá chính xác';
    return 'Ít chính xác';
  }

  /// Get confidence color
  int get confidenceColor {
    if (confidence >= 0.8) return 0xFF4CAF50; // Green
    if (confidence >= 0.6) return 0xFF8BC34A; // Light Green
    if (confidence >= 0.4) return 0xFFFF9800; // Orange
    return 0xFFFF5722; // Deep Orange
  }

  /// Get cash flow trend
  String get cashFlowTrend {
    if (predictions.length < 2) return 'Không đủ dữ liệu';

    final first = predictions.first.netFlow;
    final last = predictions.last.netFlow;

    if (last > first * 1.1) return 'Cải thiện';
    if (last < first * 0.9) return 'Giảm';
    return 'Ổn định';
  }

  /// Check if there are any negative months
  bool get hasNegativeMonths => predictions.any((p) => p.netFlow < 0);

  /// Get months with negative cash flow
  List<MonthlyPrediction> get negativeMonths =>
      predictions.where((p) => p.netFlow < 0).toList();

  /// Get average monthly net flow
  double get averageMonthlyNetFlow {
    if (predictions.isEmpty) return 0.0;
    return predictions.fold(0.0, (sum, p) => sum + p.netFlow) /
        predictions.length;
  }
}

/// Dự đoán cho từng tháng
class MonthlyPrediction {
  final DateTime month;
  final double income;
  final double expenses;
  final double netFlow;
  final double confidence; // 0.0 - 1.0

  const MonthlyPrediction({
    required this.month,
    required this.income,
    required this.expenses,
    required this.netFlow,
    required this.confidence,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'month': month.toIso8601String(),
      'income': income,
      'expenses': expenses,
      'netFlow': netFlow,
      'confidence': confidence,
    };
  }

  /// Create from JSON
  factory MonthlyPrediction.fromJson(Map<String, dynamic> json) {
    return MonthlyPrediction(
      month: DateTime.parse(json['month']),
      income: json['income'].toDouble(),
      expenses: json['expenses'].toDouble(),
      netFlow: json['netFlow'].toDouble(),
      confidence: json['confidence'].toDouble(),
    );
  }

  /// Get month name in Vietnamese
  String get monthName {
    const months = [
      '',
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12'
    ];
    return '${months[month.month]} ${month.year}';
  }

  /// Get cash flow status
  String get cashFlowStatus {
    if (netFlow > 0) return 'Dương';
    if (netFlow < 0) return 'Âm';
    return 'Cân bằng';
  }

  /// Get cash flow color
  int get cashFlowColor {
    if (netFlow > 0) return 0xFF4CAF50; // Green
    if (netFlow < 0) return 0xFFD32F2F; // Red
    return 0xFF757575; // Grey
  }

  /// Get expense ratio (expenses / income)
  double get expenseRatio {
    if (income <= 0) return 0.0;
    return expenses / income;
  }

  /// Get expense ratio level
  String get expenseRatioLevel {
    if (expenseRatio <= 0.5) return 'Tốt'; // <= 50%
    if (expenseRatio <= 0.7) return 'Trung bình'; // <= 70%
    if (expenseRatio <= 0.9) return 'Cao'; // <= 90%
    return 'Rất cao'; // > 90%
  }

  /// Check if this is a risky month
  bool get isRisky => netFlow < 0 || expenseRatio > 0.9;

  /// Get savings potential (positive net flow as percentage of income)
  double get savingsPotential {
    if (income <= 0 || netFlow <= 0) return 0.0;
    return (netFlow / income) * 100;
  }
}

/// Dự đoán chi tiêu thông minh cho ngân sách
class SmartBudgetRecommendation {
  final String id;
  final String categoryId;
  final String categoryName;
  final String
      recommendationType; // 'increase', 'decrease', 'maintain', 'create'
  final double suggestedAmount;
  final double currentSpending;
  final double priority; // 0.0 - 1.0
  final String reasoning;
  final double confidence; // 0.0 - 1.0
  final List<String> factors;

  const SmartBudgetRecommendation({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.recommendationType,
    required this.suggestedAmount,
    required this.currentSpending,
    required this.priority,
    required this.reasoning,
    required this.confidence,
    required this.factors,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'recommendationType': recommendationType,
      'suggestedAmount': suggestedAmount,
      'currentSpending': currentSpending,
      'priority': priority,
      'reasoning': reasoning,
      'confidence': confidence,
      'factors': factors,
    };
  }

  /// Create from JSON
  factory SmartBudgetRecommendation.fromJson(Map<String, dynamic> json) {
    return SmartBudgetRecommendation(
      id: json['id'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      recommendationType: json['recommendationType'],
      suggestedAmount: json['suggestedAmount'].toDouble(),
      currentSpending: json['currentSpending'].toDouble(),
      priority: json['priority'].toDouble(),
      reasoning: json['reasoning'],
      confidence: json['confidence'].toDouble(),
      factors: List<String>.from(json['factors']),
    );
  }

  /// Get recommendation type in Vietnamese
  String get recommendationTypeText {
    switch (recommendationType) {
      case 'increase':
        return 'Tăng ngân sách';
      case 'decrease':
        return 'Giảm ngân sách';
      case 'maintain':
        return 'Duy trì ngân sách';
      case 'create':
        return 'Tạo ngân sách mới';
      default:
        return recommendationType;
    }
  }

  /// Get priority level
  String get priorityLevel {
    if (priority >= 0.8) return 'Rất cao';
    if (priority >= 0.6) return 'Cao';
    if (priority >= 0.4) return 'Trung bình';
    return 'Thấp';
  }

  /// Get priority color
  int get priorityColor {
    if (priority >= 0.8) return 0xFFD32F2F; // Red
    if (priority >= 0.6) return 0xFFFF5722; // Deep Orange
    if (priority >= 0.4) return 0xFFFF9800; // Orange
    return 0xFF4CAF50; // Green
  }

  /// Get change amount (difference between suggested and current)
  double get changeAmount => suggestedAmount - currentSpending;

  /// Get change percentage
  double get changePercentage {
    if (currentSpending <= 0) return 0.0;
    return (changeAmount / currentSpending) * 100;
  }

  /// Get change direction
  String get changeDirection {
    if (changeAmount > 0) return 'tăng';
    if (changeAmount < 0) return 'giảm';
    return 'không đổi';
  }

  /// Get impact description
  String get impactDescription {
    final absChange = changeAmount.abs();
    if (absChange >= 1000000) return 'Tác động lớn'; // >= 1M
    if (absChange >= 500000) return 'Tác động trung bình'; // >= 500k
    if (absChange >= 100000) return 'Tác động nhỏ'; // >= 100k
    return 'Tác động rất nhỏ';
  }

  /// Get urgency level based on priority and confidence
  String get urgencyLevel {
    final urgencyScore = priority * confidence;
    if (urgencyScore >= 0.8) return 'Khẩn cấp';
    if (urgencyScore >= 0.6) return 'Cao';
    if (urgencyScore >= 0.4) return 'Trung bình';
    return 'Thấp';
  }

  /// Check if this recommendation should be highlighted
  bool get shouldHighlight => priority >= 0.7 && confidence >= 0.6;

  /// Get recommendation icon based on type
  String get recommendationIcon {
    switch (recommendationType) {
      case 'increase':
        return '📈';
      case 'decrease':
        return '📉';
      case 'maintain':
        return '➡️';
      case 'create':
        return '🆕';
      default:
        return '📊';
    }
  }
}
