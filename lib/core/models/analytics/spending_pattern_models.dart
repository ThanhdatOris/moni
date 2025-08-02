/// Models cho phân tích mẫu chi tiêu
/// Được tách từ AIAnalyticsService để cải thiện maintainability

import '../../../models/transaction_model.dart';

/// Kết quả phân tích mẫu chi tiêu tổng quan
class SpendingPatternAnalysis {
  final Map<String, WeeklySpendingPattern> weeklyPatterns;
  final Map<String, MonthlyTrend> monthlyTrends;
  final Map<String, CategoryDistribution> categoryDistribution;
  final Map<String, SeasonalPattern> seasonalPatterns;
  final List<SpendingAnomaly> anomalies;
  final List<SpendingPrediction> predictions;
  final DateTime analysisDate;
  final double confidenceScore;

  const SpendingPatternAnalysis({
    required this.weeklyPatterns,
    required this.monthlyTrends,
    required this.categoryDistribution,
    required this.seasonalPatterns,
    required this.anomalies,
    required this.predictions,
    required this.analysisDate,
    required this.confidenceScore,
  });

  /// Convert to JSON for API/Firebase
  Map<String, dynamic> toJson() {
    return {
      'weeklyPatterns': weeklyPatterns.map((key, value) => MapEntry(key, value.toJson())),
      'monthlyTrends': monthlyTrends.map((key, value) => MapEntry(key, value.toJson())),
      'categoryDistribution': categoryDistribution.map((key, value) => MapEntry(key, value.toJson())),
      'seasonalPatterns': seasonalPatterns.map((key, value) => MapEntry(key, value.toJson())),
      'anomalies': anomalies.map((e) => e.toJson()).toList(),
      'predictions': predictions.map((e) => e.toJson()).toList(),
      'analysisDate': analysisDate.toIso8601String(),
      'confidenceScore': confidenceScore,
    };
  }

  /// Create from JSON
  factory SpendingPatternAnalysis.fromJson(Map<String, dynamic> json) {
    return SpendingPatternAnalysis(
      weeklyPatterns: (json['weeklyPatterns'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, WeeklySpendingPattern.fromJson(value))),
      monthlyTrends: (json['monthlyTrends'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, MonthlyTrend.fromJson(value))),
      categoryDistribution: (json['categoryDistribution'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, CategoryDistribution.fromJson(value))),
      seasonalPatterns: (json['seasonalPatterns'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, SeasonalPattern.fromJson(value))),
      anomalies: (json['anomalies'] as List)
          .map((e) => SpendingAnomaly.fromJson(e))
          .toList(),
      predictions: (json['predictions'] as List)
          .map((e) => SpendingPrediction.fromJson(e))
          .toList(),
      analysisDate: DateTime.parse(json['analysisDate']),
      confidenceScore: json['confidenceScore'].toDouble(),
    );
  }
}

/// Mẫu chi tiêu theo tuần cho từng danh mục
class WeeklySpendingPattern {
  final String categoryId;
  final double averageDaily;
  final double variance;
  final int peakDay; // 1-7 (Monday to Sunday)
  final Map<int, double> dailyDistribution;

  const WeeklySpendingPattern({
    required this.categoryId,
    required this.averageDaily,
    required this.variance,
    required this.peakDay,
    required this.dailyDistribution,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'averageDaily': averageDaily,
      'variance': variance,
      'peakDay': peakDay,
      'dailyDistribution': dailyDistribution.map((key, value) => MapEntry(key.toString(), value)),
    };
  }

  factory WeeklySpendingPattern.fromJson(Map<String, dynamic> json) {
    return WeeklySpendingPattern(
      categoryId: json['categoryId'],
      averageDaily: json['averageDaily'].toDouble(),
      variance: json['variance'].toDouble(),
      peakDay: json['peakDay'],
      dailyDistribution: (json['dailyDistribution'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(int.parse(key), value.toDouble())),
    );
  }

  /// Get day name for peak day
  String get peakDayName {
    const days = ['', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
    return days[peakDay];
  }
}

/// Xu hướng chi tiêu theo tháng
class MonthlyTrend {
  final String categoryId;
  final double trend; // Positive = increasing, Negative = decreasing
  final double seasonality;
  final Map<int, double> monthlyData; // Key: yearMonth (YYYYMM)
  final double confidence; // 0.0 - 1.0

  const MonthlyTrend({
    required this.categoryId,
    required this.trend,
    required this.seasonality,
    required this.monthlyData,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'trend': trend,
      'seasonality': seasonality,
      'monthlyData': monthlyData.map((key, value) => MapEntry(key.toString(), value)),
      'confidence': confidence,
    };
  }

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) {
    return MonthlyTrend(
      categoryId: json['categoryId'],
      trend: json['trend'].toDouble(),
      seasonality: json['seasonality'].toDouble(),
      monthlyData: (json['monthlyData'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(int.parse(key), value.toDouble())),
      confidence: json['confidence'].toDouble(),
    );
  }

  /// Trend direction as text
  String get trendDescription {
    if (trend > 0.1) return 'Tăng';
    if (trend < -0.1) return 'Giảm';
    return 'Ổn định';
  }

  /// Confidence level as text
  String get confidenceLevel {
    if (confidence >= 0.8) return 'Cao';
    if (confidence >= 0.6) return 'Trung bình';
    return 'Thấp';
  }
}

/// Phân bổ chi tiêu theo danh mục
class CategoryDistribution {
  final String categoryId;
  final double totalAmount;
  final double percentage; // 0-100
  final int transactionCount;
  final double averageAmount;

  const CategoryDistribution({
    required this.categoryId,
    required this.totalAmount,
    required this.percentage,
    required this.transactionCount,
    required this.averageAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'totalAmount': totalAmount,
      'percentage': percentage,
      'transactionCount': transactionCount,
      'averageAmount': averageAmount,
    };
  }

  factory CategoryDistribution.fromJson(Map<String, dynamic> json) {
    return CategoryDistribution(
      categoryId: json['categoryId'],
      totalAmount: json['totalAmount'].toDouble(),
      percentage: json['percentage'].toDouble(),
      transactionCount: json['transactionCount'],
      averageAmount: json['averageAmount'].toDouble(),
    );
  }

  /// Get spending intensity level
  String get intensityLevel {
    if (percentage >= 30) return 'Rất cao';
    if (percentage >= 20) return 'Cao';
    if (percentage >= 10) return 'Trung bình';
    return 'Thấp';
  }
}

/// Mẫu chi tiêu theo mùa
class SeasonalPattern {
  final String categoryId;
  final Map<String, double> seasonalIndices; // Season name -> index (1.0 = average)
  final String peakSeason;
  final Map<String, double> seasonalData; // Season name -> amount

  const SeasonalPattern({
    required this.categoryId,
    required this.seasonalIndices,
    required this.peakSeason,
    required this.seasonalData,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'seasonalIndices': seasonalIndices,
      'peakSeason': peakSeason,
      'seasonalData': seasonalData,
    };
  }

  factory SeasonalPattern.fromJson(Map<String, dynamic> json) {
    return SeasonalPattern(
      categoryId: json['categoryId'],
      seasonalIndices: Map<String, double>.from(json['seasonalIndices']),
      peakSeason: json['peakSeason'],
      seasonalData: Map<String, double>.from(json['seasonalData']),
    );
  }

  /// Get seasonal recommendation
  String getSeasonalRecommendation() {
    if (peakSeason == 'Winter') return 'Chi tiêu cao nhất vào mùa đông';
    if (peakSeason == 'Spring') return 'Chi tiêu cao nhất vào mùa xuân';
    if (peakSeason == 'Summer') return 'Chi tiêu cao nhất vào mùa hè';
    if (peakSeason == 'Fall') return 'Chi tiêu cao nhất vào mùa thu';
    return 'Không có mẫu theo mùa rõ ràng';
  }
}

/// Dự đoán chi tiêu
class SpendingPrediction {
  final String categoryId;
  final double predictedAmount;
  final double confidence; // 0.0 - 1.0
  final String period; // 'next_week', 'next_month', 'next_quarter'
  final List<String> factors;

  const SpendingPrediction({
    required this.categoryId,
    required this.predictedAmount,
    required this.confidence,
    required this.period,
    required this.factors,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'predictedAmount': predictedAmount,
      'confidence': confidence,
      'period': period,
      'factors': factors,
    };
  }

  factory SpendingPrediction.fromJson(Map<String, dynamic> json) {
    return SpendingPrediction(
      categoryId: json['categoryId'],
      predictedAmount: json['predictedAmount'].toDouble(),
      confidence: json['confidence'].toDouble(),
      period: json['period'],
      factors: List<String>.from(json['factors']),
    );
  }

  /// Get period as Vietnamese text
  String get periodText {
    switch (period) {
      case 'next_week': return 'Tuần tới';
      case 'next_month': return 'Tháng tới';
      case 'next_quarter': return 'Quý tới';
      default: return period;
    }
  }

  /// Get confidence as text
  String get confidenceText {
    if (confidence >= 0.8) return 'Rất tin cậy';
    if (confidence >= 0.6) return 'Tin cậy';
    if (confidence >= 0.4) return 'Khá tin cậy';
    return 'Ít tin cậy';
  }
}

/// Anomaly trong chi tiêu
class SpendingAnomaly {
  final String id;
  final String type; // 'statistical', 'behavioral', 'temporal', 'category'
  final String severity; // 'low', 'medium', 'high', 'critical'
  final String description;
  final TransactionModel transaction;
  final DateTime detectedAt;
  final double confidence; // 0.0 - 1.0

  const SpendingAnomaly({
    required this.id,
    required this.type,
    required this.severity,
    required this.description,
    required this.transaction,
    required this.detectedAt,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'severity': severity,
      'description': description,
      'transaction': transaction.toMap(),
      'detectedAt': detectedAt.toIso8601String(),
      'confidence': confidence,
    };
  }

  factory SpendingAnomaly.fromJson(Map<String, dynamic> json) {
    return SpendingAnomaly(
      id: json['id'],
      type: json['type'],
      severity: json['severity'],
      description: json['description'],
      transaction: TransactionModel.fromMap(json['transaction'], json['transaction']['id'] ?? ''),
      detectedAt: DateTime.parse(json['detectedAt']),
      confidence: json['confidence'].toDouble(),
    );
  }

  /// Get severity color
  int get severityColor {
    switch (severity) {
      case 'critical': return 0xFFD32F2F; // Red
      case 'high': return 0xFFFF5722; // Deep Orange  
      case 'medium': return 0xFFFF9800; // Orange
      case 'low': return 0xFFFFC107; // Amber
      default: return 0xFF757575; // Grey
    }
  }

  /// Get type description in Vietnamese
  String get typeDescription {
    switch (type) {
      case 'statistical': return 'Thống kê bất thường';
      case 'behavioral': return 'Hành vi bất thường';
      case 'temporal': return 'Thời gian bất thường';
      case 'category': return 'Danh mục bất thường';
      default: return 'Bất thường khác';
    }
  }
}

/// Trending insight model for analytics
class TrendingInsight {
  final String type;
  final String title;
  final String description;
  final String categoryId;
  final double impact;
  final String trend; // 'up', 'down', 'stable'

  const TrendingInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.impact,
    required this.trend,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'impact': impact,
      'trend': trend,
    };
  }

  factory TrendingInsight.fromJson(Map<String, dynamic> json) {
    return TrendingInsight(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      categoryId: json['categoryId'] ?? '',
      impact: (json['impact'] ?? 0).toDouble(),
      trend: json['trend'] ?? 'stable',
    );
  }
} 