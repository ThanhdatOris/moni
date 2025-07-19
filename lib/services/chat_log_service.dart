import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

import '../models/chat_log_model.dart';

/// Service quản lý lịch sử tương tác với chatbot
class ChatLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  /// Tạo log tương tác mới
  Future<String> createLog({
    required String question,
    required String response,
    required String conversationId,
    String? transactionId,
    Map<String, dynamic>? transactionData,
  }) async {
    try {
      final user = _auth.currentUser;

      // Nếu conversationId bắt đầu bằng 'temp_', không lưu vào Firestore
      if (conversationId.startsWith('temp_')) {
        _logger.i(
            'Bỏ qua lưu chat log cho conversation tạm thời: $conversationId');
        return 'temp_${DateTime.now().millisecondsSinceEpoch}';
      }

      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final now = DateTime.now();
      final chatLog = ChatLogModel(
        interactionId: '', // Sẽ được Firestore tự tạo
        userId: user.uid,
        conversationId: conversationId,
        question: question,
        response: response,
        createdAt: now,
        updatedAt: now,
        transactionId: transactionId,
        transactionData: transactionData,
      );

      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chat_logs')
          .add(chatLog.toMap());

      _logger.i('Tạo chat log thành công: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.e('Lỗi tạo chat log: $e');
      throw Exception('Không thể tạo chat log: $e');
    }
  }

  /// Lấy lịch sử tương tác của người dùng
  Stream<List<ChatLogModel>> getLogs({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
    String? conversationId,
  }) {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value([]);
      }

      // Nếu conversationId bắt đầu bằng 'temp_', trả về list rỗng
      if (conversationId != null && conversationId.startsWith('temp_')) {
        _logger.i(
            'Trả về chat logs rỗng cho conversation tạm thời: $conversationId');
        return Stream.value([]);
      }

      Query query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chat_logs')
          .orderBy('created_at', descending: true);

      // Lọc theo conversationId nếu có
      if (conversationId != null) {
        query = query.where('conversation_id', isEqualTo: conversationId);
      }

      if (startDate != null) {
        query = query.where('created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('created_at',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return ChatLogModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
      });
    } catch (e) {
      _logger.e('Lỗi lấy lịch sử chat: $e');
      return Stream.value([]);
    }
  }

  /// Lấy lịch sử chat gần đây (10 log gần nhất)
  Stream<List<ChatLogModel>> getRecentLogs({
    int limit = 10,
    String? conversationId,
  }) {
    return getLogs(limit: limit, conversationId: conversationId);
  }

  /// Lấy chat log có chứa giao dịch theo transactionId
  Future<ChatLogModel?> getLogByTransactionId(String transactionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chat_logs')
          .where('transaction_id', isEqualTo: transactionId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return ChatLogModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }

      return null;
    } catch (e) {
      _logger.e('Lỗi lấy chat log theo transactionId: $e');
      return null;
    }
  }

  /// Cập nhật chat log với thông tin giao dịch
  Future<void> updateLogWithTransaction({
    required String interactionId,
    required String transactionId,
    required Map<String, dynamic> transactionData,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chat_logs')
          .doc(interactionId)
          .update({
        'transaction_id': transactionId,
        'transaction_data': transactionData,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });

      _logger.i('Cập nhật chat log với transaction thành công: $interactionId');
    } catch (e) {
      _logger.e('Lỗi cập nhật chat log với transaction: $e');
      throw Exception('Không thể cập nhật chat log: $e');
    }
  }

  /// Xóa tất cả lịch sử chat
  Future<void> clearAllLogs() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chat_logs')
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      _logger.i('Xóa tất cả chat logs thành công cho user: ${user.uid}');
    } catch (e) {
      _logger.e('Lỗi xóa tất cả chat logs: $e');
      throw Exception('Không thể xóa tất cả lịch sử chat: $e');
    }
  }
}
