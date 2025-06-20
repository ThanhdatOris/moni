import 'package:cloud_firestore/cloud_firestore.dart';

/// Model đại diện cho lịch sử tương tác với chatbot
class ChatLogModel {
  final String interactionId;
  final String userId;
  final String question;
  final String response;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatLogModel({
    required this.interactionId,
    required this.userId,
    required this.question,
    required this.response,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Tạo ChatLogModel từ Map
  factory ChatLogModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatLogModel(
      interactionId: id,
      userId: map['user_id'] ?? '',
      question: map['question'] ?? '',
      response: map['response'] ?? '',
      createdAt: (map['created_at'] as Timestamp).toDate(),
      updatedAt: (map['updated_at'] as Timestamp).toDate(),
    );
  }

  /// Chuyển ChatLogModel thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'question': question,
      'response': response,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Tạo bản sao ChatLogModel với một số trường được cập nhật
  ChatLogModel copyWith({
    String? interactionId,
    String? userId,
    String? question,
    String? response,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatLogModel(
      interactionId: interactionId ?? this.interactionId,
      userId: userId ?? this.userId,
      question: question ?? this.question,
      response: response ?? this.response,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ChatLogModel(interactionId: $interactionId, userId: $userId, question: $question, response: $response, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ChatLogModel &&
        other.interactionId == interactionId &&
        other.userId == userId &&
        other.question == question &&
        other.response == response &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return interactionId.hashCode ^
        userId.hashCode ^
        question.hashCode ^
        response.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
} 