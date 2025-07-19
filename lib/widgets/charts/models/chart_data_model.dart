class ChartDataModel {
  final String category;
  final double amount;
  final double percentage;
  final String icon;
  final String color;
  final String type; // 'expense' hoặc 'income'

  ChartDataModel({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.icon,
    required this.color,
    required this.type,
  });

  factory ChartDataModel.fromJson(Map<String, dynamic> json) {
    return ChartDataModel(
      category: json['category'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
      icon: json['icon'] ?? '',
      color: json['color'] ?? '#000000',
      type: json['type'] ?? 'expense',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'amount': amount,
      'percentage': percentage,
      'icon': icon,
      'color': color,
      'type': type,
    };
  }
}

class FinancialOverviewData {
  final double totalExpense;
  final double totalIncome;
  final double changeAmount;
  final String changePeriod;
  final bool isIncrease;

  FinancialOverviewData({
    required this.totalExpense,
    required this.totalIncome,
    required this.changeAmount,
    required this.changePeriod,
    required this.isIncrease,
  });

  factory FinancialOverviewData.fromJson(Map<String, dynamic> json) {
    return FinancialOverviewData(
      totalExpense: (json['totalExpense'] ?? 0).toDouble(),
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      changeAmount: (json['changeAmount'] ?? 0).toDouble(),
      changePeriod: json['changePeriod'] ?? '',
      isIncrease: json['isIncrease'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalExpense': totalExpense,
      'totalIncome': totalIncome,
      'changeAmount': changeAmount,
      'changePeriod': changePeriod,
      'isIncrease': isIncrease,
    };
  }
}

class TrendData {
  final String period;
  final double expense;
  final double income;
  final String label;

  TrendData({
    required this.period,
    required this.expense,
    required this.income,
    required this.label,
  });

  factory TrendData.fromJson(Map<String, dynamic> json) {
    return TrendData(
      period: json['period'] ?? '',
      expense: (json['expense'] ?? 0).toDouble(),
      income: (json['income'] ?? 0).toDouble(),
      label: json['label'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'expense': expense,
      'income': income,
      'label': label,
    };
  }
}
