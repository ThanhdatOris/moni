import 'package:moni/constants/budget_constants.dart';
import 'package:moni/constants/enums.dart';
import '../../models/category_model.dart';

/// Service xử lý logic phân bổ budget - Tách riêng khỏi UI
/// Đảm bảo tính nhất quán với Category và Transaction
class BudgetAllocationService {
  BudgetAllocationService._();
  static final BudgetAllocationService instance = BudgetAllocationService._();

  /// Chuyển đổi income từ period sang monthly
  double convertToMonthlyIncome({
    required double income,
    required BudgetPeriod period,
  }) {
    switch (period) {
      case BudgetPeriod.weekly:
        return income * BudgetConstants.weeklyToMonthlyFactor;
      case BudgetPeriod.monthly:
        return income;
      case BudgetPeriod.yearly:
        return income / BudgetConstants.yearlyToMonthlyFactor;
    }
  }

  /// Tính tổng budget có thể phân bổ (sau khi trừ savings goal)
  double calculateTotalAllocatableBudget({
    required double monthlyIncome,
    required double savingsGoalPercent,
  }) {
    if (savingsGoalPercent < 0 || savingsGoalPercent > 100) {
      throw ArgumentError('Savings goal phải trong khoảng 0-100%');
    }
    return monthlyIncome * (1 - savingsGoalPercent / 100);
  }

  /// Phân bổ budget cho các categories
  /// QUAN TRỌNG: Chỉ phân bổ cho parent categories (không có parentId)
  /// Priority categories nhận nhiều hơn theo ratio đã định
  Map<String, double> allocateBudgets({
    required double totalBudget,
    required List<CategoryModel> allCategories,
    required List<String> priorityCategoryNames,
    BudgetAllocationConfig? config,
  }) {
    final allocationConfig = config ?? const BudgetAllocationConfig();
    
    if (!allocationConfig.isValid) {
      throw ArgumentError('Budget allocation ratios không hợp lệ');
    }

    if (totalBudget < 0) {
      throw ArgumentError('Total budget không được âm');
    }

    // QUAN TRỌNG: Chỉ lấy parent categories (không có parentId)
    final parentCategories = allCategories
        .where((c) => c.parentId == null || c.parentId!.isEmpty)
        .toList();

    final categoryBudgets = <String, double>{};
    
    // Tạo map từ category name sang category để lookup nhanh
    final categoryMap = <String, CategoryModel>{};
    for (final category in parentCategories) {
      categoryMap[category.name] = category;
    }

    // Validate priority categories tồn tại và là parent categories
    final validPriorityCategories = priorityCategoryNames
        .where((name) => categoryMap.containsKey(name))
        .toList();

    // Tính budget cho priority và other categories
    final priorityBudget = totalBudget * allocationConfig.priorityRatio;
    final otherBudget = totalBudget * allocationConfig.otherRatio;

    // Phân bổ cho priority categories
    if (validPriorityCategories.isNotEmpty) {
      final perPriorityCategory = priorityBudget / validPriorityCategories.length;
      for (final categoryName in validPriorityCategories) {
        final category = categoryMap[categoryName]!;
        categoryBudgets[category.categoryId] = perPriorityCategory;
      }
    }

    // Phân bổ cho các parent category còn lại
    final otherCategories = parentCategories
        .where((c) => !validPriorityCategories.contains(c.name))
        .toList();
    
    if (otherCategories.isNotEmpty) {
      final perOtherCategory = otherBudget / otherCategories.length;
      for (final category in otherCategories) {
        // Chỉ set nếu chưa có (tránh override priority)
        categoryBudgets.putIfAbsent(
          category.categoryId,
          () => perOtherCategory,
        );
      }
    }

    // Đảm bảo không có giá trị âm
    categoryBudgets.updateAll((key, value) => value < 0 ? 0.0 : value);

    return categoryBudgets;
  }

  /// Tính toán budget allocation từ input data
  BudgetAllocationResult calculateBudgetAllocation({
    required double income,
    required BudgetPeriod period,
    required List<String> priorityCategories,
    required double savingsGoal,
    required List<CategoryModel> allCategories,
    BudgetAllocationConfig? config,
  }) {
    // Validate input
    if (income <= 0) {
      throw ArgumentError('Income phải lớn hơn 0');
    }
    if (savingsGoal < 0 || savingsGoal > 100) {
      throw ArgumentError('Savings goal phải trong khoảng 0-100%');
    }

    // Chuyển đổi sang monthly
    final monthlyIncome = convertToMonthlyIncome(
      income: income,
      period: period,
    );

    // Tính total budget có thể phân bổ
    final totalBudget = calculateTotalAllocatableBudget(
      monthlyIncome: monthlyIncome,
      savingsGoalPercent: savingsGoal,
    );

    // Phân bổ cho các categories
    final categoryBudgets = allocateBudgets(
      totalBudget: totalBudget,
      allCategories: allCategories,
      priorityCategoryNames: priorityCategories,
      config: config,
    );

    return BudgetAllocationResult(
      monthlyIncome: monthlyIncome,
      totalBudget: totalBudget,
      savingsAmount: monthlyIncome * (savingsGoal / 100),
      categoryBudgets: categoryBudgets,
    );
  }
}

/// Kết quả phân bổ budget
class BudgetAllocationResult {
  final double monthlyIncome;
  final double totalBudget;
  final double savingsAmount;
  final Map<String, double> categoryBudgets;

  BudgetAllocationResult({
    required this.monthlyIncome,
    required this.totalBudget,
    required this.savingsAmount,
    required this.categoryBudgets,
  });
}

