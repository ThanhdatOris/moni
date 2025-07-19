import 'package:flutter/material.dart';

import '../../../constants/enums.dart';

/// Chart data point model
class ChartDataPoint {
  final String label;
  final double value;
  final DateTime? date;
  final Color? color;
  final Map<String, dynamic>? metadata;

  const ChartDataPoint({
    required this.label,
    required this.value,
    this.date,
    this.color,
    this.metadata,
  });

  ChartDataPoint copyWith({
    String? label,
    double? value,
    DateTime? date,
    Color? color,
    Map<String, dynamic>? metadata,
  }) {
    return ChartDataPoint(
      label: label ?? this.label,
      value: value ?? this.value,
      date: date ?? this.date,
      color: color ?? this.color,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Chart series for multi-series charts
class ChartSeries {
  final String name;
  final List<ChartDataPoint> data;
  final Color color;
  final ChartType type;
  final bool visible;

  const ChartSeries({
    required this.name,
    required this.data,
    required this.color,
    this.type = ChartType.line,
    this.visible = true,
  });

  ChartSeries copyWith({
    String? name,
    List<ChartDataPoint>? data,
    Color? color,
    ChartType? type,
    bool? visible,
  }) {
    return ChartSeries(
      name: name ?? this.name,
      data: data ?? this.data,
      color: color ?? this.color,
      type: type ?? this.type,
      visible: visible ?? this.visible,
    );
  }
}

/// Income vs Expense specific data model
class IncomeExpenseData {
  final double income;
  final double expense;
  final DateTime period;
  final Map<String, double>? incomeBreakdown;
  final Map<String, double>? expenseBreakdown;

  const IncomeExpenseData({
    required this.income,
    required this.expense,
    required this.period,
    this.incomeBreakdown,
    this.expenseBreakdown,
  });

  double get netIncome => income - expense;
  double get savingsRate => income > 0 ? (netIncome / income) : 0.0;

  IncomeExpenseData copyWith({
    double? income,
    double? expense,
    DateTime? period,
    Map<String, double>? incomeBreakdown,
    Map<String, double>? expenseBreakdown,
  }) {
    return IncomeExpenseData(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      period: period ?? this.period,
      incomeBreakdown: incomeBreakdown ?? this.incomeBreakdown,
      expenseBreakdown: expenseBreakdown ?? this.expenseBreakdown,
    );
  }
}

/// Category analysis data model
class CategoryAnalysisData {
  final String categoryId;
  final String categoryName;
  final double totalAmount;
  final double percentage;
  final double averageTransaction;
  final int transactionCount;
  final double budgetAmount;
  final Color color;
  final List<ChartDataPoint> trend;

  const CategoryAnalysisData({
    required this.categoryId,
    required this.categoryName,
    required this.totalAmount,
    required this.percentage,
    required this.averageTransaction,
    required this.transactionCount,
    required this.budgetAmount,
    required this.color,
    required this.trend,
  });

  double get budgetUtilization => budgetAmount > 0 ? (totalAmount / budgetAmount) : 0.0;
  bool get isOverBudget => totalAmount > budgetAmount && budgetAmount > 0;

  CategoryAnalysisData copyWith({
    String? categoryId,
    String? categoryName,
    double? totalAmount,
    double? percentage,
    double? averageTransaction,
    int? transactionCount,
    double? budgetAmount,
    Color? color,
    List<ChartDataPoint>? trend,
  }) {
    return CategoryAnalysisData(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      totalAmount: totalAmount ?? this.totalAmount,
      percentage: percentage ?? this.percentage,
      averageTransaction: averageTransaction ?? this.averageTransaction,
      transactionCount: transactionCount ?? this.transactionCount,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      color: color ?? this.color,
      trend: trend ?? this.trend,
    );
  }
}

/// Financial health data model
class FinancialHealthData {
  final double overallScore;
  final double spendingScore;
  final double savingsScore;
  final double budgetScore;
  final Map<String, double> categoryScores;
  final List<String> recommendations;
  final DateTime lastCalculated;

  const FinancialHealthData({
    required this.overallScore,
    required this.spendingScore,
    required this.savingsScore,
    required this.budgetScore,
    required this.categoryScores,
    required this.recommendations,
    required this.lastCalculated,
  });

  String get healthLevel {
    if (overallScore >= 80) return 'Excellent';
    if (overallScore >= 60) return 'Good';
    if (overallScore >= 40) return 'Fair';
    return 'Poor';
  }

  Color get healthColor {
    if (overallScore >= 80) return Colors.green;
    if (overallScore >= 60) return Colors.blue;
    if (overallScore >= 40) return Colors.orange;
    return Colors.red;
  }
}

/// Trend analysis data model
class TrendAnalysisData {
  final List<ChartDataPoint> data;
  final double trendPercentage;
  final String trendDirection; // 'up', 'down', 'stable'
  final double confidence;
  final List<ChartDataPoint>? prediction;
  final Map<String, dynamic>? seasonalPatterns;

  const TrendAnalysisData({
    required this.data,
    required this.trendPercentage,
    required this.trendDirection,
    required this.confidence,
    this.prediction,
    this.seasonalPatterns,
  });

  bool get isIncreasing => trendDirection == 'up';
  bool get isDecreasing => trendDirection == 'down';
  bool get isStable => trendDirection == 'stable';
}

/// Chart insight model for AI-generated insights
class ChartInsight {
  final String title;
  final String description;
  final InsightType type;
  final double priority; // 0.0 to 1.0
  final Map<String, dynamic>? actionData;
  final DateTime generated;

  const ChartInsight({
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    this.actionData,
    required this.generated,
  });

  Color get typeColor {
    switch (type) {
      case InsightType.warning:
        return Colors.orange;
      case InsightType.positive:
        return Colors.green;
      case InsightType.info:
        return Colors.blue;
      case InsightType.negative:
        return Colors.red;
      case InsightType.critical:
        return Colors.red.shade700;
    }
  }

  String get message => description;

  IconData get typeIcon {
    switch (type) {
      case InsightType.warning:
        return Icons.warning;
      case InsightType.positive:
        return Icons.trending_up;
      case InsightType.info:
        return Icons.info;
      case InsightType.negative:
        return Icons.trending_down;
      case InsightType.critical:
        return Icons.error;
    }
  }
}
