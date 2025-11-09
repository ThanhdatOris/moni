import 'dart:async';
import 'package:moni/constants/enums.dart';
import '../../models/category_model.dart';

/// Service cache categories để tối ưu performance
class CategoryCacheService {
  static final CategoryCacheService _instance = CategoryCacheService._internal();
  factory CategoryCacheService() => _instance;
  CategoryCacheService._internal();

  // Cache với TTL (Time To Live) 5 phút
  final Map<String, _CacheEntry> _cache = {};
  final Duration _cacheTTL = const Duration(minutes: 5);

  /// Lấy categories từ cache hoặc null nếu không có/hết hạn
  List<CategoryModel>? getCachedCategories(TransactionType type) {
    final key = _getCacheKey(type);
    final entry = _cache[key];
    
    if (entry == null || entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    
    return entry.categories;
  }

  /// Cache categories với TTL
  void setCachedCategories(TransactionType type, List<CategoryModel> categories) {
    final key = _getCacheKey(type);
    _cache[key] = _CacheEntry(categories, DateTime.now().add(_cacheTTL));
  }

  /// Xóa cache cho specific type
  void clearCacheForType(TransactionType type) {
    final key = _getCacheKey(type);
    _cache.remove(key);
  }

  /// Xóa toàn bộ cache
  void clearAllCache() {
    _cache.clear();
  }

  /// Kiểm tra cache có hợp lệ không
  bool isCacheValid(TransactionType type) {
    final key = _getCacheKey(type);
    final entry = _cache[key];
    return entry != null && !entry.isExpired;
  }

  /// Lấy cache key dựa trên transaction type
  String _getCacheKey(TransactionType type) {
    return 'categories_${type.value}';
  }

  /// Preload categories để cải thiện UX
  Future<void> preloadCategories(
    TransactionType type, 
    Future<List<CategoryModel>> Function() fetchFunction
  ) async {
    if (isCacheValid(type)) return;

    try {
      final categories = await fetchFunction();
      setCachedCategories(type, categories);
    } catch (e) {
      // Fail silently cho preload
    }
  }

  /// Cleanup expired cache entries
  void cleanupExpiredCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => entry.expiryTime.isBefore(now));
  }
}

/// Cache entry với expiry time
class _CacheEntry {
  final List<CategoryModel> categories;
  final DateTime expiryTime;

  _CacheEntry(this.categories, this.expiryTime);

  bool get isExpired => DateTime.now().isAfter(expiryTime);
}
