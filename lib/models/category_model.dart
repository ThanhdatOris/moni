import 'package:cloud_firestore/cloud_firestore.dart';

import 'transaction_model.dart';

/// Model đại diện cho danh mục giao dịch
class CategoryModel {
  final String categoryId;
  final String userId;
  final String? parentId;
  final String name;
  final TransactionType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDefault;
  final bool isSuggested;

  CategoryModel({
    required this.categoryId,
    required this.userId,
    this.parentId,
    required this.name,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
    this.isSuggested = false,
  });

  /// Tạo CategoryModel từ Map
  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      categoryId: id,
      userId: map['user_id'] ?? '',
      parentId: map['parent_id'],
      name: map['name'] ?? '',
      type: TransactionType.fromString(map['type'] ?? 'EXPENSE'),
      createdAt: (map['created_at'] as Timestamp).toDate(),
      updatedAt: (map['updated_at'] as Timestamp).toDate(),
      isDefault: map['is_default'] ?? false,
      isSuggested: map['is_suggested'] ?? false,
    );
  }

  /// Chuyển CategoryModel thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'parent_id': parentId,
      'name': name,
      'type': type.value,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'is_default': isDefault,
      'is_suggested': isSuggested,
    };
  }

  /// Tạo bản sao CategoryModel với một số trường được cập nhật
  CategoryModel copyWith({
    String? categoryId,
    String? userId,
    String? parentId,
    String? name,
    TransactionType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDefault,
    bool? isSuggested,
  }) {
    return CategoryModel(
      categoryId: categoryId ?? this.categoryId,
      userId: userId ?? this.userId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDefault: isDefault ?? this.isDefault,
      isSuggested: isSuggested ?? this.isSuggested,
    );
  }

  /// Kiểm tra xem có phải danh mục cha không
  bool get isParentCategory => parentId == null;

  /// Kiểm tra xem có phải danh mục con không
  bool get isChildCategory => parentId != null;

  @override
  String toString() {
    return 'CategoryModel(categoryId: $categoryId, userId: $userId, parentId: $parentId, name: $name, type: $type, createdAt: $createdAt, updatedAt: $updatedAt, isDefault: $isDefault, isSuggested: $isSuggested)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CategoryModel &&
        other.categoryId == categoryId &&
        other.userId == userId &&
        other.parentId == parentId &&
        other.name == name &&
        other.type == type &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isDefault == isDefault &&
        other.isSuggested == isSuggested;
  }

  @override
  int get hashCode {
    return categoryId.hashCode ^
        userId.hashCode ^
        parentId.hashCode ^
        name.hashCode ^
        type.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        isDefault.hashCode ^
        isSuggested.hashCode;
  }
}
