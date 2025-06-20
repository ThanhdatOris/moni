import 'package:cloud_firestore/cloud_firestore.dart';

/// Model đại diện cho cảnh báo ngân sách
class BudgetAlertModel {
  final String alertId;
  final String userId;
  final String? categoryId;
  final double threshold;
  final String message;
  final bool isEnabled;
  final DateTime? snoozedUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  BudgetAlertModel({
    required this.alertId,
    required this.userId,
    this.categoryId,
    required this.threshold,
    required this.message,
    this.isEnabled = true,
    this.snoozedUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Tạo BudgetAlertModel từ Map
  factory BudgetAlertModel.fromMap(Map<String, dynamic> map, String id) {
    return BudgetAlertModel(
      alertId: id,
      userId: map['user_id'] ?? '',
      categoryId: map['category_id'],
      threshold: (map['threshold'] as num).toDouble(),
      message: map['message'] ?? '',
      isEnabled: map['is_enabled'] ?? true,
      snoozedUntil: map['snoozed_until'] != null
          ? (map['snoozed_until'] as Timestamp).toDate()
          : null,
      createdAt: (map['created_at'] as Timestamp).toDate(),
      updatedAt: (map['updated_at'] as Timestamp).toDate(),
    );
  }

  /// Chuyển BudgetAlertModel thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'threshold': threshold,
      'message': message,
      'is_enabled': isEnabled,
      'snoozed_until':
          snoozedUntil != null ? Timestamp.fromDate(snoozedUntil!) : null,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Tạo bản sao BudgetAlertModel với một số trường được cập nhật
  BudgetAlertModel copyWith({
    String? alertId,
    String? userId,
    String? categoryId,
    double? threshold,
    String? message,
    bool? isEnabled,
    DateTime? snoozedUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetAlertModel(
      alertId: alertId ?? this.alertId,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      threshold: threshold ?? this.threshold,
      message: message ?? this.message,
      isEnabled: isEnabled ?? this.isEnabled,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Kiểm tra xem cảnh báo có đang bị tạm dừng không
  bool get isSnoozed {
    if (snoozedUntil == null) return false;
    return DateTime.now().isBefore(snoozedUntil!);
  }

  /// Kiểm tra xem cảnh báo có đang hoạt động không
  bool get isActive => isEnabled && !isSnoozed;

  @override
  String toString() {
    return 'BudgetAlertModel(alertId: $alertId, userId: $userId, categoryId: $categoryId, threshold: $threshold, message: $message, isEnabled: $isEnabled, snoozedUntil: $snoozedUntil, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BudgetAlertModel &&
        other.alertId == alertId &&
        other.userId == userId &&
        other.categoryId == categoryId &&
        other.threshold == threshold &&
        other.message == message &&
        other.isEnabled == isEnabled &&
        other.snoozedUntil == snoozedUntil &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return alertId.hashCode ^
        userId.hashCode ^
        categoryId.hashCode ^
        threshold.hashCode ^
        message.hashCode ^
        isEnabled.hashCode ^
        snoozedUntil.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
