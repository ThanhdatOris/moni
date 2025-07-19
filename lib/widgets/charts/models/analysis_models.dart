import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'chart_data_models.dart';

/// Analysis result for income vs expense comparison
class IncomeExpenseAnalysis {
  final List<IncomeExpenseData> data;
  final double totalIncome;
  final double totalExpense;
  final double netIncome;
  final double averageMonthlyIncome;
  final double averageMonthlyExpense;
  final double savingsRate;
  final TrendAnalysisData incomeTrend;
  final TrendAnalysisData expenseTrend;
  final List<ChartInsight> insights;
  final DateTime analysisDate;

  const IncomeExpenseAnalysis({
    required this.data,
    required this.totalIncome,
    required this.totalExpense,
    required this.netIncome,
    required this.averageMonthlyIncome,
    required this.averageMonthlyExpense,
    required this.savingsRate,
    required this.incomeTrend,
    required this.expenseTrend,
    required this.insights,
    required this.analysisDate,
  });

  /// Growth rate for income
  double get incomeGrowthRate => incomeTrend.trendPercentage;

  /// Growth rate for expenses
  double get expenseGrowthRate => expenseTrend.trendPercentage;

  /// Net amount (income - expense)
  double get netAmount => netIncome;

  /// Monthly data for charts
  List<IncomeExpenseData> get monthlyData => data;

  /// Maximum amount for chart scaling
  double get maxAmount {
    if (data.isEmpty) return 0.0;
    return data.fold(0.0, (max, item) => 
      math.max(max, math.max(item.income, item.expense)));
  }

  /// Whether financial situation is improving
  bool get isImproving {
    return incomeTrend.isIncreasing || expenseTrend.isDecreasing;
  }

  /// Whether user is saving money
  bool get isSaving => netIncome > 0;

  /// Expense ratio (expense/income)
  double get expenseRatio => totalIncome > 0 ? totalExpense / totalIncome : 0.0;

  /// Financial health indicator
  String get healthIndicator {
    if (savingsRate >= 0.2) return 'Excellent';
    if (savingsRate >= 0.1) return 'Good';
    if (savingsRate >= 0.0) return 'Fair';
    return 'Poor';
  }

  /// Color for health indicator
  Color get healthColor {
    if (savingsRate >= 0.2) return Colors.green;
    if (savingsRate >= 0.1) return Colors.blue;
    if (savingsRate >= 0.0) return Colors.orange;
    return Colors.red;
  }
}

/// Category spending analysis result
class CategorySpendingAnalysis {
  final List<CategoryAnalysisData> categories;
  final CategoryAnalysisData topSpendingCategory;
  final CategoryAnalysisData mostImprovedCategory;
  final CategoryAnalysisData mostDeterioratedCategory;
  final double totalSpending;
  final Map<String, TrendAnalysisData> categoryTrends;
  final List<CategoryAnalysisData> overBudgetCategories;
  final List<ChartInsight> insights;
  final DateTime analysisDate;

  const CategorySpendingAnalysis({
    required this.categories,
    required this.topSpendingCategory,
    required this.mostImprovedCategory,
    required this.mostDeterioratedCategory,
    required this.totalSpending,
    required this.categoryTrends,
    required this.overBudgetCategories,
    required this.insights,
    required this.analysisDate,
  });

  /// Number of categories over budget
  int get overBudgetCount => overBudgetCategories.length;

  /// Total amount over budget
  double get totalOverBudget {
    return overBudgetCategories.fold(
      0.0,
      (sum, category) => sum + (category.totalAmount - category.budgetAmount),
    );
  }

  /// Budget utilization rate
  double get budgetUtilizationRate {
    final totalBudget = categories.fold(0.0, (sum, cat) => sum + cat.budgetAmount);
    return totalBudget > 0 ? totalSpending / totalBudget : 0.0;
  }

  /// Categories sorted by spending amount
  List<CategoryAnalysisData> get categoriesBySpending {
    final sorted = List<CategoryAnalysisData>.from(categories);
    sorted.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return sorted;
  }
}

/// Time-based spending pattern analysis
class SpendingPatternAnalysis {
  final Map<int, double> dailyPatterns; // Day of week -> amount
  final Map<int, double> monthlyPatterns; // Month -> amount
  final Map<int, double> hourlyPatterns; // Hour -> amount
  final List<SpendingPeak> spendingPeaks;
  final List<SpendingLow> spendingLows;
  final SeasonalAnalysis seasonalAnalysis;
  final List<SpendingAnomaly> anomalies;
  final List<ChartInsight> insights;
  final DateTime analysisDate;

  const SpendingPatternAnalysis({
    required this.dailyPatterns,
    required this.monthlyPatterns,
    required this.hourlyPatterns,
    required this.spendingPeaks,
    required this.spendingLows,
    required this.seasonalAnalysis,
    required this.anomalies,
    required this.insights,
    required this.analysisDate,
  });

  /// Most expensive day of the week
  String get mostExpensiveDay {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxEntry = dailyPatterns.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    return days[maxEntry.key - 1];
  }

  /// Most expensive month
  String get mostExpensiveMonth {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final maxEntry = monthlyPatterns.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    return months[maxEntry.key - 1];
  }

  /// Peak spending hour
  int get peakSpendingHour {
    final maxEntry = hourlyPatterns.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    return maxEntry.key;
  }
}

/// Spending peak data
class SpendingPeak {
  final DateTime date;
  final double amount;
  final String category;
  final String reason;

  const SpendingPeak({
    required this.date,
    required this.amount,
    required this.category,
    required this.reason,
  });
}

/// Spending low data
class SpendingLow {
  final DateTime date;
  final double amount;
  final String reason;

  const SpendingLow({
    required this.date,
    required this.amount,
    required this.reason,
  });
}

/// Seasonal spending analysis
class SeasonalAnalysis {
  final Map<String, double> seasonalSpending; // Season -> amount
  final Map<String, List<String>> seasonalCategories; // Season -> top categories
  final String highestSpendingSeason;
  final String lowestSpendingSeason;
  final double seasonalVariance;

  const SeasonalAnalysis({
    required this.seasonalSpending,
    required this.seasonalCategories,
    required this.highestSpendingSeason,
    required this.lowestSpendingSeason,
    required this.seasonalVariance,
  });
}

/// Spending anomaly data
class SpendingAnomaly {
  final DateTime date;
  final double amount;
  final double expectedAmount;
  final String category;
  final String type; // 'spike', 'drop', 'unusual'
  final double severity; // 0.0 to 1.0
  final String description;

  const SpendingAnomaly({
    required this.date,
    required this.amount,
    required this.expectedAmount,
    required this.category,
    required this.type,
    required this.severity,
    required this.description,
  });

  /// Deviation from expected amount
  double get deviation => amount - expectedAmount;

  /// Deviation percentage
  double get deviationPercentage {
    return expectedAmount > 0 ? (deviation / expectedAmount) : 0.0;
  }

  /// Color based on severity
  Color get severityColor {
    if (severity >= 0.8) return Colors.red;
    if (severity >= 0.6) return Colors.orange;
    if (severity >= 0.4) return Colors.yellow;
    return Colors.blue;
  }
}

/// Budget performance analysis
class BudgetPerformanceAnalysis {
  final double totalBudget;
  final double totalSpent;
  final double remainingBudget;
  final List<CategoryBudgetPerformance> categoryPerformances;
  final List<BudgetAlert> alerts;
  final BudgetProjection projection;
  final List<ChartInsight> insights;
  final DateTime analysisDate;

  const BudgetPerformanceAnalysis({
    required this.totalBudget,
    required this.totalSpent,
    required this.remainingBudget,
    required this.categoryPerformances,
    required this.alerts,
    required this.projection,
    required this.insights,
    required this.analysisDate,
  });

  /// Budget utilization percentage
  double get utilizationPercentage {
    return totalBudget > 0 ? (totalSpent / totalBudget) : 0.0;
  }

  /// Whether over budget
  bool get isOverBudget => totalSpent > totalBudget;

  /// Days remaining in budget period
  int get daysRemainingInPeriod {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return endOfMonth.difference(now).inDays;
  }
}

/// Category budget performance
class CategoryBudgetPerformance {
  final String categoryId;
  final String categoryName;
  final double budgetAmount;
  final double spentAmount;
  final double remainingAmount;
  final double utilizationRate;
  final bool isOverBudget;
  final TrendAnalysisData spendingTrend;

  const CategoryBudgetPerformance({
    required this.categoryId,
    required this.categoryName,
    required this.budgetAmount,
    required this.spentAmount,
    required this.remainingAmount,
    required this.utilizationRate,
    required this.isOverBudget,
    required this.spendingTrend,
  });
}

/// Budget alert
class BudgetAlert {
  final String categoryId;
  final String categoryName;
  final String alertType; // 'warning', 'exceeded', 'approaching'
  final double threshold;
  final double currentAmount;
  final String message;
  final DateTime alertDate;

  const BudgetAlert({
    required this.categoryId,
    required this.categoryName,
    required this.alertType,
    required this.threshold,
    required this.currentAmount,
    required this.message,
    required this.alertDate,
  });

  Color get alertColor {
    switch (alertType) {
      case 'exceeded':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'approaching':
        return Colors.yellow;
      default:
        return Colors.blue;
    }
  }
}

/// Budget projection
class BudgetProjection {
  final double projectedSpending;
  final double projectedOverage;
  final bool willExceedBudget;
  final DateTime projectedExceedDate;
  final List<CategoryProjection> categoryProjections;

  const BudgetProjection({
    required this.projectedSpending,
    required this.projectedOverage,
    required this.willExceedBudget,
    required this.projectedExceedDate,
    required this.categoryProjections,
  });
}

/// Category projection
class CategoryProjection {
  final String categoryId;
  final String categoryName;
  final double projectedAmount;
  final bool willExceedBudget;
  final DateTime? projectedExceedDate;

  const CategoryProjection({
    required this.categoryId,
    required this.categoryName,
    required this.projectedAmount,
    required this.willExceedBudget,
    this.projectedExceedDate,
  });
}

/// Financial goal progress analysis
class GoalProgressAnalysis {
  final String goalId;
  final String goalName;
  final double targetAmount;
  final double currentAmount;
  final double progressPercentage;
  final DateTime targetDate;
  final DateTime startDate;
  final bool isOnTrack;
  final double monthlyTargetAmount;
  final double currentMonthlyRate;
  final List<ChartDataPoint> progressHistory;
  final List<ChartInsight> insights;

  const GoalProgressAnalysis({
    required this.goalId,
    required this.goalName,
    required this.targetAmount,
    required this.currentAmount,
    required this.progressPercentage,
    required this.targetDate,
    required this.startDate,
    required this.isOnTrack,
    required this.monthlyTargetAmount,
    required this.currentMonthlyRate,
    required this.progressHistory,
    required this.insights,
  });

  /// Remaining amount to reach goal
  double get remainingAmount => targetAmount - currentAmount;

  /// Months remaining to target date
  int get monthsRemaining {
    final now = DateTime.now();
    return ((targetDate.year - now.year) * 12) + (targetDate.month - now.month);
  }

  /// Whether goal is achieved
  bool get isAchieved => currentAmount >= targetAmount;

  /// Projected completion date based on current rate
  DateTime get projectedCompletionDate {
    if (currentMonthlyRate <= 0) return targetDate.add(const Duration(days: 365 * 10));
    
    final monthsNeeded = remainingAmount / currentMonthlyRate;
    return DateTime.now().add(Duration(days: (monthsNeeded * 30).round()));
  }
}
