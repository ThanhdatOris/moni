import 'package:cloud_firestore/cloud_firestore.dart';

import 'transaction_model.dart';

/// Enum định nghĩa các loại icon cho danh mục
enum CategoryIconType {
  material('material'),
  emoji('emoji'),
  custom('custom');

  const CategoryIconType(this.value);
  final String value;

  static CategoryIconType fromString(String value) {
    switch (value) {
      case 'material':
        return CategoryIconType.material;
      case 'emoji':
        return CategoryIconType.emoji;
      case 'custom':
        return CategoryIconType.custom;
      default:
        return CategoryIconType.material;
    }
  }
}

/// Model đại diện cho danh mục giao dịch
class CategoryModel {
  final String categoryId;
  final String userId;
  final String? parentId;
  final String name;
  final TransactionType type;
  final String icon;
  final CategoryIconType iconType;
  final String? customIconUrl;
  final int color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDefault;
  final bool isSuggested;
  final bool isDeleted;

  CategoryModel({
    required this.categoryId,
    required this.userId,
    this.parentId,
    required this.name,
    required this.type,
    required this.icon,
    this.iconType = CategoryIconType.material,
    this.customIconUrl,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
    this.isSuggested = false,
    this.isDeleted = false,
  });

  /// Getter for id to match AI services expectations
  String get id => categoryId;

  /// Kiểm tra loại icon
  bool get isEmoji => iconType == CategoryIconType.emoji;
  bool get isMaterialIcon => iconType == CategoryIconType.material;
  bool get isCustomIcon => iconType == CategoryIconType.custom;

  /// Tạo CategoryModel từ Map
  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      categoryId: id,
      userId: map['user_id'] ?? '',
      parentId: map['parent_id'],
      name: map['name'] ?? '',
      type: TransactionType.fromString(map['type'] ?? 'EXPENSE'),
      icon: map['icon'] ?? 'category',
      iconType: CategoryIconType.fromString(map['icon_type'] ?? 'material'),
      customIconUrl: map['custom_icon_url'],
      color: map['color'] ?? 0xFF607D8B,
      createdAt: (map['created_at'] as Timestamp).toDate(),
      updatedAt: (map['updated_at'] as Timestamp).toDate(),
      isDefault: map['is_default'] ?? false,
      isSuggested: map['is_suggested'] ?? false,
      isDeleted: map['is_deleted'] ?? false,
    );
  }

  /// Chuyển CategoryModel thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'parent_id': parentId,
      'name': name,
      'type': type.value,
      'icon': icon,
      'icon_type': iconType.value,
      'custom_icon_url': customIconUrl,
      'color': color,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'is_default': isDefault,
      'is_suggested': isSuggested,
      'is_deleted': isDeleted,
    };
  }

  /// Tạo bản sao CategoryModel với một số trường được cập nhật
  CategoryModel copyWith({
    String? categoryId,
    String? userId,
    String? parentId,
    String? name,
    TransactionType? type,
    String? icon,
    CategoryIconType? iconType,
    String? customIconUrl,
    int? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDefault,
    bool? isSuggested,
    bool? isDeleted,
  }) {
    return CategoryModel(
      categoryId: categoryId ?? this.categoryId,
      userId: userId ?? this.userId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      iconType: iconType ?? this.iconType,
      customIconUrl: customIconUrl ?? this.customIconUrl,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDefault: isDefault ?? this.isDefault,
      isSuggested: isSuggested ?? this.isSuggested,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// Kiểm tra xem có phải danh mục cha không
  bool get isParentCategory => parentId == null;

  /// Kiểm tra xem có phải danh mục con không
  bool get isChildCategory => parentId != null;

  @override
  String toString() {
    return 'CategoryModel(categoryId: $categoryId, userId: $userId, parentId: $parentId, name: $name, type: $type, icon: $icon, iconType: $iconType, customIconUrl: $customIconUrl, color: $color, createdAt: $createdAt, updatedAt: $updatedAt, isDefault: $isDefault, isSuggested: $isSuggested, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.categoryId == categoryId;
  }

  @override
  int get hashCode => categoryId.hashCode;
}
