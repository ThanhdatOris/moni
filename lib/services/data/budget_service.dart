import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moni/constants/budget_constants.dart';

import '../../models/budget_model.dart';
import '../../models/category_model.dart';
import '../core/base_service.dart';
import 'category_service.dart';
import 'spending_calculator.dart';
import 'transaction_service.dart';

/// Service quản lý ngân sách - Tích hợp với Firestore
/// Đảm bảo tính nhất quán với Category và Transaction
class BudgetService extends BaseService {
  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;
  BudgetService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  TransactionService? _transactionService;
  CategoryService? _categoryService;
  final SpendingCalculator _spendingCalculator = SpendingCalculator.instance;
  
  /// Set transaction service for budget tracking
  /// REQUIRED: Phải set trước khi sử dụng các method tính toán spending
  void setTransactionService(TransactionService transactionService) {
    _transactionService = transactionService;
  }

  /// Set category service for budget validation
  /// REQUIRED: Phải set để validate parent categories
  void setCategoryService(CategoryService categoryService) {
    _categoryService = categoryService;
  }

  /// Validate budget data trước khi lưu
  /// QUAN TRỌNG: Chỉ cho phép tạo budget cho parent categories
  Future<void> _validateBudgetData({
    required String categoryId,
    required String categoryName,
    required double monthlyLimit,
  }) async {
    if (categoryId.isEmpty) {
      throw ArgumentError('Category ID không được để trống');
    }
    if (categoryName.isEmpty) {
      throw ArgumentError('Category name không được để trống');
    }
    if (monthlyLimit < BudgetConstants.minMonthlyLimit) {
      throw ArgumentError('Monthly limit phải >= ${BudgetConstants.minMonthlyLimit}');
    }
    if (monthlyLimit > BudgetConstants.maxMonthlyLimit) {
      throw ArgumentError('Monthly limit quá lớn');
    }

    // Validate chỉ cho phép parent categories
    if (_categoryService != null) {
      try {
        final categories = await _categoryService!.getCategories().first;
        final category = categories.firstWhere(
          (c) => c.categoryId == categoryId,
          orElse: () => throw ArgumentError('Category không tồn tại: $categoryId'),
        );

        // Kiểm tra đây có phải parent category không
        if (category.parentId != null && category.parentId!.isNotEmpty) {
          throw ArgumentError(
            'Chỉ có thể tạo budget cho category cha. '
            'Category "$categoryName" là category con của "${category.parentId}". '
            'Vui lòng tạo budget cho category cha thay vì category con.'
          );
        }
      } catch (e) {
        if (e is ArgumentError) rethrow;
        logError('Error validating category for budget', e);
        // Nếu không validate được, vẫn cho phép tạo nhưng log warning
        logInfo('Warning: Could not validate category parent status, proceeding anyway');
      }
    }
  }

  /// Get all budgets for current user
  Stream<List<BudgetModel>> getBudgets() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('budgets')
        .where(BudgetConstants.isActive, isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BudgetModel.fromFirestore(doc))
            .toList());
  }

  /// Get budget by category ID cho tháng hiện tại
  Future<BudgetModel?> getBudgetByCategory(String categoryId) async {
    try {
      if (categoryId.isEmpty) return null;
      
      final user = _auth.currentUser;
      if (user == null) return null;

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .where(BudgetConstants.categoryId, isEqualTo: categoryId)
          .where(BudgetConstants.isActive, isEqualTo: true)
          .get();

      // Tìm budget của tháng hiện tại
      for (final doc in snapshot.docs) {
        final budget = BudgetModel.fromFirestore(doc);
        if (budget.startDate.year == monthStart.year &&
            budget.startDate.month == monthStart.month &&
            budget.endDate.year == monthEnd.year &&
            budget.endDate.month == monthEnd.month) {
          return budget;
        }
      }

      return null;
    } catch (e) {
      logError('Error getting budget by category', e);
      return null;
    }
  }

  /// Create new budget or update existing budget for same month
  /// Nếu đã có budget cho category này trong tháng hiện tại → update
  /// Nếu chưa có → tạo mới
  /// QUAN TRỌNG: Chỉ cho phép tạo budget cho parent categories
  /// Đảm bảo tính nhất quán với Category (validate categoryId tồn tại và là parent)
  Future<String> createBudget({
    required String categoryId,
    required String categoryName,
    required double monthlyLimit,
  }) async {
    try {
      // Validate input (bao gồm kiểm tra parent category)
      await _validateBudgetData(
        categoryId: categoryId,
        categoryName: categoryName,
        monthlyLimit: monthlyLimit,
      );

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      // Kiểm tra xem đã có budget cho category này trong tháng hiện tại chưa
      final existingBudgetQuery = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .where(BudgetConstants.categoryId, isEqualTo: categoryId)
          .where(BudgetConstants.isActive, isEqualTo: true)
          .get();

      // Tìm budget có cùng tháng
      String? existingBudgetId;
      for (final doc in existingBudgetQuery.docs) {
        final data = doc.data();
        final budgetStartDate = (data[BudgetConstants.startDate] as Timestamp).toDate();
        final budgetEndDate = (data[BudgetConstants.endDate] as Timestamp).toDate();
        
        if (budgetStartDate.year == startDate.year && 
            budgetStartDate.month == startDate.month &&
            budgetEndDate.year == endDate.year &&
            budgetEndDate.month == endDate.month) {
          existingBudgetId = doc.id;
          break;
        }
      }

      if (existingBudgetId != null) {
        // Đã có budget cho tháng này → Update thay vì tạo mới
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('budgets')
            .doc(existingBudgetId)
            .update({
          BudgetConstants.monthlyLimit: monthlyLimit,
          BudgetConstants.categoryName: categoryName,
          BudgetConstants.updatedAt: FieldValue.serverTimestamp(),
        });

        logInfo('Updated existing budget for category: $categoryName (month: ${startDate.month}/${startDate.year})');
        return existingBudgetId;
      } else {
        // Chưa có budget cho tháng này → Tạo mới
        // Tính currentSpending từ transactions nếu có
        // QUAN TRỌNG: Tính spending cho parent category (gộp cả child categories)
        double currentSpending = 0.0;
        if (_transactionService != null && _categoryService != null) {
          try {
            final transactions = await _transactionService!
                .getTransactionsByDateRange(startDate, endDate);
            final categories = await _categoryService!.getCategories().first;
            
            // Tính spending cho parent category (gộp cả children)
            currentSpending = _spendingCalculator.calculateParentCategorySpending(
              transactions: transactions,
              parentCategoryId: categoryId,
              allCategories: categories,
              startDate: startDate,
              endDate: endDate,
            );
          } catch (e) {
            logError('Error calculating initial spending for parent category, using 0', e);
            // Fallback: tính như category thường nếu không có categories
            try {
              final transactions = await _transactionService!
                  .getTransactionsByDateRange(startDate, endDate);
              currentSpending = _spendingCalculator.calculateCategorySpending(
                transactions: transactions,
                categoryId: categoryId,
                startDate: startDate,
                endDate: endDate,
              );
            } catch (e2) {
              logError('Error in fallback spending calculation', e2);
            }
          }
        }

        final budget = BudgetModel(
          id: '',
          userId: user.uid,
          categoryId: categoryId,
          categoryName: categoryName,
          monthlyLimit: monthlyLimit,
          currentSpending: currentSpending,
          startDate: startDate,
          endDate: endDate,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        final docRef = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('budgets')
            .add(budget.toFirestore());

        logInfo('Created new budget for category: $categoryName (month: ${startDate.month}/${startDate.year})');
        return docRef.id;
      }
    } catch (e) {
      logError('Error creating budget', e);
      rethrow;
    }
  }

  /// Update budget limit
  Future<void> updateBudgetLimit(String budgetId, double newLimit) async {
    try {
      if (budgetId.isEmpty) {
        throw ArgumentError('Budget ID không được để trống');
      }
      if (newLimit < BudgetConstants.minMonthlyLimit) {
        throw ArgumentError('Monthly limit phải >= ${BudgetConstants.minMonthlyLimit}');
      }
      if (newLimit > BudgetConstants.maxMonthlyLimit) {
        throw ArgumentError('Monthly limit quá lớn');
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .doc(budgetId)
          .update({
        BudgetConstants.monthlyLimit: newLimit,
        BudgetConstants.updatedAt: FieldValue.serverTimestamp(),
      });

      logInfo('Updated budget limit: $newLimit');
    } catch (e) {
      logError('Error updating budget limit', e);
      rethrow;
    }
  }

  /// Update current spending for a budget của tháng hiện tại
  /// Đảm bảo tính nhất quán với Transaction data
  Future<void> updateCurrentSpending(String categoryId, double spending) async {
    try {
      if (categoryId.isEmpty) return;
      if (spending < 0) {
        logError('Invalid spending value: $spending', null);
        return;
      }

      final user = _auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);

      final budgetQuery = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .where(BudgetConstants.categoryId, isEqualTo: categoryId)
          .where(BudgetConstants.isActive, isEqualTo: true)
          .get();

      // Tìm budget của tháng hiện tại
      for (final doc in budgetQuery.docs) {
        final data = doc.data();
        final budgetStartDate = (data[BudgetConstants.startDate] as Timestamp).toDate();
        final budgetEndDate = (data[BudgetConstants.endDate] as Timestamp).toDate();
        
        if (budgetStartDate.year == monthStart.year &&
            budgetStartDate.month == monthStart.month &&
            budgetEndDate.year == monthEnd.year &&
            budgetEndDate.month == monthEnd.month) {
          await doc.reference.update({
            BudgetConstants.currentSpending: spending,
            BudgetConstants.updatedAt: FieldValue.serverTimestamp(),
          });
          return;
        }
      }
    } catch (e) {
      logError('Error updating current spending', e);
      // Không throw để tránh break flow, nhưng log để debug
    }
  }

  /// Calculate total budget and utilization cho tháng hiện tại
  /// Tối ưu: batch calculate spending thay vì loop tuần tự
  Future<Map<String, dynamic>> getBudgetSummary() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'totalBudget': 0.0,
          'totalSpending': 0.0,
          'utilizationRate': 0.0,
          'categoriesWithBudgets': 0,
        };
      }

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);

      // Get all active budgets của tháng hiện tại
      final budgetsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .where(BudgetConstants.isActive, isEqualTo: true)
          .get();

      final budgets = budgetsSnapshot.docs
          .map((doc) => BudgetModel.fromFirestore(doc))
          .where((budget) =>
              budget.startDate.year == monthStart.year &&
              budget.startDate.month == monthStart.month)
          .toList();

      if (budgets.isEmpty) {
        return {
          'totalBudget': 0.0,
          'totalSpending': 0.0,
          'utilizationRate': 0.0,
          'categoriesWithBudgets': 0,
        };
      }

      // Tối ưu: Tính spending cho tất cả parent categories cùng lúc (gộp cả children)
      Map<String, double> spendingsMap = {};
      if (_transactionService != null && _categoryService != null) {
        try {
          final transactions = await _transactionService!
              .getTransactionsByDateRange(monthStart, monthEnd);
          final categories = await _categoryService!.getCategories().first;
          
          final parentCategoryIds = budgets.map((b) => b.categoryId).toList();
          
          // Tính spending cho parent categories (gộp cả children)
          spendingsMap = _spendingCalculator.calculateMultipleParentCategorySpending(
            transactions: transactions,
            parentCategoryIds: parentCategoryIds,
            allCategories: categories,
            startDate: monthStart,
            endDate: monthEnd,
          );

          // Batch update spending (song song)
          final updateFutures = budgets.map((budget) {
            final spending = spendingsMap[budget.categoryId] ?? 0.0;
            return updateCurrentSpending(budget.categoryId, spending);
          });
          await Future.wait(updateFutures);
        } catch (e) {
          logError('Error calculating parent category spending in summary', e);
          // Fallback: tính như category đơn lẻ
          try {
            final transactions = await _transactionService!
                .getTransactionsByDateRange(monthStart, monthEnd);
            final categoryIds = budgets.map((b) => b.categoryId).toList();
            spendingsMap = _spendingCalculator.calculateMultipleCategorySpending(
              transactions: transactions,
              categoryIds: categoryIds,
              startDate: monthStart,
              endDate: monthEnd,
            );
          } catch (e2) {
            logError('Error in fallback spending calculation', e2);
          }
        }
      }

      // Calculate summary với spending đã tính
      double totalBudget = 0.0;
      double totalSpending = 0.0;
      
      for (final budget in budgets) {
        totalBudget += budget.monthlyLimit;
        final spending = spendingsMap[budget.categoryId] ?? budget.currentSpending;
        totalSpending += spending;
      }

      final utilizationRate = totalBudget > 0 ? totalSpending / totalBudget : 0.0;

      return {
        'totalBudget': totalBudget,
        'totalSpending': totalSpending,
        'utilizationRate': utilizationRate,
        'categoriesWithBudgets': budgets.length,
      };
    } catch (e) {
      logError('Error calculating budget summary', e);
      return {
        'totalBudget': 0.0,
        'totalSpending': 0.0,
        'utilizationRate': 0.0,
        'categoriesWithBudgets': 0,
      };
    }
  }

  /// Calculate current spending for a budget from transactions
  /// QUAN TRỌNG: Tính spending cho parent category (gộp cả child categories)
  /// Sử dụng SpendingCalculator để đảm bảo tính nhất quán
  Future<double> calculateCurrentSpending({
    required String categoryId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (categoryId.isEmpty) return 0.0;
      
      // Nếu không có transaction service, return 0
      if (_transactionService == null) {
        logInfo('TransactionService not set, returning 0 for spending');
        return 0.0;
      }

      // Get transactions for date range
      final transactions = await _transactionService!
          .getTransactionsByDateRange(startDate, endDate);

      // Nếu có category service, tính spending cho parent category (gộp cả children)
      if (_categoryService != null) {
        try {
          final categories = await _categoryService!.getCategories().first;
          
          // Kiểm tra đây có phải parent category không
          final category = categories.firstWhere(
            (c) => c.categoryId == categoryId,
            orElse: () => throw ArgumentError('Category not found'),
          );

          // Nếu là parent category, tính gộp cả children
          if (category.parentId == null || category.parentId!.isEmpty) {
            return _spendingCalculator.calculateParentCategorySpending(
              transactions: transactions,
              parentCategoryId: categoryId,
              allCategories: categories,
              startDate: startDate,
              endDate: endDate,
            );
          }
        } catch (e) {
          logError('Error calculating parent category spending, falling back to single category', e);
        }
      }

      // Fallback: tính như category đơn lẻ
      return _spendingCalculator.calculateCategorySpending(
        transactions: transactions,
        categoryId: categoryId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      logError('Error calculating current spending', e);
      return 0.0;
    }
  }

  /// Sync all budgets với transactions thực tế cho tháng hiện tại
  /// Tối ưu: batch calculate và update thay vì loop tuần tự
  Future<void> syncBudgetsWithTransactions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      if (_transactionService == null) {
        logInfo('TransactionService not set, skipping sync');
        return;
      }

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);

      // Get all active budgets của tháng hiện tại
      final budgetsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .where(BudgetConstants.isActive, isEqualTo: true)
          .get();

      final budgets = budgetsSnapshot.docs
          .map((doc) => BudgetModel.fromFirestore(doc))
          .where((budget) =>
              budget.startDate.year == monthStart.year &&
              budget.startDate.month == monthStart.month)
          .toList();

      if (budgets.isEmpty) {
        logInfo('No budgets to sync');
        return;
      }

      // Tối ưu: Lấy transactions một lần và tính spending cho tất cả parent categories (gộp cả children)
      final transactions = await _transactionService!
          .getTransactionsByDateRange(monthStart, monthEnd);

      Map<String, double> spendingsMap = {};
      
      if (_categoryService != null) {
        try {
          final categories = await _categoryService!.getCategories().first;
          final parentCategoryIds = budgets.map((b) => b.categoryId).toList();
          
          // Tính spending cho parent categories (gộp cả children)
          spendingsMap = _spendingCalculator.calculateMultipleParentCategorySpending(
            transactions: transactions,
            parentCategoryIds: parentCategoryIds,
            allCategories: categories,
            startDate: monthStart,
            endDate: monthEnd,
          );
        } catch (e) {
          logError('Error calculating parent category spending in sync, falling back', e);
          // Fallback: tính như category đơn lẻ
          final categoryIds = budgets.map((b) => b.categoryId).toList();
          spendingsMap = _spendingCalculator.calculateMultipleCategorySpending(
            transactions: transactions,
            categoryIds: categoryIds,
            startDate: monthStart,
            endDate: monthEnd,
          );
        }
      } else {
        // Fallback nếu không có category service
        final categoryIds = budgets.map((b) => b.categoryId).toList();
        spendingsMap = _spendingCalculator.calculateMultipleCategorySpending(
          transactions: transactions,
          categoryIds: categoryIds,
          startDate: monthStart,
          endDate: monthEnd,
        );
      }

      // Batch update spending (song song)
      final updateFutures = budgets.map((budget) {
        final spending = spendingsMap[budget.categoryId] ?? 0.0;
        return _updateBudgetSpendingDirect(budget.id, spending);
      });

      await Future.wait(updateFutures);
      logInfo('Synced ${budgets.length} budgets with transactions');
    } catch (e) {
      logError('Error syncing budgets with transactions', e);
    }
  }

  /// Update spending trực tiếp bằng budgetId (internal method)
  Future<void> _updateBudgetSpendingDirect(String budgetId, double spending) async {
    try {
      final user = _auth.currentUser;
      if (user == null || budgetId.isEmpty) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .doc(budgetId)
          .update({
        BudgetConstants.currentSpending: spending,
        BudgetConstants.updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logError('Error updating budget spending directly', e);
    }
  }

  /// Delete budget (soft delete)
  Future<void> deleteBudget(String budgetId) async {
    try {
      if (budgetId.isEmpty) {
        throw ArgumentError('Budget ID không được để trống');
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .doc(budgetId)
          .update({
        BudgetConstants.isActive: false,
        BudgetConstants.updatedAt: FieldValue.serverTimestamp(),
      });

      logInfo('Deleted budget: $budgetId');
    } catch (e) {
      logError('Error deleting budget', e);
      rethrow;
    }
  }
}
