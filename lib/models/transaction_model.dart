import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum cho loại giao dịch
enum TransactionType {
  income,
  expense;

  String get value {
    switch (this) {
      case TransactionType.income:
        return 'INCOME';
      case TransactionType.expense:
        return 'EXPENSE';
    }
  }

  static TransactionType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'INCOME':
        return TransactionType.income;
      case 'EXPENSE':
        return TransactionType.expense;
      default:
        throw ArgumentError('Loại giao dịch không hợp lệ: $value');
    }
  }
}

/// Model đại diện cho giao dịch tài chính
class TransactionModel {
  final String transactionId;
  final String userId;
  final String categoryId;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  TransactionModel({
    required this.transactionId,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.date,
    required this.type,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  /// Tạo TransactionModel từ Map
  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      transactionId: id,
      userId: map['user_id'] ?? '',
      categoryId: map['category_id'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      type: TransactionType.fromString(map['type'] ?? 'EXPENSE'),
      note: map['note'],
      createdAt: (map['created_at'] as Timestamp).toDate(),
      updatedAt: (map['updated_at'] as Timestamp).toDate(),
      isDeleted: map['is_deleted'] ?? false,
    );
  }

  /// Chuyển TransactionModel thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'type': type.value,
      'note': note,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'is_deleted': isDeleted,
    };
  }

  /// Tạo bản sao TransactionModel với một số trường được cập nhật
  TransactionModel copyWith({
    String? transactionId,
    String? userId,
    String? categoryId,
    double? amount,
    DateTime? date,
    TransactionType? type,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return TransactionModel(
      transactionId: transactionId ?? this.transactionId,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(transactionId: $transactionId, userId: $userId, categoryId: $categoryId, amount: $amount, date: $date, type: $type, note: $note, createdAt: $createdAt, updatedAt: $updatedAt, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TransactionModel &&
        other.transactionId == transactionId &&
        other.userId == userId &&
        other.categoryId == categoryId &&
        other.amount == amount &&
        other.date == date &&
        other.type == type &&
        other.note == note &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isDeleted == isDeleted;
  }

  @override
  int get hashCode {
    return transactionId.hashCode ^
        userId.hashCode ^
        categoryId.hashCode ^
        amount.hashCode ^
        date.hashCode ^
        type.hashCode ^
        note.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        isDeleted.hashCode;
  }
}
