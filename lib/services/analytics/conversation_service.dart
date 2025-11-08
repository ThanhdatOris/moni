import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

import '../../models/conversation_model.dart';

/// Service quản lý các cuộc hội thoại với chatbot
class ConversationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  /// Tạo tiêu đề động cho cuộc hội thoại dựa trên câu hỏi đầu tiên
  String _generateDynamicTitle(String firstQuestion) {
    // Giới hạn độ dài tiêu đề
    const maxLength = 50;

    if (firstQuestion.length <= maxLength) {
      return firstQuestion;
    }

    // Cắt bớt và thêm dấu ...
    return '${firstQuestion.substring(0, maxLength)}...';
  }

  /// Tạo cuộc hội thoại mới với tiêu đề động
  Future<String> createConversationWithTitle({
    String? firstQuestion,
    String? customTitle,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      // Tạo tiêu đề động hoặc sử dụng tiêu đề tùy chỉnh
      String title;
      if (customTitle != null && customTitle.isNotEmpty) {
        title = customTitle;
      } else if (firstQuestion != null && firstQuestion.isNotEmpty) {
        title = _generateDynamicTitle(firstQuestion);
      } else {
        // Fallback: tạo tiêu đề dựa trên thời gian
        final now = DateTime.now();
        title = 'Cuộc trò chuyện ${now.day}/${now.month}/${now.year}';
      }

      return await createConversation(title: title);
    } catch (e) {
      _logger.e('Lỗi tạo cuộc hội thoại với tiêu đề: $e');
      throw Exception('Không thể tạo cuộc hội thoại: $e');
    }
  }

  /// Tạo cuộc hội thoại mới
  Future<String> createConversation({
    required String title,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final now = DateTime.now();
      final conversation = ConversationModel(
        conversationId: '', // Sẽ được Firestore tự tạo
        userId: user.uid,
        title: title,
        createdAt: now,
        updatedAt: now,
        isActive: true,
        messageCount: 0,
      );

      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('conversations')
          .add(conversation.toMap());

      _logger.i('Tạo cuộc hội thoại thành công: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.e('Lỗi tạo cuộc hội thoại: $e');
      throw Exception('Không thể tạo cuộc hội thoại: $e');
    }
  }

  /// Lấy danh sách tất cả cuộc hội thoại của user
  Stream<List<ConversationModel>> getConversations() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value([]);
      }

      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('conversations')
          .orderBy('updated_at', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return ConversationModel.fromMap(
              doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      _logger.e('Lỗi lấy danh sách cuộc hội thoại: $e');
      return Stream.value([]);
    }
  }

  /// Lấy cuộc hội thoại theo ID
  Future<ConversationModel?> getConversation(String conversationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('conversations')
          .doc(conversationId)
          .get();

      if (doc.exists) {
        return ConversationModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
      }

      return null;
    } catch (e) {
      _logger.e('Lỗi lấy cuộc hội thoại: $e');
      return null;
    }
  }

  /// Cập nhật cuộc hội thoại
  Future<void> updateConversation({
    required String conversationId,
    String? title,
    bool? isActive,
    int? messageCount,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final updates = <String, dynamic>{
        'updated_at': Timestamp.fromDate(DateTime.now()),
      };

      if (title != null) {
        updates['title'] = title;
      }
      if (isActive != null) {
        updates['is_active'] = isActive;
      }
      if (messageCount != null) {
        updates['message_count'] = messageCount;
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('conversations')
          .doc(conversationId)
          .update(updates);

      _logger.i('Cập nhật cuộc hội thoại thành công: $conversationId');
    } catch (e) {
      _logger.e('Lỗi cập nhật cuộc hội thoại: $e');
      throw Exception('Không thể cập nhật cuộc hội thoại: $e');
    }
  }

  /// Cập nhật tiêu đề cuộc hội thoại dựa trên nội dung chat
  Future<void> updateConversationTitle({
    required String conversationId,
    required String newTitle,
  }) async {
    try {
      await updateConversation(
        conversationId: conversationId,
        title: newTitle,
      );
      _logger.i('Cập nhật tiêu đề cuộc hội thoại thành công: $newTitle');
    } catch (e) {
      _logger.e('Lỗi cập nhật tiêu đề cuộc hội thoại: $e');
      throw Exception('Không thể cập nhật tiêu đề: $e');
    }
  }

  /// Xóa cuộc hội thoại và tất cả tin nhắn liên quan
  Future<void> deleteConversation(String conversationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      // Xóa tất cả chat logs của cuộc hội thoại này
      final chatLogsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chat_logs')
          .where('conversation_id', isEqualTo: conversationId)
          .get();

      final batch = _firestore.batch();

      // Xóa chat logs
      for (final doc in chatLogsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Xóa cuộc hội thoại
      batch.delete(_firestore
          .collection('users')
          .doc(user.uid)
          .collection('conversations')
          .doc(conversationId));

      await batch.commit();

      _logger.i('Xóa cuộc hội thoại thành công: $conversationId');
    } catch (e) {
      _logger.e('Lỗi xóa cuộc hội thoại: $e');
      throw Exception('Không thể xóa cuộc hội thoại: $e');
    }
  }

  /// Xóa tất cả cuộc hội thoại của user
  Future<void> deleteAllConversations() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      // Xóa tất cả chat logs
      final chatLogsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chat_logs')
          .get();

      // Xóa tất cả cuộc hội thoại
      final conversationsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('conversations')
          .get();

      final batch = _firestore.batch();

      // Xóa chat logs
      for (final doc in chatLogsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Xóa cuộc hội thoại
      for (final doc in conversationsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      _logger.i('Xóa tất cả cuộc hội thoại thành công cho user: ${user.uid}');
    } catch (e) {
      _logger.e('Lỗi xóa tất cả cuộc hội thoại: $e');
      throw Exception('Không thể xóa tất cả cuộc hội thoại: $e');
    }
  }

  /// Tăng số lượng tin nhắn trong cuộc hội thoại
  Future<void> incrementMessageCount(String conversationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('conversations')
          .doc(conversationId)
          .update({
        'message_count': FieldValue.increment(1),
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });

      _logger.i('Tăng message count thành công: $conversationId');
    } catch (e) {
      _logger.e('Lỗi tăng message count: $e');
      throw Exception('Không thể tăng message count: $e');
    }
  }

  /// Lấy cuộc hội thoại gần nhất hoặc tạo mới
  Future<String> getOrCreateActiveConversation({
    String? firstQuestion,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        // Nếu user chưa đăng nhập, tạo conversation ID tạm thời
        return 'temp_${DateTime.now().millisecondsSinceEpoch}';
      }

      // ✅ ENHANCED: Tìm cuộc hội thoại gần nhất (không chỉ active)
      final recentConversations = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('conversations')
          .orderBy('updated_at', descending: true)
          .limit(1)
          .get();

      if (recentConversations.docs.isNotEmpty) {
        final conversationDoc = recentConversations.docs.first;
        final conversationId = conversationDoc.id;
        
        // ✅ ENHANCED: Set conversation as active nếu chưa active
        final conversationData = conversationDoc.data();
        if (conversationData['is_active'] != true) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('conversations')
              .doc(conversationId)
              .update({
            'is_active': true,
            'updated_at': DateTime.now(),
          });
          _logger.i('Set conversation as active: $conversationId');
        }
        
        _logger.i('Using recent conversation: $conversationId');
        return conversationId;
      }

      // Nếu không có conversation nào, tạo mới với tiêu đề động
      _logger.i('No existing conversations, creating new one');
      final newConversationId = await createConversationWithTitle(firstQuestion: firstQuestion);
      return newConversationId;
    } catch (e) {
      _logger.e('Lỗi lấy hoặc tạo cuộc hội thoại: $e');
      // Fallback: tạo conversation ID tạm thời nếu có lỗi
      return 'temp_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
