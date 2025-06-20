import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'transaction.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final TransactionType type;
  final String? parentId;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    String? id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.parentId,
    this.isDefault = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert Category to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'color': color.value,
      'type': type.index,
      'parentId': parentId,
      'isDefault': isDefault ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Create Category from Map
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      icon: IconData(map['icon'], fontFamily: 'MaterialIcons'),
      color: Color(map['color']),
      type: TransactionType.values[map['type']],
      parentId: map['parentId'],
      isDefault: map['isDefault'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  // Copy with new values
  Category copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    TransactionType? type,
    String? parentId,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Static method to get default categories
  static List<Category> getDefaultCategories() {
    return [
      // Income categories
      Category(
        id: 'income_salary',
        name: 'Lương',
        icon: Icons.work,
        color: const Color(0xFF4CAF50),
        type: TransactionType.income,
        isDefault: true,
      ),
      Category(
        id: 'income_bonus',
        name: 'Thưởng',
        icon: Icons.card_giftcard,
        color: const Color(0xFF2E7D32),
        type: TransactionType.income,
        isDefault: true,
      ),
      Category(
        id: 'income_investment',
        name: 'Đầu tư',
        icon: Icons.trending_up,
        color: const Color(0xFF388E3C),
        type: TransactionType.income,
        isDefault: true,
      ),
      Category(
        id: 'income_freelance',
        name: 'Làm thêm',
        icon: Icons.computer,
        color: const Color(0xFF43A047),
        type: TransactionType.income,
        isDefault: true,
      ),
      Category(
        id: 'income_other',
        name: 'Thu khác',
        icon: Icons.attach_money,
        color: const Color(0xFF66BB6A),
        type: TransactionType.income,
        isDefault: true,
      ),

      // Expense categories
      Category(
        id: 'expense_food',
        name: 'Ăn uống',
        icon: Icons.restaurant,
        color: const Color(0xFFFF9800),
        type: TransactionType.expense,
        isDefault: true,
      ),
      Category(
        id: 'expense_transport',
        name: 'Di chuyển',
        icon: Icons.directions_car,
        color: const Color(0xFF2196F3),
        type: TransactionType.expense,
        isDefault: true,
      ),
      Category(
        id: 'expense_shopping',
        name: 'Mua sắm',
        icon: Icons.shopping_bag,
        color: const Color(0xFF9C27B0),
        type: TransactionType.expense,
        isDefault: true,
      ),
      Category(
        id: 'expense_entertainment',
        name: 'Giải trí',
        icon: Icons.movie,
        color: const Color(0xFFE91E63),
        type: TransactionType.expense,
        isDefault: true,
      ),
      Category(
        id: 'expense_bills',
        name: 'Hóa đơn',
        icon: Icons.receipt,
        color: const Color(0xFFF44336),
        type: TransactionType.expense,
        isDefault: true,
      ),
      Category(
        id: 'expense_health',
        name: 'Sức khỏe',
        icon: Icons.local_hospital,
        color: const Color(0xFF607D8B),
        type: TransactionType.expense,
        isDefault: true,
      ),
      Category(
        id: 'expense_education',
        name: 'Giáo dục',
        icon: Icons.school,
        color: const Color(0xFF795548),
        type: TransactionType.expense,
        isDefault: true,
      ),
      Category(
        id: 'expense_travel',
        name: 'Du lịch',
        icon: Icons.flight,
        color: const Color(0xFF00BCD4),
        type: TransactionType.expense,
        isDefault: true,
      ),
      Category(
        id: 'expense_other',
        name: 'Chi khác',
        icon: Icons.more_horiz,
        color: const Color(0xFF9E9E9E),
        type: TransactionType.expense,
        isDefault: true,
      ),
    ];
  }

  // Get categories by type
  static List<Category> getCategoriesByType(TransactionType type) {
    return getDefaultCategories()
        .where((category) => category.type == type)
        .toList();
  }

  // Get category by id
  static Category? getCategoryById(String id) {
    try {
      return getDefaultCategories().firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }
} 