/// Model đại diện cho một tin nhắn trong cuộc hội thoại
class ChatMessage {
  final String text;
  final bool isUser; // True nếu tin nhắn từ user, false nếu từ bot
  final DateTime timestamp;
  final String? transactionId; // ID của giao dịch nếu AI tạo giao dịch

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.transactionId,
  });

  /// Tạo bản sao ChatMessage với một số trường được cập nhật
  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    String? transactionId,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      transactionId: transactionId ?? this.transactionId,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(text: $text, isUser: $isUser, timestamp: $timestamp, transactionId: $transactionId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChatMessage &&
        other.text == text &&
        other.isUser == isUser &&
        other.timestamp == timestamp &&
        other.transactionId == transactionId;
  }

  @override
  int get hashCode {
    return text.hashCode ^
        isUser.hashCode ^
        timestamp.hashCode ^
        transactionId.hashCode;
  }
}
