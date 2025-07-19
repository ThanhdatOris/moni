import 'package:cloud_firestore/cloud_firestore.dart';

/// Model đại diện cho lịch sử tương tác với chatbot
class ChatLogModel {
  final String interactionId;
  final String userId;
  final String conversationId; // ID của cuộc hội thoại
  final String question;
  final String response;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Thêm thông tin giao dịch nếu AI tạo giao dịch
  final String? transactionId;
  final Map<String, dynamic>? transactionData;

  ChatLogModel({
    required this.interactionId,
    required this.userId,
    required this.conversationId,
    required this.question,
    required this.response,
    required this.createdAt,
    required this.updatedAt,
    this.transactionId,
    this.transactionData,
  });

  /// Tạo ChatLogModel từ Map
  factory ChatLogModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatLogModel(
      interactionId: id,
      userId: map['user_id'] ?? '',
      conversationId: map['conversation_id'] ?? '',
      question: map['question'] ?? '',
      response: map['response'] ?? '',
      createdAt: (map['created_at'] as Timestamp).toDate(),
      updatedAt: (map['updated_at'] as Timestamp).toDate(),
      transactionId: map['transaction_id'],
      transactionData: map['transaction_data'] != null
          ? Map<String, dynamic>.from(map['transaction_data'])
          : null,
    );
  }

  /// Chuyển ChatLogModel thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    final map = {
      'user_id': userId,
      'conversation_id': conversationId,
      'question': question,
      'response': response,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };

    // Chỉ thêm transactionId và transactionData nếu có
    if (transactionId != null) {
      map['transaction_id'] = transactionId as Object;
    }
    if (transactionData != null) {
      map['transaction_data'] = transactionData as Object;
    }

    return map;
  }

  /// Tạo bản sao ChatLogModel với một số trường được cập nhật
  ChatLogModel copyWith({
    String? interactionId,
    String? userId,
    String? conversationId,
    String? question,
    String? response,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? transactionId,
    Map<String, dynamic>? transactionData,
  }) {
    return ChatLogModel(
      interactionId: interactionId ?? this.interactionId,
      userId: userId ?? this.userId,
      conversationId: conversationId ?? this.conversationId,
      question: question ?? this.question,
      response: response ?? this.response,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      transactionId: transactionId ?? this.transactionId,
      transactionData: transactionData ?? this.transactionData,
    );
  }

  /// Kiểm tra xem chat log này có chứa thông tin giao dịch không
  bool get hasTransaction => transactionId != null && transactionId!.isNotEmpty;

  @override
  String toString() {
    return 'ChatLogModel(interactionId: $interactionId, userId: $userId, question: $question, response: $response, createdAt: $createdAt, updatedAt: $updatedAt, transactionId: $transactionId, transactionData: $transactionData)';
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
        other.updatedAt == updatedAt &&
        other.transactionId == transactionId &&
        other.transactionData == transactionData;
  }

  @override
  int get hashCode {
    return interactionId.hashCode ^
        userId.hashCode ^
        question.hashCode ^
        response.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        transactionId.hashCode ^
        transactionData.hashCode;
  }
}
