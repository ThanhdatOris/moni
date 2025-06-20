import 'package:cloud_firestore/cloud_firestore.dart';

/// Model đại diện cho người dùng trong ứng dụng Moni
class UserModel {
  final String userId;
  final String name;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? defaultCategory;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.defaultCategory,
  });

  /// Tạo UserModel từ Map
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      userId: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      createdAt: (map['created_at'] as Timestamp).toDate(),
      updatedAt: (map['updated_at'] as Timestamp).toDate(),
      defaultCategory: map['default_category'],
    );
  }

  /// Chuyển UserModel thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'default_category': defaultCategory,
    };
  }

  /// Tạo bản sao UserModel với một số trường được cập nhật
  UserModel copyWith({
    String? userId,
    String? name,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? defaultCategory,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      defaultCategory: defaultCategory ?? this.defaultCategory,
    );
  }

  @override
  String toString() {
    return 'UserModel(userId: $userId, name: $name, email: $email, createdAt: $createdAt, updatedAt: $updatedAt, defaultCategory: $defaultCategory)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.userId == userId &&
        other.name == name &&
        other.email == email &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.defaultCategory == defaultCategory;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        name.hashCode ^
        email.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        defaultCategory.hashCode;
  }
}
