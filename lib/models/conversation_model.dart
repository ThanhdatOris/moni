import 'package:cloud_firestore/cloud_firestore.dart';

/// Model đại diện cho một cuộc hội thoại với chatbot
class ConversationModel {
  final String conversationId;
  final String userId;
  final String title; // Tiêu đề cuộc hội thoại (auto-generated)
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive; // Cuộc hội thoại đang active hay không
  final int messageCount; // Số lượng tin nhắn trong cuộc hội thoại

  ConversationModel({
    required this.conversationId,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.messageCount = 0,
  });

  /// Tạo ConversationModel từ Map
  factory ConversationModel.fromMap(Map<String, dynamic> map, String id) {
    return ConversationModel(
      conversationId: id,
      userId: map['user_id'] ?? '',
      title: map['title'] ?? 'Cuộc trò chuyện mới',
      createdAt: (map['created_at'] as Timestamp).toDate(),
      updatedAt: (map['updated_at'] as Timestamp).toDate(),
      isActive: map['is_active'] ?? true,
      messageCount: map['message_count'] ?? 0,
    );
  }

  /// Chuyển ConversationModel thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'title': title,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'is_active': isActive,
      'message_count': messageCount,
    };
  }

  /// Tạo bản sao ConversationModel với một số trường được cập nhật
  ConversationModel copyWith({
    String? conversationId,
    String? userId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? messageCount,
  }) {
    return ConversationModel(
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  /// Tạo tiêu đề tự động từ tin nhắn đầu tiên
  static String generateTitle(String firstMessage) {
    if (firstMessage.length <= 30) {
      return firstMessage;
    }
    return '${firstMessage.substring(0, 27)}...';
  }

  @override
  String toString() {
    return 'ConversationModel(conversationId: $conversationId, userId: $userId, title: $title, createdAt: $createdAt, updatedAt: $updatedAt, isActive: $isActive, messageCount: $messageCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ConversationModel &&
        other.conversationId == conversationId &&
        other.userId == userId &&
        other.title == title &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isActive == isActive &&
        other.messageCount == messageCount;
  }

  @override
  int get hashCode {
    return conversationId.hashCode ^
        userId.hashCode ^
        title.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        isActive.hashCode ^
        messageCount.hashCode;
  }
}
