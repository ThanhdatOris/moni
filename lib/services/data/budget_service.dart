import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/budget_model.dart';
import '../core/base_service.dart';

/// Service quản lý ngân sách - Tích hợp với Firestore
class BudgetService extends BaseService {
  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;
  BudgetService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BudgetModel.fromFirestore(doc))
            .toList());
  }

  /// Get budget by category ID
  Future<BudgetModel?> getBudgetByCategory(String categoryId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .where('categoryId', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return BudgetModel.fromFirestore(doc);
    } catch (e) {
      logError('Error getting budget by category', e);
      return null;
    }
  }

  /// Create new budget
  Future<String> createBudget({
    required String categoryId,
    required String categoryName,
    required double monthlyLimit,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      final budget = BudgetModel(
        id: '',
        userId: user.uid,
        categoryId: categoryId,
        categoryName: categoryName,
        monthlyLimit: monthlyLimit,
        currentSpending: 0.0,
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

      logInfo('Created budget for category: $categoryName');
      return docRef.id;
    } catch (e) {
      logError('Error creating budget', e);
      rethrow;
    }
  }

  /// Update budget limit
  Future<void> updateBudgetLimit(String budgetId, double newLimit) async {
    try {
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
        'monthlyLimit': newLimit,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      logInfo('Updated budget limit: $newLimit');
    } catch (e) {
      logError('Error updating budget limit', e);
      rethrow;
    }
  }

  /// Update current spending for a budget
  Future<void> updateCurrentSpending(String categoryId, double spending) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final budgetQuery = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .where('categoryId', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (budgetQuery.docs.isNotEmpty) {
        final budgetDoc = budgetQuery.docs.first;
        await budgetDoc.reference.update({
          'currentSpending': spending,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      logError('Error updating current spending', e);
    }
  }

  /// Calculate total budget and utilization
  Future<Map<String, dynamic>> getBudgetSummary() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'totalBudget': 0.0,
          'utilizationRate': 0.0,
          'categoriesWithBudgets': 0,
          'categoriesWithoutBudgets': 0,
        };
      }

      // Get all active budgets
      final budgetsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .where('isActive', isEqualTo: true)
          .get();

      final budgets = budgetsSnapshot.docs
          .map((doc) => BudgetModel.fromFirestore(doc))
          .toList();

      // Calculate spending for each budget
      for (final budget in budgets) {
        // Simplified spending calculation - can be enhanced later
        final spending = 0.0; // TODO: Implement proper spending calculation
        
        // Update current spending in Firestore
        await updateCurrentSpending(budget.categoryId, spending);
      }

      // Calculate summary
      final totalBudget = budgets.fold(0.0, (sum, b) => sum + b.monthlyLimit);
      final totalSpending = budgets.fold(0.0, (sum, b) => sum + b.currentSpending);
      final utilizationRate = totalBudget > 0 ? totalSpending / totalBudget : 0.0;

      // Count categories with/without budgets
      final categoriesWithBudgets = budgets.length;
      final categoriesWithoutBudgets = 0; // TODO: Implement proper category counting

      return {
        'totalBudget': totalBudget,
        'utilizationRate': utilizationRate,
        'categoriesWithBudgets': categoriesWithBudgets,
        'categoriesWithoutBudgets': categoriesWithoutBudgets,
      };
    } catch (e) {
      logError('Error calculating budget summary', e);
      return {
        'totalBudget': 0.0,
        'utilizationRate': 0.0,
        'categoriesWithBudgets': 0,
        'categoriesWithoutBudgets': 0,
      };
    }
  }

  /// Delete budget
  Future<void> deleteBudget(String budgetId) async {
    try {
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
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      logInfo('Deleted budget: $budgetId');
    } catch (e) {
      logError('Error deleting budget', e);
      rethrow;
    }
  }
}
