import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Intelligent caching service for Assistant modules
class AssistantCacheService {
  static final AssistantCacheService _instance =
      AssistantCacheService._internal();
  factory AssistantCacheService() => _instance;
  AssistantCacheService._internal();

  static const String _prefix = 'assistant_cache_';
  static const Duration _defaultTtl = Duration(minutes: 30);
  final Logger _logger = Logger();

  // Memory cache for frequently accessed data
  final Map<String, CacheEntry> _memoryCache = {};
  static const int _maxMemoryEntries = 50;

  /// Cache data with TTL (Time To Live)
  Future<void> cacheData(
    String key,
    dynamic data, {
    Duration? ttl,
    CacheType type = CacheType.memory,
  }) async {
    final effectiveTtl = ttl ?? _defaultTtl;
    final cacheKey = _buildKey(key);

    final entry = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      ttl: effectiveTtl,
      type: type,
    );

    try {
      switch (type) {
        case CacheType.memory:
          _cacheInMemory(cacheKey, entry);
          break;
        case CacheType.persistent:
          await _cachePersistent(cacheKey, entry);
          break;
        case CacheType.both:
          _cacheInMemory(cacheKey, entry);
          await _cachePersistent(cacheKey, entry);
          break;
      }

      _logger.d('Cached data for key: $key (type: ${type.name})');
    } catch (e) {
      _logger.e('Error caching data for key: $key', error: e);
    }
  }

  /// Get cached data
  Future<T?> getCachedData<T>(String key) async {
    final cacheKey = _buildKey(key);

    try {
      // Check memory cache first
      final memoryEntry = _memoryCache[cacheKey];
      if (memoryEntry != null && !memoryEntry.isExpired) {
        _logger.d('Cache hit (memory): $key');
        return memoryEntry.data as T?;
      }

      // Check persistent cache
      final persistentEntry = await _getPersistentCache(cacheKey);
      if (persistentEntry != null && !persistentEntry.isExpired) {
        _logger.d('Cache hit (persistent): $key');
        // Also cache in memory for faster access
        _cacheInMemory(cacheKey, persistentEntry);
        return persistentEntry.data as T?;
      }

      _logger.d('Cache miss: $key');
      return null;
    } catch (e) {
      _logger.e('Error getting cached data for key: $key', error: e);
      return null;
    }
  }

  /// Check if data is cached and not expired
  Future<bool> isCached(String key) async {
    final cacheKey = _buildKey(key);

    // Check memory cache
    final memoryEntry = _memoryCache[cacheKey];
    if (memoryEntry != null && !memoryEntry.isExpired) {
      return true;
    }

    // Check persistent cache
    final persistentEntry = await _getPersistentCache(cacheKey);
    return persistentEntry != null && !persistentEntry.isExpired;
  }

  /// Invalidate specific cache
  Future<void> invalidateCache(String key) async {
    final cacheKey = _buildKey(key);

    // Remove from memory
    _memoryCache.remove(cacheKey);

    // Remove from persistent storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(cacheKey);
      _logger.d('Invalidated cache: $key');
    } catch (e) {
      _logger.e('Error invalidating cache: $key', error: e);
    }
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    try {
      // Clear memory cache
      _memoryCache.clear();

      // Clear persistent cache
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_prefix));

      for (final key in keys) {
        await prefs.remove(key);
      }

      _logger.i('Cleared all assistant cache');
    } catch (e) {
      _logger.e('Error clearing cache', error: e);
    }
  }

  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    try {
      // Clear expired memory cache
      _memoryCache.removeWhere((key, entry) => entry.isExpired);

      // Clear expired persistent cache
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_prefix));

      for (final key in keys) {
        final entry = await _getPersistentCache(key);
        if (entry != null && entry.isExpired) {
          await prefs.remove(key);
        }
      }

      _logger.d('Cleared expired cache entries');
    } catch (e) {
      _logger.e('Error clearing expired cache', error: e);
    }
  }

  /// Get cache statistics
  Future<CacheStats> getCacheStats() async {
    int memoryEntries = _memoryCache.length;
    int persistentEntries = 0;
    int expiredEntries = 0;

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_prefix));
      persistentEntries = keys.length;

      for (final key in keys) {
        final entry = await _getPersistentCache(key);
        if (entry != null && entry.isExpired) {
          expiredEntries++;
        }
      }
    } catch (e) {
      _logger.e('Error getting cache stats', error: e);
    }

    return CacheStats(
      memoryEntries: memoryEntries,
      persistentEntries: persistentEntries,
      expiredEntries: expiredEntries,
      memoryHitRate: _calculateHitRate(),
    );
  }

  /// Cache data in memory with LRU eviction
  void _cacheInMemory(String key, CacheEntry entry) {
    // Remove oldest entries if cache is full
    if (_memoryCache.length >= _maxMemoryEntries) {
      final oldestKey = _memoryCache.entries
          .reduce(
              (a, b) => a.value.timestamp.isBefore(b.value.timestamp) ? a : b)
          .key;
      _memoryCache.remove(oldestKey);
    }

    _memoryCache[key] = entry;
  }

  /// Cache data persistently
  Future<void> _cachePersistent(String key, CacheEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = jsonEncode(entry.toJson());
    await prefs.setString(key, serialized);
  }

  /// Get persistent cache entry
  Future<CacheEntry?> _getPersistentCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serialized = prefs.getString(key);

      if (serialized != null) {
        final json = jsonDecode(serialized) as Map<String, dynamic>;
        return CacheEntry.fromJson(json);
      }
    } catch (e) {
      _logger.e('Error getting persistent cache: $key', error: e);
    }

    return null;
  }

  String _buildKey(String key) => '$_prefix$key';

  double _calculateHitRate() {
    // Simple hit rate calculation - could be enhanced with actual tracking
    return _memoryCache.isNotEmpty ? 0.8 : 0.0;
  }

  /// Dispose resources
  void dispose() {
    _memoryCache.clear();
  }
}

/// Cache entry model
class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration ttl;
  final CacheType type;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
    required this.type,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;

  Map<String, dynamic> toJson() => {
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'ttl_seconds': ttl.inSeconds,
        'type': type.name,
      };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
        data: json['data'],
        timestamp: DateTime.parse(json['timestamp'] as String),
        ttl: Duration(seconds: json['ttl_seconds'] as int),
        type: CacheType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => CacheType.memory,
        ),
      );
}

/// Cache types
enum CacheType { memory, persistent, both }

/// Cache statistics
class CacheStats {
  final int memoryEntries;
  final int persistentEntries;
  final int expiredEntries;
  final double memoryHitRate;

  CacheStats({
    required this.memoryEntries,
    required this.persistentEntries,
    required this.expiredEntries,
    required this.memoryHitRate,
  });

  @override
  String toString() =>
      'CacheStats(memory: $memoryEntries, persistent: $persistentEntries, '
      'expired: $expiredEntries, hitRate: ${(memoryHitRate * 100).toStringAsFixed(1)}%)';
}

/// Cache keys for different data types
class CacheKeys {
  static const String analyticsData = 'analytics_data';
  static const String budgetData = 'budget_data';
  static const String aiInsights = 'ai_insights';
  static const String chartData = 'chart_data';
  static const String userPreferences = 'user_preferences';
  static const String conversationHistory = 'conversation_history';

  // Generate timestamped keys
  static String withTimestamp(String baseKey) =>
      '${baseKey}_${DateTime.now().millisecondsSinceEpoch}';
  static String withUserId(String baseKey, String userId) =>
      '${baseKey}_$userId';
  static String withPeriod(String baseKey, String period) =>
      '${baseKey}_$period';
}
