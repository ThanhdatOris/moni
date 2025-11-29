import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:moni/constants/enums.dart';

import '../../models/category_model.dart';
import 'category_cache_service.dart';
import '../core/environment_service.dart';

/// Service quản lý danh mục giao dịch
class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  // ✅ Cache để tránh log spam
  final Map<String, DateTime> _lastLogTimes = {};
  final CategoryCacheService _cacheService = CategoryCacheService();

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

      // ✅ IMPROVED: Only log in debug mode with essential info
      if (EnvironmentService.debugMode && EnvironmentService.loggingEnabled) {
        _logger.d('📁 Category created: ${category.name} (${docRef.id})');
      }
      return docRef.id;
    } catch (e) {
      _logger.e('❌ Error creating category: $e');
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

      final updatedCategory = category.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .doc(category.categoryId)
          .update(updatedCategory.toMap());

      // ✅ IMPROVED: Only log in debug mode with essential info
      if (EnvironmentService.debugMode && EnvironmentService.loggingEnabled) {
        _logger.d(
          '📝 Category updated: ${category.name} (${category.categoryId})',
        );
      }
    } catch (e) {
      _logger.e('❌ Lỗi cập nhật danh mục: $e');
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

      // ✅ IMPROVED: Only log in debug mode with essential info
      if (EnvironmentService.debugMode && EnvironmentService.loggingEnabled) {
        _logger.d('🗑️ Category deleted: $categoryId');
      }
    } catch (e) {
      _logger.e('❌ Lỗi xóa danh mục: $e');
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

      // ✅ IMPROVED: Only log in debug mode with essential info
      if (EnvironmentService.debugMode && EnvironmentService.loggingEnabled) {
        _logger.d('🔗 Category parent set: $categoryId → $parentId');
      }
    } catch (e) {
      _logger.e('❌ Lỗi gán danh mục cha: $e');
      throw Exception('Không thể gán danh mục cha: $e');
    }
  }

  /// Lấy danh sách danh mục của người dùng với cache tối ưu
  Stream<List<CategoryModel>> getCategoriesOptimized({
    TransactionType? type,
  }) async* {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        yield [];
        return;
      }

      // Kiểm tra cache trước
      if (type != null) {
        final cachedCategories = _cacheService.getCachedCategories(type);
        if (cachedCategories != null) {
          yield cachedCategories;
        }
      }

      // Lấy dữ liệu từ Firestore
      Query query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .where('is_deleted', isEqualTo: false);

      // Áp dụng filter type nếu có
      if (type != null) {
        query = query.where('type', isEqualTo: type.value);
      } else {
        query = query.orderBy('name');
      }

      await for (final snapshot in query.snapshots()) {
        var categories = snapshot.docs.map((doc) {
          return CategoryModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();

        // Sắp xếp trong client nếu cần
        if (type != null) {
          categories.sort((a, b) => a.name.compareTo(b.name));
          // Cache kết quả
          _cacheService.setCachedCategories(type, categories);
        }

        yield categories;
      }
    } catch (e) {
      _logger.e('Lỗi lấy danh sách danh mục: $e');
      yield [];
    }
  }

  /// Lấy danh sách danh mục của người dùng
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
          .where('is_deleted', isEqualTo: false);

      // Áp dụng filter type nếu có
      if (type != null) {
        // ✅ IMPROVED: Only log filtering in debug mode
        if (EnvironmentService.debugMode && EnvironmentService.loggingEnabled) {
          _logger.d('🔍 Filtering categories by type: ${type.value}');
        }
        query = query.where('type', isEqualTo: type.value);
        // Không thêm orderBy khi có where clause để tránh cần composite index
      } else {
        // ✅ FIXED: Không orderBy để tránh composite index requirements
        // Sẽ sort ở client side thay thế
      }

      return query.snapshots().map((snapshot) {
        // ⏱️ PERFORMANCE: Measure query processing time
        final startTime = DateTime.now();

        // ✅ IMPROVED: Reduce log spam với throttling
        if (EnvironmentService.debugMode && EnvironmentService.loggingEnabled) {
          final now = DateTime.now();
          final cacheKey = 'categories_log_${type?.value ?? 'all'}';
          final lastLogTime = _lastLogTimes[cacheKey];

          // Chỉ log mỗi 5 giây để tránh spam
          if (lastLogTime == null ||
              now.difference(lastLogTime).inSeconds > 5) {
            _logger.d(
              '📦 Categories query returned ${snapshot.docs.length} documents${type != null ? " (filtered by ${type.value})" : ""}',
            );
            _lastLogTimes[cacheKey] = now;
          }
        }

        var categories = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return CategoryModel.fromMap(data, doc.id);
        }).toList();

        // ✅ FIXED: Always sort on client side để tránh index requirements
        categories.sort((a, b) => a.name.compareTo(b.name));

        // ⏱️ PERFORMANCE: Log processing time
        final processingTime = DateTime.now().difference(startTime);
        if (EnvironmentService.debugMode && EnvironmentService.loggingEnabled) {
          _logger.d(
            '⏱️ Category query processed in ${processingTime.inMilliseconds}ms',
          );
        }

        return categories;
      });
    } catch (e) {
      _logger.e('❌ Error getting categories: $e');
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
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
      });
    } catch (e) {
      _logger.e('❌ Error getting parent categories: $e');
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
              return CategoryModel.fromMap(doc.data(), doc.id);
            }).toList();
          });
    } catch (e) {
      _logger.e('❌ Error getting child categories: $e');
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
        return CategoryModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      _logger.e('❌ Error getting category details: $e');
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
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
      });
    } catch (e) {
      _logger.e('❌ Error getting default categories: $e');
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

      // Kiểm tra xem đã có danh mục chưa
      final existingCategories = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .limit(1)
          .get();

      if (existingCategories.docs.isNotEmpty) {
        // ✅ IMPROVED: Only log in debug mode
        if (EnvironmentService.debugMode && EnvironmentService.loggingEnabled) {
          _logger.d('📁 Default categories already exist, skipping creation');
        }
        return;
      }

      final now = DateTime.now();
      final batch = _firestore.batch();

      // Danh mục chi tiêu với emoji
      final expenseCategories = [
        {
          'name': 'Ăn uống',
          'icon': '🍽️',
          'iconType': 'emoji',
          'color': 0xFFFF6B35,
        },
        {
          'name': 'Di chuyển',
          'icon': '🚗',
          'iconType': 'emoji',
          'color': 0xFF2196F3,
        },
        {
          'name': 'Mua sắm',
          'icon': '🛒',
          'iconType': 'emoji',
          'color': 0xFF9C27B0,
        },
        {
          'name': 'Giải trí',
          'icon': '🎬',
          'iconType': 'emoji',
          'color': 0xFFFF9800,
        },
        {
          'name': 'Hóa đơn',
          'icon': '🧾',
          'iconType': 'emoji',
          'color': 0xFFF44336,
        },
        {
          'name': 'Y tế',
          'icon': '🏥',
          'iconType': 'emoji',
          'color': 0xFF4CAF50,
        },
      ];

      // Danh mục thu nhập với emoji
      final incomeCategories = [
        {
          'name': 'Lương',
          'icon': '💼',
          'iconType': 'emoji',
          'color': 0xFF4CAF50,
        },
        {
          'name': 'Thưởng',
          'icon': '🎁',
          'iconType': 'emoji',
          'color': 0xFFFFD700,
        },
        {
          'name': 'Đầu tư',
          'icon': '📈',
          'iconType': 'emoji',
          'color': 0xFF00BCD4,
        },
        {
          'name': 'Khác',
          'icon': '💰',
          'iconType': 'emoji',
          'color': 0xFF607D8B,
        },
      ];

      // Tạo danh mục chi tiêu
      for (final categoryData in expenseCategories) {
        final docRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('categories')
            .doc();

        final category = CategoryModel(
          categoryId: docRef.id,
          userId: user.uid,
          name: categoryData['name'] as String,
          type: TransactionType.expense,
          icon: categoryData['icon'] as String,
          iconType: CategoryIconType.fromString(
            categoryData['iconType'] as String? ?? 'material',
          ),
          color: categoryData['color'] as int,
          isDefault: true,
          parentId: null,
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
        );

        batch.set(docRef, category.toMap());
      }

      // Tạo danh mục thu nhập
      for (final categoryData in incomeCategories) {
        final docRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('categories')
            .doc();

        final category = CategoryModel(
          categoryId: docRef.id,
          userId: user.uid,
          name: categoryData['name'] as String,
          type: TransactionType.income,
          icon: categoryData['icon'] as String,
          iconType: CategoryIconType.fromString(
            categoryData['iconType'] as String? ?? 'material',
          ),
          color: categoryData['color'] as int,
          isDefault: true,
          parentId: null,
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
        );

        batch.set(docRef, category.toMap());
      }

      await batch.commit();
      // ✅ IMPROVED: Single comprehensive success message
      _logger.i(
        '📁 Default categories created successfully (${expenseCategories.length + incomeCategories.length} categories)',
      );
    } catch (e) {
      _logger.e('❌ Error creating default categories: $e');
      throw Exception('Không thể tạo danh mục mặc định: $e');
    }
  }

  /// Get all categories for user (alias method for frontend compatibility)
  Future<List<CategoryModel>> getUserCategories(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .where('is_deleted', isEqualTo: false)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) {
        return CategoryModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      _logger.e('❌ Error getting user categories: $e');
      return [];
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
      _logger.e('❌ Error checking transactions in category: $e');
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
      _logger.e('❌ Error deleting child categories: $e');
      rethrow;
    }
  }
}
