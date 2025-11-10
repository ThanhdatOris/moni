import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moni/constants/enums.dart';

import '../../core/injection_container.dart' as di;
import '../../models/category_model.dart';
import '../data/category_service.dart';

/// Service Provider
final categoryServiceProvider = Provider<CategoryService>((ref) {
  return di.getIt<CategoryService>();
});

/// Base Provider - Query tất cả categories (1 query duy nhất)
/// Cache toàn bộ categories để các derived providers filter từ cache
final allCategoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final service = ref.watch(categoryServiceProvider);
  // Query tất cả categories không filter để cache
  // Keep alive để đảm bảo stream được giữ active khi không có listeners
  ref.keepAlive();
  return service.getCategories();
});

/// Derived Provider - Categories theo type (filter từ cache)
final categoriesByTypeProvider = Provider.family<List<CategoryModel>, TransactionType>((ref, type) {
  final all = ref.watch(allCategoriesProvider).value ?? [];
  return all
      .where((c) => !c.isDeleted && c.type == type)
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
});

/// Derived Provider - Parent categories (filter từ cache)
final parentCategoriesProvider = Provider.family<List<CategoryModel>, TransactionType?>((ref, type) {
  final all = ref.watch(allCategoriesProvider).value ?? [];
  var parents = all
      .where((c) => !c.isDeleted && (c.parentId == null || c.parentId!.isEmpty))
      .toList();
  
  if (type != null) {
    parents = parents.where((c) => c.type == type).toList();
  }
  
  parents.sort((a, b) => a.name.compareTo(b.name));
  return parents;
});

/// Derived Provider - Child categories của một parent (filter từ cache)
final childCategoriesProvider = Provider.family<List<CategoryModel>, String>((ref, parentId) {
  final all = ref.watch(allCategoriesProvider).value ?? [];
  return all
      .where((c) => !c.isDeleted && c.parentId == parentId)
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
});

/// Derived Provider - Default categories (filter từ cache)
final defaultCategoriesProvider = Provider.family<List<CategoryModel>, TransactionType?>((ref, type) {
  final all = ref.watch(allCategoriesProvider).value ?? [];
  var defaults = all
      .where((c) => !c.isDeleted && c.isDefault)
      .toList();
  
  if (type != null) {
    defaults = defaults.where((c) => c.type == type).toList();
  }
  
  defaults.sort((a, b) => a.name.compareTo(b.name));
  return defaults;
});

/// Derived Provider - Category theo ID (tìm từ cache)
final categoryByIdProvider = Provider.family<CategoryModel?, String>((ref, categoryId) {
  final all = ref.watch(allCategoriesProvider).value ?? [];
  try {
    return all.firstWhere(
      (c) => c.categoryId == categoryId && !c.isDeleted,
      orElse: () => throw StateError('Category not found'),
    );
  } catch (e) {
    return null;
  }
});

/// Derived Provider - Expense categories (convenience)
final expenseCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  return ref.watch(categoriesByTypeProvider(TransactionType.expense));
});

/// Derived Provider - Income categories (convenience)
final incomeCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  return ref.watch(categoriesByTypeProvider(TransactionType.income));
});

