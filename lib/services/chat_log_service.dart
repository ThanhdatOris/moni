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
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final now = DateTime.now();
      final chatLog = ChatLogModel(
        interactionId: '', // Sẽ được Firestore tự tạo
        userId: user.uid,
        question: question,
        response: response,
        createdAt: now,
        updatedAt: now,
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
  }) {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value([]);
      }

      Query query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chat_logs')
          .orderBy('created_at', descending: true);

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
  Stream<List<ChatLogModel>> getRecentLogs({int limit = 10}) {
    return getLogs(limit: limit);
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
