import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';

/// Service quản lý danh mục giao dịch
class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  /// Tạo danh mục mới
  Future<String> createCategory(CategoryModel category) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final now = DateTime.now();
      final categoryData = category.copyWith(
        userId: user.uid,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .add(categoryData.toMap());

      _logger.i('Tạo danh mục thành công: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.e('Lỗi tạo danh mục: $e');
      throw Exception('Không thể tạo danh mục: $e');
    }
  }

  /// Cập nhật danh mục
  Future<void> updateCategory(CategoryModel category) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final updatedCategory = category.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc(category.categoryId)
          .update(updatedCategory.toMap());

      _logger.i('Cập nhật danh mục thành công: ${category.categoryId}');
    } catch (e) {
      _logger.e('Lỗi cập nhật danh mục: $e');
      throw Exception('Không thể cập nhật danh mục: $e');
    }
  }

  /// Xóa danh mục
  Future<void> deleteCategory(String categoryId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      // Kiểm tra xem danh mục có đang được sử dụng không
      final hasTransactions = await _hasTransactionsInCategory(categoryId);
      if (hasTransactions) {
        throw Exception('Không thể xóa danh mục đang có giao dịch');
      }

      // Xóa tất cả danh mục con trước
      await _deleteChildCategories(categoryId);

      // Xóa danh mục chính
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc(categoryId)
          .delete();

      _logger.i('Xóa danh mục thành công: $categoryId');
    } catch (e) {
      _logger.e('Lỗi xóa danh mục: $e');
      throw Exception('Không thể xóa danh mục: $e');
    }
  }

  /// Gán danh mục cha
  Future<void> setParent(String categoryId, String parentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc(categoryId)
          .update({
        'parent_id': parentId,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });

      _logger.i('Gán danh mục cha thành công: $categoryId -> $parentId');
    } catch (e) {
      _logger.e('Lỗi gán danh mục cha: $e');
      throw Exception('Không thể gán danh mục cha: $e');
    }
  }

  /// Lấy danh sách tất cả danh mục của người dùng
  Stream<List<CategoryModel>> getCategories({TransactionType? type}) {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value([]);
      }

      Query query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .orderBy('name');

      if (type != null) {
        query = query.where('type', isEqualTo: type.value);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return CategoryModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
      });
    } catch (e) {
      _logger.e('Lỗi lấy danh sách danh mục: $e');
      return Stream.value([]);
    }
  }

  /// Lấy danh mục cha (không có parent_id)
  Stream<List<CategoryModel>> getParentCategories({TransactionType? type}) {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value([]);
      }

      Query query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .where('parent_id', isNull: true)
          .orderBy('name');

      if (type != null) {
        query = query.where('type', isEqualTo: type.value);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return CategoryModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
      });
    } catch (e) {
      _logger.e('Lỗi lấy danh mục cha: $e');
      return Stream.value([]);
    }
  }

  /// Lấy danh mục con của một danh mục cha
  Stream<List<CategoryModel>> getChildCategories(String parentId) {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value([]);
      }

      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .where('parent_id', isEqualTo: parentId)
          .orderBy('name')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CategoryModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
      });
    } catch (e) {
      _logger.e('Lỗi lấy danh mục con: $e');
      return Stream.value([]);
    }
  }

  /// Lấy chi tiết một danh mục
  Future<CategoryModel?> getCategory(String categoryId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc(categoryId)
          .get();

      if (doc.exists && doc.data() != null) {
        return CategoryModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      _logger.e('Lỗi lấy chi tiết danh mục: $e');
      return null;
    }
  }

  /// Lấy danh mục mặc định của người dùng
  Stream<List<CategoryModel>> getDefaultCategories({TransactionType? type}) {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value([]);
      }

      Query query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .where('is_default', isEqualTo: true)
          .orderBy('name');

      if (type != null) {
        query = query.where('type', isEqualTo: type.value);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return CategoryModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
      });
    } catch (e) {
      _logger.e('Lỗi lấy danh mục mặc định: $e');
      return Stream.value([]);
    }
  }

  /// Tạo danh mục mặc định cho người dùng mới
  Future<void> createDefaultCategories() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      final now = DateTime.now();
      final batch = _firestore.batch();

      // Danh mục thu nhập mặc định
      final incomeCategories = [
        'Lương',
        'Thưởng',
        'Thu nhập phụ',
        'Đầu tư',
        'Khác'
      ];

      // Danh mục chi tiêu mặc định
      final expenseCategories = [
        'Ăn uống',
        'Mua sắm',
        'Đi lại',
        'Giải trí',
        'Y tế',
        'Học tập',
        'Tiện ích',
        'Khác'
      ];

      // Tạo danh mục thu nhập
      for (final categoryName in incomeCategories) {
        final categoryRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('categories')
            .doc();

        final category = CategoryModel(
          categoryId: categoryRef.id,
          userId: user.uid,
          name: categoryName,
          type: TransactionType.income,
          createdAt: now,
          updatedAt: now,
          isDefault: true,
        );

        batch.set(categoryRef, category.toMap());
      }

      // Tạo danh mục chi tiêu
      for (final categoryName in expenseCategories) {
        final categoryRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('categories')
            .doc();

        final category = CategoryModel(
          categoryId: categoryRef.id,
          userId: user.uid,
          name: categoryName,
          type: TransactionType.expense,
          createdAt: now,
          updatedAt: now,
          isDefault: true,
        );

        batch.set(categoryRef, category.toMap());
      }

      await batch.commit();
      _logger.i('Tạo danh mục mặc định thành công cho user: ${user.uid}');
    } catch (e) {
      _logger.e('Lỗi tạo danh mục mặc định: $e');
      throw Exception('Không thể tạo danh mục mặc định: $e');
    }
  }

  /// Kiểm tra xem danh mục có giao dịch không
  Future<bool> _hasTransactionsInCategory(String categoryId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .where('category_id', isEqualTo: categoryId)
          .where('is_deleted', isEqualTo: false)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      _logger.e('Lỗi kiểm tra giao dịch trong danh mục: $e');
      return true; // Err on the side of caution
    }
  }

  /// Xóa tất cả danh mục con
  Future<void> _deleteChildCategories(String parentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .where('parent_id', isEqualTo: parentId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        // Kiểm tra danh mục con có giao dịch không
        final hasTransactions = await _hasTransactionsInCategory(doc.id);
        if (hasTransactions) {
          throw Exception('Không thể xóa danh mục con đang có giao dịch');
        }
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      _logger.e('Lỗi xóa danh mục con: $e');
      rethrow;
    }
  }
}
