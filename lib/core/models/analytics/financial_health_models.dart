/// Models cho đánh giá sức khỏe tài chính
/// Được tách từ AIAnalyticsService để cải thiện maintainability

/// Điểm số sức khỏe tài chính tổng quan
class FinancialHealthScore {
  final double overallScore; // 0.0 - 100.0
  final double spendingScore; // 0.0 - 100.0
  final double budgetScore; // 0.0 - 100.0
  final double savingsScore; // 0.0 - 100.0
  final List<HealthRecommendation> recommendations;
  final DateTime lastCalculated;
  final double trend; // Positive = improving, Negative = declining
  final List<String> factors; // Key factors affecting the score

  const FinancialHealthScore({
    required this.overallScore,
    required this.spendingScore,
    required this.budgetScore,
    required this.savingsScore,
    required this.recommendations,
    required this.lastCalculated,
    required this.trend,
    required this.factors,
  });

  /// Convert to JSON for API/Firebase
  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'spendingScore': spendingScore,
      'budgetScore': budgetScore,
      'savingsScore': savingsScore,
      'recommendations': recommendations.map((e) => e.toJson()).toList(),
      'lastCalculated': lastCalculated.toIso8601String(),
      'trend': trend,
      'factors': factors,
    };
  }

  /// Create from JSON
  factory FinancialHealthScore.fromJson(Map<String, dynamic> json) {
    return FinancialHealthScore(
      overallScore: json['overallScore'].toDouble(),
      spendingScore: json['spendingScore'].toDouble(),
      budgetScore: json['budgetScore'].toDouble(),
      savingsScore: json['savingsScore'].toDouble(),
      recommendations: (json['recommendations'] as List)
          .map((e) => HealthRecommendation.fromJson(e))
          .toList(),
      lastCalculated: DateTime.parse(json['lastCalculated']),
      trend: json['trend'].toDouble(),
      factors: List<String>.from(json['factors']),
    );
  }

  /// Get overall health level as text
  String get healthLevel {
    if (overallScore >= 80) return 'Xuất sắc';
    if (overallScore >= 60) return 'Tốt';
    if (overallScore >= 40) return 'Trung bình';
    if (overallScore >= 20) return 'Cần cải thiện';
    return 'Kém';
  }

  /// Get health color based on score
  int get healthColor {
    if (overallScore >= 80) return 0xFF4CAF50; // Green
    if (overallScore >= 60) return 0xFF8BC34A; // Light Green
    if (overallScore >= 40) return 0xFFFF9800; // Orange
    if (overallScore >= 20) return 0xFFFF5722; // Deep Orange
    return 0xFFD32F2F; // Red
  }

  /// Get trend description
  String get trendDescription {
    if (trend > 5) return 'Cải thiện mạnh';
    if (trend > 0.1) return 'Cải thiện';
    if (trend > -0.1) return 'Ổn định';
    if (trend > -5) return 'Giảm';
    return 'Giảm mạnh';
  }

  /// Get trend icon
  String get trendIcon {
    if (trend > 0.1) return '📈';
    if (trend < -0.1) return '📉';
    return '➡️';
  }

  /// Check if action is needed
  bool get needsAction =>
      overallScore < 60 || recommendations.any((r) => r.priority == 'high');

  /// Get priority recommendations (high priority only)
  List<HealthRecommendation> get priorityRecommendations =>
      recommendations.where((r) => r.priority == 'high').toList();
}

/// Gợi ý cải thiện sức khỏe tài chính
class HealthRecommendation {
  final String type; // 'spending', 'budget', 'savings', 'debt', 'emergency'
  final String title;
  final String description;
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final double impact; // 0.0 - 100.0 (expected impact on overall score)

  const HealthRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.impact,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'priority': priority,
      'impact': impact,
    };
  }

  /// Create from JSON
  factory HealthRecommendation.fromJson(Map<String, dynamic> json) {
    return HealthRecommendation(
      type: json['type'],
      title: json['title'],
      description: json['description'],
      priority: json['priority'],
      impact: json['impact'].toDouble(),
    );
  }

  /// Get priority color
  int get priorityColor {
    switch (priority) {
      case 'urgent':
        return 0xFFD32F2F; // Red
      case 'high':
        return 0xFFFF5722; // Deep Orange
      case 'medium':
        return 0xFFFF9800; // Orange
      case 'low':
        return 0xFF4CAF50; // Green
      default:
        return 0xFF757575; // Grey
    }
  }

  /// Get type icon
  String get typeIcon {
    switch (type) {
      case 'spending':
        return '💰';
      case 'budget':
        return '📊';
      case 'savings':
        return '🏦';
      case 'debt':
        return '📉';
      case 'emergency':
        return '🚨';
      default:
        return '📋';
    }
  }

  /// Get type description in Vietnamese
  String get typeDescription {
    switch (type) {
      case 'spending':
        return 'Chi tiêu';
      case 'budget':
        return 'Ngân sách';
      case 'savings':
        return 'Tiết kiệm';
      case 'debt':
        return 'Nợ';
      case 'emergency':
        return 'Khẩn cấp';
      default:
        return 'Khác';
    }
  }

  /// Get priority description in Vietnamese
  String get priorityDescription {
    switch (priority) {
      case 'urgent':
        return 'Khẩn cấp';
      case 'high':
        return 'Cao';
      case 'medium':
        return 'Trung bình';
      case 'low':
        return 'Thấp';
      default:
        return 'Không xác định';
    }
  }

  /// Get impact level description
  String get impactDescription {
    if (impact >= 80) return 'Tác động rất lớn';
    if (impact >= 60) return 'Tác động lớn';
    if (impact >= 40) return 'Tác động trung bình';
    if (impact >= 20) return 'Tác động nhỏ';
    return 'Tác động rất nhỏ';
  }
}

/// Dữ liệu chi tiêu để tính toán sức khỏe tài chính
class SpendingData {
  final double totalSpending;
  final double averageDaily;
  final Map<String, dynamic> categories; // CategoryDistribution data
  final Map<String, dynamic> trends; // MonthlyTrend data

  const SpendingData({
    required this.totalSpending,
    required this.averageDaily,
    required this.categories,
    required this.trends,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalSpending': totalSpending,
      'averageDaily': averageDaily,
      'categories': categories,
      'trends': trends,
    };
  }

  factory SpendingData.fromJson(Map<String, dynamic> json) {
    return SpendingData(
      totalSpending: json['totalSpending'].toDouble(),
      averageDaily: json['averageDaily'].toDouble(),
      categories: Map<String, dynamic>.from(json['categories']),
      trends: Map<String, dynamic>.from(json['trends']),
    );
  }

  /// Get spending level
  String get spendingLevel {
    if (averageDaily > 500000) return 'Rất cao'; // > 500k/day
    if (averageDaily > 200000) return 'Cao'; // > 200k/day
    if (averageDaily > 100000) return 'Trung bình'; // > 100k/day
    if (averageDaily > 50000) return 'Thấp'; // > 50k/day
    return 'Rất thấp';
  }
}

/// Dữ liệu ngân sách để tính toán sức khỏe tài chính
class BudgetData {
  final double totalBudget;
  final double utilizationRate; // 0.0 - 1.0
  final int categoriesWithBudgets;
  final int categoriesWithoutBudgets;

  const BudgetData({
    required this.totalBudget,
    required this.utilizationRate,
    required this.categoriesWithBudgets,
    required this.categoriesWithoutBudgets,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalBudget': totalBudget,
      'utilizationRate': utilizationRate,
      'categoriesWithBudgets': categoriesWithBudgets,
      'categoriesWithoutBudgets': categoriesWithoutBudgets,
    };
  }

  factory BudgetData.fromJson(Map<String, dynamic> json) {
    return BudgetData(
      totalBudget: json['totalBudget'].toDouble(),
      utilizationRate: json['utilizationRate'].toDouble(),
      categoriesWithBudgets: json['categoriesWithBudgets'],
      categoriesWithoutBudgets: json['categoriesWithoutBudgets'],
    );
  }

  /// Get budget health level
  String get budgetHealthLevel {
    if (utilizationRate <= 0.8) return 'Tốt';
    if (utilizationRate <= 0.9) return 'Cảnh báo';
    if (utilizationRate <= 1.0) return 'Nguy hiểm';
    return 'Vượt quá';
  }

  /// Get budget utilization color
  int get utilizationColor {
    if (utilizationRate <= 0.8) return 0xFF4CAF50; // Green
    if (utilizationRate <= 0.9) return 0xFFFF9800; // Orange
    if (utilizationRate <= 1.0) return 0xFFFF5722; // Deep Orange
    return 0xFFD32F2F; // Red
  }

  /// Get budget coverage percentage
  double get budgetCoveragePercentage {
    final totalCategories = categoriesWithBudgets + categoriesWithoutBudgets;
    if (totalCategories == 0) return 0.0;
    return (categoriesWithBudgets / totalCategories) * 100;
  }
}

/// Dữ liệu tiết kiệm để tính toán sức khỏe tài chính
class SavingsData {
  final double totalSavings;
  final double monthlyContribution;
  final double savingsRate; // 0.0 - 1.0 (percentage of income saved)
  final double savingsGoal;

  const SavingsData({
    required this.totalSavings,
    required this.monthlyContribution,
    required this.savingsRate,
    required this.savingsGoal,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalSavings': totalSavings,
      'monthlyContribution': monthlyContribution,
      'savingsRate': savingsRate,
      'savingsGoal': savingsGoal,
    };
  }

  factory SavingsData.fromJson(Map<String, dynamic> json) {
    return SavingsData(
      totalSavings: json['totalSavings'].toDouble(),
      monthlyContribution: json['monthlyContribution'].toDouble(),
      savingsRate: json['savingsRate'].toDouble(),
      savingsGoal: json['savingsGoal'].toDouble(),
    );
  }

  /// Get savings rate level
  String get savingsRateLevel {
    if (savingsRate >= 0.2) return 'Xuất sắc'; // >= 20%
    if (savingsRate >= 0.15) return 'Tốt'; // >= 15%
    if (savingsRate >= 0.1) return 'Trung bình'; // >= 10%
    if (savingsRate >= 0.05) return 'Thấp'; // >= 5%
    return 'Rất thấp';
  }

  /// Get savings rate color
  int get savingsRateColor {
    if (savingsRate >= 0.2) return 0xFF4CAF50; // Green
    if (savingsRate >= 0.15) return 0xFF8BC34A; // Light Green
    if (savingsRate >= 0.1) return 0xFFFF9800; // Orange
    if (savingsRate >= 0.05) return 0xFFFF5722; // Deep Orange
    return 0xFFD32F2F; // Red
  }

  /// Get goal progress percentage
  double get goalProgressPercentage {
    if (savingsGoal <= 0) return 0.0;
    return (totalSavings / savingsGoal * 100).clamp(0.0, 100.0);
  }

  /// Get goal progress description
  String get goalProgressDescription {
    final progress = goalProgressPercentage;
    if (progress >= 100) return 'Đã đạt mục tiêu';
    if (progress >= 80) return 'Gần đạt mục tiêu';
    if (progress >= 50) return 'Đang tiến bộ tốt';
    if (progress >= 25) return 'Đang trên đường đạt mục tiêu';
    return 'Cần nỗ lực hơn';
  }

  /// Estimate months to reach goal
  int get monthsToReachGoal {
    if (monthlyContribution <= 0) return -1; // Cannot reach
    final remaining = savingsGoal - totalSavings;
    if (remaining <= 0) return 0; // Already reached
    return (remaining / monthlyContribution).ceil();
  }
}
