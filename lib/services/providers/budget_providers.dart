import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/injection_container.dart' as di;
import '../../models/budget_model.dart';
import '../data/budget_service.dart';

/// Service Provider
final budgetServiceProvider = Provider<BudgetService>((ref) {
  return di.getIt<BudgetService>();
});

/// Base Provider - Query tất cả budgets (1 query duy nhất)
final allBudgetsProvider = StreamProvider<List<BudgetModel>>((ref) {
  final service = ref.watch(budgetServiceProvider);
  return service.getBudgets();
});

/// Derived Provider - Budget theo category ID (filter từ cache)
final budgetByCategoryProvider = Provider.family<BudgetModel?, String>((ref, categoryId) {
  final all = ref.watch(allBudgetsProvider).value ?? [];
  try {
    return all.firstWhere(
      (b) => b.categoryId == categoryId && b.isActive,
      orElse: () => throw StateError('Budget not found'),
    );
  } catch (e) {
    return null;
  }
});

/// Derived Provider - Active budgets (filter từ cache)
final activeBudgetsProvider = Provider<List<BudgetModel>>((ref) {
  final all = ref.watch(allBudgetsProvider).value ?? [];
  return all.where((b) => b.isActive).toList();
});

/// Derived Provider - Budget summary (tính từ cache)
final budgetSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final budgets = ref.watch(activeBudgetsProvider);
  
  final totalBudget = budgets.fold(0.0, (total, b) => total + b.monthlyLimit);
  final totalSpending = budgets.fold(0.0, (total, b) => total + b.currentSpending);
  final utilizationRate = totalBudget > 0 ? totalSpending / totalBudget : 0.0;
  
  return {
    'totalBudget': totalBudget,
    'totalSpending': totalSpending,
    'utilizationRate': utilizationRate,
    'categoriesWithBudgets': budgets.length,
  };
});

