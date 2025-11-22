import 'package:moni/constants/enums.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';

/// Service tính toán spending - Đảm bảo tính nhất quán với Transaction
/// Tách riêng để tránh duplicate logic và đảm bảo tính chính xác
/// Hỗ trợ tính spending cho parent category (gộp cả child categories)
class SpendingCalculator {
  SpendingCalculator._();
  static final SpendingCalculator instance = SpendingCalculator._();

  /// Tính tổng chi tiêu cho một category trong khoảng thời gian
  /// Chỉ tính các transaction expense, không deleted, trong date range
  double calculateCategorySpending({
    required List<TransactionModel> transactions,
    required String categoryId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    if (transactions.isEmpty) return 0.0;
    if (categoryId.isEmpty) return 0.0;

    final filteredTransactions = transactions.where((transaction) {
      // Chỉ tính expense transactions
      if (transaction.type != TransactionType.expense) return false;
      
      // Không tính deleted transactions
      if (transaction.isDeleted) return false;
      
      // Phải match category
      if (transaction.categoryId != categoryId) return false;
      
      // Phải trong date range (bao gồm cả start và end date)
      final transactionDate = transaction.date;
      if (transactionDate.isBefore(startDate) || transactionDate.isAfter(endDate)) {
        return false;
      }
      
      return true;
    });

    return filteredTransactions.fold(
      0.0,
      (total, transaction) => total + transaction.amount,
    );
  }

  /// Tính tổng chi tiêu cho nhiều categories cùng lúc (tối ưu performance)
  /// Trả về Map\<categoryId, spending>
  Map<String, double> calculateMultipleCategorySpending({
    required List<TransactionModel> transactions,
    required List<String> categoryIds,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final result = <String, double>{};
    
    // Initialize với 0 cho tất cả categories
    for (final categoryId in categoryIds) {
      result[categoryId] = 0.0;
    }

    // Filter transactions một lần
    final validTransactions = transactions.where((transaction) {
      if (transaction.type != TransactionType.expense) return false;
      if (transaction.isDeleted) return false;
      if (!categoryIds.contains(transaction.categoryId)) return false;
      
      final transactionDate = transaction.date;
      if (transactionDate.isBefore(startDate) || transactionDate.isAfter(endDate)) {
        return false;
      }
      
      return true;
    });

    // Tính tổng cho từng category
    for (final transaction in validTransactions) {
      final categoryId = transaction.categoryId;
      result[categoryId] = (result[categoryId] ?? 0.0) + transaction.amount;
    }

    return result;
  }

  /// Tính tổng chi tiêu cho tất cả categories trong date range
  double calculateTotalSpending({
    required List<TransactionModel> transactions,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    if (transactions.isEmpty) return 0.0;

    final filteredTransactions = transactions.where((transaction) {
      if (transaction.type != TransactionType.expense) return false;
      if (transaction.isDeleted) return false;
      
      final transactionDate = transaction.date;
      if (transactionDate.isBefore(startDate) || transactionDate.isAfter(endDate)) {
        return false;
      }
      
      return true;
    });

    return filteredTransactions.fold(
      0.0,
      (total, transaction) => total + transaction.amount,
    );
  }

  /// Tính tổng chi tiêu cho parent category (gộp cả spending của các child categories)
  /// QUAN TRỌNG: Chỉ dùng cho parent categories, không dùng cho child categories
  double calculateParentCategorySpending({
    required List<TransactionModel> transactions,
    required String parentCategoryId,
    required List<CategoryModel> allCategories,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    if (transactions.isEmpty) return 0.0;
    if (parentCategoryId.isEmpty) return 0.0;

    // Tìm parent category để validate
    final parentCategory = allCategories.firstWhere(
      (c) => c.categoryId == parentCategoryId,
      orElse: () => throw ArgumentError('Parent category not found: $parentCategoryId'),
    );

    // Validate đây là parent category (không có parentId)
    if (parentCategory.parentId != null && parentCategory.parentId!.isNotEmpty) {
      throw ArgumentError('Category $parentCategoryId is not a parent category');
    }

    // Lấy tất cả child category IDs của parent này
    final childCategoryIds = allCategories
        .where((c) => c.parentId == parentCategoryId)
        .map((c) => c.categoryId)
        .toList();

    // Tính spending cho parent category và tất cả child categories
    final allCategoryIds = [parentCategoryId, ...childCategoryIds];

    final filteredTransactions = transactions.where((transaction) {
      if (transaction.type != TransactionType.expense) return false;
      if (transaction.isDeleted) return false;
      if (!allCategoryIds.contains(transaction.categoryId)) return false;
      
      final transactionDate = transaction.date;
      if (transactionDate.isBefore(startDate) || transactionDate.isAfter(endDate)) {
        return false;
      }
      
      return true;
    });

    return filteredTransactions.fold(
      0.0,
      (total, transaction) => total + transaction.amount,
    );
  }

  /// Tính tổng chi tiêu cho nhiều parent categories cùng lúc (tối ưu performance)
  /// Gộp spending của các child categories vào parent
  /// Trả về Map\<parentCategoryId, totalSpending>
  Map<String, double> calculateMultipleParentCategorySpending({
    required List<TransactionModel> transactions,
    required List<String> parentCategoryIds,
    required List<CategoryModel> allCategories,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final result = <String, double>{};
    
    // Initialize với 0 cho tất cả parent categories
    for (final parentId in parentCategoryIds) {
      result[parentId] = 0.0;
    }

    // Tạo map: parentId -> [parentId, ...childIds]
    final categoryGroups = <String, List<String>>{};
    for (final parentId in parentCategoryIds) {
      final parentCategory = allCategories.firstWhere(
        (c) => c.categoryId == parentId,
        orElse: () => throw ArgumentError('Parent category not found: $parentId'),
      );

      if (parentCategory.parentId != null && parentCategory.parentId!.isNotEmpty) {
        throw ArgumentError('Category $parentId is not a parent category');
      }

      final childIds = allCategories
          .where((c) => c.parentId == parentId)
          .map((c) => c.categoryId)
          .toList();
      
      categoryGroups[parentId] = [parentId, ...childIds];
    }

    // Lấy tất cả category IDs cần tính (parent + children)
    final allCategoryIds = categoryGroups.values.expand((ids) => ids).toSet().toList();

    // Filter transactions một lần
    final validTransactions = transactions.where((transaction) {
      if (transaction.type != TransactionType.expense) return false;
      if (transaction.isDeleted) return false;
      if (!allCategoryIds.contains(transaction.categoryId)) return false;
      
      final transactionDate = transaction.date;
      if (transactionDate.isBefore(startDate) || transactionDate.isAfter(endDate)) {
        return false;
      }
      
      return true;
    });

    // Tính tổng cho từng parent category (gộp cả children)
    for (final transaction in validTransactions) {
      final transactionCategoryId = transaction.categoryId;
      
      // Tìm parent category của transaction này
      for (final entry in categoryGroups.entries) {
        final parentId = entry.key;
        final categoryIds = entry.value;
        
        if (categoryIds.contains(transactionCategoryId)) {
          result[parentId] = (result[parentId] ?? 0.0) + transaction.amount;
          break; // Mỗi transaction chỉ thuộc 1 parent
        }
      }
    }

    return result;
  }
}

