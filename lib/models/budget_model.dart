import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Budget Model - Đơn giản và hiệu quả
class BudgetModel extends Equatable {
  final String id;
  final String userId;
  final String categoryId;
  final String categoryName;
  final double monthlyLimit;
  final double currentSpending;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BudgetModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    required this.monthlyLimit,
    required this.currentSpending,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    categoryId,
    categoryName,
    monthlyLimit,
    currentSpending,
    startDate,
    endDate,
    isActive,
    createdAt,
    updatedAt,
  ];

  /// Tính toán tỷ lệ sử dụng ngân sách
  double get utilizationRate {
    if (monthlyLimit <= 0) return 0.0;
    return (currentSpending / monthlyLimit).clamp(0.0, 2.0);
  }

  /// Tính toán số tiền còn lại
  double get remainingAmount {
    return (monthlyLimit - currentSpending).clamp(0.0, double.infinity);
  }

  /// Kiểm tra xem có vượt quá ngân sách không
  bool get isOverBudget {
    return currentSpending > monthlyLimit;
  }

  /// Kiểm tra xem có gần hết ngân sách không (80%)
  bool get isNearLimit {
    return utilizationRate >= 0.8;
  }

  /// Lấy trạng thái ngân sách
  BudgetStatus get status {
    if (isOverBudget) return BudgetStatus.overBudget;
    if (isNearLimit) return BudgetStatus.warning;
    return BudgetStatus.good;
  }

  /// Copy with method
  BudgetModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? categoryName,
    double? monthlyLimit,
    double? currentSpending,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      currentSpending: currentSpending ?? this.currentSpending,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'category_name': categoryName,
      'monthly_limit': monthlyLimit,
      'current_spending': currentSpending,
      'start_date': Timestamp.fromDate(startDate),
      'end_date': Timestamp.fromDate(endDate),
      'is_active': isActive,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create from Firestore document
  factory BudgetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return BudgetModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      categoryId: data['category_id'] ?? '',
      categoryName: data['category_name'] ?? '',
      monthlyLimit: (data['monthly_limit'] ?? 0).toDouble(),
      currentSpending: (data['current_spending'] ?? 0).toDouble(),
      startDate: (data['start_date'] as Timestamp).toDate(),
      endDate: (data['end_date'] as Timestamp).toDate(),
      isActive: data['is_active'] ?? true,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  /// Create new budget
  factory BudgetModel.create({
    required String userId,
    required String categoryId,
    required String categoryName,
    required double monthlyLimit,
  }) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);

    return BudgetModel(
      id: '', // Will be set by Firestore
      userId: userId,
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
  }
}

/// Budget status enum
enum BudgetStatus {
  good,
  warning,
  overBudget,
}

/// Budget alert model
class BudgetAlert {
  final String id;
  final String budgetId;
  final String message;
  final BudgetAlertType type;
  final DateTime createdAt;
  final bool isRead;

  const BudgetAlert({
    required this.id,
    required this.budgetId,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'budget_id': budgetId,
      'message': message,
      'type': type.index,
      'created_at': Timestamp.fromDate(createdAt),
      'is_read': isRead,
    };
  }

  factory BudgetAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return BudgetAlert(
      id: doc.id,
      budgetId: data['budget_id'] ?? '',
      message: data['message'] ?? '',
      type: BudgetAlertType.values[data['type'] ?? 0],
      createdAt: (data['created_at'] as Timestamp).toDate(),
      isRead: data['is_read'] ?? false,
    );
  }
}

/// Budget alert type enum
enum BudgetAlertType {
  nearLimit,
  overBudget,
  reset,
} 